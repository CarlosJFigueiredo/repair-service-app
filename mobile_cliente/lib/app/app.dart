import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../shared/theme/app_theme.dart';
import 'routes.dart';

class TecnicoResolveApp extends StatelessWidget {
  const TecnicoResolveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Tecnico Resolve',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: auth.isLoggedIn ? AppRoutes.chamados : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
