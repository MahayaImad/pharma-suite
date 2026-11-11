import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/api/stock_api.dart';
import '../../../domain/stock.dart';

part 'stock_providers.freezed.dart';

/// Pas de nouvel essai automatique : l'écran d'erreur propose « Réessayer ».
Duration? _sansNouvelEssai(int essais, Object erreur) => null;

/// En-tête : totaux, familles, heure des données.
final resumeStockProvider = FutureProvider<ResumeStock>(
  (ref) => ref.watch(stockApiProvider).resume(),
  retry: _sansNouvelEssai,
);

/// Ce qui demande une action : ruptures, péremptions à risque, surstock.
final aTraiterProvider = FutureProvider<ATraiter>(
  (ref) => ref.watch(stockApiProvider).aTraiter(),
  retry: _sansNouvelEssai,
);

/// Filtres choisis au-dessus de la liste.
class FiltreController extends Notifier<FiltreProduits> {
  @override
  FiltreProduits build() => const FiltreProduits();

  void chercher(String texte) => state = state.copyWith(recherche: texte);
  void famille(int? id) => state = state.copyWith(idFamille: id);
  void etat(FiltreEtat? etat) => state = state.copyWith(etat: etat);
  void trier(TriProduits tri) => state = state.copyWith(tri: tri);
  void effacer() => state = FiltreProduits(tri: state.tri);
}

final filtreProduitsProvider = NotifierProvider<FiltreController, FiltreProduits>(FiltreController.new);

/// La liste déjà chargée et ce qui reste à charger.
@freezed
abstract class ListeProduits with _$ListeProduits {
  const ListeProduits._();

  const factory ListeProduits({
    @Default(<Produit>[]) List<Produit> produits,
    @Default(0) int total,
    @Default(false) bool chargeSuite,
  }) = _ListeProduits;

  bool get complete => produits.length >= total;
}

/// Liste paginée : 50 produits, puis la suite au défilement.
class ListeProduitsController extends AsyncNotifier<ListeProduits> {
  static const taillePage = 50;

  @override
  Future<ListeProduits> build() async {
    final filtre = ref.watch(filtreProduitsProvider);
    final page = await ref.watch(stockApiProvider).produits(filtre, limite: taillePage);
    return ListeProduits(produits: page.items, total: page.total);
  }

  /// Charge la page suivante ; sans effet si tout est là ou déjà en cours.
  Future<void> chargerSuite() async {
    final actuelle = state.value;
    if (actuelle == null || actuelle.complete || actuelle.chargeSuite || state.isLoading) return;
    final filtre = ref.read(filtreProduitsProvider);
    state = AsyncData(actuelle.copyWith(chargeSuite: true));
    try {
      final page = await ref
          .read(stockApiProvider)
          .produits(filtre, offset: actuelle.produits.length, limite: taillePage);
      // Le filtre a pu changer pendant l'appel : la page ne vaut plus rien.
      if (ref.read(filtreProduitsProvider) != filtre) return;
      state = AsyncData(ListeProduits(produits: [...actuelle.produits, ...page.items], total: page.total));
    } catch (_) {
      // La liste déjà chargée reste affichée ; le prochain défilement réessaie.
      state = AsyncData(actuelle);
    }
  }
}

final listeProduitsProvider = AsyncNotifierProvider<ListeProduitsController, ListeProduits>(
  ListeProduitsController.new,
  retry: _sansNouvelEssai,
);

/// Fiche d'un produit.
final ficheProduitProvider = FutureProvider.family<Produit, int>(
  (ref, id) => ref.watch(stockApiProvider).fiche(id),
  retry: _sansNouvelEssai,
);

/// Indicateurs de gestion d'un produit.
final indicateursProduitProvider = FutureProvider.family<IndicateursProduit, int>(
  (ref, id) => ref.watch(stockApiProvider).indicateurs(id),
  retry: _sansNouvelEssai,
);

/// Lots d'un produit : `epuises` ajoute les lots à stock nul.
final lotsProduitProvider = FutureProvider.family<List<Lot>, ({int id, bool epuises})>(
  (ref, p) => ref.watch(stockApiProvider).lots(p.id, epuises: p.epuises),
  retry: _sansNouvelEssai,
);
