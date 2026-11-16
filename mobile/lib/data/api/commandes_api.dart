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

  /// « Commander » depuis le Stock : au brouillon du jour du fournisseur
  /// principal, à la quantité proposée ce soir (au moins 1).
  /// Avec [idFournisseur] et [qte] : chez cet autre grossiste (produit non livré).
  Future<AjoutCommande> ajouter(int idNom, {int? qte, int? idFournisseur});

  /// Commandes envoyées des derniers jours, rapprochées des réceptions.
  Future<SuiviLivraisons> suivi();

  /// Change le grossiste d'une ligne ; renvoie la journée à jour.
  Future<JourneeCommandes> deplacer(int idNom, int de, int vers);

  /// Retient le grossiste préféré d'un produit ; null : celui du dernier achat.
  Future<void> preferer(int idNom, int? idFournisseur);

  /// Remplace une ligne d'un brouillon par un autre générique (même DCI).
  Future<JourneeCommandes> remplacer(int idCommande, int idNom, int par);

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

  /// Produits en tension : détectés à confirmer, puis décidés.
  Future<List<Tension>> tensions();

  /// Tension d'un produit (non décidé : tension fausse, non confirmé).
  Future<Tension> tension(int idNom);

  /// Confirme ou écarte la tension d'un produit (titulaire).
  Future<Tension> reglerTension(int idNom, bool tension);

  /// Pourquoi cette quantité : détail du calcul d'un produit.
  Future<DetailCalcul> calcul(int idNom);

  /// Marques de même DCI qu'un produit, et lesquelles sont commandées.
  Future<GroupeGenerique> generiques(int idNom);

  /// Choix forcé d'une marque : « garder », « exclure » ou null (automatique).
  Future<GroupeGenerique> choisirGenerique(int idNom, String? choix);

  /// Mode forcé du groupe : « toutes », « quelques » ou null (d'après la classe).
  Future<GroupeGenerique> modeGroupe(int idNom, String? mode);

  /// Comptes de l'application (titulaire seulement).
  Future<List<Compte>> comptes();
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
  Future<AjoutCommande> ajouter(int idNom, {int? qte, int? idFournisseur}) => _appel(
    () => _dio.post(
      '/commandes/ajouter',
      data: {'id_nom': idNom, 'qte': ?qte, 'id_fournisseur': ?idFournisseur},
      options: _long,
    ),
    (d) => AjoutCommande.fromJson(d as Map<String, dynamic>),
  );

  @override
  Future<SuiviLivraisons> suivi() =>
      _appel(() => _dio.get('/commandes/suivi'), (d) => SuiviLivraisons.fromJson(d as Map<String, dynamic>));

  @override
  Future<JourneeCommandes> deplacer(int idNom, int de, int vers) => _appel(
    () => _dio.post('/commandes/lignes/$idNom/deplacer', data: {'de': de, 'vers': vers}, options: _long),
    _journee,
  );

  @override
  Future<void> preferer(int idNom, int? idFournisseur) =>
      _appel(() => _dio.put('/commandes/preferes/$idNom', data: {'id_fournisseur': idFournisseur}), (_) {});

  @override
  Future<JourneeCommandes> remplacer(int idCommande, int idNom, int par) => _appel(
    () => _dio.post('/commandes/$idCommande/lignes/$idNom/remplacer', data: {'par': par}, options: _long),
    _journee,
  );

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

  @override
  Future<List<Tension>> tensions() => _appel(
    () => _dio.get('/commandes/tensions'),
    (d) => [for (final x in d as List) Tension.fromJson(x as Map<String, dynamic>)],
  );

  @override
  Future<Tension> tension(int idNom) =>
      _appel(() => _dio.get('/commandes/tensions/$idNom'), (d) => Tension.fromJson(d as Map<String, dynamic>));

  @override
  Future<Tension> reglerTension(int idNom, bool tension) => _appel(
    () => _dio.put('/commandes/tensions/$idNom', data: {'tension': tension}),
    (d) => Tension.fromJson(d as Map<String, dynamic>),
  );

  @override
  Future<DetailCalcul> calcul(int idNom) => _appel(
    () => _dio.get('/commandes/calcul/$idNom', options: _long),
    (d) => DetailCalcul.fromJson(d as Map<String, dynamic>),
  );

  GroupeGenerique _groupe(Object? d) => GroupeGenerique.fromJson(d as Map<String, dynamic>);

  @override
  Future<GroupeGenerique> generiques(int idNom) =>
      _appel(() => _dio.get('/commandes/generiques/$idNom', options: _long), _groupe);

  @override
  Future<GroupeGenerique> choisirGenerique(int idNom, String? choix) =>
      _appel(() => _dio.put('/commandes/generiques/$idNom/choix', data: {'choix': choix}, options: _long), _groupe);

  @override
  Future<GroupeGenerique> modeGroupe(int idNom, String? mode) =>
      _appel(() => _dio.put('/commandes/generiques/$idNom/mode', data: {'mode': mode}, options: _long), _groupe);

  @override
  Future<List<Compte>> comptes() async {
    try {
      final r = await _dio.get<List<dynamic>>('/auth/users');
      return [for (final x in r.data!) Compte.fromJson(x as Map<String, dynamic>)];
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }
}

final commandesApiProvider = Provider<CommandesApi>((ref) => CommandesApiDio(ref.watch(dioProvider)));
