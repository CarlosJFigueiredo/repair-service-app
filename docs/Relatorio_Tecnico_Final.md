# Relatório Técnico Final — Técnico Resolve

**Aluno:** Carlos Figueiredo  
**Disciplina:** Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas — PUC Minas  
**Curso:** Engenharia de Software — 5º Período  
**Semestre:** 1º Semestre 2026  

---

## 1. Introdução

O **Técnico Resolve** é uma plataforma de suporte técnico sob demanda que conecta clientes com problemas em dispositivos eletrônicos a técnicos especializados. O sistema foi desenvolvido ao longo de quatro sprints, partindo de um Web Service REST até a entrega de um fluxo completo de ponta a ponta com dois papéis de usuário (Cliente e Técnico), comunicação assíncrona via MOM e aplicativo móvel multiplataforma em Flutter.

Este relatório consolida as decisões de arquitetura, os padrões aplicados, as dificuldades encontradas e as soluções adotadas em cada fase do projeto.

---

## 2. Arquitetura do Sistema

### 2.1 Visão Geral

O sistema segue uma **Arquitetura Orientada a Eventos (EDA)** com três componentes principais:

```
┌─────────────────────────────────────────────────────────────┐
│            APLICATIVOS FLUTTER (mobile_cliente)             │
│                                                             │
│  Role: CLIENTE              Role: TÉCNICO                   │
│  ─ Abrir chamado            ─ Ver chamados disponíveis      │
│  ─ Acompanhar status        ─ Aceitar / Recusar             │
│  ─ Ver alertas              ─ Atualizar progresso           │
│                                                             │
│         Polling automático a cada 30 segundos               │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP REST + JWT
┌──────────────────────────▼──────────────────────────────────┐
│              BACKEND (Flask REST API)                       │
│                                                             │
│  /api/usuarios/    Cadastro e autenticação JWT              │
│  /api/chamados/    CRUD de chamados com controle de papel   │
│                                                             │
│  chamado_service.py ──► publicar_evento() ──► RabbitMQ      │
└──────────────────────────┬──────────────────────────────────┘
                           │ AMQP (pika)
┌──────────────────────────▼──────────────────────────────────┐
│               RabbitMQ 3.13 (MOM)                           │
│                                                             │
│  fila: chamado.criado          (durable)                    │
│  fila: chamado.status_alterado (durable)                    │
│                                                             │
│  Consumer independente (consumer_runner.py)                 │
└─────────────────────────────────────────────────────────────┘
         │ SQLite
┌────────▼────────────────────────────────────────────────────┐
│  Banco de dados: usuarios, chamados                         │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Backend — Flask REST API

O backend foi desenvolvido em **Python com Flask**, seguindo uma organização em camadas:

| Camada | Módulo | Responsabilidade |
|---|---|---|
| Rotas | `app/routes/` | Receber requisições HTTP, validar papel do usuário |
| Serviços | `app/services/` | Regras de negócio e publicação de eventos MOM |
| Repositórios | `app/repositories/` | Acesso ao banco de dados SQLite |
| Modelos | `app/models/` | Entidades do domínio (Usuario, Chamado) |
| Messaging | `app/messaging/` | Producer e Consumer RabbitMQ |

O controle de acesso é feito por papel (`perfil`): apenas `CLIENTE` pode criar chamados; apenas `TECNICO` pode atualizar status. A autenticação usa **JWT** verificado em cada requisição via decorator.

### 2.3 Fluxo de Status do Chamado

```
ABERTO ──► ACEITO ──► EM_ANDAMENTO ──► CONCLUIDO
       │        │
       └────────┴──► RECUSADO
