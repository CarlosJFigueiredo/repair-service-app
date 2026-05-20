from app.models.chamado import Chamado
from app.repositories import chamado_repository as repo
from app.repositories import usuario_repository as usuario_repo
from app.messaging.producer import publicar_evento

TIPOS_VALIDOS = {"CELULAR", "NOTEBOOK", "INTERNET", "OUTRO"}

# Transições de status permitidas
TRANSICOES = {
    "ABERTO":       {"ACEITO", "RECUSADO"},
    "ACEITO":       {"EM_ANDAMENTO", "RECUSADO"},
    "EM_ANDAMENTO": {"CONCLUIDO"},
}


def abrir(dados: dict) -> tuple[dict, int]:
    campos = ["cliente_id", "tipo_servico", "descricao"]
    faltando = [c for c in campos if not dados.get(c)]
    if faltando:
        return {"erro": f"Campos obrigatórios ausentes: {', '.join(faltando)}"}, 400

    if dados["tipo_servico"] not in TIPOS_VALIDOS:
        return {"erro": f"tipo_servico deve ser um de: {', '.join(TIPOS_VALIDOS)}"}, 400

    cliente = usuario_repo.buscar_por_id(dados["cliente_id"])
    if not cliente:
        return {"erro": "Cliente não encontrado"}, 404
    if cliente.perfil != "CLIENTE":
        return {"erro": "Apenas usuários com perfil CLIENTE podem abrir chamados"}, 403

    chamado = Chamado(
        id=None,
        cliente_id=dados["cliente_id"],
        tecnico_id=None,
        tipo_servico=dados["tipo_servico"],
        descricao=dados["descricao"],
        status="ABERTO",
        criado_em=None,
        atualizado_em=None,
    )
    criado = repo.criar(chamado)
    publicar_evento("chamado.criado", {
        "chamado_id": criado.id,
        "cliente_id": criado.cliente_id,
        "tipo_servico": criado.tipo_servico,
        "descricao": criado.descricao,
        "criado_em": criado.criado_em,
    })
    return criado.to_dict(), 201


def listar(status: str = None) -> tuple[list, int]:
    return [c.to_dict() for c in repo.listar(status)], 200


def buscar_por_id(chamado_id: int) -> tuple[dict, int]:
    chamado = repo.buscar_por_id(chamado_id)
    if not chamado:
        return {"erro": "Chamado não encontrado"}, 404
    return chamado.to_dict(), 200


def atualizar_status(chamado_id: int, dados: dict) -> tuple[dict, int]:
    novo_status = dados.get("status")
    if not novo_status:
        return {"erro": "Campo 'status' é obrigatório"}, 400

    chamado = repo.buscar_por_id(chamado_id)
    if not chamado:
        return {"erro": "Chamado não encontrado"}, 404

    destinos = TRANSICOES.get(chamado.status, set())
    if novo_status not in destinos:
        return {
            "erro": f"Transição inválida: {chamado.status} → {novo_status}",
            "transicoes_permitidas": list(destinos),
        }, 422

    tecnico_id = dados.get("tecnico_id")
    if novo_status == "ACEITO":
        if not tecnico_id:
            return {"erro": "tecnico_id é obrigatório para aceitar o chamado"}, 400
        tecnico = usuario_repo.buscar_por_id(tecnico_id)
        if not tecnico or tecnico.perfil != "TECNICO":
            return {"erro": "Técnico não encontrado ou perfil inválido"}, 404

    atualizado = repo.atualizar_status(chamado_id, novo_status, tecnico_id)
    publicar_evento("chamado.status_alterado", {
        "chamado_id": atualizado.id,
        "status_anterior": chamado.status,
        "status_novo": atualizado.status,
        "tecnico_id": atualizado.tecnico_id,
        "atualizado_em": atualizado.atualizado_em,
    })
    return atualizado.to_dict(), 200
