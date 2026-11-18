import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/data/api/categories_api.dart';
import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/domain/categories.dart';
import 'package:pharmasuite/domain/format.dart';
import 'package:pharmasuite/domain/session.dart';
import 'package:pharmasuite/features/connexion/application/session_controller.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pc = Size(1440, 1000);
const _portable = Size(390, 844);

class FausseCategoriesApi implements CategoriesApi {
  FausseCategoriesApi({this.panne = false});
  bool panne;
  final appels = <String>[];
  bool classe = false;
  final labos = {
    1: const LaboratoirePrime(id: 1, labo: 'Numidia Pharma', generique: true, ca: 492300, produits: 148, partCa: 14),
    2: const LaboratoirePrime(id: 2, labo: 'Atlas Santé Europe', ca: 386100, produits: 96, partCa: 11),
  };
  String? choix;

  @override
  Future<PrimeCategories> mois(int annee, int mois) async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    appels.add('mois $annee/$mois');
    return PrimeCategories(
      annee: annee,
      mois: mois,
      enveloppe: classe ? 46900 : 41870,
      ca: 3512400,
      categories: [
        const CategorieMois(categorie: 'princeps', tauxPct: .5, ca: 1334700, produits: 900, montant: 6673.5),
        const CategorieMois(categorie: 'generique', tauxPct: 1, ca: 1088840, produits: 700, montant: 10888.4),
        const CategorieMois(categorie: 'generique++', tauxPct: 3, ca: 316120, produits: 80, montant: 9483.6),
        CategorieMois(tauxPct: .5, ca: classe ? 0 : 772740, produits: classe ? 0 : 412, montant: 3863.7),
      ],
      sansCategorieTotal: classe ? 0 : 412,
      dernierClassement: classe ? DernierClassement(le: DateTime(2026, 11, 18), par: 'titulaire', produits: 412) : null,
    );
  }

  @override
  Future<PageLaboratoires> laboratoires(int annee, int mois, {String? recherche, int limite = 6}) async {
    appels.add('labos ${recherche ?? ''} $limite');
    final l = [
      for (final x in labos.values)
        if (recherche == null || recherche.isEmpty || x.labo.toLowerCase().contains(recherche.toLowerCase())) x,
    ];
    return PageLaboratoires(laboratoires: l.take(limite).toList(), total: (recherche ?? '').isEmpty ? 66 : l.length);
  }

  @override
  Future<List<ProduitCategorie>> produits(int annee, int mois) async => [
    ProduitCategorie(
      id: 10,
      nom: 'DOLIPRANE-LIKE 1G CP',
      labo: 'Atlas Santé Europe',
      ca: 84200,
      categorie: choix,
      manuelle: choix != null,
    ),
    const ProduitCategorie(id: 11, nom: 'LAIT 1ER AGE 400G', ca: 48300),
  ];

  @override
  Future<void> marquerLaboratoire(int id, bool generique) async {
    appels.add('labo $id $generique');
    labos[id] = labos[id]!.copyWith(generique: generique);
  }

  @override
  Future<void> choisir(int idNom, String? categorie) async {
    appels.add('choisir $idNom $categorie');
    choix = categorie;
  }

  @override
  Future<ResultatClassement> classer(double seuilMarge, {bool tout = false}) async {
    appels.add('classer $seuilMarge $tout');
    classe = true;
    return const ResultatClassement(princeps: 123, generique: 251, generiquePlus: 38, total: 412);
  }
}

