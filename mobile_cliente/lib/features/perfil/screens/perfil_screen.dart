import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    if (usuario == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                usuario.nome.isNotEmpty
                    ? usuario.nome[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              usuario.nome,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                usuario.perfil == 'TECNICO' ? 'Técnico' : 'Cliente',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _InfoTile(
                    icone: Icons.email_outlined,
                    label: 'E-mail',
                    valor: usuario.email,
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icone: Icons.phone_outlined,
                    label: 'Telefone',
                    valor: usuario.telefone,
                  ),
                  if (usuario.especialidade != null) ...[
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icone: Icons.engineering_outlined,
                      label: 'Especialidade',
                      valor: usuario.especialidade!,
                    ),
                  ],
                  if (usuario.criadoEm != null) ...[
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icone: Icons.calendar_today_outlined,
                      label: 'Membro desde',
                      valor: _formatarData(usuario.criadoEm!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sair da conta'),
                    content: const Text('Tem certeza que deseja sair?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sair',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await auth.logout();
                  navigator.pushReplacementNamed(AppRoutes.login);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sair da conta',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;
  const _InfoTile(
      {required this.icone, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icone, size: 22, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
