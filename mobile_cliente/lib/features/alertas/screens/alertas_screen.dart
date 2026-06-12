import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/providers/chamado_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../chamados/models/chamado.dart';
import '../../chamados/screens/lista_chamados_screen.dart';


class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChamadoProvider>();
    final alertas = provider.alertas;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alertas')),
      body: alertas.isEmpty
          ? const _VazioView()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alertas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _AlertaCard(chamado: alertas[i]),
            ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final Chamado chamado;
  const _AlertaCard({required this.chamado});

  String get _mensagem {
    switch (chamado.status) {
      case 'ACEITO':
        return 'Seu chamado foi aceito por um técnico.';
      case 'EM_ANDAMENTO':
        return 'O técnico está trabalhando no seu chamado.';
      case 'CONCLUIDO':
        return 'Seu chamado foi concluído com sucesso!';
      case 'RECUSADO':
        return 'Seu chamado foi recusado pelo técnico.';
      default:
        return 'Status atualizado.';
    }
  }

  IconData get _icone {
    switch (chamado.status) {
      case 'ACEITO':
        return Icons.thumb_up_outlined;
      case 'EM_ANDAMENTO':
        return Icons.engineering_outlined;
      case 'CONCLUIDO':
        return Icons.check_circle_outline;
      case 'RECUSADO':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _cor {
    switch (chamado.status) {
      case 'ACEITO':
        return AppColors.statusAceito;
      case 'EM_ANDAMENTO':
        return AppColors.statusAndamento;
      case 'CONCLUIDO':
        return AppColors.statusConcluido;
      case 'RECUSADO':
        return AppColors.statusRecusado;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.detalhesChamado,
          arguments: chamado.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icone, color: _cor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${chamado.tipoServicoLabel} · #${chamado.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(_mensagem,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    if (chamado.atualizadoEm != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatarData(chamado.atualizadoEm!),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _VazioView extends StatelessWidget {
  const _VazioView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Nenhum alerta',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text('Atualizações dos seus chamados aparecerão aqui.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
