import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/commandes_api.dart';
import '../../../domain/commandes.dart';

/// La journée de commandes, et les gestes qui la changent. Après chaque geste
/// la journée est relue sans repasser par l'état de chargement : l'écran
/// garde ce qu'il affiche pendant ce temps.
class JourneeController extends AsyncNotifier<JourneeCommandes> {
  CommandesApi get _api => ref.read(commandesApiProvider);

  @override
  Future<JourneeCommandes> build() => ref.watch(commandesApiProvider).journee();

  Future<void> _relire() async => state = AsyncData(await _api.journee());

  Future<void> preparer() async => state = AsyncData(await _api.preparer());

  /// Change une quantité : affichée tout de suite, enregistrée ensuite ; en
  /// cas d'échec, la journée est relue et l'erreur remonte.
  Future<void> modifier(Panier panier, LigneCommande ligne, int qte) async {
    final commande = panier.commande;
    final actuelle = state.value;
    if (commande == null || actuelle == null) return;
    state = AsyncData(actuelle.avecLigne(panier.fournisseur.id, ligne.idNom, qte));
    try {
      await _api.modifierLigne(commande.id, ligne.idNom, qte);
    } catch (_) {
      await _relire();
      rethrow;
    }
  }

  /// Ajoute un produit à la main dans un brouillon (ou change sa quantité).
  Future<void> ajouter(int idCommande, int idNom, int qte) async {
    await _api.modifierLigne(idCommande, idNom, qte);
    await _relire();
  }

  Future<void> valider(int idCommande) async {
    await _api.valider(idCommande);
    await _relire();
  }

  Future<void> rouvrir(int idCommande) async {
    await _api.rouvrir(idCommande);
    await _relire();
  }

  Future<void> annuler(int idCommande) async {
    await _api.annuler(idCommande);
    await _relire();
  }

  Future<BonCommande> envoyer(int idCommande) async {
    final bon = await _api.envoyer(idCommande);
    await _relire();
    return bon;
  }
}

final journeeProvider = AsyncNotifierProvider<JourneeController, JourneeCommandes>(
  JourneeController.new,
  retry: (_, _) => null,
);

final fournisseursCommandeProvider = FutureProvider<List<FournisseurReglage>>(
  (ref) => ref.watch(commandesApiProvider).fournisseurs(),
  retry: (_, _) => null,
);

final valideursProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(commandesApiProvider).valideurs(),
  retry: (_, _) => null,
);

final comptesProvider = FutureProvider<List<Compte>>(
  (ref) => ref.watch(commandesApiProvider).comptes(),
  retry: (_, _) => null,
);
