import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/commandes_api.dart';
import 'package:pharmasuite/domain/commandes.dart';
import 'package:pharmasuite/domain/format.dart';
import 'package:pharmasuite/features/commandes/presentation/panier.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_commandes_api.dart';

const _pc = Size(1440, 900);
final liensOuverts = <Uri>[];
const _portable = Size(390, 844);

Future<void> _lancer(
  WidgetTester tester,
  FausseCommandesApi api, {
  Size taille = _portable,
  String depart = '/commandes',
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
        commandesApiProvider.overrideWithValue(api),
        ouvreurLienProvider.overrideWithValue((lien) async {
          liensOuverts.add(lien);
          return true;
        }),
        routeurProvider.overrideWithValue(construireRouteur(depart: depart)),
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
  group('règles', () {
    test('explication de la quantité proposée', () {
      const l = LigneCommande(
        idNom: 1,
        qte: 8,
        qteProposee: 8,
        stock: 0,
        raison: Raison(type: 'regulier', rythme: 3.1, joursCouverts: 2, securite: 2, stock: 0),
      );
      expect(l.explication, '3,1/j × 2 j + sécurité 2 − stock 0');
      expect(l.copyWith(raison: const Raison(type: 'lent')).explication, 'Vente lente : garder 1 boîte en rayon');
      expect(const LigneCommande(idNom: 2, qte: 1).explication, 'Ajouté à la main');
      expect(l.avecQuantite(3).modifiee, isTrue);
    });

    test('numéro WhatsApp et lien du bon', () {
      expect(numeroWhatsapp('0550 12 34 56'), '213550123456');
      expect(numeroWhatsapp('+213 550 12 34 56'), '213550123456');
      expect(numeroWhatsapp(null), isNull);
      final lien = const BonCommande(idCommande: 1, whatsapp: '0550123456', texte: 'A — 2').lienWhatsapp;
      expect(lien.toString(), 'https://wa.me/213550123456?text=A+%E2%80%94+2');
    });

    test('totaux du panier recalculés après une modification', () {
      final j = JourneeCommandes(
        jour: DateTime(2026, 11, 14),
        paniers: [
          Panier(
            fournisseur: const FournisseurPanier(id: 1),
            lignes: const [
              LigneCommande(idNom: 1, qte: 2, prixAchat: 10, montant: 20, stock: 0),
              LigneCommande(idNom: 2, qte: 1, prixAchat: 5, montant: 5, stock: 3),
            ],
          ),
        ],
      );
      final p = j.avecLigne(1, 1, 5).panier(1)!;
      expect((p.boites, p.montant, p.ruptures), (6, 55.0, 1));
      expect(j.avecLigne(1, 2, 0).panier(1)!.nbLignes, 1);
    });

    test('budget : reste après la proposition du soir', () {
      const b = Budget(budget: 3000000, recu: 1800000, engage: 120000, propose: 400000);
      expect(b.resteApres, 680000);
      expect(const Budget().fixe, isFalse);
    });
  });

  testWidgets('portable : budget, cartes par type, avertissement psychotropes', (tester) async {
    await _lancer(tester, FausseCommandesApi());
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('bande-budget')), findsOneWidget);
    expect(find.textContaining('Commande du samedi 14/11'), findsOneWidget);
    expect(find.text('PHARMACEUTIQUE'), findsOneWidget);
    expect(find.byKey(const ValueKey('carte-fournisseur-1')), findsOneWidget);
    expect(find.text(dinars(2640)), findsOneWidget);
    expect(find.text('1 rupture'), findsOneWidget);
    expect(find.text('Proposé'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.byKey(const ValueKey('avertissement-psychotropes')), 200);
    await tester.tap(find.byKey(const ValueKey('avertissement-psychotropes')));
    await tester.pumpAndSettle();
    expect(find.text('Rivotril 2mg'), findsOneWidget);
  });

  testWidgets('préparer, corriger, valider puis envoyer depuis le panier', (tester) async {
    final api = FausseCommandesApi();
    await _lancer(tester, api);
    await _toucher(tester, find.byKey(const ValueKey('carte-fournisseur-1')));
    expect(find.text('3,1/j × 2 j + sécurité 2 − stock 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('total-panier')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('total-panier'))).data, dinars(2640));

    await _toucher(tester, find.byKey(const ValueKey('action-preparer')));
    expect(api.appels, contains('preparer'));
    expect(find.text('Brouillon'), findsOneWidget);

    await _toucher(tester, find.byKey(const ValueKey('pas-11-plus')));
    expect(api.appels.last, 'ligne 100 11 9');
    expect(tester.widget<Text>(find.byKey(const ValueKey('total-panier'))).data, dinars(2736));
    expect(find.textContaining('modifié (proposé 8)'), findsOneWidget);

    await _toucher(tester, find.byKey(const ValueKey('action-valider')));
    expect(api.appels, contains('valider 100'));
    expect(find.byKey(const ValueKey('pas-11-plus')), findsNothing); // figée
    expect(find.byKey(const ValueKey('action-envoyer')), findsOneWidget);

    await _toucher(tester, find.byKey(const ValueKey('action-envoyer')));
    expect(api.appels, contains('envoyer 100'));
    expect(liensOuverts.last.host, 'wa.me');
    expect(liensOuverts.last.path, '/213550123456');
    expect(find.byKey(const ValueKey('texte-bon')), findsOneWidget);
    expect(find.textContaining('PARACETAMOL 1G CPR B/8 — 9'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('action-revoir')), findsOneWidget);
  });

  testWidgets('employé non désigné : pas de bouton « Valider »', (tester) async {
    final api = FausseCommandesApi(peutValider: false);
    await api.preparer();
    await _lancer(tester, api, depart: '/commandes/1');
    expect(find.byKey(const ValueKey('action-valider')), findsNothing);
    expect(find.byKey(const ValueKey('action-attente')), findsOneWidget);
    expect(find.byKey(const ValueKey('pas-11-plus')), findsOneWidget); // il peut corriger
  });

  testWidgets('PC : le panier s\'ouvre à côté des cartes', (tester) async {
    await _lancer(tester, FausseCommandesApi(), taille: _pc);
    expect(tester.takeException(), isNull);
    expect(find.text('Choisissez un fournisseur pour voir son panier.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('carte-fournisseur-2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('carte-fournisseur-1')), findsOneWidget); // les cartes restent
    expect(find.text('Creme Solaire SPF50'), findsOneWidget);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    final api = FausseCommandesApi(panne: true);
    await _lancer(tester, api);
    expect(find.text('Hors connexion'), findsOneWidget);
    api.panne = false;
    await tester.tap(find.byKey(const ValueKey('bouton-reessayer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('carte-fournisseur-1')), findsOneWidget);
  });
}
