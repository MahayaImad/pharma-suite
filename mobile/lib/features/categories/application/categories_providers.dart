import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/categories_api.dart';
import '../../../domain/categories.dart';

/// Mois affiché : le mois en cours par défaut.
class MoisCategories extends Notifier<({int annee, int mois})> {
  @override
  ({int annee, int mois}) build() {
    final n = DateTime.now();
    return (annee: n.year, mois: n.month);
  }

  void decaler(int pas) {
    final d = DateTime(state.annee, state.mois + pas);
    state = (annee: d.year, mois: d.month);
  }
}

final moisCategoriesProvider = NotifierProvider<MoisCategories, ({int annee, int mois})>(MoisCategories.new);

/// Recherche de laboratoire, et « voir tous les laboratoires ».
class FiltreLaboratoires extends Notifier<({String recherche, bool tous})> {
  @override
  ({String recherche, bool tous}) build() => (recherche: '', tous: false);

  void chercher(String texte) => state = (recherche: texte.trim(), tous: state.tous);
  void toutVoir() => state = (recherche: state.recherche, tous: true);
}

final filtreLaboratoiresProvider = NotifierProvider<FiltreLaboratoires, ({String recherche, bool tous})>(
  FiltreLaboratoires.new,
);

final primeCategoriesProvider = FutureProvider<PrimeCategories>((ref) {
  final m = ref.watch(moisCategoriesProvider);
  return ref.watch(categoriesApiProvider).mois(m.annee, m.mois);
}, retry: (_, _) => null);

final laboratoiresPrimeProvider = FutureProvider<PageLaboratoires>((ref) {
  final m = ref.watch(moisCategoriesProvider);
  final f = ref.watch(filtreLaboratoiresProvider);
  return ref
      .watch(categoriesApiProvider)
      .laboratoires(m.annee, m.mois, recherche: f.recherche, limite: f.tous ? 500 : 6);
}, retry: (_, _) => null);

final produitsCategorieProvider = FutureProvider<List<ProduitCategorie>>((ref) {
  final m = ref.watch(moisCategoriesProvider);
  return ref.watch(categoriesApiProvider).produits(m.annee, m.mois);
}, retry: (_, _) => null);

/// Gestes de l'écran : chacun relit ce qu'il change.
class GestesCategories {
  GestesCategories(this.ref);
  final Ref ref;

  CategoriesApi get _api => ref.read(categoriesApiProvider);

  Future<void> marquerLaboratoire(int id, bool generique) async {
    await _api.marquerLaboratoire(id, generique);
    ref.invalidate(laboratoiresPrimeProvider);
  }

  Future<void> choisir(int idNom, String? categorie) async {
    await _api.choisir(idNom, categorie);
    ref.invalidate(produitsCategorieProvider);
    ref.invalidate(primeCategoriesProvider);
  }

  Future<ResultatClassement> classer(double seuil, {bool tout = false}) async {
    final r = await _api.classer(seuil, tout: tout);
    ref.invalidate(produitsCategorieProvider);
    ref.invalidate(primeCategoriesProvider);
    return r;
  }
}

final gestesCategoriesProvider = Provider<GestesCategories>(GestesCategories.new);
