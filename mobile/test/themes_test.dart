import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/core/theme/themes.dart';

void main() {
  test('le bleu médical est le thème par défaut', () {
    expect(ThemeId.defaut, ThemeId.bleu);
    expect(ThemeId.depuisNom(null), ThemeId.bleu);
    expect(ThemeId.depuisNom('un_theme_supprime'), ThemeId.bleu);
    expect(ThemeId.depuisNom('sombre'), ThemeId.sombre);
  });

  test('chaque thème se construit avec ses couleurs d\'état', () {
    for (final id in ThemeId.values) {
      final theme = construireTheme(id);
      expect(theme.extension<CouleursEtat>(), isNotNull, reason: id.name);
      expect(theme.extension<CouleursApp>(), isNotNull, reason: id.name);
      expect(theme.brightness, id == ThemeId.sombre ? Brightness.dark : Brightness.light,
          reason: id.name);
    }
  });

  test('les couleurs d\'état sont les mêmes dans tous les thèmes clairs', () {
    final attendu = construireTheme(ThemeId.bleu).extension<CouleursEtat>()!;
    for (final id in ThemeId.values.where((t) => t != ThemeId.sombre)) {
      expect(construireTheme(id).extension<CouleursEtat>()!.critique, attendu.critique,
          reason: id.name);
    }
  });

  test('le texte reste lisible sur la couleur principale', () {
    // Contraste WCAG d'au moins 4,5 entre le bouton et son texte.
    double contraste(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      final clair = la > lb ? la : lb, fonce = la > lb ? lb : la;
      return (clair + 0.05) / (fonce + 0.05);
    }

    for (final id in ThemeId.values) {
      final s = construireTheme(id).colorScheme;
      expect(contraste(s.primary, s.onPrimary), greaterThanOrEqualTo(4.5), reason: id.name);
      expect(contraste(s.primaryContainer, s.onPrimaryContainer), greaterThanOrEqualTo(4.5),
          reason: id.name);
      expect(contraste(s.surface, s.onSurface), greaterThanOrEqualTo(7), reason: id.name);
    }
  });
}
