import 'package:flutter/material.dart';

import '../theme/themes.dart';
import 'coquille.dart';

/// État vide d'une section qui n'est pas encore construite.
class EcranAVenir extends StatelessWidget {
  const EcranAVenir({super.key, required this.titre, required this.icone, required this.description});

  final String titre;
  final IconData icone;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titre), actions: const [BoutonPreferences(), SizedBox(width: 4)]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: context.schema.primaryContainer, shape: BoxShape.circle),
              child: Icon(icone, size: 34, color: context.schema.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text('Bientôt disponible',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(description,
                  textAlign: TextAlign.center, style: TextStyle(color: context.couleurs.encre2)),
            ),
          ]),
        ),
      ),
    );
  }
}
