import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/commandes_api.dart';
import 'package:pharmasuite/domain/commandes.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_commandes_api.dart';

const _pc = Size(1440, 900);
const _portable = Size(390, 844);

const _atlas = FournisseurPanier(id: 1, nom: 'GROSSISTE ATLAS');

/// Commande du 14 livrée en partie, commande du 10 où XARIA manquait déjà,
/// commande du 15 attendue.
SuiviLivraisons _suivi() => SuiviLivraisons(
  jour: DateTime(2026, 11, 16),
  commandes: [
    CommandeSuivie(
      id: 3,
      jour: DateTime(2026, 11, 15),
      fournisseur: _atlas,
      livraisonPrevue: DateTime(2026, 11, 17),
      lignes: const [LigneSuivie(idNom: 9, nom: 'AMLOR 5 MG', qte: 30, reste: 30)],
    ),
    CommandeSuivie(
      id: 2,
      jour: DateTime(2026, 11, 14),
      fournisseur: _atlas,
      livraisonPrevue: DateTime(2026, 11, 15),
      etat: EtatLivraison.partielle,
      lignes: [
        const LigneSuivie(
          idNom: 7,
          nom: 'XARIA 20 MG',
          qte: 10,
          reste: 10,
          etat: EtatLivraison.manquante,
          tension: 'proposee',
        ),
        LigneSuivie(
          idNom: 8,
          nom: 'NOVOFORMINE 1000',
          qte: 60,
          recu: 20,
          reste: 40,
          stock: 20,
          etat: EtatLivraison.partielle,
          recuLe: DateTime(2026, 11, 15),
        ),
        const LigneSuivie(idNom: 6, nom: 'DOLIPRANE 1 G', qte: 100, recu: 100, etat: EtatLivraison.livree),
      ],
    ),
    CommandeSuivie(
      id: 1,
      jour: DateTime(2026, 11, 10),
      fournisseur: _atlas,
      livraisonPrevue: DateTime(2026, 11, 11),
      etat: EtatLivraison.manquante,
      lignes: const [LigneSuivie(idNom: 7, nom: 'XARIA 20 MG', qte: 10, reste: 10, etat: EtatLivraison.manquante)],
    ),
  ],
  fournisseurs: const [
    ServiceFournisseur(
      id: 1,
      nom: 'GROSSISTE ATLAS',
      commandes: 2,
      lignes: 4,
      qte: 180,
      recu: 120,
      tauxLignes: 25,
      tauxQuantite: 67,
    ),
  ],
);

Future<void> _lancer(WidgetTester tester, FausseCommandesApi api, {Size taille = _portable, String? depart}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesLocalesProvider.overrideWithValue(prefs),
        commandesApiProvider.overrideWithValue(api),
        routeurProvider.overrideWithValue(construireRouteur(depart: depart ?? '/commandes/livraisons')),
      ],
      child: const PharmaSuite(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('un produit non livré deux fois ne compte qu\'une fois ; taux de service global', () {
    final s = _suivi();
    expect(s.lignesDe(EtatLivraison.manquante).map((l) => l.commande.id), [2]);
    expect(s.aVerifier, 2);
    expect(s.tauxService, 67);
    expect(SuiviLivraisons(jour: DateTime(2026, 11, 16)).tauxService, isNull);
  });

  testWidgets('portable : tuiles, non livrés d\'abord, filtres, taux de service', (tester) async {
    await _lancer(tester, FausseCommandesApi()..livraisons = _suivi());
    expect(tester.takeException(), isNull);
    expect(find.text('Livraisons'), findsWidgets);
    expect(find.text('produits non livrés'), findsOneWidget);
    expect(find.byKey(const ValueKey('pastille-livraisons')), findsOneWidget);
    expect(find.byKey(const ValueKey('livraison-7-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('livraison-7-1')), findsNothing);
    expect(find.text('Tension ?'), findsOneWidget);
    expect(find.text('NOVOFORMINE 1000'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tuile-partielle')));
    await tester.pumpAndSettle();
    expect(find.text('Reste 40'), findsOneWidget);
    expect(find.textContaining('reçu le 15/11'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('filtre-attendue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filtre-attendue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('prévue mardi 17/11'), findsOneWidget);
    expect(find.byKey(const ValueKey('autre-9')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('taux-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<Text>(find.byKey(const ValueKey('taux-1'))).data, '67 %');
    expect(tester.takeException(), isNull);
  });

  testWidgets('PC : « Autre grossiste » ajoute le reste au brouillon d\'un autre grossiste actif', (tester) async {
    final api = FausseCommandesApi()..livraisons = _suivi();
    await _lancer(tester, api, taille: _pc);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('taux-service')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('autre-7')));
    await tester.pumpAndSettle();
    expect(find.text('Commander 10 boîtes chez…'), findsOneWidget);
    expect(find.byKey(const ValueKey('vers-1')), findsNothing); // le grossiste d'origine
    await tester.tap(find.byKey(const ValueKey('vers-2')));
    await tester.pumpAndSettle();
    expect(api.appels, contains('ajouter 7 10 2'));
    expect(find.textContaining('Ajouté à la commande de PARA BELLA : 10 boîtes'), findsOneWidget);
  });

  testWidgets('aucune commande envoyée, puis serveur injoignable', (tester) async {
    final api = FausseCommandesApi();
    await _lancer(tester, api);
    expect(find.text('Aucune commande envoyée'), findsOneWidget);
    expect(find.byKey(const ValueKey('pastille-livraisons')), findsNothing);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    await _lancer(tester, FausseCommandesApi(panne: true));
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('onglets : de « À commander » vers « Livraisons » et retour', (tester) async {
    await _lancer(tester, FausseCommandesApi()..livraisons = _suivi(), depart: '/commandes');
    await tester.tap(find.byKey(const ValueKey('onglet-/commandes/livraisons')));
    await tester.pumpAndSettle();
    expect(find.text('produits non livrés'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onglet-/commandes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sous-titre-commandes')), findsOneWidget);
  });
}