```

Cada transição dispara a publicação de um evento `chamado.status_alterado` no RabbitMQ.

### 2.4 Aplicativo Flutter — Clean Architecture

O aplicativo móvel adota **Clean Architecture** em quatro camadas, com dependências sempre apontando de fora para dentro:

```
┌─────────────────────────────────────────────────────────────┐
│  APRESENTAÇÃO — features/*/screens/                         │
│  Telas: auth, chamados, historico, alertas, perfil, home    │
└──────────────────────┬──────────────────────────────────────┘
                       │ consome
┌──────────────────────▼──────────────────────────────────────┐
│  ESTADO — core/providers/                                   │
│  AuthProvider, ChamadoProvider (ChangeNotifier + polling)   │
└──────────────────────┬──────────────────────────────────────┘
                       │ chama
┌──────────────────────▼──────────────────────────────────────┐
│  DADOS — core/services/                                     │
│  ApiClient (Dio + interceptor JWT), StorageService (JWT)    │
└──────────────────────┬──────────────────────────────────────┘
                       │ mapeia
┌──────────────────────▼──────────────────────────────────────┐
│  DOMÍNIO — features/*/models/                               │
│  Usuario, Chamado (entidades puras sem dependências)        │
└─────────────────────────────────────────────────────────────┘
```

Um único aplicativo serve os dois papéis: o campo `perfil` do token JWT (`CLIENTE` | `TECNICO`) controla quais telas e ações ficam disponíveis para cada usuário.

---

## 3. Decisões de Design

### 3.1 Um app Flutter para dois perfis

**Decisão:** manter um único aplicativo Flutter com navegação condicional baseada no campo `perfil` do usuário autenticado, em vez de dois apps separados.

**Justificativa:** a maior parte do código (autenticação, cliente HTTP, tema, modelos) é compartilhada entre os dois papéis. Manter duas bases de código independentes duplicaria o esforço de manutenção sem benefício proporcional. O padrão de feature-first (vertical slices) garante que cada feature seja coesa e contenha apenas o que lhe pertence.

### 3.2 Polling como mecanismo de notificação

**Decisão:** implementar polling automático a cada 30 segundos via `Timer.periodic` no `HomeScreen`, acionando `ChamadoProvider.listar()`.

**Justificativa:** polling é simples de implementar, depurar e manter, sem necessidade de infraestrutura adicional no cliente (sem canal WebSocket persistente, sem plugin STOMP/AMQP). Para o volume de uso esperado em ambiente acadêmico, o intervalo de 30 segundos oferece responsividade suficiente. O backend já publica eventos no RabbitMQ, o que deixa aberta a migração futura para WebSocket ou notificações push sem mudança de lógica de negócio.

### 3.3 RabbitMQ como broker de mensagens

**Decisão:** adotar RabbitMQ 3.13 via Docker com a biblioteca `pika` para Python.

**Justificativa:** o protocolo AMQP oferece garantias de entrega (`basic_ack`), filas duráveis e reconexão automática. A Management UI integrada (`http://localhost:15672`) facilita a inspeção das filas durante o desenvolvimento. A biblioteca `pika` é madura e mantém consistência com o stack Flask/Python do projeto.

### 3.4 Producer resiliente ao broker indisponível

**Decisão:** o producer envolve todas as chamadas ao RabbitMQ em `try/except`, registra o erro em log e retorna normalmente caso o broker esteja indisponível.

**Justificativa:** o servidor Flask não pode ser derrubado por uma falha no MOM. A API REST deve continuar funcional independentemente do estado do broker, degradando apenas a notificação assíncrona — não o serviço principal.

### 3.5 SQLite como banco de dados

**Decisão:** utilizar SQLite em vez de PostgreSQL ou MySQL.

**Justificativa:** SQLite elimina a necessidade de um processo de banco de dados separado, simplificando a execução local e o CI. O volume de dados e a concorrência esperados em ambiente acadêmico não justificam a complexidade de um banco cliente-servidor.

---

## 4. Dificuldades Encontradas e Soluções Adotadas

### 4.1 Conflito de porta do RabbitMQ

**Problema:** durante o desenvolvimento, a porta padrão do AMQP (5672) estava ocupada por outro container RabbitMQ de um projeto paralelo na mesma máquina. Tentar subir o `docker-compose.yml` resultava em erro de bind de porta.

**Solução:** mapear a porta externa para `5673` no `docker-compose.yml`, mantendo a porta interna do container em 5672 (padrão AMQP). O arquivo de conexão `connection.py` aponta explicitamente para `localhost:5673`, isolando os dois ambientes sem interromper nenhum dos projetos.

### 4.2 Autenticação JWT no Flutter com Dio

**Problema:** todas as requisições autenticadas precisavam incluir o header `Authorization: Bearer <token>`, mas gerenciar esse header manualmente em cada chamada seria frágil e repetitivo.

**Solução:** implementar um interceptor Dio (`api_client.dart`) que injeta automaticamente o token em cada requisição e intercepta respostas 401 para redirecionar ao login. O token é persistido via `SharedPreferences` (através do `StorageService`) e lido a cada inicialização do app, mantendo a sessão entre fechamentos.

### 4.3 Controle de papel na mesma tela

**Problema:** `ListaChamadosScreen` e `DetalhesChamadoScreen` precisam se comportar de forma diferente para clientes e técnicos (FAB oculto, botões de ação distintos, filtros de API diferentes), mas manter duas telas duplicadas seria custoso.

**Solução:** ler o perfil do usuário autenticado via `context.watch<AuthProvider>().usuario?.perfil` e condicionar a renderização de widgets e chamadas de API dentro da mesma tela. Isso mantém a lógica de negócio centralizada e o código de UI coeso.

