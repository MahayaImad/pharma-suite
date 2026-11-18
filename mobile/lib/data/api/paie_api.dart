import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/paie.dart';
import 'client_api.dart';

/// Paie brute (`/paie`, réponses `{data, error}`), titulaire seulement. Lève [ErreurApi].
abstract interface class PaieApi {
  Future<PaieMois> mois(int annee, int mois);
  Future<void> heuresSup(int annee, int mois, int idEmploye, double heures);
  Future<void> valider(int annee, int mois);

  /// Recalcule les primes de rendement du mois (`/performance/primes/…/calculer`).
  Future<void> recalculerPrimes(int annee, int mois);
}

class PaieApiDio implements PaieApi {
  PaieApiDio(this._dio);
  final Dio _dio;

  Future<T> _appel<T>(Future<Response<Object?>> Function() requete, T Function(Object? data) lire) async {
    try {
      final r = await requete();
      final corps = r.data;
      return lire(corps is Map<String, dynamic> && corps.containsKey('data') ? corps['data'] : corps);
    } on DioException catch (e) {
      final corps = e.response?.data;
      if (corps is Map && corps['error'] is Map) {
        throw ErreurApi((corps['error'] as Map)['message'] as String? ?? 'Erreur.');
      }
      if (corps is Map && corps['detail'] is String) throw ErreurApi(corps['detail'] as String);
      throw ErreurApi.depuis(e);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  static final _long = Options(receiveTimeout: const Duration(minutes: 2));

  @override
  Future<PaieMois> mois(int annee, int mois) =>
      _appel(() => _dio.get('/paie/$annee/$mois', options: _long), (d) => PaieMois.fromJson(d as Map<String, dynamic>));

  @override
  Future<void> heuresSup(int annee, int mois, int idEmploye, double heures) =>
      _appel(() => _dio.put('/paie/$annee/$mois/heures-sup/$idEmploye', data: {'heures': heures}), (_) {});

  @override
  Future<void> valider(int annee, int mois) =>
      _appel(() => _dio.post('/paie/$annee/$mois/valider', options: _long), (_) {});

  @override
  Future<void> recalculerPrimes(int annee, int mois) =>
      _appel(() => _dio.post('/performance/primes/$annee/$mois/calculer', options: _long), (_) {});
}

final paieApiProvider = Provider<PaieApi>((ref) => PaieApiDio(ref.watch(dioProvider)));
