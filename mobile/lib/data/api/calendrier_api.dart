import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/calendrier.dart';
import 'client_api.dart';

/// Calendrier de l'officine (`/calendrier`, réponses `{data, error}`) et
/// réglages des commandes (`/stock/reglages`). Lève [ErreurApi].
abstract interface class CalendrierApi {
  Future<List<Garde>> gardes();
  Future<Garde> enregistrerGarde(DateTime jour, TypeGarde type, {String? note});
  Future<void> supprimerGarde(DateTime jour);

  /// Écarte une garde détectée ou proposée : elle ne sera plus reproposée.
  Future<void> annulerGarde(DateTime jour);

  /// Ajoute les gardes des [mois] prochains mois d'après la rotation (à
  /// confirmer) ; renvoie celles qui ont été ajoutées.
  Future<List<Garde>> proposerGardes({int mois = 3});

  Future<List<Evenement>> evenements();
  Future<Evenement> enregistrerEvenement(TypeEvenement type, DateTime debut, DateTime fin, {int? id});
  Future<void> supprimerEvenement(int id);

  Future<List<Ferie>> feries();
  Future<Ferie> ajouterFerie(DateTime jour, String libelle);
  Future<void> supprimerFerie(int id);

  Future<List<Reglage>> reglages();
  Future<List<Reglage>> modifierReglages(Map<String, double> valeurs);
}

class CalendrierApiDio implements CalendrierApi {
  CalendrierApiDio(this._dio);
  final Dio _dio;

  /// Appelle une route du calendrier et déballe `{data, error}`.
  Future<T> _appel<T>(Future<Response<Object?>> Function() requete, T Function(Object? data) lire) async {
    try {
      final r = await requete();
      return lire((r.data as Map<String, dynamic>)['data']);
    } on DioException catch (e) {
      final corps = e.response?.data;
      if (corps is Map && corps['error'] is Map) {
        throw ErreurApi((corps['error'] as Map)['message'] as String? ?? 'Erreur.');
      }
      throw ErreurApi.depuis(e);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  List<T> _liste<T>(Object? d, T Function(Map<String, dynamic>) f) => [
    for (final x in d as List) f(x as Map<String, dynamic>),
  ];

  @override
  Future<List<Garde>> gardes() => _appel(() => _dio.get('/calendrier/gardes'), (d) => _liste(d, Garde.fromJson));

  @override
  Future<Garde> enregistrerGarde(DateTime jour, TypeGarde type, {String? note}) => _appel(
    () => _dio.put('/calendrier/gardes/${jourApi(jour)}', data: {'type': type.api, 'note': note}),
    (d) => Garde.fromJson(d as Map<String, dynamic>),
  );

  @override
  Future<List<Garde>> proposerGardes({int mois = 3}) => _appel(
    () => _dio.post('/calendrier/gardes/proposer', queryParameters: {'mois': mois}),
    (d) => _liste(d, Garde.fromJson),
  );

  @override
  Future<void> annulerGarde(DateTime jour) =>
      _appel(() => _dio.post('/calendrier/gardes/${jourApi(jour)}/annuler'), (_) {});

  @override
  Future<void> supprimerGarde(DateTime jour) =>
      _appel(() => _dio.delete('/calendrier/gardes/${jourApi(jour)}'), (_) {});

  @override
  Future<List<Evenement>> evenements() =>
      _appel(() => _dio.get('/calendrier/evenements'), (d) => _liste(d, Evenement.fromJson));

  @override
  Future<Evenement> enregistrerEvenement(TypeEvenement type, DateTime debut, DateTime fin, {int? id}) {
    final corps = {'type': type.api, 'date_debut': jourApi(debut), 'date_fin': jourApi(fin)};
    return _appel(
      () => id == null
          ? _dio.post('/calendrier/evenements', data: corps)
          : _dio.put('/calendrier/evenements/$id', data: corps),
      (d) => Evenement.fromJson(d as Map<String, dynamic>),
    );
  }

  @override
  Future<void> supprimerEvenement(int id) => _appel(() => _dio.delete('/calendrier/evenements/$id'), (_) {});

  @override
  Future<List<Ferie>> feries() => _appel(() => _dio.get('/calendrier/feries'), (d) => _liste(d, Ferie.fromJson));

  @override
  Future<Ferie> ajouterFerie(DateTime jour, String libelle) => _appel(
    () => _dio.post('/calendrier/feries', data: {'date': jourApi(jour), 'label': libelle}),
    (d) => Ferie.fromJson(d as Map<String, dynamic>),
  );

  @override
  Future<void> supprimerFerie(int id) => _appel(() => _dio.delete('/calendrier/feries/$id'), (_) {});

  // `/stock/reglages` : ancien style, pas d'enveloppe.
  @override
  Future<List<Reglage>> reglages() async {
    try {
      final r = await _dio.get<List<dynamic>>('/stock/reglages');
      return [for (final x in r.data!) Reglage.fromJson(x as Map<String, dynamic>)];
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  @override
  Future<List<Reglage>> modifierReglages(Map<String, double> valeurs) async {
    try {
      final r = await _dio.patch<List<dynamic>>('/stock/reglages', data: valeurs);
      return [for (final x in r.data!) Reglage.fromJson(x as Map<String, dynamic>)];
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      if (detail is String) throw ErreurApi(detail);
      throw ErreurApi.depuis(e);
    }
  }
}

final calendrierApiProvider = Provider<CalendrierApi>((ref) => CalendrierApiDio(ref.watch(dioProvider)));
