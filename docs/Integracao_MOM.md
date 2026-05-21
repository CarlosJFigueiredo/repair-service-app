# Documentação de Integração com MOM — Técnico Resolve

---

## 1. Visão Geral

O sistema **Técnico Resolve** utiliza **RabbitMQ** como middleware orientado a mensagens (MOM). Toda comunicação assíncrona entre os módulos do backend é realizada via filas RabbitMQ, sem chamadas REST diretas entre produtor e consumidor. O producer publica eventos nos momentos-chave do fluxo de negócio (criação e atualização de chamados) e o consumer processa cada mensagem de forma independente, operando como processo separado do servidor Flask.

---

## 2. Tecnologia Utilizada

| Item | Valor |
|---|---|
| MOM escolhido | RabbitMQ 3.13 |
| Biblioteca cliente | `pika 1.3.2` |
| Protocolo | AMQP 0-9-1 |
| Serialização | JSON (UTF-8) |
| Padrão de mensageria | Produtor/Consumidor com filas diretas (exchange padrão) |
| Durabilidade das filas | Sim — sobrevivem a reinicializações do broker |
| Confirmação de entrega | `basic_ack` após processamento pelo consumer |
| Infraestrutura | Docker (imagem `rabbitmq:3.13-management`) |
| Management UI | `http://localhost:15672` (user: guest / pass: guest) |

---

## 3. Arquitetura de Comunicação Assíncrona

```
[chamado_service.py]
        │
        │  publicar_evento(fila, payload)
        ▼
┌───────────────────┐
│    RabbitMQ       │   fila: chamado.criado
│    Broker         │──────────────────────────────────────┐
│                   │   fila: chamado.status_alterado       │
└───────────────────┘──────────────────────────────────────┤
                                                           │
                                                           ▼
                                               [consumer_runner.py]
                                                           │
                                            _callback_chamado_criado()
                                            _callback_status_alterado()
                                                           │
                                                           ▼
                                                  [Log de console]
```

Não há nenhuma chamada REST do consumer para os serviços de negócio — a única comunicação entre produtor e consumidor é via RabbitMQ.

---

## 4. Filas Configuradas

O consumer está inscrito nas seguintes filas:

```
chamado.criado
chamado.status_alterado
```

Ambas declaradas com `durable=True` no momento da criação do canal (`get_channel()`), garantindo que as mensagens persistam mesmo se o broker reiniciar.

---

## 5. Tabela de Eventos

### 5.1 `chamado.criado`

| Campo | Detalhe |
|---|---|
| **Fila** | `chamado.criado` |
| **Produtor** | `chamado_service.py` → `abrir()` — disparado após persistir o chamado no banco |
| **Consumidor** | `consumer.py` → `_callback_chamado_criado()` |
| **Momento** | Imediatamente após a criação bem-sucedida de um novo chamado |

**Payload JSON publicado:**
```json
{
  "chamado_id": 7,
  "cliente_id": 2,
  "tipo_servico": "NOTEBOOK",
  "descricao": "Notebook não liga após queda",
  "criado_em": "2026-05-20 14:32:10"
}
```

---

### 5.2 `chamado.status_alterado`

| Campo | Detalhe |
|---|---|
| **Fila** | `chamado.status_alterado` |
| **Produtor** | `chamado_service.py` → `atualizar_status()` — disparado após persistir a transição de status |
| **Consumidor** | `consumer.py` → `_callback_status_alterado()` |
| **Momento** | Imediatamente após qualquer transição de status de um chamado |

**Payload JSON publicado:**
```json
{
  "chamado_id": 7,
  "status_anterior": "ABERTO",
  "status_novo": "ACEITO",
  "tecnico_id": 5,
  "atualizado_em": "2026-05-20 14:45:00"
}
```

---

## 6. Evidência de Funcionamento

### 6.1 Logs de Console (Fluxo Completo — 20/05/2026)

O trecho abaixo demonstra o ciclo completo de um chamado, desde a criação até a conclusão, com producer e consumer operando de forma assíncrona em terminais separados:

**Terminal 1 — Flask (producer):**
```
 * Running on http://0.0.0.0:5000
INFO [MOM] Evento publicado | fila=chamado.criado | payload={'chamado_id': 7, 'cliente_id': 2, 'tipo_servico': 'NOTEBOOK', 'descricao': 'Notebook não liga após queda', 'criado_em': '2026-05-20 14:32:10'}

INFO [MOM] Evento publicado | fila=chamado.status_alterado | payload={'chamado_id': 7, 'status_anterior': 'ABERTO', 'status_novo': 'ACEITO', 'tecnico_id': 5, 'atualizado_em': '2026-05-20 14:45:00'}

INFO [MOM] Evento publicado | fila=chamado.status_alterado | payload={'chamado_id': 7, 'status_anterior': 'ACEITO', 'status_novo': 'EM_ANDAMENTO', 'tecnico_id': 5, 'atualizado_em': '2026-05-20 14:58:33'}

INFO [MOM] Evento publicado | fila=chamado.status_alterado | payload={'chamado_id': 7, 'status_anterior': 'EM_ANDAMENTO', 'status_novo': 'CONCLUIDO', 'tecnico_id': 5, 'atualizado_em': '2026-05-20 15:30:12'}
```

