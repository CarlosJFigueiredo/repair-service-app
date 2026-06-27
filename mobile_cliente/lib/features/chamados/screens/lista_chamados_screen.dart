import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/chamado_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/chamado.dart';

class ListaChamadosScreen extends StatefulWidget {
  const ListaChamadosScreen({super.key});

  @override
  State<ListaChamadosScreen> createState() => _ListaChamadosScreenState();
}

class _ListaChamadosScreenState extends State<ListaChamadosScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChamadoProvider>();
    final isTecnico =
        context.watch<AuthProvider>().usuario?.perfil == 'TECNICO';
    final ativos = provider.ativos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isTecnico ? 'Chamados' : 'Meus Chamados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ChamadoProvider>().listar(),
          ),
        ],
      ),
      floatingActionButton: isTecnico
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final p = context.read<ChamadoProvider>();
                await Navigator.pushNamed(context, AppRoutes.abrirChamado);
                if (mounted) p.listar();
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo chamado'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
      body: _buildBody(provider, ativos, isTecnico),
    );
  }

  Widget _buildBody(ChamadoProvider provider, List<Chamado> ativos, bool isTecnico) {
    if (provider.loading && ativos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.erro != null && ativos.isEmpty) {
      return _ErroView(
        mensagem: provider.erro!,
        onRetry: () => context.read<ChamadoProvider>().listar(),
      );
    }
    if (ativos.isEmpty) {
      return _VazioView(
        icone: Icons.check_circle_outline,
        mensagem: 'Nenhum chamado ativo',
        sub: isTecnico
            ? 'Nenhum chamado disponível no momento.'
            : 'Toque em "Novo chamado" para abrir um.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ChamadoProvider>().listar(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: ativos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ChamadoCard(chamado: ativos[i]),
      ),
    );
  }
}

class _ChamadoCard extends StatelessWidget {
  final Chamado chamado;
  const _ChamadoCard({required this.chamado});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconeTipo(chamado.tipoServico),
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    chamado.tipoServicoLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  StatusBadge(
                      status: chamado.status, label: chamado.statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                chamado.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (chamado.criadoEm != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Aberto em ${formatarData(chamado.criadoEm!)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  const StatusBadge({super.key, required this.status, required this.label});

  Color get _cor {
    switch (status) {
      case 'ABERTO':
        return AppColors.statusAberto;
      case 'ACEITO':
        return AppColors.statusAceito;
      case 'EM_ANDAMENTO':
        return AppColors.statusAndamento;
      case 'CONCLUIDO':
        return AppColors.statusConcluido;
      case 'RECUSADO':
        return AppColors.statusRecusado;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _cor),
      ),
    );
  }
}

class _VazioView extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String sub;
  const _VazioView(
      {required this.icone, required this.mensagem, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(mensagem,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _ErroView({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData iconeTipo(String tipo) {
  switch (tipo) {
    case 'CELULAR':
      return Icons.phone_android;
    case 'NOTEBOOK':
      return Icons.laptop;
    case 'INTERNET':
      return Icons.wifi;
    default:
      return Icons.build_outlined;
  }
}

String formatarData(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return iso;
  }
}
