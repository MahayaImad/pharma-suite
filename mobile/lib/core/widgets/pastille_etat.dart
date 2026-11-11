import 'package:flutter/material.dart';

import '../theme/themes.dart';

enum NiveauEtat { critique, alerte, bon }

/// Étiquette d'état : une couleur, toujours accompagnée d'une icône et d'un
/// libellé — la couleur seule ne porte jamais le sens.
class PastilleEtat extends StatelessWidget {
  const PastilleEtat({super.key, required this.niveau, required this.libelle});

  final NiveauEtat niveau;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    final e = context.etats;
    final (texte, fond, icone) = switch (niveau) {
      NiveauEtat.critique => (e.critique, e.critiqueDoux, Icons.remove_circle_outline),
      NiveauEtat.alerte => (e.alerte, e.alerteDoux, Icons.schedule),
      NiveauEtat.bon => (e.bon, e.bonDoux, Icons.check_circle_outline),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 15, color: texte),
        const SizedBox(width: 5),
        Text(libelle, style: TextStyle(color: texte, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
