import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/providers/chamado_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../chamados/screens/lista_chamados_screen.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChamadoProvider>();
    final hist = provider.historico;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Histórico')),
      body: _buildBody(context, provider, hist),
    );
  }

  Widget _buildBody(BuildContext context, ChamadoProvider provider, list) {
    if (provider.loading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return const _VazioView();
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ChamadoProvider>().listar(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final c = list[i];
          return Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.detalhesChamado,
                arguments: c.id,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (c.isConcluido
                                ? AppColors.statusConcluido
                                : AppColors.statusRecusado)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        c.isConcluido
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: c.isConcluido
                            ? AppColors.statusConcluido
                            : AppColors.statusRecusado,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(c.tipoServicoLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              StatusBadge(
                                  status: c.status, label: c.statusLabel),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.descricao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                          if (c.atualizadoEm != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              formatarData(c.atualizadoEm!),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
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
          Icon(Icons.history, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Nenhum chamado finalizado',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text('Seus chamados concluídos ou recusados\naparecerão aqui.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
