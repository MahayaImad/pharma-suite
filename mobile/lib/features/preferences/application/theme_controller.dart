import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/themes.dart';

/// Préférences locales de l'appareil. Fourni au démarrage (voir `main.dart`) :
/// la lecture est asynchrone, mais l'application doit connaître le thème dès
/// la première image, sans éclair de l'ancien thème.
final preferencesLocalesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('preferencesLocalesProvider doit être fourni au démarrage'),
);

const cleTheme = 'theme';

/// Thème choisi par l'utilisateur, conservé sur l'appareil.
class ThemeController extends Notifier<ThemeId> {
  @override
  ThemeId build() =>
      ThemeId.depuisNom(ref.watch(preferencesLocalesProvider).getString(cleTheme));

  Future<void> choisir(ThemeId theme) async {
    // L'affichage change tout de suite ; l'écriture suit, sans bloquer l'écran.
    state = theme;
    await ref.read(preferencesLocalesProvider).setString(cleTheme, theme.name);
  }
}

final themeProvider = NotifierProvider<ThemeController, ThemeId>(ThemeController.new);
