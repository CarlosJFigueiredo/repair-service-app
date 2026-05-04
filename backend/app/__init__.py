from flask import Flask
from flask_cors import CORS
from config import DATABASE_PATH, SCHEMA_PATH
import sqlite3
import os


def create_app():
    app = Flask(__name__)
    CORS(app)

    _init_db()

    from app.routes.usuario_routes import usuario_bp
    from app.routes.chamado_routes import chamado_bp

    app.register_blueprint(usuario_bp, url_prefix="/api/usuarios")
    app.register_blueprint(chamado_bp, url_prefix="/api/chamados")

    return app


def _init_db():
    if not os.path.exists(DATABASE_PATH):
        conn = sqlite3.connect(DATABASE_PATH)
        with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
            conn.executescript(f.read())
        conn.close()
