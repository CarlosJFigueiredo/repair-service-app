import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/chamado_provider.dart';
import '../../chamados/screens/lista_chamados_screen.dart';
import '../../historico/screens/historico_screen.dart';
import '../../alertas/screens/alertas_screen.dart';
import '../../perfil/screens/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _pollingTimer;

  static const _intervaloPolling = Duration(seconds: 10);

  final List<Widget> _screens = const [
    ListaChamadosScreen(),
    HistoricoScreen(),
    AlertasScreen(),
    PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Carga inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChamadoProvider>().listar();
    });
    // Polling periódico para refletir atualizações do servidor automaticamente
    _pollingTimer = Timer.periodic(_intervaloPolling, (_) {
      if (mounted) context.read<ChamadoProvider>().listar();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Chamados'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alertas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
