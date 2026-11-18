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

  /// Crée ou met à jour les fiches depuis les utilisateurs d'EASYPHARM ; rend leur nombre.
  Future<int> importerEmployes();

  Future<List<PosteTravail>> postes();

  /// Champs de la fiche à changer (`poste_code`, `date_entree`, `date_sortie`,
  /// `heure_debut`, `eligible_prime`) ; une valeur null efface.
  Future<void> modifierEmploye(int id, Map<String, Object?> champs);
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

  @override
  Future<int> importerEmployes() =>
      _appel(() => _dio.post('/paie/employes/importer'), (d) => ((d as Map)['employes'] as num?)?.toInt() ?? 0);

  @override
  Future<List<PosteTravail>> postes() => _appel(
    () => _dio.get('/paie/postes'),
    (d) => [for (final p in d as List) PosteTravail.fromJson(p as Map<String, dynamic>)],
  );

  @override
  Future<void> modifierEmploye(int id, Map<String, Object?> champs) =>
      _appel(() => _dio.put('/paie/employes/$id', data: champs), (_) {});
}

final paieApiProvider = Provider<PaieApi>((ref) => PaieApiDio(ref.watch(dioProvider)));
