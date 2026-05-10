import sqlite3
from typing import Optional
from config import DATABASE_PATH
from app.models.usuario import Usuario


def _row_to_usuario(row) -> Usuario:
    return Usuario(
        id=row[0],
        nome=row[1],
        email=row[2],
        telefone=row[3],
        perfil=row[4],
        especialidade=row[5],
        senha=row[6],
        criado_em=row[7],
    )


def _conn():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def criar(usuario: Usuario) -> Usuario:
    with _conn() as conn:
        cur = conn.execute(
            """
            INSERT INTO usuarios (nome, email, telefone, perfil, especialidade, senha)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (usuario.nome, usuario.email, usuario.telefone, usuario.perfil, usuario.especialidade, usuario.senha),
        )
        usuario.id = cur.lastrowid
        row = conn.execute("SELECT * FROM usuarios WHERE id = ?", (usuario.id,)).fetchone()
        return _row_to_usuario(row)


def listar() -> list[Usuario]:
    with _conn() as conn:
        rows = conn.execute("SELECT * FROM usuarios ORDER BY id").fetchall()
        return [_row_to_usuario(r) for r in rows]


def buscar_por_id(usuario_id: int) -> Optional[Usuario]:
    with _conn() as conn:
        row = conn.execute("SELECT * FROM usuarios WHERE id = ?", (usuario_id,)).fetchone()
        return _row_to_usuario(row) if row else None


def buscar_por_email(email: str) -> Optional[Usuario]:
    with _conn() as conn:
        row = conn.execute("SELECT * FROM usuarios WHERE email = ?", (email,)).fetchone()
        return _row_to_usuario(row) if row else None
