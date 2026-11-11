import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/pastille_etat.dart';
import '../../../domain/format.dart';
import '../../../domain/stock.dart';
import '../application/stock_providers.dart';
import 'elements_stock.dart';

/// Fiche d'un produit : chiffres clés, prix et lots.
///
/// [enPanneau] : affichée à côté de la liste (grand écran), avec un bouton
/// « fermer » au lieu du retour.
class FicheProduit extends ConsumerWidget {
  const FicheProduit({super.key, required this.id, this.enPanneau = false});

  final int id;
  final bool enPanneau;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiche = ref.watch(ficheProduitProvider(id));
    void fermer() => context.go('/stock');

    return Scaffold(
      backgroundColor: enPanneau ? context.schema.surface : null,
      appBar: AppBar(
        backgroundColor: enPanneau ? context.schema.surface : null,
        automaticallyImplyLeading: false,
        leading: enPanneau
            ? null
            : IconButton(tooltip: 'Retour', icon: const Icon(Icons.arrow_back_rounded), onPressed: fermer),
        title: Text(enPanneau ? 'Fiche produit' : '', style: const TextStyle(fontSize: 16)),
        actions: [
          if (enPanneau)
            IconButton(tooltip: 'Fermer', icon: const Icon(Icons.close_rounded), onPressed: fermer),
          const SizedBox(width: 4),
        ],
      ),
      body: fiche.when(
        data: (p) => _Contenu(produit: p),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: MessageErreur(erreur: e, reessayer: () => ref.invalidate(ficheProduitProvider(id))),
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final sousTitre = [p.dci, p.labo].where((t) => t != null && t.trim().isNotEmpty).join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        if (p.famille != null && p.famille!.isNotEmpty)
          Text(
            libelle(p.famille!).toUpperCase(),
            style: TextStyle(
              color: context.schema.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          p.designation,
          style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, height: 1.25),
        ),
        if (sousTitre.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(sousTitre, style: TextStyle(color: context.couleurs.encre2, fontSize: 14)),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PastilleStock(produit: p, avecQuantite: false),
            EtiquetteClasse(p),
            if (p.psychotrope == 1) const Etiquette('Psychotrope', icone: Icons.gpp_maybe_outlined),
            if (p.remboursable == 1) const Etiquette('Remboursable', icone: Icons.verified_outlined),
            if (p.categorie != null && p.categorie!.isNotEmpty) Etiquette(libelle(p.categorie!)),
          ],
        ),
        const SizedBox(height: 20),
        _Chiffres(produit: p),
        const SizedBox(height: 24),
        _Titre('Prix'),
        _Prix(produit: p),
        const SizedBox(height: 24),
        _Lots(id: p.id),
        if (p.codeBarre != null && p.codeBarre!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 18, color: context.couleurs.encre3),
              const SizedBox(width: 6),
              SelectableText(p.codeBarre!, style: TextStyle(color: context.couleurs.encre2, fontSize: 13)),
            ],
          ),
        ],
      ],
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte, {this.fin});
  final String texte;
  final Widget? fin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(texte, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        ?fin,
      ],
    ),
  );
}

