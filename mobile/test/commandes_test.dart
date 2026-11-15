import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/commandes_api.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:pharmasuite/domain/stock.dart';
import 'package:pharmasuite/features/commandes/application/commandes_providers.dart';
import 'package:pharmasuite/domain/commandes.dart';
import 'package:pharmasuite/domain/format.dart';
import 'package:pharmasuite/domain/session.dart';
import 'package:pharmasuite/features/connexion/application/session_controller.dart';
import 'package:pharmasuite/features/commandes/presentation/panier.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_commandes_api.dart';
import 'fausse_stock_api.dart';

const _pc = Size(1440, 900);
final liensOuverts = <Uri>[];
const _portable = Size(390, 844);

Future<void> _lancer(
  WidgetTester tester,
  FausseCommandesApi api, {
  Size taille = _portable,
  String depart = '/commandes',
  String? role,
  StockApi? stock,
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
        if (stock != null) stockApiProvider.overrideWithValue(stock),
        ouvreurLienProvider.overrideWithValue((lien) async {
          liensOuverts.add(lien);
          return true;
        }),
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
      final reprise = l.copyWith(raison: l.raison!.copyWith(reprend: ['XYDOL 600']));
      expect(reprise.explication, '3,1/j × 2 j + sécurité 2 − stock 0 · reprend Xydol 600');
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
    expect(find.textContaining('samedi 14/11'), findsOneWidget);
    expect(find.text('PHARMACEUTIQUE'), findsOneWidget);
    expect(find.byKey(const ValueKey('carte-fournisseur-1')), findsOneWidget);
    expect(find.text(dinars(2640)), findsOneWidget);
    expect(find.textContaining('1 rupt.'), findsOneWidget);
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
    expect(find.textContaining('3,1/j × 2 j + sécurité 2 − stock 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('total-panier')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('total-panier'))).data, dinars(2640));

    // Proposé : le premier geste prépare les brouillons, puis enregistre la quantité.
    await _toucher(tester, find.byKey(const ValueKey('pas-11-plus')));
    expect(api.appels, containsAllInOrder(['preparer', 'ligne 100 11 9']));
    expect(find.text('Brouillon'), findsOneWidget);
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

  testWidgets('proposé : « Valider » prépare puis valide', (tester) async {
    final api = FausseCommandesApi();
    await _lancer(tester, api, depart: '/commandes/1');
    await _toucher(tester, find.byKey(const ValueKey('action-valider')));
    expect(api.appels, containsAllInOrder(['preparer', 'valider 100']));
    expect(find.byKey(const ValueKey('action-envoyer')), findsOneWidget);
  });

  testWidgets('portable : une ligne change de générique puis de grossiste', (tester) async {
    final api = FausseCommandesApi();
    await api.preparer();
    await _lancer(tester, api, depart: '/commandes/1');
    await _toucher(tester, find.byKey(const ValueKey('ligne-12')));
    expect(find.byKey(const ValueKey('action-ligne-generique')), findsNothing); // pas de code DCI
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    api.paniers = [
      for (final p in api.paniers)
        p.copyWith(lignes: [for (final l in p.lignes) l.idNom == 11 ? l.copyWith(codeDci: '04B044') : l]),
    ];
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await _toucher(tester, find.byKey(const ValueKey('carte-fournisseur-1')));
    // Le panier relu : la ligne 11 a maintenant un code DCI.
    final ctx = tester.element(find.byKey(const ValueKey('ligne-11')));
    ProviderScope.containerOf(ctx).invalidate(journeeProvider);
    await tester.pumpAndSettle();
    await _toucher(tester, find.byKey(const ValueKey('ligne-11')));
    await _toucher(tester, find.byKey(const ValueKey('action-ligne-generique')));
    await _toucher(tester, find.byKey(const ValueKey('remplacer-par-2')));
    expect(api.appels.last, 'remplacer 100 11 2');
    expect(find.textContaining('remplacé par'), findsOneWidget);

    await _toucher(tester, find.byKey(const ValueKey('ligne-12')));
    await _toucher(tester, find.byKey(const ValueKey('action-ligne-grossiste')));
    await _toucher(tester, find.byKey(const ValueKey('vers-2')));
    expect(api.appels.last, 'deplacer 12 1 2');
    expect(find.byKey(const ValueKey('ligne-12')), findsNothing);
  });

  testWidgets('PC : glisser une ligne sur un autre grossiste', (tester) async {
    final api = FausseCommandesApi();
    await _lancer(tester, api, taille: _pc, depart: '/commandes/1');
    final poignee = find.byKey(const ValueKey('poignee-12'));
    final cible = find.byKey(const ValueKey('carte-fournisseur-2'));
    final geste = await tester.startGesture(tester.getCenter(poignee));
    await tester.pump(const Duration(milliseconds: 50));
    await geste.moveTo(tester.getCenter(cible));
    await tester.pump();
    expect(find.text('Déposer ici'), findsOneWidget);
    await geste.up();
    await tester.pumpAndSettle();
    expect(api.appels.last, 'deplacer 12 1 2');
    expect(find.byKey(const ValueKey('ligne-12')), findsNothing);
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

  testWidgets('fournisseurs : actifs par défaut, inactifs à part, réglage et valideurs (titulaire)', (tester) async {
    final api = FausseCommandesApi();
    await _lancer(tester, api, depart: '/preferences/fournisseurs', role: 'admin');
    expect(tester.takeException(), isNull);
    expect(find.text('Actifs (2)'), findsWidgets); // filtre et titre de la liste
    expect(find.byKey(const ValueKey('titre-inactifs')), findsOneWidget); // les deux listes, l'une sous l'autre
    await tester.tap(find.byKey(const ValueKey('filtre-actifs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fournisseur-3')), findsNothing);
    expect(find.text('Réglage automatique'), findsOneWidget); // PARA BELLA
    await tester.tap(find.byKey(const ValueKey('filtre-inactifs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fournisseur-3')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('actif-3')));
    await tester.pumpAndSettle();
    expect(api.appels.last, 'regler 3 pharma true null');

    await tester.tap(find.byKey(const ValueKey('filtre-tous')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fournisseur-2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('numero-whatsapp')), '0661 22 33 44');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(api.appels.last, 'regler 2 para true 0661 22 33 44');

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ajouter-valideur')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('valideur-karim')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('ajouter-valideur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ajouter-valideur')), warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('compte-titulaire')), findsNothing); // déjà valideur de droit
    expect(find.byKey(const ValueKey('compte-karim')), findsNothing); // déjà désigné
    await tester.tap(find.byKey(const ValueKey('compte-sara')));
    await tester.pumpAndSettle();
    expect(api.listeValideurs, ['karim', 'sara']);
  });

  testWidgets('fournisseurs : un employé voit sans pouvoir modifier', (tester) async {
    await _lancer(tester, FausseCommandesApi(), depart: '/preferences/fournisseurs', role: 'employee');
    expect(tester.widget<Switch>(find.byKey(const ValueKey('actif-1'))).onChanged, isNull);
    expect(find.byKey(const ValueKey('ajouter-valideur')), findsNothing);
  });

  testWidgets('fiche produit : génériques de la même DCI, choix du titulaire', (tester) async {
    final api = FausseCommandesApi();
    final stock = FausseStockApi(
      produits: [const Produit(id: 1, nom: 'SAPOFEN 600', stock: 12, actif: true, codeDci: '04B044')],
    );
    await _lancer(tester, api, depart: '/stock/1', role: 'admin', stock: stock);
    final section = find.byKey(const ValueKey('section-generiques'));
    await tester.scrollUntilVisible(section, 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Seules les 2 marques les plus vendues'), findsOneWidget);
    expect(find.text('Non recommandé'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('choix-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choix-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ne plus commander'));
    await tester.pumpAndSettle();
    expect(api.appels.last, 'choix 2 exclure');
    expect(find.text('Non recommandé'), findsNWidgets(2));
  });
}