### 4.4 Sincronização de estado entre telas após ação do técnico

**Problema:** após o técnico aceitar um chamado na `DetalhesChamadoScreen`, a `ListaChamadosScreen` precisava refletir o novo status imediatamente, mas o estado era mantido em cache no provider.

**Solução:** após cada mutação de status, o provider chama `listar()` para refazer o fetch completo e `notifyListeners()` para reconstruir todas as telas ouvintes. O polling de 30 segundos garante convergência mesmo em casos onde a atualização manual falhe.

---

## 5. Reflexão sobre os Padrões Estudados

### 5.1 Clean Architecture

A separação em camadas (Apresentação → Estado → Dados → Domínio) demonstrou seu valor prático: foi possível trocar o mecanismo de polling (de 10 para 30 segundos) e ajustar endpoints da API sem tocar nas telas. As entidades `Usuario` e `Chamado` permaneceram estáveis ao longo de todas as sprints, validando a premissa de que o domínio deve ser isolado de detalhes de infraestrutura [MARTIN, 2017].

### 5.2 REST

A API segue os princípios REST: recursos identificados por URI (`/api/chamados/{id}`), verbos HTTP semânticos (GET para leitura, POST para criação, PATCH para atualização de status), respostas em JSON e ausência de estado no servidor (stateless via JWT). A granularidade de endpoints por recurso e o controle de acesso por papel demonstram como REST facilita a evolução independente de cliente e servidor [FIELDING, 2000].

### 5.3 EDA — Arquitetura Orientada a Eventos

O backend produz eventos (`chamado.criado`, `chamado.status_alterado`) como consequência de operações de escrita, sem conhecimento de quem vai consumi-los. Isso desacopla o produtor do consumidor: o `chamado_service.py` não chama o consumer diretamente, apenas publica no broker. Qualquer novo consumidor (notificações push, analytics, auditoria) pode ser adicionado sem modificar o serviço produtor [FOWLER, 2017].

### 5.4 MOM — Middleware Orientado a Mensagens

O RabbitMQ cumpriu seu papel de intermediário assíncrono: as mensagens persistem na fila mesmo que o consumer esteja temporariamente indisponível, e o `basic_ack` garante que uma mensagem só seja removida da fila após processamento confirmado. O padrão Produtor/Consumidor com filas diretas mostrou-se adequado para o volume e a complexidade do projeto, com a Management UI acelerando significativamente o debug durante o desenvolvimento [VIDELA; WILLIAMS, 2012].

---

## 6. Demonstração do Fluxo Completo

O fluxo de ponta a ponta implementado é:

```
1. Cliente abre o app e cria um chamado
   POST /api/chamados/  →  backend persiste no SQLite

2. Backend publica evento no MOM
   publicar_evento("chamado.criado", payload)  →  fila RabbitMQ

3. Consumer recebe e processa o evento
   _callback_chamado_criado()  →  log de auditoria

4. Técnico recebe notificação (polling 30s)
   GET /api/chamados/  →  novo chamado ABERTO aparece na lista

5. Técnico aceita o chamado
   PATCH /api/chamados/{id}/status  →  status = ACEITO

6. Backend publica evento de atualização
   publicar_evento("chamado.status_alterado", payload)

7. Cliente é notificado (polling 30s)
   AlertasScreen exibe "Seu chamado foi aceito por um técnico."
```

A evidência de funcionamento completo está registrada nos logs de console incluídos em [docs/Integracao_MOM.md](Integracao_MOM.md) e no screencast em `docs/video/sprint-4.mp4`.

---

## 7. Referências Bibliográficas

FIELDING, Roy Thomas. **Architectural Styles and the Design of Network-based Software Architectures**. Tese de Doutorado — University of California, Irvine, 2000. Disponível em: https://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm

FOWLER, Martin. **What do you mean by "Event-Driven"?** Martin Fowler Blog, 2017. Disponível em: https://martinfowler.com/articles/201701-event-driven.html

MARTIN, Robert C. **Clean Architecture: A Craftsman's Guide to Software Structure and Design**. Prentice Hall, 2017. ISBN 978-0-13-468599-1.

VIDELA, Alvaro; WILLIAMS, Jason J. W. **RabbitMQ in Action: Distributed Messaging for Everyone**. Manning Publications, 2012. ISBN 978-1-935182-97-5.

GAMMA, Erich et al. **Design Patterns: Elements of Reusable Object-Oriented Software**. Addison-Wesley, 1994. ISBN 978-0-20-163361-5.
