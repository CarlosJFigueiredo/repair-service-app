import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/selecao_tipo_screen.dart';
import '../features/auth/screens/cadastro_screen.dart';
import '../features/auth/screens/cadastro_tecnico_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/chamados/screens/abrir_chamado_screen.dart';
import '../features/chamados/screens/detalhes_chamado_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const selecaoTipo = '/cadastro';
  static const cadastroCliente = '/cadastro/cliente';
  static const cadastroTecnico = '/cadastro/tecnico';
  static const chamados = '/';
  static const abrirChamado = '/chamados/novo';
  static const detalhesChamado = '/chamados/detalhes';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        selecaoTipo: (_) => const SelecaoTipoScreen(),
        cadastroCliente: (_) => const CadastroScreen(),
        cadastroTecnico: (_) => const CadastroTecnicoScreen(),
        chamados: (_) => const HomeScreen(),
        abrirChamado: (_) => const AbrirChamadoScreen(),
        detalhesChamado: (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as int;
          return DetalhesChamadoScreen(chamadoId: id);
        },
      };
}
