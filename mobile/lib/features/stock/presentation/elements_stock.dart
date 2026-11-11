import 'package:flutter/material.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/pastille_etat.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/format.dart';
import '../../../domain/stock.dart';

/// Pastille de l'état de stock : mêmes couleurs et mêmes mots partout.
class PastilleStock extends StatelessWidget {
  const PastilleStock({super.key, required this.produit, this.avecQuantite = true});

  final Produit produit;
  final bool avecQuantite;

  @override
  Widget build(BuildContext context) {
    final q = entier(produit.stock);
    final (niveau, texte, icone) = switch (produit.etat) {
      EtatStock.enStock => (NiveauEtat.bon, avecQuantite ? '$q en stock' : 'En stock', null),
      EtatStock.sousSeuil => (
        NiveauEtat.alerte,
        avecQuantite ? '$q · sous le seuil' : 'Sous le seuil',
        Icons.trending_down,
      ),
      EtatStock.rupture => (NiveauEtat.critique, 'Rupture', null),
      EtatStock.quota => (
        NiveauEtat.alerte,
        avecQuantite ? '$q · quota' : 'Quota',
        Icons.lock_clock_outlined,
      ),
      EtatStock.inactif => (NiveauEtat.neutre, 'Inactif', null),
    };
    return PastilleEtat(niveau: niveau, libelle: texte, icone: icone);
  }
}

/// Petite étiquette discrète : classe ABC, psychotrope, famille…
class Etiquette extends StatelessWidget {
  const Etiquette(this.texte, {super.key, this.icone, this.accent = false});

  final String texte;
  final IconData? icone;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final couleur = accent ? context.schema.onPrimaryContainer : context.couleurs.encre2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? context.schema.primaryContainer : context.couleurs.neutreDoux,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[Icon(icone, size: 13, color: couleur), const SizedBox(width: 4)],
          Text(
            texte,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: couleur),
          ),
        ],
      ),
    );
  }
}

/// Classe ABC (et XYZ) d'un produit, ou rien s'il n'est pas classé.
class EtiquetteClasse extends StatelessWidget {
  const EtiquetteClasse(this.produit, {super.key});
  final Produit produit;

  @override
  Widget build(BuildContext context) {
    final abc = produit.classeAbc;
    if (abc == null || abc.isEmpty) return const SizedBox.shrink();
    final xyz = produit.classeXyz;
    return Tooltip(
      message: 'Classe $abc${xyz != null ? ' · régularité $xyz' : ''}',
      child: Etiquette('$abc${xyz ?? ''}', accent: abc == 'A'),
    );
  }
}

/// État d'erreur : message et bouton « Réessayer ».
class MessageErreur extends StatelessWidget {
  const MessageErreur({super.key, required this.erreur, required this.reessayer});

  final Object erreur;
  final VoidCallback reessayer;

  @override
  Widget build(BuildContext context) {
    final e = ErreurApi.depuis(erreur);
    return _Centre(
      icone: e.reseau ? Icons.wifi_off_rounded : Icons.error_outline,
      couleur: context.etats.critique,
      fond: context.etats.critiqueDoux,
      titre: e.reseau ? 'Hors connexion' : 'Chargement impossible',
      texte: e.message,
      action: FilledButton.tonalIcon(
        key: const ValueKey('bouton-reessayer'),
        onPressed: reessayer,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
      ),
    );
  }
}

/// État vide.
class MessageVide extends StatelessWidget {
  const MessageVide({super.key, required this.titre, required this.texte, this.action});

  final String titre, texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _Centre(
    icone: Icons.search_off_rounded,
    couleur: context.schema.onPrimaryContainer,
    fond: context.schema.primaryContainer,
    titre: titre,
    texte: texte,
    action: action,
  );
}

class _Centre extends StatelessWidget {
  const _Centre({
    required this.icone,
    required this.couleur,
    required this.fond,
    required this.titre,
    required this.texte,
    this.action,
  });

  final IconData icone;
  final Color couleur, fond;
  final String titre, texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
          child: Icon(icone, size: 30, color: couleur),
        ),
        const SizedBox(height: 14),
        Text(
          titre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            texte,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.couleurs.encre2),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

/// Bloc gris animé à la place d'un texte pendant le chargement.
class Squelette extends StatelessWidget {
  const Squelette({super.key, required this.largeur, this.hauteur = 12});
  final double largeur, hauteur;

  @override
  Widget build(BuildContext context) => Container(
    width: largeur,
    height: hauteur,
    decoration: BoxDecoration(color: context.couleurs.neutreDoux, borderRadius: BorderRadius.circular(6)),
  );
}

// ── Familles ────────────────────────────────────────────────────────────────

