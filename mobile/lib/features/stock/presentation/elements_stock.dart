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
