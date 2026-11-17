import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/data/api/inventaire_api.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:pharmasuite/domain/inventaire.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_stock_api.dart';

const _pc = Size(1440, 900);
const _portable = Size(390, 844);
final _jour = DateTime(2026, 11, 17);

/// Simule le serveur : liste du jour, comptages, écarts à corriger.
class FausseInventaireApi implements InventaireApi {
  FausseInventaireApi({this.panne = false});
  bool panne;
  final appels = <String>[];
  var _id = 0;
  final _theorique = {1: 12, 2: 0, 3: 34};
  final _liste = const [
    ProduitACompter(idNom: 1, nom: 'DOLIPRANE 1 G B/8', classe: 'A', raison: 'jamais compté', stockTheorique: 12),
    ProduitACompter(
      idNom: 2,
      nom: 'XARIA 20 MG B/28',
      classe: 'B',
      raison: 'à 0 mais vendu récemment : vérifier le rayon',
    ),
    ProduitACompter(
      idNom: 3,
      nom: 'AMLOR 5 MG B/30',
      classe: 'A',
      raison: 'dernier comptage il y a 34 jours',
      stockTheorique: 34,
    ),
  ];
  final comptes = <Comptage>[];

  @override
  Future<JourneeInventaire> journee() async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    final faits = comptes.map((c) => c.idNom).toSet();
    final aCorriger = [
      for (final c in comptes)
        if (c.ecart != 0 && !c.corrige) c,
    ];
    final dansListe = comptes.where((c) => c.dansLaListe).toList();
    return JourneeInventaire(
      jour: _jour,
      aCompter: [
        for (final a in _liste)
          if (!faits.contains(a.idNom)) a,
      ],
      comptes: comptes.reversed.toList(),
      progression: Progression(
        total: _liste.length,
        comptes: dansListe.length,
        ecarts: comptes.where((c) => c.ecart != 0).length,
      ),
      exactitude: Exactitude(
        comptesMois: comptes.length,
        exactitudePct: comptes.isEmpty
            ? null
            : (100 * comptes.where((c) => c.ecart == 0).length / comptes.length).round(),
        aCorriger: aCorriger.length,
      ),
      aCorriger: aCorriger,
    );
  }

  @override
  Future<Comptage> compter(int idNom, int stockCompte, {CauseEcart? cause}) async {
    appels.add('compter $idNom $stockCompte ${cause?.api}');
    comptes.removeWhere((c) => c.idNom == idNom);
    final t = _theorique[idNom] ?? 5;
    final c = Comptage(
      id: ++_id,
      idNom: idNom,
      nom: idNom == 9 ? 'SPASFON B/30' : _liste.firstWhere((a) => a.idNom == idNom).nom,
      stockTheorique: t,
      stockCompte: stockCompte,
      ecart: stockCompte - t,
      valeurEcart: (stockCompte - t) * 120.0,
      cause: cause,
      comptePar: 'karim',
      jour: _jour,
      dansLaListe: _theorique.containsKey(idNom),
    );
    comptes.add(c);
    return c;
  }

  @override
  Future<void> annuler(int idComptage) async {
    appels.add('annuler $idComptage');
    comptes.removeWhere((c) => c.id == idComptage);
  }

  @override
  Future<void> corriger(int idComptage, bool corrige) async {
    appels.add('corriger $idComptage $corrige');
    final i = comptes.indexWhere((c) => c.id == idComptage);
    comptes[i] = comptes[i].copyWith(corrige: corrige);
  }
}

Future<void> _lancer(WidgetTester tester, InventaireApi api, {Size taille = _portable}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesLocalesProvider.overrideWithValue(prefs),
        inventaireApiProvider.overrideWithValue(api),
        stockApiProvider.overrideWithValue(FausseStockApi()),
        routeurProvider.overrideWithValue(construireRouteur(depart: '/inventaire')),
      ],
      child: const PharmaSuite(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  test('libellé de l\'écart', () {
    Comptage c(int e) => Comptage(id: 1, idNom: 1, ecart: e, jour: _jour);
    expect([c(0).libelleEcart, c(-3).libelleEcart, c(2).libelleEcart], ['Juste', 'Écart −3', 'Écart +2']);
  });

  testWidgets('portable : compter juste, compter avec écart et cause, annuler', (tester) async {
    final api = FausseInventaireApi();
    await _lancer(tester, api);
    expect(tester.takeException(), isNull);
    expect(find.text('À COMPTER · 3'), findsOneWidget);
    expect(find.textContaining('Doliprane 1 g B/8', findRichText: true), findsOneWidget);
    expect(find.textContaining('vérifier le rayon'), findsOneWidget);

    // Juste : pas de question.
    await _toucher(tester, find.byKey(const ValueKey('valider-1')));
    expect(api.appels.last, 'compter 1 12 null');
    expect(find.text('Juste'), findsOneWidget);
    expect(find.textContaining('1 / 3'), findsOneWidget);

    // Amlor : 34 → 31 avec « − » ×3, cause « Casse ».
    for (var i = 0; i < 3; i++) {
      await _toucher(tester, find.byKey(const ValueKey('moins-3')));
    }
    await _toucher(tester, find.byKey(const ValueKey('valider-3')));
    expect(find.textContaining('écart −3'), findsOneWidget);
    await _toucher(tester, find.byKey(const ValueKey('cause-casse')));
    expect(api.appels.last, 'compter 3 31 casse');
    expect(find.text('Écart −3'), findsOneWidget);

    // Xaria : taper la quantité au clavier.
    await _toucher(tester, find.byKey(const ValueKey('quantite-2')));
    await tester.enterText(find.byKey(const ValueKey('saisie-quantite')), '4');
    await _toucher(tester, find.byKey(const ValueKey('saisie-ok')));
    await _toucher(tester, find.byKey(const ValueKey('valider-2')));
    await _toucher(tester, find.byKey(const ValueKey('cause-aucune')));
    expect(api.appels.last, 'compter 2 4 null');
    expect(find.text('Liste du jour terminée'), findsOneWidget);

    // Annuler Doliprane : il revient dans la liste.
    await _toucher(tester, find.byKey(const ValueKey('annuler-1')));
    expect(api.appels.last, 'annuler 1');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('a-compter-1')), findsOneWidget);

    // En bas : exactitude et écarts à corriger.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('exactitude')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('À corriger dans EASYPHARM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PC : écarts à droite, marquer corrigé ; compter un produit hors liste', (tester) async {
    final api = FausseInventaireApi();
    await _lancer(tester, api, taille: _pc);
    await _toucher(tester, find.byKey(const ValueKey('plus-1')));
    await _toucher(tester, find.byKey(const ValueKey('valider-1')));
    await _toucher(tester, find.byKey(const ValueKey('cause-saisie')));
    expect(find.byKey(const ValueKey('a-corriger-1')), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    await _toucher(tester, find.byKey(const ValueKey('corrige-1')));
    expect(api.appels.last, 'corriger 1 true');
    expect(find.byKey(const ValueKey('a-corriger-1')), findsNothing);

    await _toucher(tester, find.byKey(const ValueKey('compter-autre')));
    expect(find.text('Compter un produit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    await _lancer(tester, FausseInventaireApi(panne: true));
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
