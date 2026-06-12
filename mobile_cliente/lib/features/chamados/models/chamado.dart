class Chamado {
  final int id;
  final int clienteId;
  final int? tecnicoId;
  final String tipoServico; // 'CELULAR' | 'NOTEBOOK' | 'INTERNET' | 'OUTRO'
  final String descricao;
  final String status; // 'ABERTO' | 'ACEITO' | 'EM_ANDAMENTO' | 'CONCLUIDO' | 'RECUSADO'
  final String? criadoEm;
  final String? atualizadoEm;

  const Chamado({
    required this.id,
    required this.clienteId,
    this.tecnicoId,
    required this.tipoServico,
    required this.descricao,
    required this.status,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory Chamado.fromJson(Map<String, dynamic> json) => Chamado(
        id: json['id'] as int,
        clienteId: json['cliente_id'] as int,
        tecnicoId: json['tecnico_id'] as int?,
        tipoServico: json['tipo_servico'] as String,
        descricao: json['descricao'] as String,
        status: json['status'] as String,
        criadoEm: json['criado_em'] as String?,
        atualizadoEm: json['atualizado_em'] as String?,
      );

  bool get isAberto => status == 'ABERTO';
  bool get isAceito => status == 'ACEITO';
  bool get isEmAndamento => status == 'EM_ANDAMENTO';
  bool get isConcluido => status == 'CONCLUIDO';
  bool get isRecusado => status == 'RECUSADO';
  bool get isFinalizado => isConcluido || isRecusado;

  String get statusLabel {
    switch (status) {
      case 'ABERTO':
        return 'Aberto';
      case 'ACEITO':
        return 'Aceito';
      case 'EM_ANDAMENTO':
        return 'Em atendimento';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'RECUSADO':
        return 'Recusado';
      default:
        return status;
    }
  }

  String get tipoServicoLabel {
    switch (tipoServico) {
      case 'CELULAR':
        return 'Celular';
      case 'NOTEBOOK':
        return 'Notebook';
      case 'INTERNET':
        return 'Internet';
      default:
        return 'Outro';
    }
  }
}
