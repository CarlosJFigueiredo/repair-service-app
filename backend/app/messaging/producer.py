import json
import logging
from app.messaging.connection import get_connection, get_channel

logger = logging.getLogger(__name__)


def publicar_evento(fila: str, payload: dict) -> None:
    try:
        connection = get_connection()
        channel = get_channel(connection)
        channel.basic_publish(
            exchange="",
            routing_key=fila,
            body=json.dumps(payload, ensure_ascii=False),
        )
        connection.close()
        logger.info("[MOM] Evento publicado | fila=%s | payload=%s", fila, payload)
    except Exception as e:
        # Não bloqueia o fluxo principal se o broker estiver indisponível
        logger.error("[MOM] Falha ao publicar evento | fila=%s | erro=%s", fila, e)
