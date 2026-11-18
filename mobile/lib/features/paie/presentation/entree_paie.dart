import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';

/// Entrée « Paie » des Préférences (titulaire) : seul accès à la paie sur portable.
class EntreePaie extends StatelessWidget {
  const EntreePaie({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: context.schema.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: context.couleurs.bord),
    ),
    child: InkWell(
      key: const ValueKey('entree-paie'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/paie'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.schema.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.payments_outlined, color: context.schema.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    'Salaire brut du mois, primes et bulletins',
                    style: TextStyle(color: context.couleurs.encre2, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.couleurs.encre3),
          ],
        ),
      ),
    ),
  );
}
