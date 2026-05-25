from flask import Blueprint, request, jsonify
from app.services import usuario_service as service
from app.auth import token_requerido, perfil_requerido

usuario_bp = Blueprint("usuarios", __name__)


@usuario_bp.post("/")
def cadastrar():
    dados = request.get_json(silent=True) or {}
    resultado, status = service.cadastrar(dados)
    return jsonify(resultado), status


@usuario_bp.post("/login")
def login():
    dados = request.get_json(silent=True) or {}
    resultado, status = service.login(dados)
    return jsonify(resultado), status


@usuario_bp.get("/")
@perfil_requerido("TECNICO")
def listar():
    resultado, status = service.listar()
    return jsonify(resultado), status


@usuario_bp.get("/<int:usuario_id>")
@token_requerido
def buscar(usuario_id):
    logado = request.usuario_logado
    if logado["perfil"] == "CLIENTE" and int(logado["sub"]) != usuario_id:
        return jsonify({"erro": "Acesso negado"}), 403
    resultado, status = service.buscar_por_id(usuario_id)
    return jsonify(resultado), status
