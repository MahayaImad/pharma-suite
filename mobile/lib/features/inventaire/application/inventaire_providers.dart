import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/inventaire_api.dart';
import '../../../domain/inventaire.dart';

/// La journée d'inventaire, et les gestes qui la changent. Après chaque geste
/// la journée est relue sans repasser par l'état de chargement.
class InventaireController extends AsyncNotifier<JourneeInventaire> {
  InventaireApi get _api => ref.read(inventaireApiProvider);

  @override
  Future<JourneeInventaire> build() => ref.watch(inventaireApiProvider).journee();

  Future<void> _relire() async => state = AsyncData(await _api.journee());

  Future<Comptage> compter(int idNom, int stockCompte, {CauseEcart? cause}) async {
    final c = await _api.compter(idNom, stockCompte, cause: cause);
    await _relire();
    return c;
  }

  Future<void> annuler(int idComptage) async {
    await _api.annuler(idComptage);
    await _relire();
  }

  Future<void> corriger(int idComptage, bool corrige) async {
    await _api.corriger(idComptage, corrige);
    await _relire();
  }
}

final inventaireProvider = AsyncNotifierProvider<InventaireController, JourneeInventaire>(
  InventaireController.new,
  retry: (_, _) => null,
);
