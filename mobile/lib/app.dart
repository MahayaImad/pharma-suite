import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/routeur.dart';
import 'core/theme/themes.dart';
import 'features/preferences/application/theme_controller.dart';

/// Le routeur vit aussi longtemps que l'application : le recréer à chaque
/// changement de thème ramènerait l'utilisateur à l'écran de départ.
final routeurProvider = Provider<GoRouter>((ref) => construireRouteur());

class PharmaSuite extends ConsumerWidget {
  const PharmaSuite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PharmaSuite',
      debugShowCheckedModeBanner: false,
      theme: construireTheme(ref.watch(themeProvider)),
      routerConfig: ref.watch(routeurProvider),
    );
  }
}
