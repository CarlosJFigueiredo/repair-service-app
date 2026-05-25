import sqlite3
from typing import Optional
from config import DATABASE_PATH
from app.models.chamado import Chamado


def _row_to_chamado(row) -> Chamado:
    return Chamado(
        id=row[0],
        cliente_id=row[1],
        tecnico_id=row[2],
        tipo_servico=row[3],
        descricao=row[4],
        status=row[5],
        criado_em=row[6],
        atualizado_em=row[7],
    )


def _conn():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def criar(chamado: Chamado) -> Chamado:
    with _conn() as conn:
        cur = conn.execute(
            """
            INSERT INTO chamados (cliente_id, tipo_servico, descricao)
            VALUES (?, ?, ?)
            """,
            (chamado.cliente_id, chamado.tipo_servico, chamado.descricao),
        )
        row = conn.execute("SELECT * FROM chamados WHERE id = ?", (cur.lastrowid,)).fetchone()
        return _row_to_chamado(row)


def listar(status: Optional[str] = None) -> list[Chamado]:
    with _conn() as conn:
        if status:
            rows = conn.execute(
                "SELECT * FROM chamados WHERE status = ? ORDER BY id", (status,)
            ).fetchall()
        else:
            rows = conn.execute("SELECT * FROM chamados ORDER BY id").fetchall()
        return [_row_to_chamado(r) for r in rows]


def listar_por_cliente(cliente_id: int) -> list[Chamado]:
    with _conn() as conn:
        rows = conn.execute(
            "SELECT * FROM chamados WHERE cliente_id = ? ORDER BY id", (cliente_id,)
        ).fetchall()
        return [_row_to_chamado(r) for r in rows]


def buscar_por_id(chamado_id: int) -> Optional[Chamado]:
    with _conn() as conn:
        row = conn.execute("SELECT * FROM chamados WHERE id = ?", (chamado_id,)).fetchone()
        return _row_to_chamado(row) if row else None


def atualizar_status(chamado_id: int, status: str, tecnico_id: Optional[int] = None) -> Optional[Chamado]:
    with _conn() as conn:
        if tecnico_id is not None:
            conn.execute(
                """
                UPDATE chamados
                SET status = ?, tecnico_id = ?, atualizado_em = datetime('now')
                WHERE id = ?
                """,
                (status, tecnico_id, chamado_id),
            )
        else:
            conn.execute(
                """
                UPDATE chamados
                SET status = ?, atualizado_em = datetime('now')
                WHERE id = ?
                """,
                (status, chamado_id),
            )
        row = conn.execute("SELECT * FROM chamados WHERE id = ?", (chamado_id,)).fetchone()
        return _row_to_chamado(row) if row else None
