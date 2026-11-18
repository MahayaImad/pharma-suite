import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/data/api/paie_api.dart';
import 'package:pharmasuite/domain/format.dart';
import 'package:pharmasuite/domain/paie.dart';
import 'package:pharmasuite/domain/session.dart';
import 'package:pharmasuite/features/connexion/application/session_controller.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pc = Size(1440, 1000);
const _portable = Size(390, 844);

LigneBulletin _l(String code, String libelle, double m) => LigneBulletin(code: code, libelle: libelle, montant: m);

PaieEmploye _ana({double hs = 0, BulletinValide? bulletin}) => PaieEmploye(
  employe: EmployePaie(
    id: 1,
    nom: 'Benali',
    prenom: 'Ana',
    posteCode: 'caissier',
    poste: 'Caissier',
    dateEntree: DateTime(2020, 9, 1),
  ),
  jours: const JoursPaie(presence: 24, absences: 1),
  ancienneteAnnees: 6,
  heuresSup: hs,
  lignes: [
    _l('salaire_base', 'Salaire de base', 40000),
    _l('anciennete', "Prime d'ancienneté", 6000),
    _l('transport', 'Prime de transport', 7200),
    _l('panier', 'Prime de panier', 14400),
    _l('heures_sup', 'Heures supplémentaires', hs == 0 ? 0 : 1384.64),
    _l('retenue_absences', 'Retenue pour absence', -1333.33),
  ],
  partFixe: 66266.67 + (hs == 0 ? 0 : 1384.64),
  partVariable: 18198.69,
  brut: 84465.36 + (hs == 0 ? 0 : 1384.64),
  prime: const PrimeDetail(
    plancher: 5000,
    merite: 13198.69,
    criteres: [
      Critere(code: 'ca_realise', libelle: 'CA réalisé', unite: 'DA', valeur: 312400, poids: 20, indice: 155),
      Critere(code: 'taches_completees', libelle: 'Tâches', unite: 'nb', valeur: 18, poids: 20, indice: 120),
      Critere(code: 'nb_ventes', libelle: 'Nombre de ventes', unite: 'nb', valeur: 842, poids: 12, indice: 145),
      Critere(code: 'ponctualite', libelle: "Jours à l'heure", unite: 'nb', valeur: 22, poids: 10, indice: 95),
    ],
  ),
  bulletin: bulletin,
);

final _chafia = PaieEmploye(
  employe: EmployePaie(
    id: 2,
    nom: 'Saidi',
    prenom: 'Chafia',
    posteCode: 'preparateur',
    poste: 'Préparateur',
    dateEntree: DateTime(2026, 11, 16),
  ),
  jours: const JoursPaie(contrat: 15, presence: 0, aConfirmer: 13),
  lignes: [_l('salaire_base', 'Salaire de base', 17500)],
  partFixe: 17500,
  brut: 17500,
  aVerifier: ['13 jours de présence à confirmer (sans transport ni panier tant qu\'ils ne sont pas corrigés).'],
);

class FaussePaieApi implements PaieApi {
  FaussePaieApi({this.panne = false, this.vide = false});
  bool panne;
  bool vide;
  Map<String, Object?>? modifie;
  final appels = <String>[];
  double hs = 0;
  BulletinValide? bulletin;

  @override
  Future<PaieMois> mois(int annee, int mois) async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    appels.add('mois $annee/$mois');
    final a = _ana(hs: hs, bulletin: bulletin);
    return PaieMois(
      annee: annee,
      mois: mois,
      employes: vide ? const [] : [a, _chafia],
      totaux: TotauxPaie(partFixe: a.partFixe + 17500, partVariable: 18198.69, brut: a.brut + 17500),
    );
  }

  @override
  Future<void> heuresSup(int annee, int mois, int idEmploye, double heures) async {
    appels.add('hs $idEmploye $heures');
    hs = heures;
  }

  @override
  Future<void> recalculerPrimes(int annee, int mois) async => appels.add('primes $annee/$mois');

  @override
  Future<int> importerEmployes() async {
    appels.add('importer');
    vide = false;
    return 2;
  }

  @override
  Future<List<PosteTravail>> postes() async => const [
    PosteTravail(code: 'caissier', libelle: 'Caissier', salaireBase: 40000),
    PosteTravail(code: 'preparateur', libelle: 'Préparateur', salaireBase: 35000, vendAuComptoir: false),
  ];

  @override
  Future<void> modifierEmploye(int id, Map<String, Object?> champs) async {
    appels.add('fiche $id');
    modifie = champs;
  }

  @override
  Future<void> valider(int annee, int mois) async {
    appels.add('valider $annee/$mois');
    bulletin = const BulletinValide(version: 1, validePar: 'titulaire');
  }
}

