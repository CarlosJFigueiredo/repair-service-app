import json
import logging
from app.messaging.connection import get_connection, get_channel

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [CONSUMER] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def _callback_chamado_criado(ch, method, properties, body):
    payload = json.loads(body)
    logger.info("chamado.criado recebido | chamado_id=%s | cliente_id=%s | tipo=%s",
                payload.get("chamado_id"),
                payload.get("cliente_id"),
                payload.get("tipo_servico"))
    ch.basic_ack(delivery_tag=method.delivery_tag)


def _callback_status_alterado(ch, method, properties, body):
    payload = json.loads(body)
    logger.info("chamado.status_alterado recebido | chamado_id=%s | %s -> %s | tecnico_id=%s",
                payload.get("chamado_id"),
                payload.get("status_anterior"),
                payload.get("status_novo"),
                payload.get("tecnico_id"))
    ch.basic_ack(delivery_tag=method.delivery_tag)


def iniciar():
    connection = get_connection()
    channel = get_channel(connection)

    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue="chamado.criado", on_message_callback=_callback_chamado_criado)
    channel.basic_consume(queue="chamado.status_alterado", on_message_callback=_callback_status_alterado)

    logger.info("Aguardando mensagens nas filas: chamado.criado, chamado.status_alterado")
    channel.start_consuming()
