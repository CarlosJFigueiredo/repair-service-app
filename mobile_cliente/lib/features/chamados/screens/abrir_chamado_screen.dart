import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/chamado_provider.dart';
import '../../../shared/theme/app_theme.dart';

class AbrirChamadoScreen extends StatefulWidget {
  const AbrirChamadoScreen({super.key});

  @override
  State<AbrirChamadoScreen> createState() => _AbrirChamadoScreenState();
}

class _AbrirChamadoScreenState extends State<AbrirChamadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  String _tipoServico = 'CELULAR';

  static const _tipos = [
    ('CELULAR', 'Celular', Icons.phone_android),
    ('NOTEBOOK', 'Notebook', Icons.laptop),
    ('INTERNET', 'Internet', Icons.wifi),
    ('OUTRO', 'Outro', Icons.build_outlined),
  ];

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrir() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ChamadoProvider>();
    final erro = await provider.abrir(
      tipoServico: _tipoServico,
      descricao: _descricaoCtrl.text.trim(),
    );
    if (!mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chamado aberto com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ChamadoProvider>().loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Abrir Chamado')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tipo de serviço',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: _tipos.map((t) {
                    final selecionado = _tipoServico == t.$1;
                    return InkWell(
                      onTap: () => setState(() => _tipoServico = t.$1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selecionado
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selecionado
                                ? AppColors.primary
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(t.$3,
                                size: 18,
                                color: selecionado
                                    ? Colors.white
                                    : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              t.$2,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: selecionado
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Descrição do problema',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoCtrl,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Descreva o problema com detalhes para facilitar o atendimento...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Descreva o problema';
                    }
                    if (v.trim().length < 10) {
                      return 'Descrição muito curta (mín. 10 caracteres)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: loading ? null : _abrir,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Abrir chamado'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