Future<void> _lancer(
  WidgetTester tester,
  PaieApi api, {
  Size taille = _pc,
  String depart = '/paie',
  String role = 'admin',
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
        paieApiProvider.overrideWithValue(api),
        routeurProvider.overrideWithValue(construireRouteur(depart: depart)),
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
  test('critère : valeur lisible et écart à la moyenne ; état d\'un employé', () {
    final c = _ana().prime!.criteres;
    expect([c[0].valeurLisible, c[0].ecart], ['${entier(312400)} DA', '+55 %']);
    expect([c[3].valeurLisible, c[3].ecart], ['22 j', '−5 %']);
    expect(const Critere(code: 'x').ecart, isNull);
    expect([_ana().etat, _chafia.etat], [EtatPaie.prete, EtatPaie.aConfirmer]);
    expect(detailLigne(_ana(), 'transport', const ReglesPaie()), '24 jours × 300');
    expect(libelleMois(2026, 11), 'novembre 2026');
  });

  testWidgets('PC : liste, bulletin de la première employée, radar et critères', (tester) async {
    await _lancer(tester, FaussePaieApi());
    expect(tester.takeException(), isNull);
    expect(find.text('Paie'), findsWidgets);
    expect(find.byKey(const ValueKey('employe-paie-1')), findsOneWidget);
    expect(find.text('13 jours à confirmer'), findsOneWidget);
    expect(find.text('Ana Benali'), findsWidgets);
    expect(find.byKey(const ValueKey('radar')), findsOneWidget);
    expect(find.byKey(const ValueKey('critere-ca_realise')), findsOneWidget);
    expect(find.text('+55 %'), findsOneWidget);
    expect(find.text('24 jours × 300'), findsOneWidget);

    // Bulletin de Chafia : à vérifier, pas de prime calculée.
    await _toucher(tester, find.byKey(const ValueKey('employe-paie-2')));
    expect(find.byKey(const ValueKey('a-verifier')), findsOneWidget);
    expect(find.textContaining('Pas encore calculée'), findsOneWidget);
    expect(find.byKey(const ValueKey('radar')), findsNothing);
  });

  testWidgets('PC : heures sup, recalcul des primes, validation confirmée', (tester) async {
    final api = FaussePaieApi();
    await _lancer(tester, api, depart: '/paie/1');
    await _toucher(tester, find.byKey(const ValueKey('modifier-heures-sup')));
    await tester.enterText(find.byKey(const ValueKey('saisie-heures-sup')), '4');
    await _toucher(tester, find.byKey(const ValueKey('heures-sup-ok')));
    expect(api.appels, contains('hs 1 4.0'));
    expect(find.textContaining('4 h majorées'), findsOneWidget);

    await _toucher(tester, find.byKey(const ValueKey('recalculer-primes')));
    expect(api.appels.any((a) => a.startsWith('primes ')), isTrue);
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await _toucher(tester, find.byKey(const ValueKey('valider-paie')));
    expect(find.textContaining('2 bulletins bruts'), findsOneWidget);
    await _toucher(tester, find.byKey(const ValueKey('confirmer-validation')));
    expect(api.appels.any((a) => a.startsWith('valider ')), isTrue);
    expect(find.textContaining('Bulletin validé (version 1)'), findsOneWidget);
  });

  testWidgets('aucun employé : importer depuis EASYPHARM remplit la liste', (tester) async {
    final api = FaussePaieApi(vide: true);
    await _lancer(tester, api);
    expect(find.text('Aucun employé'), findsOneWidget);
    await _toucher(tester, find.byKey(const ValueKey('importer-employes')));
    expect(api.appels, contains('importer'));
    expect(find.byKey(const ValueKey('employe-paie-1')), findsOneWidget);
    expect(find.textContaining('2 fiches à jour'), findsOneWidget);
  });

  testWidgets('fiche employé : poste et retrait de la paie, seuls les changements partent', (tester) async {
    final api = FaussePaieApi();
    await _lancer(tester, api, depart: '/paie/2');
    await _toucher(tester, find.byKey(const ValueKey('modifier-fiche')));
    expect(find.text('Préparateur · ${dinars(35000)}'), findsOneWidget);
    await _toucher(tester, find.byKey(const ValueKey('choix-poste')));
    await _toucher(tester, find.text('Caissier · ${dinars(40000)}').last);
    await _toucher(tester, find.byKey(const ValueKey('dans-la-paie')));
    await _toucher(tester, find.byKey(const ValueKey('enregistrer-fiche')));
    expect(api.appels, contains('fiche 2'));
    expect(api.modifie, {'poste_code': 'caissier', 'eligible_prime': false});
    expect(find.textContaining('n\'est plus dans la paie'), findsOneWidget);
  });

  testWidgets('changer de mois relit la paie', (tester) async {
    final api = FaussePaieApi();
    await _lancer(tester, api);
    final avant = api.appels.length;
    await _toucher(tester, find.byKey(const ValueKey('mois-precedent')));
    expect(api.appels.length, avant + 1);
    final n = DateTime.now(), d = DateTime(n.year, n.month - 1);
    expect(api.appels.last, 'mois ${d.year}/${d.month}');
  });

  testWidgets('portable : liste, bulletin en plein écran avec le radar, retour', (tester) async {
    await _lancer(tester, FaussePaieApi(), taille: _portable);
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsNothing); // hors de la barre du bas
    await _toucher(tester, find.byKey(const ValueKey('employe-paie-1')));
    expect(find.text('Bulletin'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('radar')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    await _toucher(tester, find.byTooltip('Retour'));
    expect(find.byKey(const ValueKey('employe-paie-2')), findsOneWidget);
  });

  testWidgets('titulaire : entrée dans le menu sur PC', (tester) async {
    await _lancer(tester, FaussePaieApi(), depart: '/stock');
    expect(find.widgetWithText(InkWell, 'Paie'), findsWidgets);
  });

  testWidgets('titulaire : entrée dans les Préférences sur portable', (tester) async {
    await _lancer(tester, FaussePaieApi(), taille: _portable, depart: '/preferences');
    expect(find.byKey(const ValueKey('entree-paie')), findsOneWidget);
  });

  testWidgets('employé : ni menu ni entrée Paie', (tester) async {
    await _lancer(tester, FaussePaieApi(), taille: _portable, depart: '/preferences', role: 'employee');
    expect(find.byKey(const ValueKey('entree-paie')), findsNothing);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    await _lancer(tester, FaussePaieApi(panne: true));
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
