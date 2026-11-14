import 'package:flutter/material.dart';

/// Les thèmes proposés à l'utilisateur. `bleu` est le thème par défaut,
/// `sombre` le second choix ; les autres sont des options des préférences.
///
/// Le nom de la valeur est ce qui est enregistré dans les préférences : ne
/// pas le renommer sans migration.
enum ThemeId {
  bleu('Bleu médical'),
  sombre('Sombre'),
  vert('Vert officine'),
  turquoise('Turquoise'),
  indigo('Indigo');

  const ThemeId(this.libelle);
  final String libelle;

  static const defaut = ThemeId.bleu;

  static ThemeId depuisNom(String? nom) => ThemeId.values.where((t) => t.name == nom).firstOrNull ?? defaut;
}

/// Couleurs d'état : rupture, seuil ou péremption proche, bon.
///
/// Elles gardent le même sens dans tous les thèmes et ne se confondent jamais
/// avec la couleur principale. Elles s'emploient toujours avec une icône et
/// un libellé, jamais seules (docs/05-stock-guide.md, section 7).
@immutable
class CouleursEtat extends ThemeExtension<CouleursEtat> {
  const CouleursEtat({
    required this.critique,
    required this.critiqueDoux,
    required this.alerte,
    required this.alerteDoux,
    required this.alerteIcone,
    required this.bon,
    required this.bonDoux,
  });

  final Color critique, critiqueDoux;
  final Color alerte, alerteDoux, alerteIcone;
  final Color bon, bonDoux;

  static const clair = CouleursEtat(
    critique: Color(0xFFC62F2F),
    critiqueDoux: Color(0xFFFBE9E9),
    alerte: Color(0xFF9A5B00),
    alerteDoux: Color(0xFFFFF1D6),
    alerteIcone: Color(0xFFE79A00),
    bon: Color(0xFF0B7A2B),
    bonDoux: Color(0xFFE3F4E7),
  );

  static const sombre = CouleursEtat(
    critique: Color(0xFFF28B8B),
    critiqueDoux: Color(0xFF3B2020),
    alerte: Color(0xFFF2BE5C),
    alerteDoux: Color(0xFF3A2F16),
    alerteIcone: Color(0xFFF2B544),
    bon: Color(0xFF6FD08A),
    bonDoux: Color(0xFF173323),
  );

  @override
  CouleursEtat copyWith() => this;

  @override
  CouleursEtat lerp(CouleursEtat? autre, double t) {
    if (autre == null) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return CouleursEtat(
      critique: m(critique, autre.critique),
      critiqueDoux: m(critiqueDoux, autre.critiqueDoux),
      alerte: m(alerte, autre.alerte),
      alerteDoux: m(alerteDoux, autre.alerteDoux),
      alerteIcone: m(alerteIcone, autre.alerteIcone),
      bon: m(bon, autre.bon),
      bonDoux: m(bonDoux, autre.bonDoux),
    );
  }
}

/// Les quelques couleurs qui distinguent un thème d'un autre.
class _Palette {
  const _Palette({
    required this.primaire,
    required this.primaireFonce,
    required this.primaireDoux,
    required this.fond,
    required this.bord,
    this.surPrimaire = Colors.white,
    this.surface = Colors.white,
    this.encre = const Color(0xFF14201D),
    this.encre2 = const Color(0xFF4A5A56),
    this.encre3 = const Color(0xFF7C8B87),
    this.neutreDoux = const Color(0xFFEDF1F0),
    this.tuilePrincipale,
    this.luminosite = Brightness.light,
  });

  final Color primaire, primaireFonce, primaireDoux, surPrimaire;
  final Color fond, surface, bord;
  final Color encre, encre2, encre3, neutreDoux;

  /// Fond de la tuile principale ; par défaut la couleur primaire.
  final Color? tuilePrincipale;
  final Brightness luminosite;
}

