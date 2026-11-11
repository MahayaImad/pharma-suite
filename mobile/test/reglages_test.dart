import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/calendrier_api.dart';
import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/domain/calendrier.dart';
import 'package:pharmasuite/domain/session.dart';
import 'package:pharmasuite/features/connexion/application/session_controller.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FauxCalendrier implements CalendrierApi {
  final gardesEnBase = <Garde>[
    Garde(date: DateTime.now().add(const Duration(days: 5)), type: TypeGarde.soiree),
    Garde(date: DateTime(2026, 10, 28), type: TypeGarde.soiree, source: 'detection', confirme: false),
    Garde(date: DateTime(2026, 10, 1), type: TypeGarde.h24, note: 'donnée par l\'officine'),
  ];
  final enregistrees = <(DateTime, TypeGarde)>[];
  final reglagesModifies = <Map<String, double>>[];

  @override
  Future<List<Garde>> gardes() async => List.of(gardesEnBase);

  @override
  Future<Garde> enregistrerGarde(DateTime jour, TypeGarde type, {String? note}) async {
    enregistrees.add((jour, type));
    gardesEnBase.removeWhere((g) => g.date == jour);
    final g = Garde(date: jour, type: type, note: note);
    gardesEnBase.add(g);
    return g;
  }

  @override
  Future<void> supprimerGarde(DateTime jour) async => gardesEnBase.removeWhere((g) => g.date == jour);

  @override
  Future<List<Evenement>> evenements() async => [
    Evenement(
      id: 1,
      type: TypeEvenement.ramadan,
      debut: DateTime(2027, 2, 8),
      fin: DateTime(2027, 3, 9),
      aVerifier: true,
    ),
    Evenement(id: 2, type: TypeEvenement.aidFitr, debut: DateTime(2026, 3, 20), fin: DateTime(2026, 3, 21)),
  ];

  @override
  Future<Evenement> enregistrerEvenement(TypeEvenement type, DateTime debut, DateTime fin, {int? id}) async =>
      Evenement(id: id ?? 9, type: type, debut: debut, fin: fin);

  @override
  Future<void> supprimerEvenement(int id) async {}

  @override
  Future<List<Ferie>> feries() async => [Ferie(id: 1, date: DateTime(2027, 1, 12), label: 'Yennayer')];

  @override
  Future<Ferie> ajouterFerie(DateTime jour, String libelle) async => Ferie(id: 2, date: jour, label: libelle);

  @override
  Future<void> supprimerFerie(int id) async {}

  @override
  Future<List<Reglage>> reglages() async => const [
    Reglage(cle: 'delai_livraison_jours', valeur: 1),
    Reglage(cle: 'delai_securite_jours', valeur: 2),
    Reglage(cle: 'periode_commande_jours', valeur: 7),
  ];

  @override
  Future<List<Reglage>> modifierReglages(Map<String, double> valeurs) async {
    reglagesModifies.add(valeurs);
    if (valeurs.values.any((v) => v > 60)) throw const ErreurApi('Valeur trop grande.');
    return reglages();
  }
}

Future<FauxCalendrier> _lancer(
  WidgetTester tester, {
  String role = 'admin',
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final api = FauxCalendrier();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesLocalesProvider.overrideWithValue(prefs),
        calendrierApiProvider.overrideWithValue(api),
        sessionProvider.overrideWithBuild(
          (ref, _) => Session(
            jeton: 'j',
            profil: Profil(utilisateur: 'u', role: role),
          ),
        ),
        routeurProvider.overrideWithValue(construireRouteur(depart: '/preferences')),
      ],
      child: const PharmaSuite(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('entree-reglages')));
  await tester.pumpAndSettle();
  return api;
}

Future<void> _voir(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('les préférences ouvrent le calendrier ; les quatre sections sont là', (tester) async {
    await _lancer(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Calendrier et réglages'), findsOneWidget);
    expect(find.text('Gardes'), findsOneWidget);
    expect(find.text('à confirmer'), findsOneWidget);
    await _voir(tester, find.byKey(const ValueKey('section-fetes')));
    expect(find.text('à vérifier'), findsOneWidget);
    await _voir(tester, find.byKey(const ValueKey('section-feries')));
    await _voir(tester, find.text('Yennayer'));
    await _voir(tester, find.byKey(const ValueKey('reglage-periode_commande_jours')));
    expect(find.text('7 jours'), findsOneWidget);
  });

  testWidgets('confirmer une garde retrouvée dans les ventes', (tester) async {
    final api = await _lancer(tester);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(api.enregistrees.single, (DateTime(2026, 10, 28), TypeGarde.soiree));
    expect(find.text('à confirmer'), findsNothing);
  });

  testWidgets('corriger le type d\'une garde', (tester) async {
    final api = await _lancer(tester);
    await _voir(tester, find.byKey(const ValueKey('garde-2026-10-01')));
    await tester.tap(find.byKey(const ValueKey('garde-2026-10-01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('type-soiree')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('enregistrer')));
    await tester.pumpAndSettle();
    expect(api.enregistrees.single, (DateTime(2026, 10, 1), TypeGarde.soiree));
  });

  testWidgets('modifier un réglage ; une erreur du serveur s\'affiche', (tester) async {
    final api = await _lancer(tester);
    await _voir(tester, find.byKey(const ValueKey('reglage-periode_commande_jours')));
    await tester.tap(find.byKey(const ValueKey('reglage-periode_commande_jours')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('valeur-reglage')), '90');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Valeur trop grande.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('valeur-reglage')), '10,5');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(api.reglagesModifies.last, {'periode_commande_jours': 10.5});
    expect(find.byKey(const ValueKey('valeur-reglage')), findsNothing);
  });

  testWidgets('employé : lecture seule, aucun bouton de modification', (tester) async {
    await _lancer(tester, role: 'employee');
    expect(find.text('Lecture seule : seul le titulaire modifie ces réglages.'), findsOneWidget);
    expect(find.byKey(const ValueKey('ajouter-gardes')), findsNothing);
    expect(find.text('Confirmer'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('garde-2026-10-01')).hitTestable(), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('enregistrer')), findsNothing);
  });

  testWidgets('PC : pas de débordement', (tester) async {
    await _lancer(tester, taille: const Size(1440, 900));
    expect(tester.takeException(), isNull);
  });
}
