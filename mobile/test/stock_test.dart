import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:pharmasuite/domain/stock.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_stock_api.dart';

const _pc = Size(1440, 900);
const _portable = Size(390, 844);

Future<void> _lancer(WidgetTester tester, FausseStockApi api,
    {Size taille = _portable, String depart = '/stock'}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      preferencesLocalesProvider.overrideWithValue(prefs),
      stockApiProvider.overrideWithValue(api),
      routeurProvider.overrideWithValue(construireRouteur(depart: depart)),
    ],
    child: const PharmaSuite(),
  ));
  await tester.pumpAndSettle();
}

Finder _produit(int id) => find.byKey(ValueKey('produit-$id'));

void main() {
  testWidgets('liste : valeur du stock, familles, produits et leur état', (tester) async {
    await _lancer(tester, FausseStockApi());
    expect(tester.takeException(), isNull);
    expect(find.text('15,9 M DA'), findsOneWidget);
    expect(find.textContaining("Données EASYPHARM aujourd'hui à"), findsOneWidget);
    // Familles : celles qui ont des produits actifs ; libellé en capitales adouci.
    expect(find.text('Médicaments'), findsOneWidget);
    expect(find.text('Bebe et maman'), findsOneWidget);
    expect(find.text('Cosmétiques'), findsNothing);
    expect(find.text('DOLIPRANE 1000 MG CPR'), findsOneWidget);
    expect(find.text('48 en stock'), findsOneWidget);
    expect(find.text('3 · sous le seuil'), findsOneWidget);
    expect(find.text('Rupture'), findsWidgets);
    expect(find.text('3 produits'), findsOneWidget);
  });

  testWidgets('famille : filtre la liste par id_famille', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await tester.drag(find.byKey(const ValueKey('familles')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bebe et maman'));
    await tester.pumpAndSettle();
    expect(api.demandes.last.idFamille, 15);
    expect(_produit(3), findsOneWidget);
    expect(_produit(1), findsNothing);
    expect(find.text('1 produit'), findsOneWidget);
  });

  testWidgets('état « Sous le seuil »', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await tester.ensureVisible(find.text('Sous le seuil'));
    await tester.tap(find.text('Sous le seuil'));
    await tester.pumpAndSettle();
    expect(api.demandes.last.etat, FiltreEtat.sousSeuil);
    expect(_produit(2), findsOneWidget);
    expect(_produit(1), findsNothing);
  });

  testWidgets('recherche : part après la frappe, état vide puis effacer', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await tester.enterText(find.byKey(const ValueKey('champ-recherche')), 'zzz');
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.demandes.last.recherche, ''); // pas encore envoyée
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(api.demandes.last.recherche, 'zzz');
    expect(find.text('Rien ne correspond à « zzz ».'), findsOneWidget);
    await tester.tap(find.text('Effacer les filtres'));
    await tester.pumpAndSettle();
    expect(_produit(1), findsOneWidget);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    final api = FausseStockApi(panne: true);
    await _lancer(tester, api);
    expect(find.text('Hors connexion'), findsOneWidget);
    api.panne = false;
    await tester.tap(find.byKey(const ValueKey('bouton-reessayer')));
    await tester.pumpAndSettle();
    expect(_produit(1), findsOneWidget);
  });

  testWidgets('portable : la fiche s\'ouvre en plein écran, le retour ramène à la liste', (tester) async {
    await _lancer(tester, FausseStockApi());
    await tester.tap(_produit(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('champ-recherche')), findsNothing);
    expect(find.text('MÉDICAMENTS'), findsOneWidget);
    expect(find.text('Paracétamol · SANOFI'), findsOneWidget);
    // Couverture : 48 ÷ (612 / 365) = 28,6 → 29 jours
    expect(find.text('29 jours'), findsOneWidget);
    // Marge : 185 − 130 = 55 DA, soit 42,3 % du prix d'achat
    expect(find.text('55 DA  ·  42,3 %'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lot C7781'), 200);
    expect(find.text('Périmé'), findsOneWidget); // 01/26
    expect(find.text('HYDRAPHARM · entré le 03/02/2025'), findsOneWidget);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('champ-recherche')), findsOneWidget);
  });

  testWidgets('lots épuisés : affichés à la demande', (tester) async {
    await _lancer(tester, FausseStockApi(), depart: '/stock/1');
    await tester.scrollUntilVisible(find.byKey(const ValueKey('lots-epuises')), 200);
    expect(find.text('Lot Z0001'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('lots-epuises')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Lot Z0001'), 200);
    expect(find.text('épuisé'), findsOneWidget);
  });

  testWidgets('PC : la fiche s\'ouvre à côté de la liste', (tester) async {
    await _lancer(tester, FausseStockApi(), taille: _pc);
    expect(find.text('Choisissez un produit pour voir sa fiche et ses lots.'), findsOneWidget);
    await tester.tap(_produit(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('champ-recherche')), findsOneWidget); // la liste reste
    expect(find.text('Fiche produit'), findsOneWidget);
    expect(find.text('AUGMENTIN 1 G SACH'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Fiche produit'), findsNothing);
  });
}
