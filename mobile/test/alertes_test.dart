import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/alertes_api.dart';
import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/data/api/commandes_api.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:pharmasuite/domain/alertes.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_commandes_api.dart';
import 'fausse_stock_api.dart';

const _pc = Size(1440, 900);
const _portable = Size(390, 844);

class FausseAlertesApi implements AlertesApi {
  FausseAlertesApi(this.liste, {this.panne = false});
  ListeAlertes liste;
  bool panne;
  int lectures = 0;

  @override
  Future<ListeAlertes> alertes() async {
    lectures++;
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    return liste;
  }
}

ListeAlertes _liste({bool admin = true}) => ListeAlertes(
  jour: DateTime(2026, 11, 17),
  peutDecider: admin,
  alertes: [
    const Alerte(
      id: 'rupture-12',
      niveau: NiveauAlerte.aujourdhui,
      icone: 'rupture',
      sujet: 'DOLIPRANE 1 G B/8',
      titre: 'en rupture',
      detail: '9 ventes par jour · non livré par BIOPHARM le 15/11',
      idNom: 12,
      action: ActionAlerte(sorte: SorteAction.commander, libelle: 'Commander'),
    ),
    const Alerte(
      id: 'livraison-4',
      type: TypeAlerte.livraison,
      niveau: NiveauAlerte.aujourdhui,
      icone: 'livraison',
      sujet: 'BIOPHARM',
      titre: 'rien reçu de la commande du 14/11',
      detail: '9 lignes · 96 400 DA non reçus · prévue le 15/11',
      action: ActionAlerte(
        sorte: SorteAction.ouvrir,
        libelle: 'Voir la livraison',
        route: '/commandes/livraisons/commandes/4',
      ),
    ),
    Alerte(
      id: 'tension-7',
      type: TypeAlerte.confirmer,
      niveau: NiveauAlerte.semaine,
      icone: 'tension',
      sujet: 'XARIA 20 MG B/28',
      titre: 'en tension ?',
      detail: 'Commandé 3 fois en 45 jours, jamais livré',
      idNom: 7,
      action: admin
          ? const ActionAlerte(sorte: SorteAction.tension, libelle: 'Confirmer')
          : const ActionAlerte(sorte: SorteAction.ouvrir, libelle: 'Voir', route: '/stock/7'),
    ),
    const Alerte(
      id: 'surstock',
      icone: 'surstock',
      titre: '31 produits en surstock',
      detail: '212 000 DA immobilisés au-dessus du maximum',
      action: ActionAlerte(sorte: SorteAction.ouvrir, libelle: 'Voir', route: '/stock'),
    ),
  ],
  bref: const BrefAlertes(
    ruptures: 4,
    rupturesImminentes: 2,
    valeurARisque: 47820,
    commandesNonLivrees: 2,
    budgetPct: 64,
  ),
);

Future<FausseCommandesApi> _lancer(WidgetTester tester, AlertesApi api, {Size taille = _portable}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final commandes = FausseCommandesApi();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesLocalesProvider.overrideWithValue(prefs),
        alertesApiProvider.overrideWithValue(api),
        commandesApiProvider.overrideWithValue(commandes),
        stockApiProvider.overrideWithValue(FausseStockApi()),
        routeurProvider.overrideWithValue(construireRouteur(depart: '/alertes')),
      ],
      child: const PharmaSuite(),
    ),
  );
  await tester.pumpAndSettle();
  return commandes;
}

void main() {
  test('alertes par niveau et par famille', () {
    final l = _liste();
    expect(l.de(NiveauAlerte.aujourdhui).map((a) => a.id), ['rupture-12', 'livraison-4']);
    expect(l.de(NiveauAlerte.aujourdhui, TypeAlerte.livraison).single.id, 'livraison-4');
    expect((l.nombre(), l.nombre(TypeAlerte.stock), l.nombre(TypeAlerte.peremption)), (4, 2, 0));
    expect(l.alertes.first.titreComplet, 'Doliprane 1 g B/8 · en rupture');
    expect(l.alertes.last.titreComplet, '31 produits en surstock');
  });

  testWidgets('portable : groupes par urgence, filtres, chiffres clés en bas', (tester) async {
    await _lancer(tester, FausseAlertesApi(_liste()));
    expect(tester.takeException(), isNull);
    expect(find.text("AUJOURD'HUI · 2"), findsOneWidget);
    expect(find.text('CETTE SEMAINE · 1'), findsOneWidget);
    expect(find.text('Doliprane 1 g B/8 · en rupture'), findsOneWidget);
    expect(find.textContaining('4 à traiter'), findsOneWidget);
    expect(find.byKey(const ValueKey('filtre-peremption')), findsNothing); // aucune alerte de ce type

    await tester.tap(find.byKey(const ValueKey('filtre-livraison')));
    await tester.pumpAndSettle();
    expect(find.text("AUJOURD'HUI · 1"), findsOneWidget);
    expect(find.byKey(const ValueKey('alerte-rupture-12')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('filtre-toutes')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('en-bref')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rupture sous 2 jours'), findsOneWidget);
    expect(find.text('64 %'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PC : commander, confirmer une tension, ouvrir la livraison', (tester) async {
    final api = FausseAlertesApi(_liste());
    final commandes = await _lancer(tester, api, taille: _pc);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('en-bref')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('action-rupture-12')));
    await tester.pumpAndSettle();
    expect(commandes.appels, contains('ajouter 12'));
    expect(api.lectures, 2); // la liste est relue après l'action

    await tester.tap(find.byKey(const ValueKey('action-tension-7')));
    await tester.pumpAndSettle();
    expect(commandes.appels.any((a) => a.contains('tension 7 true')), isTrue);
    expect(find.textContaining('Xaria 20 mg B/28 : tension confirmée'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('action-livraison-4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('alerte-livraison-4')), findsNothing); // on a quitté les alertes
    expect(find.text('Livraisons'), findsWidgets);
  });

  testWidgets('employé : pas de boutons pour décider d\'une tension', (tester) async {
    await _lancer(tester, FausseAlertesApi(_liste(admin: false)));
    expect(find.byKey(const ValueKey('ecarter-tension-7')), findsNothing);
    expect(find.byKey(const ValueKey('action-tension-7')), findsOneWidget); // « Voir »
  });

  testWidgets('rien à signaler, puis serveur injoignable', (tester) async {
    await _lancer(tester, FausseAlertesApi(ListeAlertes(jour: DateTime(2026, 11, 17))));
    expect(find.text('Rien à signaler'), findsOneWidget);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    await _lancer(tester, FausseAlertesApi(_liste(), panne: true));
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