/// Couleur et icône d'une famille, par son id EASYPHARM (`familles.id`).
/// Simple habillage : une famille inconnue prend l'icône par défaut, la liste
/// elle-même vient toujours de la base.
({Color couleur, IconData icone}) visuelFamille(int? id) => switch (id) {
  1 => (couleur: const Color(0xFF1F5FBF), icone: Icons.medication_outlined),
  3 => (couleur: const Color(0xFFC2417A), icone: Icons.water_drop_outlined),
  4 => (couleur: const Color(0xFFB26A00), icone: Icons.baby_changing_station_outlined),
  9 => (couleur: const Color(0xFF2E8B57), icone: Icons.eco_outlined),
  10 => (couleur: const Color(0xFF7A4DD1), icone: Icons.spa_outlined),
  11 => (couleur: const Color(0xFF0B7A8C), icone: Icons.soap_outlined),
  12 => (couleur: const Color(0xFF5B6B7A), icone: Icons.accessible_outlined),
  13 => (couleur: const Color(0xFF0E8A9A), icone: Icons.brush_outlined),
  15 => (couleur: const Color(0xFFD2556B), icone: Icons.child_friendly_outlined),
  _ => (couleur: const Color(0xFF5B6B7A), icone: Icons.inventory_2_outlined),
};

class IconeFamille extends StatelessWidget {
  const IconeFamille(this.idFamille, {super.key, this.taille = 40});
  final int? idFamille;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final v = visuelFamille(idFamille);
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final couleur = sombre ? Color.lerp(v.couleur, Colors.white, .35)! : v.couleur;
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: v.couleur.withValues(alpha: sombre ? .22 : .11),
        borderRadius: BorderRadius.circular(taille * .3),
      ),
      child: Icon(v.icone, size: taille * .55, color: couleur),
    );
  }
}

// ── Signaux ─────────────────────────────────────────────────────────────────

/// Couleur de texte et de fond d'un signal, dans le thème courant.
({Color texte, Color fond}) couleursSignal(BuildContext context, Signal s) {
  final e = context.etats;
  final sombre = Theme.of(context).brightness == Brightness.dark;
  final violet = sombre ? const Color(0xFFC3A8F5) : const Color(0xFF6B3FC4);
  return switch (s) {
    Signal.rupture => (texte: e.critique, fond: e.critiqueDoux),
    Signal.sousSeuil => (texte: e.alerte, fond: e.alerteDoux),
    Signal.risque => (texte: violet, fond: violet.withValues(alpha: sombre ? .18 : .1)),
    Signal.surstock || Signal.inactif => (texte: context.couleurs.encre2, fond: context.couleurs.neutreDoux),
    Signal.ok => (texte: e.bon, fond: e.bonDoux),
  };
}

String libelleSignal(Signal s) => switch (s) {
  Signal.rupture => 'Rupture',
  Signal.sousSeuil => 'Sous le seuil',
  Signal.risque => 'Péremption à risque',
  Signal.surstock => 'Surstock',
  Signal.inactif => 'Inactif',
  Signal.ok => 'En stock',
};

IconData iconeSignal(Signal s) => switch (s) {
  Signal.rupture => Icons.remove_circle_outline,
  Signal.sousSeuil => Icons.trending_down,
  Signal.risque => Icons.hourglass_bottom_rounded,
  Signal.surstock => Icons.layers_outlined,
  Signal.inactif => Icons.remove,
  Signal.ok => Icons.check_circle_outline,
};

/// Pastille d'état : couleur, icône et libellé, jamais la couleur seule.
class PastilleSignal extends StatelessWidget {
  const PastilleSignal(this.signal, {super.key});
  final Signal signal;

  @override
  Widget build(BuildContext context) {
    final c = couleursSignal(context, signal);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(color: c.fond, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconeSignal(signal), size: 14, color: c.texte),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              libelleSignal(signal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.texte, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jauge du stock : remplie jusqu'au stock, sur une échelle qui va jusqu'au
/// stock maximum ; un trait marque le stock de sécurité.
class JaugeStock extends StatelessWidget {
  const JaugeStock({super.key, required this.produit, this.legende = true});
  final Produit produit;
  final bool legende;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final echelle = [p.stockMaximum.toDouble(), p.stock, 1.0].reduce((a, b) => a > b ? a : b);
    final rempli = (p.stock / echelle).clamp(0.0, 1.0);
    final securite = (p.stockSecurite / echelle).clamp(0.0, 1.0);
    final c = couleursSignal(context, p.signal).texte;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (legende)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Text.rich(
                  maxLines: 1,
                  TextSpan(
                    children: [
                      TextSpan(
                        text: entier(p.stock),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      TextSpan(
                        text: ' u',
                        style: TextStyle(color: context.couleurs.encre3, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.stockMaximum > 0 ? 'max ${entier(p.stockMaximum)}' : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: context.couleurs.encre3, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 6,
          child: LayoutBuilder(
            builder: (context, c2) => Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.couleurs.neutreDoux,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: c2.maxWidth * rempli,
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
                ),
                if (p.stockSecurite > 0)
                  Positioned(
                    left: (c2.maxWidth * securite - 1).clamp(0, c2.maxWidth - 2),
                    top: -3,
                    bottom: -3,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: context.couleurs.encre3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
