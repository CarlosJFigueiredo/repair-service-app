# Técnico Resolve

Plataforma de suporte técnico sob demanda que conecta clientes com problemas em dispositivos eletrônicos a técnicos especializados. O cliente abre um chamado, o técnico recebe a notificação em tempo real, aceita ou recusa o atendimento, e o cliente acompanha o status até a conclusão.

**Aluno:** Carlos Figueiredo  
**Disciplina:** Lab. de Desenvolvimento de Aplicações Móveis e Distribuídas — PUC Minas  
**Curso:** Engenharia de Software — 5º Período  
**Semestre:** 1º Semestre 2026  

---

## Estrutura do Repositório

```
repair-service-app/
├── backend/                  # Web Service REST (Flask + SQLite + RabbitMQ)
│   ├── app/
│   │   ├── models/           # Entidades do domínio (Usuario, Chamado)
│   │   ├── repositories/     # Acesso ao banco de dados (SQLite)
│   │   ├── services/         # Regras de negócio + publicação de eventos MOM
│   │   ├── routes/           # Endpoints REST (Blueprints Flask)
│   │   └── messaging/        # Producer e Consumer RabbitMQ (pika)
│   ├── database/
│   │   └── schema.sql        # Definição das tabelas
│   ├── config.py
│   ├── run.py                # Servidor Flask
│   ├── consumer_runner.py    # Consumer MOM (processo independente)
│   └── requirements.txt
├── mobile_cliente/           # App Flutter (perfis Cliente e Técnico)
│   ├── lib/
│   │   ├── features/         # auth, chamados, historico, alertas, perfil, home
│   │   └── core/             # providers, services, constants
│   └── ARQUITETURA.md        # Documentação da Clean Architecture do app
├── docker-compose.yml        # RabbitMQ 3.13 + Management UI
└── docs/                     # Documentação e mídia
    ├── Relatorio_Tecnico_Final.md          # Relatório técnico da Sprint 4
    ├── Integracao_MOM.md                   # Detalhes da integração RabbitMQ
    ├── video/
    │   ├── sprint-3.mp4                    # Screencast Sprint 3
    │   └── sprint-4.mp4                    # Screencast Sprint 4 (fluxo completo)
    └── tecnico-resolve.postman_collection.json
```

---

## Arquitetura do Sistema

O sistema segue uma arquitetura orientada a eventos (EDA), com backend REST em Flask, banco de dados SQLite, middleware de mensagens RabbitMQ e aplicativos móveis em Flutter.

![Diagrama de Arquitetura](docs/img/Diagrama%20da%20Arquitetura.png)

> RabbitMQ e WebSocket são integrados na Sprint 2.

---

## Banco de Dados

Banco SQLite com duas tabelas. O schema completo está em `backend/database/schema.sql`.

![Diagrama Entidade-Relacionamento](docs/img/Diagrama%20Entidade-Relacionamento.png)

## Como Executar

### Pré-requisitos

- Python 3.11+
- Flutter 3.x
- Docker (para o RabbitMQ)

### 1. RabbitMQ (MOM)

```bash
docker-compose up -d
```

Management UI disponível em `http://localhost:15672` (guest / guest).

### 2. Backend Flask

```bash
cd backend
python -m pip install -r requirements.txt
python run.py
```

O servidor sobe em `http://0.0.0.0:5000`.

Em um segundo terminal, inicie o consumer MOM:

```bash
cd backend
python consumer_runner.py
```

### 3. App Flutter

```bash
cd mobile_cliente
flutter pub get
flutter run
```

O app detecta o perfil automaticamente no login (`CLIENTE` ou `TECNICO`).

Para testar os endpoints diretamente, importe a coleção do Postman em `docs/tecnico-resolve.postman_collection.json`.

---

## Fluxo de Status do Chamado

```
ABERTO ──► ACEITO ──► EM_ANDAMENTO ──► CONCLUIDO
       │        │
       └────────┴──► RECUSADO
```

---

## Sprints

| Sprint | Foco | Prazo |
|--------|------|-------|
| 1 | Proposta + Backend REST | 11/05/2026 |
| 2 | Integração MOM (RabbitMQ) | 25/05/2026 |
| 3 | App Flutter — Cliente | 15/06/2026 |
| 4 | App Flutter — Técnico + Entrega Final | 03/07/2026 |
