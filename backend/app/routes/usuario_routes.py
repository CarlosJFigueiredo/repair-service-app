from flask import Blueprint, request, jsonify
from app.services import usuario_service as service

usuario_bp = Blueprint("usuarios", __name__)


@usuario_bp.post("/")
def cadastrar():
    dados = request.get_json(silent=True) or {}
    resultado, status = service.cadastrar(dados)
    return jsonify(resultado), status


@usuario_bp.get("/")
def listar():
    resultado, status = service.listar()
    return jsonify(resultado), status


@usuario_bp.get("/<int:usuario_id>")
def buscar(usuario_id):
    resultado, status = service.buscar_por_id(usuario_id)
    return jsonify(resultado), status


@usuario_bp.post("/login")
def login():
    dados = request.get_json(silent=True) or {}
    resultado, status = service.login(dados)
    return jsonify(resultado), status
