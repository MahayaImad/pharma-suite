import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/paie_api.dart';
import '../../../domain/paie.dart';

/// Mois affiché : le mois en cours par défaut.
class MoisPaie extends Notifier<({int annee, int mois})> {
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

final moisPaieProvider = NotifierProvider<MoisPaie, ({int annee, int mois})>(MoisPaie.new);

/// La paie du mois affiché, et les gestes qui la changent (relue sans repasser
/// par l'état de chargement).
class PaieController extends AsyncNotifier<PaieMois> {
  PaieApi get _api => ref.read(paieApiProvider);

  @override
  Future<PaieMois> build() {
    final m = ref.watch(moisPaieProvider);
    return ref.watch(paieApiProvider).mois(m.annee, m.mois);
  }

  Future<void> _relire() async {
    final m = ref.read(moisPaieProvider);
    state = AsyncData(await _api.mois(m.annee, m.mois));
  }

  Future<void> heuresSup(int idEmploye, double heures) async {
    final m = ref.read(moisPaieProvider);
    await _api.heuresSup(m.annee, m.mois, idEmploye, heures);
    await _relire();
  }

  Future<void> recalculerPrimes() async {
    final m = ref.read(moisPaieProvider);
    await _api.recalculerPrimes(m.annee, m.mois);
    await _relire();
  }

  Future<int> importerEmployes() async {
    final n = await _api.importerEmployes();
    await _relire();
    return n;
  }

  Future<void> modifierEmploye(int id, Map<String, Object?> champs) async {
    await _api.modifierEmploye(id, champs);
    await _relire();
  }

  Future<void> valider() async {
    final m = ref.read(moisPaieProvider);
    await _api.valider(m.annee, m.mois);
    await _relire();
  }
}

final paieProvider = AsyncNotifierProvider<PaieController, PaieMois>(PaieController.new, retry: (_, _) => null);

/// Les postes de travail (choix de la fiche employé).
final postesTravailProvider = FutureProvider<List<PosteTravail>>(
  (ref) => ref.watch(paieApiProvider).postes(),
  retry: (_, _) => null,
);
