import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_PATH = os.path.join(BASE_DIR, "database", "tecnico_resolve.db")
SCHEMA_PATH = os.path.join(BASE_DIR, "database", "schema.sql")

JWT_SECRET = os.environ.get("JWT_SECRET", "tecnico-resolve-secret-key")
JWT_EXPIRATION_HOURS = 8

RABBITMQ_HOST = os.environ.get("RABBITMQ_HOST", "localhost")
RABBITMQ_PORT = int(os.environ.get("RABBITMQ_PORT", 5673))
RABBITMQ_USER = os.environ.get("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.environ.get("RABBITMQ_PASS", "guest")
