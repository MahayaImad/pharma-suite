import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/data/api/auth_api.dart';
import 'package:pharmasuite/domain/session.dart';
import 'package:pharmasuite/features/connexion/application/session_controller.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_stock_api.dart';

/// API simulée : « sara » / « secret » est le seul compte valide.
class FausseAuthApi implements AuthApi {
  FausseAuthApi({this.panne = false});
  final bool panne;
  int appels = 0;

  @override
  Future<ReponseJeton> connecter(String utilisateur, String motDePasse) async {
    appels++;
    if (panne) throw const ErreurConnexion(EchecConnexion.serveurInjoignable);
    if (utilisateur == 'sara' && motDePasse == 'secret') return const ReponseJeton(jeton: 'jeton-sara');
    throw const ErreurConnexion(EchecConnexion.identifiants);
  }

  @override
  Future<Profil> moi(String jeton) async => const Profil(utilisateur: 'sara', nom: 'Benali', prenom: 'Sara');
}

Future<SharedPreferences> _lancer(
  WidgetTester tester, {
  required FausseAuthApi api,
  Size taille = const Size(1440, 900),
  Map<String, Object> preferences = const {},
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stockApiProvider.overrideWithValue(FausseStockApi()),
        preferencesLocalesProvider.overrideWithValue(prefs),
        authApiProvider.overrideWithValue(api),
      ],
      child: const PharmaSuite(),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

Future<void> _saisir(WidgetTester tester, String utilisateur, String motDePasse) async {
  await tester.enterText(find.byKey(const ValueKey('champ-utilisateur')), utilisateur);
  await tester.enterText(find.byKey(const ValueKey('champ-mot-de-passe')), motDePasse);
  await tester.tap(find.byKey(const ValueKey('bouton-connexion')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans session, l\'application s\'ouvre sur la connexion', (tester) async {
    await _lancer(tester, api: FausseAuthApi());
    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Votre officine, pilotée au quotidien.'), findsOneWidget);
    expect(find.text('Préférences'), findsNothing);
  });

  testWidgets('connexion réussie : ouvre le stock et garde la session', (tester) async {
    final prefs = await _lancer(tester, api: FausseAuthApi());
    await _saisir(tester, 'sara', 'secret');

    expect(find.byKey(const ValueKey('champ-recherche')), findsOneWidget);
    expect(find.text('Sara Benali'), findsOneWidget); // menu latéral
    final enregistree = Session.fromJson(jsonDecode(prefs.getString(cleSession)!) as Map<String, dynamic>);
    expect(enregistree.jeton, 'jeton-sara');
  });

  testWidgets('mauvais mot de passe : message clair, mot de passe effacé', (tester) async {
    await _lancer(tester, api: FausseAuthApi());
    await _saisir(tester, 'sara', 'faux');

    expect(find.text(EchecConnexion.identifiants.message), findsOneWidget);
    final champ = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('champ-mot-de-passe')),
        matching: find.byType(EditableText),
      ),
    );
    expect(champ.controller.text, isEmpty);
    expect(find.text('Connexion'), findsOneWidget);
  });

  testWidgets('serveur injoignable : message réseau', (tester) async {
    await _lancer(tester, api: FausseAuthApi(panne: true));
    await _saisir(tester, 'sara', 'secret');
    expect(find.text(EchecConnexion.serveurInjoignable.message), findsOneWidget);
  });

  testWidgets('champs vides : rien n\'est envoyé', (tester) async {
    final api = FausseAuthApi();
    await _lancer(tester, api: api);
    await tester.tap(find.byKey(const ValueKey('bouton-connexion')));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez votre utilisateur.'), findsOneWidget);
    expect(find.text('Indiquez votre mot de passe.'), findsOneWidget);
    expect(api.appels, 0);
  });

  testWidgets('session enregistrée : on arrive directement dans l\'application', (tester) async {
    const session = Session(
      jeton: 'j',
      profil: Profil(utilisateur: 'sara', prenom: 'Sara', nom: 'Benali'),
    );
    await _lancer(tester, api: FausseAuthApi(), preferences: {cleSession: jsonEncode(session.toJson())});
    expect(find.text('Connexion'), findsNothing);
    expect(find.text('Sara Benali'), findsOneWidget);
  });

  testWidgets('se déconnecter ramène à la connexion et oublie la session', (tester) async {
    const session = Session(
      jeton: 'j',
      profil: Profil(utilisateur: 'sara'),
    );
    final prefs = await _lancer(
      tester,
      api: FausseAuthApi(),
      preferences: {cleSession: jsonEncode(session.toJson())},
    );
    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion'), findsOneWidget);
    expect(prefs.getString(cleSession), isNull);
  });

  testWidgets('sur portable : bandeau photo au-dessus du formulaire, sans débordement', (tester) async {
    await _lancer(tester, api: FausseAuthApi(), taille: const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('Connexion'), findsOneWidget);
    await _saisir(tester, 'sara', 'secret');
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  test('initiales et nom affiché', () {
    expect(const Profil(utilisateur: 'sara', prenom: 'Sara', nom: 'Benali').initiales, 'SB');
    expect(const Profil(utilisateur: 'caisse2').nomAffiche, 'caisse2');
    expect(const Profil(utilisateur: 'caisse2').initiales, 'C');
  });
}
