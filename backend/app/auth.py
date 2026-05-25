import jwt
from datetime import datetime, timedelta, timezone
from functools import wraps
from flask import request, jsonify
from config import JWT_SECRET, JWT_EXPIRATION_HOURS


def gerar_token(usuario) -> str:
    payload = {
        "sub": str(usuario.id),
        "nome": usuario.nome,
        "perfil": usuario.perfil,
        "exp": datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRATION_HOURS),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


def _extrair_payload():
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return None, ({"erro": "Token não fornecido"}, 401)
    token = auth.split(" ", 1)[1]
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload, None
    except jwt.ExpiredSignatureError:
        return None, ({"erro": "Token expirado"}, 401)
    except jwt.InvalidTokenError:
        return None, ({"erro": "Token inválido"}, 401)


def token_requerido(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        payload, erro = _extrair_payload()
        if erro:
            return jsonify(erro[0]), erro[1]
        request.usuario_logado = payload
        return f(*args, **kwargs)
    return decorated


def perfil_requerido(*perfis):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            payload, erro = _extrair_payload()
            if erro:
                return jsonify(erro[0]), erro[1]
            if payload["perfil"] not in perfis:
                return jsonify({"erro": "Acesso negado para este perfil"}), 403
            request.usuario_logado = payload
            return f(*args, **kwargs)
        return decorated
    return decorator
