import pika
import logging
from config import RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_USER, RABBITMQ_PASS

logger = logging.getLogger(__name__)


def get_connection():
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        heartbeat=60,
        blocked_connection_timeout=30,
    )
    return pika.BlockingConnection(parameters)


def get_channel(connection):
    channel = connection.channel()
    # Declara as filas como duráveis para sobreviver a reinicializações do broker
    channel.queue_declare(queue="chamado.criado", durable=True)
    channel.queue_declare(queue="chamado.status_alterado", durable=True)
    return channel
