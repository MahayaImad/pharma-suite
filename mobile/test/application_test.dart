import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/app.dart';
import 'package:pharmasuite/core/router/routeur.dart';
import 'package:pharmasuite/core/theme/themes.dart';
import 'package:pharmasuite/features/preferences/application/theme_controller.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fausse_stock_api.dart';

Future<SharedPreferences> _lancer(
  WidgetTester tester, {
  required Size taille,
  Map<String, Object> preferences = const {},
  String depart = '/stock',
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      stockApiProvider.overrideWithValue(FausseStockApi()),
      preferencesLocalesProvider.overrideWithValue(prefs),
      routeurProvider.overrideWithValue(construireRouteur(depart: depart)),
    ],
    child: const PharmaSuite(),
  ));
  await tester.pumpAndSettle();
  return prefs;
}

ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first));

const _pc = Size(1440, 900);
const _portable = Size(390, 844);

void main() {
  testWidgets('sur PC : menu latéral, pas de barre du bas', (tester) async {
    await _lancer(tester, taille: _pc);
    expect(find.text('PharmaSuite'), findsOneWidget);
    expect(find.text('Préférences'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('sur portable : barre du bas, pas de menu latéral', (tester) async {
    await _lancer(tester, taille: _portable);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('PharmaSuite'), findsNothing);
  });

  testWidgets('la navigation change d\'écran', (tester) async {
    await _lancer(tester, taille: _portable);
    await tester.tap(find.text('Alertes'));
    await tester.pumpAndSettle();
    expect(find.text('Ruptures, seuils et péremptions à traiter.'), findsOneWidget);
  });

  testWidgets('sur portable : les préférences s\'ouvrent en plein écran et se referment',
      (tester) async {
    await _lancer(tester, taille: _portable);
    await tester.tap(find.byTooltip('Préférences'));
    await tester.pumpAndSettle();
    expect(find.text('Thème'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Thème'), findsNothing);
  });

  testWidgets('sur portable : préférences ouvertes par leur adresse, le retour mène au stock',
      (tester) async {
    await _lancer(tester, taille: _portable, depart: '/preferences');
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('champ-recherche')), findsOneWidget);
  });

  testWidgets('sur PC : pas de bouton préférences dans la barre de titre', (tester) async {
    await _lancer(tester, taille: _pc);
    expect(find.byTooltip('Préférences'), findsNothing);
  });

  testWidgets('premier lancement : thème bleu médical', (tester) async {
    await _lancer(tester, taille: _pc);
    expect(_theme(tester).colorScheme.primary, construireTheme(ThemeId.bleu).colorScheme.primary);
  });

  testWidgets('le thème enregistré est repris au lancement', (tester) async {
    await _lancer(tester, taille: _pc, preferences: {cleTheme: 'sombre'});
    expect(_theme(tester).brightness, Brightness.dark);
  });

  testWidgets('choisir un thème l\'applique et l\'enregistre', (tester) async {
    final prefs = await _lancer(tester, taille: _pc, depart: '/preferences');
    for (final t in ThemeId.values) {
      expect(find.text(t.libelle), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('theme-sombre')));
    await tester.pumpAndSettle();
    expect(_theme(tester).brightness, Brightness.dark);
    expect(prefs.getString(cleTheme), 'sombre');
    // On est toujours sur les préférences : changer de thème ne renvoie pas
    // à l'écran de départ.
    expect(find.text('Aperçu'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-indigo')));
    await tester.pumpAndSettle();
    expect(_theme(tester).colorScheme.primary, construireTheme(ThemeId.indigo).colorScheme.primary);
    expect(prefs.getString(cleTheme), 'indigo');
  });

  testWidgets('les préférences tiennent sur un portable sans débordement', (tester) async {
    await _lancer(tester, taille: _portable, depart: '/preferences');
    expect(tester.takeException(), isNull);
    expect(find.text('Thème'), findsOneWidget);
  });
}
