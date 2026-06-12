import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../services/api_client.dart';
import '../../features/chamados/models/chamado.dart';

class ChamadoProvider extends ChangeNotifier {
  List<Chamado> _chamados = [];
  bool _loading = false;
  String? _erro;

  List<Chamado> get chamados => _chamados;
  bool get loading => _loading;
  String? get erro => _erro;

  List<Chamado> get ativos => _chamados
      .where((c) => c.isAberto || c.isAceito || c.isEmAndamento)
      .toList();

  List<Chamado> get historico =>
      _chamados.where((c) => c.isFinalizado).toList();

  List<Chamado> get alertas =>
      _chamados.where((c) => !c.isAberto).toList();

  Future<void> listar() async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.get(ApiConstants.chamados);
      final list = (response.data as List).cast<Map<String, dynamic>>();
      _chamados = list.map(Chamado.fromJson).toList();
    } on DioException catch (e) {
      _erro = _parseError(e, 'Erro ao carregar chamados');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> abrir({
    required String tipoServico,
    required String descricao,
  }) async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      await ApiClient.instance.post(
        ApiConstants.chamados,
        data: {'tipo_servico': tipoServico, 'descricao': descricao},
      );
      await listar();
      return null;
    } on DioException catch (e) {
      _erro = _parseError(e, 'Erro ao abrir chamado');
      _loading = false;
      notifyListeners();
      return _erro;
    }
  }

  Future<Chamado?> buscarPorId(int id) async {
    try {
      final url = '${ApiConstants.chamados}$id';
      final response = await ApiClient.instance.get(url);
      return Chamado.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String _parseError(DioException e, String fallback) {
    if (e.response != null) {
      final data = e.response!.data;
      return (data is Map ? data['erro'] as String? : null) ??
          'Erro ${e.response!.statusCode}';
    }
    return fallback;
  }
}
