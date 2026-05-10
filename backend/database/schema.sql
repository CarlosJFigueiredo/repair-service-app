CREATE TABLE IF NOT EXISTS usuarios (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    nome         TEXT    NOT NULL,
    email        TEXT    NOT NULL UNIQUE,
    telefone     TEXT    NOT NULL,
    perfil       TEXT    NOT NULL CHECK (perfil IN ('CLIENTE', 'TECNICO')),
    especialidade TEXT,
    senha        TEXT    NOT NULL,
    criado_em    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS chamados (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id    INTEGER NOT NULL REFERENCES usuarios(id),
    tecnico_id    INTEGER          REFERENCES usuarios(id),
    tipo_servico  TEXT    NOT NULL CHECK (tipo_servico IN ('CELULAR', 'NOTEBOOK', 'INTERNET', 'OUTRO')),
    descricao     TEXT    NOT NULL,
    status        TEXT    NOT NULL DEFAULT 'ABERTO'
                          CHECK (status IN ('ABERTO', 'ACEITO', 'EM_ANDAMENTO', 'CONCLUIDO', 'RECUSADO')),
    criado_em     TEXT    NOT NULL DEFAULT (datetime('now')),
    atualizado_em TEXT    NOT NULL DEFAULT (datetime('now'))
);
