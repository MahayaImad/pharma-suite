import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/commandes.dart';
import 'client_api.dart';

/// Commandes fournisseurs (`/commandes`, réponses `{data, error}`). Lève [ErreurApi].
abstract interface class CommandesApi {
  /// Paniers du soir : brouillons enregistrés, sinon proposition.
  Future<JourneeCommandes> journee();

  /// Enregistre la proposition en brouillons ; renvoie la journée à jour.
  Future<JourneeCommandes> preparer();

  /// Quantité d'un produit dans un brouillon ; 0 retire la ligne.
  Future<void> modifierLigne(int idCommande, int idNom, int qte);

  Future<void> valider(int idCommande);
  Future<void> rouvrir(int idCommande);
  Future<void> annuler(int idCommande);

  /// Marque envoyée et renvoie le bon.
  Future<BonCommande> envoyer(int idCommande);
  Future<BonCommande> bon(int idCommande);

  Future<List<FournisseurReglage>> fournisseurs();
  Future<void> reglerFournisseur(int id, TypeFournisseur type, bool actif, String? whatsapp);
  Future<List<String>> valideurs();
  Future<void> ajouterValideur(String username);
  Future<void> retirerValideur(String username);
}

class CommandesApiDio implements CommandesApi {
  CommandesApiDio(this._dio);
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

  JourneeCommandes _journee(Object? d) => JourneeCommandes.fromJson(d as Map<String, dynamic>);
  BonCommande _bon(Object? d) => BonCommande.fromJson(d as Map<String, dynamic>);

  // Le premier calcul du jour relit des années de ventes : on lui laisse le temps.
  static final _long = Options(receiveTimeout: const Duration(minutes: 3));

  @override
  Future<JourneeCommandes> journee() => _appel(() => _dio.get('/commandes/jour', options: _long), _journee);

  @override
  Future<JourneeCommandes> preparer() => _appel(() => _dio.post('/commandes/preparer', options: _long), _journee);

  @override
  Future<void> modifierLigne(int idCommande, int idNom, int qte) =>
      _appel(() => _dio.put('/commandes/$idCommande/lignes/$idNom', data: {'qte': qte}), (_) {});

  @override
  Future<void> valider(int idCommande) => _appel(() => _dio.post('/commandes/$idCommande/valider'), (_) {});

  @override
  Future<void> rouvrir(int idCommande) => _appel(() => _dio.post('/commandes/$idCommande/rouvrir'), (_) {});

  @override
  Future<void> annuler(int idCommande) => _appel(() => _dio.post('/commandes/$idCommande/annuler'), (_) {});

  @override
  Future<BonCommande> envoyer(int idCommande) => _appel(() => _dio.post('/commandes/$idCommande/envoyer'), _bon);

  @override
  Future<BonCommande> bon(int idCommande) => _appel(() => _dio.get('/commandes/$idCommande/bon'), _bon);

  @override
  Future<List<FournisseurReglage>> fournisseurs() => _appel(
    () => _dio.get('/commandes/reglages/fournisseurs'),
    (d) => [for (final x in d as List) FournisseurReglage.fromJson(x as Map<String, dynamic>)],
  );

  @override
  Future<void> reglerFournisseur(int id, TypeFournisseur type, bool actif, String? whatsapp) => _appel(
    () => _dio.put(
      '/commandes/reglages/fournisseurs/$id',
      data: {'type': type.api, 'actif': actif, 'whatsapp': whatsapp},
    ),
    (_) {},
  );

  @override
  Future<List<String>> valideurs() =>
      _appel(() => _dio.get('/commandes/reglages/valideurs'), (d) => [for (final x in d as List) x as String]);

  @override
  Future<void> ajouterValideur(String username) =>
      _appel(() => _dio.post('/commandes/reglages/valideurs', data: {'username': username}), (_) {});

  @override
  Future<void> retirerValideur(String username) =>
      _appel(() => _dio.delete('/commandes/reglages/valideurs/${Uri.encodeComponent(username)}'), (_) {});
}

final commandesApiProvider = Provider<CommandesApi>((ref) => CommandesApiDio(ref.watch(dioProvider)));
