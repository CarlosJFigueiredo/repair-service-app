from flask import Blueprint, request, jsonify
from app.services import chamado_service as service
from app.auth import token_requerido, perfil_requerido

chamado_bp = Blueprint("chamados", __name__)


@chamado_bp.post("/")
@perfil_requerido("CLIENTE")
def abrir():
    dados = request.get_json(silent=True) or {}
    cliente_id = int(request.usuario_logado["sub"])
    resultado, status = service.abrir(dados, cliente_id)
    return jsonify(resultado), status


@chamado_bp.get("/")
@token_requerido
def listar():
    logado = request.usuario_logado
    if logado["perfil"] == "CLIENTE":
        resultado, status = service.listar(cliente_id=int(logado["sub"]))
    else:
        resultado, status = service.listar(tecnico_id=int(logado["sub"]))
    return jsonify(resultado), status


@chamado_bp.get("/<int:chamado_id>")
@token_requerido
def buscar(chamado_id):
    logado = request.usuario_logado
    resultado, status = service.buscar_por_id(chamado_id)
    if status == 200 and logado["perfil"] == "CLIENTE" and resultado["cliente_id"] != int(logado["sub"]):
        return jsonify({"erro": "Acesso negado"}), 403
    return jsonify(resultado), status


@chamado_bp.patch("/<int:chamado_id>/status")
@perfil_requerido("TECNICO")
def atualizar_status(chamado_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = service.atualizar_status(chamado_id, dados)
    return jsonify(resultado), status