Future<void> _lancer(WidgetTester tester, CategoriesApi api, {Size taille = _pc, String role = 'admin'}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesLocalesProvider.overrideWithValue(prefs),
        categoriesApiProvider.overrideWithValue(api),
        routeurProvider.overrideWithValue(construireRouteur(depart: '/preferences/categories')),
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
  test('libellés des catégories', () {
    expect(
      [
        for (final c in [...categoriesPrime, null]) libelleCategorie(c),
      ],
      ['Princeps', 'Générique', 'Générique++', 'Sans catégorie'],
    );
    expect(const PrimeCategories(annee: 2026, mois: 11).categorie(null).ca, 0);
  });

  testWidgets('PC : enveloppe, tuiles, laboratoires, produits à classer', (tester) async {
    await _lancer(tester, FausseCategoriesApi());
    expect(tester.takeException(), isNull);
    expect(find.text('Catégories de prime'), findsWidgets);
    expect(find.text(dinars(41870)), findsOneWidget);
    expect(find.byKey(const ValueKey('tuile-sans')), findsOneWidget);
    expect(find.textContaining('au taux princeps · 412 produits'), findsOneWidget);
    expect(find.text('Numidia Pharma'), findsOneWidget);
    expect(find.text('Voir les 64 autres laboratoires'), findsOneWidget);
    expect(find.text(libelleProduit('DOLIPRANE-LIKE 1G CP')), findsOneWidget);
    expect(find.text('Classer les 412 produits sans catégorie'), findsOneWidget);
  });

  testWidgets('marquer un laboratoire, voir tous, chercher', (tester) async {
    final api = FausseCategoriesApi();
    await _lancer(tester, api);
    await _toucher(tester, find.byKey(const ValueKey('labo-2')));
    expect(api.appels, contains('labo 2 true'));
    expect(tester.widget<Switch>(find.byKey(const ValueKey('labo-2'))).value, isTrue);
    await _toucher(tester, find.byKey(const ValueKey('voir-tous-labos')));
    expect(api.appels.last, 'labos  500');
    await tester.enterText(find.byKey(const ValueKey('recherche-labo')), 'atlas');
    await tester.pumpAndSettle();
    expect(find.text('Numidia Pharma'), findsNothing);
    expect(find.text('Atlas Santé Europe'), findsWidgets);
  });

  testWidgets('classer : seuil changé, relecture de l\'enveloppe', (tester) async {
    final api = FausseCategoriesApi();
    await _lancer(tester, api);
    await _toucher(tester, find.byKey(const ValueKey('seuil-marge')));
    await tester.enterText(find.byKey(const ValueKey('saisie-seuil')), '60');
    await _toucher(tester, find.byKey(const ValueKey('seuil-ok')));
    await _toucher(tester, find.byKey(const ValueKey('classer')));
    expect(api.appels, contains('classer 60.0 false'));
    expect(find.textContaining('412 produits classés'), findsOneWidget);
    expect(find.text(dinars(46900)), findsOneWidget);
    expect(find.textContaining('Dernier classement : 18/11/2026 par titulaire'), findsOneWidget);
  });

  testWidgets('tout reclasser demande confirmation', (tester) async {
    final api = FausseCategoriesApi();
    await _lancer(tester, api);
    await _toucher(tester, find.byKey(const ValueKey('tout-reclasser')));
    expect(find.text('Tout reclasser ?'), findsOneWidget);
    await _toucher(tester, find.byKey(const ValueKey('confirmer-reclasser')));
    expect(api.appels, contains('classer 50.0 true'));
  });

  testWidgets('choisir une catégorie à la main, puis revenir à l\'automatique', (tester) async {
    final api = FausseCategoriesApi();
    await _lancer(tester, api);
    await _toucher(tester, find.byKey(const ValueKey('choisir-10')));
    await _toucher(tester, find.text('Princeps').last);
    expect(api.appels, contains('choisir 10 princeps'));
    expect(find.text('Princeps · à la main'), findsOneWidget);
    await _toucher(tester, find.byKey(const ValueKey('choisir-10')));
    await _toucher(tester, find.text('Classement automatique'));
    expect(api.appels, contains('choisir 10 null'));
    expect(find.text('Princeps · à la main'), findsNothing);
  });

  testWidgets('portable : tout tient sur 390 px, retour', (tester) async {
    await _lancer(tester, FausseCategoriesApi(), taille: _portable);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('choisir-11')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Retour'), findsOneWidget);
  });

  testWidgets('titulaire : entrée dans les Préférences', (tester) async {
    await _lancer(tester, FausseCategoriesApi(), taille: _portable);
    await _toucher(tester, find.byTooltip('Retour'));
    expect(find.byKey(const ValueKey('entree-categories')), findsOneWidget);
  });

  testWidgets('serveur injoignable : message et « Réessayer »', (tester) async {
    await _lancer(tester, FausseCategoriesApi(panne: true));
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
