import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/preferences/application/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lues avant la première image : l'application s'ouvre directement dans le
  // thème choisi.
  final preferences = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [preferencesLocalesProvider.overrideWithValue(preferences)],
    child: const PharmaSuite(),
  ));
}
