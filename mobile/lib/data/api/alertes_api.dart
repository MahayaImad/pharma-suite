import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/alertes.dart';
import 'client_api.dart';

/// Alertes (`/alertes`, réponse `{data, error}`). Lève [ErreurApi].
abstract interface class AlertesApi {
  Future<ListeAlertes> alertes();
}

class AlertesApiDio implements AlertesApi {
  AlertesApiDio(this._dio);
  final Dio _dio;

  // La liste s'appuie sur le calcul du stock : le premier appel du jour peut être long.
  static final _long = Options(receiveTimeout: const Duration(minutes: 2));

  @override
  Future<ListeAlertes> alertes() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/alertes', options: _long);
      return ListeAlertes.fromJson(r.data!['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }
}

final alertesApiProvider = Provider<AlertesApi>((ref) => AlertesApiDio(ref.watch(dioProvider)));
