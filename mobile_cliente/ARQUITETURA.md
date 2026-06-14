# Arquitetura do App — Tecnico Resolve (Cliente)

## Padrão adotado: Clean Architecture em camadas

O app segue o padrão **Clean Architecture**, organizado em quatro camadas com
dependências sempre apontando para dentro (das camadas externas para as internas).

```
┌─────────────────────────────────────────────────────────────────┐
│                    CAMADA DE APRESENTAÇÃO                       │
│                      (Presentation Layer)                       │
│                                                                 │
│  features/                                                      │
│  ├── auth/screens/      login, cadastro, seleção de tipo        │
│  ├── chamados/screens/  lista, abrir chamado, detalhes          │
│  ├── historico/screens/ histórico de chamados                   │
│  ├── alertas/screens/   alertas de status                       │
│  ├── perfil/screens/    perfil do usuário                       │
│  └── home/screens/      navegação principal (polling 30s)       │
│                                                                 │
│  Responsabilidade: renderizar UI, capturar eventos do usuário   │
│  Dependências: Providers (camada de estado)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │ consome
┌────────────────────────────▼────────────────────────────────────┐
│                    CAMADA DE ESTADO                             │
│                  (State / Use-Case Layer)                       │
│                                                                 │
│  core/providers/                                                │
│  ├── auth_provider.dart    login, cadastro, logout, sessão      │
│  └── chamado_provider.dart listar, abrir, buscar, polling       │
│                                                                 │
│  Responsabilidade: orquestrar regras de negócio, manter         │
│  estado reativo via ChangeNotifier (Provider)                   │
│  Dependências: Services (camada de dados)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │ chama
┌────────────────────────────▼────────────────────────────────────┐
│                    CAMADA DE DADOS                              │
│                      (Data Layer)                               │
│                                                                 │
│  core/services/                                                 │
│  ├── api_client.dart       cliente HTTP (Dio) + interceptor JWT │
│  └── storage_service.dart  persistência local (SharedPrefs)     │
│                                                                 │
│  core/constants/                                                │
│  └── api_constants.dart    URLs base e rotas da API             │
│                                                                 │
│  Responsabilidade: comunicação com API REST e armazenamento     │
│  local de token JWT                                             │
└────────────────────────────┬────────────────────────────────────┘
                             │ mapeia
┌────────────────────────────▼────────────────────────────────────┐
│                    CAMADA DE DOMÍNIO                            │
│                      (Domain / Entities)                        │
│                                                                 │
│  features/auth/models/                                          │
│  └── usuario.dart          entidade Usuario (fromJson)          │
│                                                                 │
│  features/chamados/models/                                      │
│  └── chamado.dart          entidade Chamado (fromJson, getters) │
│                                                                 │
│  Responsabilidade: definir as entidades centrais do negócio,    │
│  sem dependência de nenhuma outra camada                        │
└─────────────────────────────────────────────────────────────────┘
                             │ consome (API externa)
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (externo)                            │
│                                                                 │
│  Flask REST API  →  http://127.0.0.1:5000/api/                  │
│  ├── /api/usuarios/        cadastro e login                     │
│  └── /api/chamados/        CRUD de chamados                     │
│                                                                 │
│  RabbitMQ (MOM)  →  eventos chamado.criado, status_alterado     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Fluxo de dados

```
Usuário interage com Screen
        │
        ▼
Screen chama Provider (context.read<...>().metodo())
        │
        ▼
Provider executa lógica de negócio e chama ApiClient
        │
        ▼
ApiClient (Dio) faz requisição HTTP com JWT no header
        │
        ▼
Backend Flask valida token e retorna JSON
        │
        ▼
Provider atualiza estado e chama notifyListeners()
        │
        ▼
Screens ouvintes (context.watch) reconstroem automaticamente
```

---

## Atualização assíncrona de estado (Polling)

O app implementa **polling automático com intervalo de 30 segundos** via `Timer.periodic`
no `HomeScreen`. Isso garante que o cliente visualize atualizações do servidor
(ex.: técnico aceitando um chamado) sem precisar fazer refresh manual.

```
HomeScreen.initState()
    │
    └── Timer.periodic(30s)
            │
            ▼
        ChamadoProvider.listar()   ◄── GET /api/chamados/
            │
            ▼
        notifyListeners()
            │
            ▼
        ListaChamadosScreen / HistoricoScreen / AlertasScreen
        rebuildam com os dados atualizados
```

Alternativas previstas pelo professor também suportadas no backend:
- **MOM (RabbitMQ)**: o backend já publica eventos `chamado.criado` e
  `chamado.status_alterado` no broker. O app poderia assinar via plugin
  STOMP/AMQP para receber push em vez de polling.
- **WebSockets**: o Flask poderia expor um endpoint WS com Flask-SocketIO
  e o app assinar com `web_socket_channel`.

---

## Estrutura de diretórios

```
mobile_cliente/lib/
├── main.dart                        ponto de entrada, registro dos Providers
├── app/
│   ├── app.dart                     MaterialApp, tema, roteamento por auth
│   └── routes.dart                  definição centralizada de rotas nomeadas
├── core/                            ◄ compartilhado por todas as features
│   ├── constants/api_constants.dart URLs da API
│   ├── providers/
│   │   ├── auth_provider.dart       estado de autenticação
│   │   └── chamado_provider.dart    estado de chamados + polling
│   └── services/
│       ├── api_client.dart          Dio + interceptor JWT
│       └── storage_service.dart     SharedPreferences
├── features/                        ◄ uma pasta por feature (vertical slice)
│   ├── auth/
│   │   ├── models/usuario.dart
│   │   └── screens/ (login, cadastro cliente/técnico, seleção tipo)
│   ├── chamados/
│   │   ├── models/chamado.dart
│   │   └── screens/ (lista, abrir, detalhes)
│   ├── historico/screens/
│   ├── alertas/screens/
│   ├── home/screens/                hub de navegação com polling
│   └── perfil/screens/
└── shared/
    └── theme/app_theme.dart         cores e tema Material 3
```
