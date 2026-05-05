from dataclasses import dataclass
from typing import Optional


@dataclass
class Usuario:
    id: Optional[int]
    nome: str
    email: str
    telefone: str
    perfil: str          # 'CLIENTE' | 'TECNICO'
    especialidade: Optional[str]
    criado_em: Optional[str]

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "nome": self.nome,
            "email": self.email,
            "telefone": self.telefone,
            "perfil": self.perfil,
            "especialidade": self.especialidade,
            "criado_em": self.criado_em,
        }
