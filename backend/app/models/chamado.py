from dataclasses import dataclass
from typing import Optional


@dataclass
class Chamado:
    id: Optional[int]
    cliente_id: int
    tecnico_id: Optional[int]
    tipo_servico: str    # 'CELULAR' | 'NOTEBOOK' | 'INTERNET' | 'OUTRO'
    descricao: str
    status: str          # 'ABERTO' | 'ACEITO' | 'EM_ANDAMENTO' | 'CONCLUIDO' | 'RECUSADO'
    criado_em: Optional[str]
    atualizado_em: Optional[str]

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "cliente_id": self.cliente_id,
            "tecnico_id": self.tecnico_id,
            "tipo_servico": self.tipo_servico,
            "descricao": self.descricao,
            "status": self.status,
            "criado_em": self.criado_em,
            "atualizado_em": self.atualizado_em,
        }
