import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/inventaire.dart';
import 'client_api.dart';

/// Inventaire tournant (`/inventaire`, réponses `{data, error}`). Lève [ErreurApi].
abstract interface class InventaireApi {
  Future<JourneeInventaire> journee();

  /// Enregistre un comptage ; recompter le même produit le même jour remplace.
  Future<Comptage> compter(int idNom, int stockCompte, {CauseEcart? cause});

  /// Annule un comptage du jour : le produit revient dans la liste.
  Future<void> annuler(int idComptage);

  /// L'écart a été reporté dans EASYPHARM (ou non).
  Future<void> corriger(int idComptage, bool corrige);
}

class InventaireApiDio implements InventaireApi {
  InventaireApiDio(this._dio);
  final Dio _dio;

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

  @override
  Future<JourneeInventaire> journee() => _appel(
    () => _dio.get('/inventaire/jour', options: Options(receiveTimeout: const Duration(minutes: 1))),
    (d) => JourneeInventaire.fromJson(d as Map<String, dynamic>),
  );

  @override
  Future<Comptage> compter(int idNom, int stockCompte, {CauseEcart? cause}) => _appel(
    () => _dio.post('/inventaire/comptages', data: {'id_nom': idNom, 'stock_compte': stockCompte, 'cause': cause?.api}),
    (d) => Comptage.fromJson(d as Map<String, dynamic>),
  );

  @override
  Future<void> annuler(int idComptage) => _appel(() => _dio.delete('/inventaire/comptages/$idComptage'), (_) {});

  @override
  Future<void> corriger(int idComptage, bool corrige) =>
      _appel(() => _dio.put('/inventaire/comptages/$idComptage/corrige', data: {'corrige': corrige}), (_) {});
}

final inventaireApiProvider = Provider<InventaireApi>((ref) => InventaireApiDio(ref.watch(dioProvider)));
