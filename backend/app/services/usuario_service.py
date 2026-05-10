from werkzeug.security import generate_password_hash, check_password_hash
from app.models.usuario import Usuario
from app.repositories import usuario_repository as repo

PERFIS_VALIDOS = {"CLIENTE", "TECNICO"}


def cadastrar(dados: dict) -> tuple[dict, int]:
    campos = ["nome", "email", "telefone", "perfil", "senha"]
    faltando = [c for c in campos if not dados.get(c)]
    if faltando:
        return {"erro": f"Campos obrigatórios ausentes: {', '.join(faltando)}"}, 400

    if dados["perfil"] not in PERFIS_VALIDOS:
        return {"erro": "perfil deve ser CLIENTE ou TECNICO"}, 400

    if dados["perfil"] == "TECNICO" and not dados.get("especialidade"):
        return {"erro": "especialidade é obrigatória para técnicos"}, 400

    if repo.buscar_por_email(dados["email"]):
        return {"erro": "E-mail já cadastrado"}, 409

    usuario = Usuario(
        id=None,
        nome=dados["nome"],
        email=dados["email"],
        telefone=dados["telefone"],
        perfil=dados["perfil"],
        especialidade=dados.get("especialidade"),
        senha=generate_password_hash(dados["senha"]),
        criado_em=None,
    )
    criado = repo.criar(usuario)
    return criado.to_dict(), 201


def login(dados: dict) -> tuple[dict, int]:
    if not dados.get("email") or not dados.get("senha"):
        return {"erro": "email e senha são obrigatórios"}, 400

    usuario = repo.buscar_por_email(dados["email"])
    if not usuario or not check_password_hash(usuario.senha, dados["senha"]):
        return {"erro": "Credenciais inválidas"}, 401

    return usuario.to_dict(), 200


def listar() -> tuple[list, int]:
    return [u.to_dict() for u in repo.listar()], 200


def buscar_por_id(usuario_id: int) -> tuple[dict, int]:
    usuario = repo.buscar_por_id(usuario_id)
    if not usuario:
        return {"erro": "Usuário não encontrado"}, 404
    return usuario.to_dict(), 200
