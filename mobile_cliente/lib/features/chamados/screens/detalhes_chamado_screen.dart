import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/chamado_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/chamado.dart';
import 'lista_chamados_screen.dart';

class DetalhesChamadoScreen extends StatefulWidget {
  final int chamadoId;
  const DetalhesChamadoScreen({super.key, required this.chamadoId});

  @override
  State<DetalhesChamadoScreen> createState() => _DetalhesChamadoScreenState();
}

class _DetalhesChamadoScreenState extends State<DetalhesChamadoScreen> {
  Chamado? _chamado;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final chamado =
        await context.read<ChamadoProvider>().buscarPorId(widget.chamadoId);
    if (!mounted) return;
    setState(() {
      _chamado = chamado;
      _loading = false;
      if (chamado == null) _erro = 'Chamado não encontrado';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Chamado #${widget.chamadoId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_erro!),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    final c = _chamado!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(chamado: c),
          const SizedBox(height: 16),
          _TimelineCard(chamado: c),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Chamado chamado;
  const _InfoCard({required this.chamado});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconeTipo(chamado.tipoServico),
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  chamado.tipoServicoLabel,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const Spacer(),
                StatusBadge(
                    status: chamado.status, label: chamado.statusLabel),
              ],
            ),
            const Divider(height: 24),
            const Text('Descrição',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: 12)),
            const SizedBox(height: 6),
            Text(chamado.descricao,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15)),
            if (chamado.criadoEm != null) ...[
              const SizedBox(height: 16),
              _DetalheRow(
                  label: 'Aberto em',
                  valor: formatarData(chamado.criadoEm!)),
            ],
            if (chamado.atualizadoEm != null) ...[
              const SizedBox(height: 8),
              _DetalheRow(
                  label: 'Atualizado em',
                  valor: formatarData(chamado.atualizadoEm!)),
            ],
            if (chamado.tecnicoId != null) ...[
              const SizedBox(height: 8),
              _DetalheRow(
                  label: 'Técnico responsável',
                  valor: '#${chamado.tecnicoId}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetalheRow extends StatelessWidget {
  final String label;
  final String valor;
  const _DetalheRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(valor,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final Chamado chamado;
  const _TimelineCard({required this.chamado});

  static const _etapas = [
    ('ABERTO', 'Aberto', 'Chamado registrado'),
    ('ACEITO', 'Aceito', 'Técnico aceitou o chamado'),
    ('EM_ANDAMENTO', 'Em atendimento', 'Serviço em execução'),
    ('CONCLUIDO', 'Concluído', 'Serviço finalizado'),
  ];

  int _indexStatus(String status) {
    switch (status) {
      case 'ABERTO':
        return 0;
      case 'ACEITO':
        return 1;
      case 'EM_ANDAMENTO':
        return 2;
      case 'CONCLUIDO':
        return 3;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (chamado.isRecusado) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.cancel_outlined,
                  color: AppColors.statusRecusado, size: 28),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chamado recusado',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.statusRecusado)),
                  Text('O técnico recusou este chamado.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final atual = _indexStatus(chamado.status);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Andamento',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontSize: 12)),
            const SizedBox(height: 16),
            ..._etapas.asMap().entries.map((entry) {
              final i = entry.key;
              final etapa = entry.value;
              final concluido = i <= atual;
              final ativo = i == atual;
              return _TimelineItem(
                titulo: etapa.$2,
                sub: etapa.$3,
                concluido: concluido,
                ativo: ativo,
                ultimo: i == _etapas.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String titulo;
  final String sub;
  final bool concluido;
  final bool ativo;
  final bool ultimo;

  const _TimelineItem({
    required this.titulo,
    required this.sub,
    required this.concluido,
    required this.ativo,
    required this.ultimo,
  });

  @override
  Widget build(BuildContext context) {
    final cor = concluido ? AppColors.primary : const Color(0xFFE0E0E0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: concluido ? AppColors.primary : Colors.white,
                border: Border.all(color: cor, width: 2),
                shape: BoxShape.circle,
              ),
              child: concluido
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!ultimo)
              Container(
                width: 2,
                height: 36,
                color: cor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontWeight:
                      ativo ? FontWeight.bold : FontWeight.normal,
                  color: concluido
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
