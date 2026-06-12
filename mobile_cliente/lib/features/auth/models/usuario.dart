class Usuario {
  final int id;
  final String nome;
  final String email;
  final String telefone;
  final String perfil; // 'CLIENTE' | 'TECNICO'
  final String? especialidade;
  final String? criadoEm;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.perfil,
    this.especialidade,
    this.criadoEm,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        telefone: json['telefone'] as String,
        perfil: json['perfil'] as String,
        especialidade: json['especialidade'] as String?,
        criadoEm: json['criado_em'] as String?,
      );
}
