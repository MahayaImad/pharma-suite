import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/routeur.dart';
import 'core/theme/themes.dart';
import 'features/connexion/application/session_controller.dart';
import 'features/preferences/application/theme_controller.dart';

/// Le routeur vit aussi longtemps que l'application : le recréer à chaque
/// changement de thème ramènerait l'utilisateur à l'écran de départ.
final routeurProvider = Provider<GoRouter>((ref) {
  // Le routeur est créé une fois ; un compteur le prévient des changements
  // de session (connexion, déconnexion, jeton expiré).
  final changements = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => changements.value++);
  ref.onDispose(changements.dispose);
  return construireRouteur(connecte: () => ref.read(sessionProvider) != null, rafraichir: changements);
});

class PharmaSuite extends ConsumerWidget {
  const PharmaSuite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PharmaSuite',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: construireTheme(ref.watch(themeProvider)),
      routerConfig: ref.watch(routeurProvider),
    );
  }
}
