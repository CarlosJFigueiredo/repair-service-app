import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../../features/auth/models/usuario.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  bool _loading = false;
  String? _erro;

  Usuario? get usuario => _usuario;
  bool get isLoggedIn => _usuario != null;
  bool get loading => _loading;
  String? get erro => _erro;

  // Verifica token salvo ao abrir o app e recarrega o perfil
  Future<void> inicializar() async {
    final token = await StorageService.getToken();
    if (token == null) return;

    try {
      final userId = _userIdFromToken(token);
      final response = await ApiClient.instance.get('${ApiConstants.usuarios}/$userId');
      _usuario = Usuario.fromJson(response.data as Map<String, dynamic>);
      notifyListeners();
    } catch (_) {
      await StorageService.removeToken();
    }
  }

  Future<String?> login(String email, String senha) async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post(
        ApiConstants.login,
        data: {'email': email, 'senha': senha},
      );

      final data = response.data as Map<String, dynamic>;
      await StorageService.saveToken(data['token'] as String);
      _usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
      return null;
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = (e.response!.data as Map?)?['erro'] as String?;
        _erro = msg ?? 'Erro ${e.response!.statusCode}';
      } else {
        _erro = 'Sem conexão com o servidor (${e.message})';
      }
      return _erro;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    String perfil = 'CLIENTE',
    String? especialidade,
  }) async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'senha': senha,
        'perfil': perfil,
        if (especialidade != null && especialidade.isNotEmpty)
          'especialidade': especialidade,
      };
      await ApiClient.instance.post(ApiConstants.usuarios, data: body);
      return null;
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;
        final msg = data is Map ? data['erro'] as String? : null;
        _erro = msg ?? 'Erro ${e.response!.statusCode}';
      } else {
        _erro = 'Sem conexão com o servidor (${e.message})';
      }
      return _erro;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await StorageService.removeToken();
    _usuario = null;
    notifyListeners();
  }

  // Extrai o campo 'sub' (user id) do payload JWT sem biblioteca externa
  int _userIdFromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Token inválido');

    // JWT usa Base64URL — normaliza para Base64 padrão
    var payload = parts[1];
    payload = payload.replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
      case 3:
        payload += '=';
    }

    final decoded = utf8.decode(base64.decode(payload));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    return json['sub'] as int;
  }
}