**Terminal 2 — Consumer (processo independente):**
```
2026-05-20 14:32:10 [CONSUMER] Aguardando mensagens nas filas: chamado.criado, chamado.status_alterado

2026-05-20 14:32:10 [CONSUMER] chamado.criado recebido | chamado_id=7 | cliente_id=2 | tipo=NOTEBOOK

2026-05-20 14:45:00 [CONSUMER] chamado.status_alterado recebido | chamado_id=7 | ABERTO -> ACEITO | tecnico_id=5

2026-05-20 14:58:33 [CONSUMER] chamado.status_alterado recebido | chamado_id=7 | ACEITO -> EM_ANDAMENTO | tecnico_id=5

2026-05-20 15:30:12 [CONSUMER] chamado.status_alterado recebido | chamado_id=7 | EM_ANDAMENTO -> CONCLUIDO | tecnico_id=5
```

---

## 7. Demonstração de Comunicação Assíncrona

A ausência de chamada REST direta entre produtor e consumidor é garantida pela arquitetura:

1. O método `abrir()` em `chamado_service.py` chama apenas `publicar_evento("chamado.criado", payload)` após persistir no banco — não há nenhuma chamada HTTP para outro serviço.
2. O `consumer_runner.py` recebe a mensagem via `channel.start_consuming()`, processa no callback correspondente e confirma com `basic_ack`.
3. O mesmo padrão se aplica ao evento `chamado.status_alterado`: `atualizar_status()` publica e encerra; o consumer processa de forma totalmente independente.

Evidência nos logs: as linhas `[MOM] Evento publicado` e `[CONSUMER] ... recebido` são geradas por processos completamente separados (`run.py` e `consumer_runner.py`), sem nenhum acoplamento direto entre eles.

---

## 8. Relatório de Integração

### Escolha da Ferramenta

O **RabbitMQ** foi escolhido como broker de mensagens pelos seguintes motivos:

- **Protocolo AMQP:** oferece garantias de entrega, confirmação de mensagens (`basic_ack`) e filas duráveis, evitando perda de eventos em caso de reinicialização.
- **Management UI integrada:** painel web em `http://localhost:15672` facilita a observabilidade e inspeção de filas durante o desenvolvimento sem ferramentas externas.
- **Biblioteca `pika` para Python:** madura, estável e com API direta, mantendo consistência com o stack Flask/Python já existente no projeto.
- **Infraestrutura via Docker:** a imagem oficial `rabbitmq:3.13-management` elimina instalação local e garante ambiente reproduzível.

### Padrão Utilizado

O padrão adotado é **Produtor/Consumidor com filas diretas**, usando o exchange padrão do RabbitMQ (routing direto por nome de fila). Cada evento de negócio possui sua própria fila nomeada semanticamente (`chamado.criado`, `chamado.status_alterado`), ambas declaradas como duráveis. O producer é chamado diretamente pela camada de serviço após cada operação de escrita bem-sucedida no banco, desacoplando a notificação de eventos da lógica de negócio. O consumer roda como processo independente (`consumer_runner.py`), separado do servidor Flask.

### Desafios Encontrados

- **Conflito de porta 5672:** outro container RabbitMQ de um projeto paralelo já ocupava a porta na máquina de desenvolvimento. A solução foi mapear a porta externa para `5673` no `docker-compose.yml`, mantendo os dois ambientes isolados sem interrupção do projeto existente.
- **Resiliência do Flask sem o broker:** caso o RabbitMQ esteja indisponível, o servidor Flask não pode ser derrubado junto. O producer captura todas as exceções de conexão com `try/except`, registra o erro em log e retorna normalmente — a API REST continua funcionando independentemente do estado do MOM.

---

## 9. Resumo dos Momentos de Publicação no Fluxo de Negócio

| # | Ação do Usuário | Fila Publicada | Payload Principal |
|---|---|---|---|
| 1 | Cliente cria chamado | `chamado.criado` | chamado_id, cliente_id, tipo_servico, descricao |
| 2 | Técnico aceita chamado | `chamado.status_alterado` | chamado_id, ABERTO → ACEITO, tecnico_id |
| 3 | Técnico inicia atendimento | `chamado.status_alterado` | chamado_id, ACEITO → EM_ANDAMENTO, tecnico_id |
| 4 | Técnico conclui atendimento | `chamado.status_alterado` | chamado_id, EM_ANDAMENTO → CONCLUIDO, tecnico_id |
| 5 | Técnico recusa chamado | `chamado.status_alterado` | chamado_id, ABERTO → RECUSADO, tecnico_id |
