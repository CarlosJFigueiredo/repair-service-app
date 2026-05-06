from flask import Blueprint, request, jsonify
from app.services import chamado_service as service

chamado_bp = Blueprint("chamados", __name__)


@chamado_bp.post("/")
def abrir():
    dados = request.get_json(silent=True) or {}
    resultado, status = service.abrir(dados)
    return jsonify(resultado), status


@chamado_bp.get("/")
def listar():
    status_filtro = request.args.get("status")
    resultado, status = service.listar(status_filtro)
    return jsonify(resultado), status


@chamado_bp.get("/<int:chamado_id>")
def buscar(chamado_id):
    resultado, status = service.buscar_por_id(chamado_id)
    return jsonify(resultado), status


@chamado_bp.patch("/<int:chamado_id>/status")
def atualizar_status(chamado_id):
    dados = request.get_json(silent=True) or {}
    resultado, status = service.atualizar_status(chamado_id, dados)
    return jsonify(resultado), status