const _palettes = <ThemeId, _Palette>{
  ThemeId.bleu: _Palette(
    primaire: Color(0xFF1F5FBF),
    primaireFonce: Color(0xFF174A96),
    primaireDoux: Color(0xFFE1ECFB),
    fond: Color(0xFFF4F6FA),
    bord: Color(0xFFE0E5EE),
  ),
  ThemeId.vert: _Palette(
    primaire: Color(0xFF0E6B5C),
    primaireFonce: Color(0xFF0A4F44),
    primaireDoux: Color(0xFFDDF0EB),
    fond: Color(0xFFF4F7F6),
    bord: Color(0xFFE1E7E5),
  ),
  ThemeId.turquoise: _Palette(
    primaire: Color(0xFF0B7A8C),
    primaireFonce: Color(0xFF085C6A),
    primaireDoux: Color(0xFFD9F0F4),
    fond: Color(0xFFF3F7F8),
    bord: Color(0xFFDEE7E9),
  ),
  ThemeId.indigo: _Palette(
    primaire: Color(0xFF4338A8),
    primaireFonce: Color(0xFF322A82),
    primaireDoux: Color(0xFFE8E6F8),
    fond: Color(0xFFF6F5FB),
    bord: Color(0xFFE3E1EF),
  ),
  ThemeId.sombre: _Palette(
    primaire: Color(0xFF2FA88F),
    primaireFonce: Color(0xFF8FE3CE),
    primaireDoux: Color(0xFF1D3A34),
    surPrimaire: Color(0xFF06211C),
    fond: Color(0xFF0F1614),
    surface: Color(0xFF18211F),
    bord: Color(0xFF2A3633),
    encre: Color(0xFFE8EFEC),
    encre2: Color(0xFFA9B8B3),
    encre3: Color(0xFF80908A),
    neutreDoux: Color(0xFF232E2B),
    tuilePrincipale: Color(0xFF1B6F5F),
    luminosite: Brightness.dark,
  ),
};

/// Couleurs propres à PharmaSuite que `ColorScheme` ne nomme pas.
@immutable
class CouleursApp extends ThemeExtension<CouleursApp> {
  const CouleursApp({
    required this.encre2,
    required this.encre3,
    required this.bord,
    required this.neutreDoux,
    required this.tuilePrincipale,
    required this.surTuilePrincipale,
  });

  /// Texte secondaire, texte discret.
  final Color encre2, encre3;
  final Color bord, neutreDoux;
  final Color tuilePrincipale, surTuilePrincipale;

  @override
  CouleursApp copyWith() => this;

  @override
  CouleursApp lerp(CouleursApp? autre, double t) {
    if (autre == null) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return CouleursApp(
      encre2: m(encre2, autre.encre2),
      encre3: m(encre3, autre.encre3),
      bord: m(bord, autre.bord),
      neutreDoux: m(neutreDoux, autre.neutreDoux),
      tuilePrincipale: m(tuilePrincipale, autre.tuilePrincipale),
      surTuilePrincipale: m(surTuilePrincipale, autre.surTuilePrincipale),
    );
  }
}

/// Construit le `ThemeData` d'un thème.
ThemeData construireTheme(ThemeId id) {
  final p = _palettes[id]!;
  final sombre = p.luminosite == Brightness.dark;

  final schema = ColorScheme.fromSeed(seedColor: p.primaire, brightness: p.luminosite).copyWith(
    primary: p.primaire,
    onPrimary: p.surPrimaire,
    primaryContainer: p.primaireDoux,
    onPrimaryContainer: p.primaireFonce,
    secondaryContainer: p.primaireDoux,
    onSecondaryContainer: p.primaireFonce,
    surface: p.surface,
    onSurface: p.encre,
    onSurfaceVariant: p.encre2,
    outline: p.encre3,
    outlineVariant: p.bord,
    error: sombre ? CouleursEtat.sombre.critique : CouleursEtat.clair.critique,
  );

  final bordure = BorderSide(color: p.bord);
  final forme = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: bordure);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: schema,
    scaffoldBackgroundColor: p.fond,
    dividerTheme: DividerThemeData(color: p.bord, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: p.fond,
      foregroundColor: p.encre,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: p.encre, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: forme,
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primaireDoux,
      selectedIconTheme: IconThemeData(color: p.primaireFonce),
      unselectedIconTheme: IconThemeData(color: p.encre2),
      selectedLabelTextStyle: TextStyle(color: p.primaireFonce, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: p.encre2, fontWeight: FontWeight.w500),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primaireDoux,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (etats) => IconThemeData(color: etats.contains(WidgetState.selected) ? p.primaireFonce : p.encre3),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((etats) {
        final choisi = etats.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: choisi ? FontWeight.w600 : FontWeight.w500,
          color: choisi ? p.primaireFonce : p.encre3,
        );
      }),
    ),
    extensions: [
      sombre ? CouleursEtat.sombre : CouleursEtat.clair,
      CouleursApp(
        encre2: p.encre2,
        encre3: p.encre3,
        bord: p.bord,
        neutreDoux: p.neutreDoux,
        tuilePrincipale: p.tuilePrincipale ?? p.primaire,
        surTuilePrincipale: Colors.white,
      ),
    ],
  );
}

/// Accès court aux couleurs du thème depuis un widget.
extension CouleursDuContexte on BuildContext {
  ColorScheme get schema => Theme.of(this).colorScheme;
  CouleursEtat get etats => Theme.of(this).extension<CouleursEtat>()!;
  CouleursApp get couleurs => Theme.of(this).extension<CouleursApp>()!;
}
