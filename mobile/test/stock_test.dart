import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:pharmasuite/domain/session.dart';
import 'package:pharmasuite/domain/stock.dart';
import 'package:pharmasuite/features/connexion/application/session_controller.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_stock_api.dart';

const _pc = Size(1440, 900);
const _portable = Size(390, 844);

Future<void> _lancer(
  WidgetTester tester,
  FausseStockApi api, {
  Size taille = _portable,
  String depart = '/stock',
  String? role,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesLocalesProvider.overrideWithValue(prefs),
        stockApiProvider.overrideWithValue(api),
        routeurProvider.overrideWithValue(construireRouteur(depart: depart)),
        if (role != null)
          sessionProvider.overrideWithBuild(
            (ref, _) => Session(
              jeton: 'j',
              profil: Profil(utilisateur: 'u', role: role),
            ),
          ),
      ],
      child: const PharmaSuite(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _produit(int id) => find.byKey(ValueKey('produit-$id'));

Future<void> _voir(WidgetTester tester, Finder f) async {
  // Plusieurs occurrences (titre de groupe et pastille) : la première suffit.
  final cible = f.evaluate().length > 1 ? f.first : f;
  await tester.scrollUntilVisible(cible, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('accueil : tuiles, groupes à traiter, puis tout le stock avec la jauge', (tester) async {
    await _lancer(tester, FausseStockApi());
    expect(tester.takeException(), isNull);
    expect(find.textContaining("Données aujourd'hui à"), findsOneWidget);
    expect(find.text('ruptures à commander'), findsOneWidget);
    expect(find.text('À commander'), findsOneWidget);
    expect(find.byKey(const ValueKey('action-3')), findsOneWidget); // rupture d'abord
    expect(find.text('Rupture · 3 vendus par mois'), findsOneWidget);
    await _voir(tester, find.text('Péremption à risque'));
    expect(find.text('5 unités périmeront avant d\'être vendues · 650 DA'), findsOneWidget);
    await _voir(tester, _produit(1));
    expect(find.text('Tout le stock'), findsOneWidget);
    expect(find.text('Doliprane 1000 mg'), findsWidgets); // nom lisible
    expect(find.text('max 19'), findsOneWidget); // jauge
  });

  testWidgets('une tuile filtre la liste, la croix retire le filtre', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await tester.tap(find.byKey(const ValueKey('tuile-rupture')));
    await tester.pumpAndSettle();
    expect(api.demandes.last.etat, FiltreEtat.rupture);
    expect(find.text('À commander'), findsNothing); // plus de groupes
    expect(tester.widget<Text>(find.byKey(const ValueKey('titre-liste'))).data, 'Ruptures');
    expect(_produit(3), findsOneWidget);
    expect(_produit(1), findsNothing);
    await tester.tap(find.byTooltip('Retirer le filtre'));
    await tester.pumpAndSettle();
    expect(api.demandes.last.etat, isNull);
  });

  testWidgets('« Tout voir » ouvre le groupe entier ; « Commander » prévient', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await tester.tap(find.text('Commander').first);
    await tester.pump();
    expect(find.text('Le module Commandes arrive bientôt.'), findsOneWidget);
    await tester.tap(find.text('Tout voir').first);
    await tester.pumpAndSettle();
    expect(api.demandes.last.etat, FiltreEtat.aCommander);
    expect(_produit(2), findsOneWidget);
    expect(_produit(3), findsOneWidget);
  });

  testWidgets('famille : filtre la liste par id_famille', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await _voir(tester, find.byKey(const ValueKey('familles')));
    await tester.drag(find.byKey(const ValueKey('familles')), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bebe et maman'));
    await tester.pumpAndSettle();
    expect(api.demandes.last.idFamille, 15);
  });

  testWidgets('recherche : part après la frappe, état vide puis effacer', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await tester.enterText(find.byKey(const ValueKey('champ-recherche')), 'zzz');
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.demandes.last.recherche, ''); // pas encore envoyée
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(api.demandes.last.recherche, 'zzz');
    expect(find.text('Résultats'), findsOneWidget);
    await _voir(tester, find.text('Effacer les filtres'));
    expect(find.text('Rien ne correspond à « zzz ».'), findsOneWidget);
    await tester.tap(find.text('Effacer les filtres'));
    await tester.pumpAndSettle();
    expect(find.text('À commander'), findsOneWidget);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    final api = FausseStockApi(panne: true);
    await _lancer(tester, api);
    expect(find.text('Hors connexion'), findsWidgets);
    api.panne = false;
    await tester.tap(find.byKey(const ValueKey('bouton-reessayer')).first);
    await tester.pumpAndSettle();
    expect(find.text('À commander'), findsOneWidget);
  });

  testWidgets('portable : fiche en plein écran, conseil, projection, lots, retour', (tester) async {
    await _lancer(tester, FausseStockApi());
    await tester.tap(find.byKey(const ValueKey('action-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await _voir(tester, _produit(1));
    await tester.tap(_produit(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('champ-recherche')), findsNothing);
    expect(find.text('Médicaments · Sanofi'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('bande-Couverture'))).data, '28 jours');
    expect(find.byKey(const ValueKey('jauge-fiche')), findsOneWidget);
    expect(find.text('5 unités à risque · 650 DA'), findsOneWidget);
    expect(find.textContaining('retour au fournisseur'), findsOneWidget);
    await _voir(tester, find.byKey(const ValueKey('projection')));
    await _voir(tester, find.text('Lot C7781'));
    expect(find.text('Périmé'), findsOneWidget); // 01/26
    expect(find.text('5 à risque · 0 écoulables en 0 j'), findsOneWidget);
    await _voir(tester, find.byKey(const ValueKey('cmj')));
    expect(find.text('1,7 / jour'), findsOneWidget);
    expect(find.textContaining('commande du jour livrée dimanche 15/11'), findsOneWidget);
    await _voir(tester, find.byKey(const ValueKey('prix-2')));
    expect(find.text('55 DA  ·  42,3 %'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    // Retour à la liste, à l'endroit où on l'avait laissée.
    expect(find.byTooltip('Retour'), findsNothing);
    expect(_produit(1), findsOneWidget);
  });

  testWidgets('lots épuisés : affichés à la demande', (tester) async {
    await _lancer(tester, FausseStockApi(), depart: '/stock/1');
    await _voir(tester, find.byKey(const ValueKey('lots-epuises')));
    expect(find.text('Lot Z0001'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('lots-epuises')));
    await tester.pumpAndSettle();
    await _voir(tester, find.text('Lot Z0001'));
    expect(find.text('épuisé'), findsOneWidget);
  });

  testWidgets('PC : la fiche s\'ouvre à côté de la liste', (tester) async {
    await _lancer(tester, FausseStockApi(), taille: _pc);
    expect(tester.takeException(), isNull);
    expect(find.text('Choisissez un produit pour voir sa fiche et ses lots.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('action-2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('champ-recherche')), findsOneWidget); // la liste reste
    expect(find.text('Fiche produit'), findsOneWidget);
    expect(find.byKey(const ValueKey('conseil')), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Fiche produit'), findsNothing);
  });

  testWidgets('consommable proposé : le titulaire confirme depuis la fiche', (tester) async {
    final api = FausseStockApi(
      produits: [
        ...FausseStockApi.exemples,
        const Produit(id: 9, nom: 'AIGUILLES INSUPEN', stock: 40, actif: true, consommablePropose: true),
      ],
    );
    await _lancer(tester, api, depart: '/stock/9', role: 'admin');
    expect(find.byKey(const ValueKey('proposition-consommable')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('consommable-oui')));
    await tester.pumpAndSettle();
    expect(api.decisionsConsommable.single, (9, true));
    expect(find.byKey(const ValueKey('proposition-consommable')), findsNothing);
    expect(find.text('Consommable'), findsWidgets); // étiquette et case
  });

  testWidgets('employé : la case consommable est grisée, pas de boutons de décision', (tester) async {
    final api = FausseStockApi(
      produits: [const Produit(id: 9, nom: 'AIGUILLES', stock: 40, actif: true, consommablePropose: true)],
    );
    await _lancer(tester, api, depart: '/stock/9', role: 'employee');
    expect(find.byKey(const ValueKey('consommable-oui')), findsNothing);
    await _voir(tester, find.byKey(const ValueKey('case-consommable')));
    final caseConso = tester.widget<SwitchListTile>(find.byKey(const ValueKey('case-consommable')));
    expect(caseConso.onChanged, isNull);
  });

  testWidgets('laboratoire : filtre la liste, la puce le retire', (tester) async {
    final api = FausseStockApi();
    await _lancer(tester, api);
    await _voir(tester, find.byKey(const ValueKey('bouton-labo')));
    await tester.tap(find.byKey(const ValueKey('bouton-labo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('labo-SANOFI')));
    await tester.pumpAndSettle();
    expect(api.demandes.last.labo, 'SANOFI');
    expect(find.text('À commander'), findsNothing); // plus les groupes
    await _voir(tester, find.byKey(const ValueKey('puce-labo')));
    expect(find.text('Sanofi'), findsWidgets);
    await tester.tap(find.byTooltip('Tous les laboratoires'));
    await tester.pumpAndSettle();
    expect(api.demandes.last.labo, isNull);
  });
}
