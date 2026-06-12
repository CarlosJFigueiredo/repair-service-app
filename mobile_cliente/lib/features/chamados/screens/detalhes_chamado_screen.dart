import 'package:flutter/material.dart';

class DetalhesChamadoScreen extends StatelessWidget {
  final int chamadoId;

  const DetalhesChamadoScreen({super.key, required this.chamadoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chamado #$chamadoId')),
      body: const Center(child: Text('Detalhes — em construção')),
    );
  }
}