/// Stock, seuil, vendu sur 12 mois, couverture.
class _Chiffres extends StatelessWidget {
  const _Chiffres({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final couverture = couvertureJours(p.stock, p.vendu12Mois);
    final tuiles = [
      ('Stock', entier(p.stock), 'unités'),
      (
        "Seuil d'alerte",
        p.seuil == null || p.seuil == 0 ? '—' : entier(p.seuil!),
        p.seuil == null || p.seuil == 0 ? 'non défini' : 'unités',
      ),
      ('Vendu', entier(p.vendu12Mois ?? 0), 'sur 12 mois'),
      (
        'Couverture',
        couverture == null ? '—' : duree(couverture),
        couverture == null ? 'aucune vente' : 'au rythme actuel',
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final parLigne = c.maxWidth >= 520 ? 4 : 2;
        final largeur = (c.maxWidth - 8 * (parLigne - 1)) / parLigne;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (titre, valeur, unite) in tuiles)
              Container(
                width: largeur,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: context.schema.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.couleurs.bord),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: TextStyle(fontSize: 12, color: context.couleurs.encre2)),
                    const SizedBox(height: 4),
                    Text(
                      valeur,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text(unite, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Prix extends StatelessWidget {
  const _Prix({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final taux = tauxMarge(p.prixVente, p.prixAchat);
    String ou(double v, String Function(double) f) => v > 0 ? f(v) : '—';
    final lignes = [
      ('Prix de vente', ou(p.prixVente, dinars)),
      ("Prix d'achat moyen", ou(p.prixAchat, dinars)),
      ('Marge', taux == null ? '—' : '${dinars(p.prixVente - p.prixAchat)}  ·  ${pourcent(taux)}'),
      ('Valeur du stock (achat)', dinars(p.valeurAchat)),
      ('Valeur du stock (vente)', dinars(p.valeurVente)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.schema.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.couleurs.bord),
      ),
      child: Column(
        children: [
          for (final (i, (titre, valeur)) in lignes.indexed) ...[
            if (i > 0) const Divider(indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(titre, style: TextStyle(color: context.couleurs.encre2)),
                  ),
                  Text(
                    valeur,
                    key: ValueKey('prix-$i'),
                    style: TextStyle(fontWeight: i == 2 ? FontWeight.w700 : FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lots, du plus proche de la péremption au plus lointain.
class _Lots extends ConsumerStatefulWidget {
  const _Lots({required this.id});
  final int id;

  @override
  ConsumerState<_Lots> createState() => _LotsState();
}

class _LotsState extends ConsumerState<_Lots> {
  bool _epuises = false;

  @override
  Widget build(BuildContext context) {
    final cle = (id: widget.id, epuises: _epuises);
    final lots = ref.watch(lotsProduitProvider(cle));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Titre(
          'Lots',
          fin: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lots épuisés', style: TextStyle(fontSize: 13, color: context.couleurs.encre2)),
              Switch(
                key: const ValueKey('lots-epuises'),
                value: _epuises,
                onChanged: (v) => setState(() => _epuises = v),
              ),
            ],
          ),
        ),
        lots.when(
          data: (liste) => liste.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _epuises ? 'Aucun lot enregistré.' : 'Aucun lot en stock.',
                    style: TextStyle(color: context.couleurs.encre2),
                  ),
                )
              : Column(
                  children: [
                    for (final l in liste)
                      Padding(padding: const EdgeInsets.only(bottom: 8), child: _LigneLot(l)),
                  ],
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
          error: (e, _) =>
              MessageErreur(erreur: e, reessayer: () => ref.invalidate(lotsProduitProvider(cle))),
        ),
      ],
    );
  }
}

class _LigneLot extends StatelessWidget {
  const _LigneLot(this.lot);
  final Lot lot;

  @override
  Widget build(BuildContext context) {
    final etat = etatPeremption(lot.peremptionDate, DateTime.now());
    final (niveau, texte) = switch (etat) {
      EtatPeremption.perime => (NiveauEtat.critique, 'Périmé'),
      EtatPeremption.proche => (NiveauEtat.alerte, 'Moins de 3 mois'),
      EtatPeremption.bonne => (NiveauEtat.bon, 'Bonne'),
      EtatPeremption.inconnue => (NiveauEtat.alerte, 'Sans date'),
    };
    final details = [
      if (lot.fournisseur != null && lot.fournisseur!.isNotEmpty) lot.fournisseur!,
      if (lot.dateEntree != null) 'entré le ${date(lot.dateEntree!)}',
      if (lot.numBl != null && lot.numBl!.isNotEmpty) 'BL ${lot.numBl}',
    ].join(' · ');
    final epuise = lot.stock <= 0;

    return Opacity(
      opacity: epuise ? .6 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: context.schema.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.couleurs.bord),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.peremption?.isNotEmpty == true ? lot.peremption! : '—',
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  Text('péremption', style: TextStyle(fontSize: 11, color: context.couleurs.encre3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Lot ${lot.lot?.isNotEmpty == true ? lot.lot : '—'}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (lot.bloque) ...[
                        const SizedBox(width: 6),
                        const Etiquette('Bloqué', icone: Icons.block),
                      ],
                    ],
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.couleurs.encre2),
                    ),
                  const SizedBox(height: 6),
                  if (!epuise) PastilleEtat(niveau: niveau, libelle: texte),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entier(lot.stock),
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  epuise ? 'épuisé' : 'unités',
                  style: TextStyle(fontSize: 11, color: context.couleurs.encre3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
