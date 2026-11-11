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
        const _Titre('Réapprovisionnement'),
        _Reappro(produit: p),
        const SizedBox(height: 24),
        const _Titre('Prix'),
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

/// Quatre chiffres clés : stock, CMM, couverture, stock maximum.
class _Chiffres extends ConsumerWidget {
  const _Chiffres({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i = ref.watch(indicateursProduitProvider(produit.id)).value;
    final attente = i == null;
    final couverture = i?.couverture;
    final tuiles = <_Tuile>[
      _Tuile('Stock', entier(produit.stock), 'unités'),
      _Tuile('CMM', attente ? '…' : decimal(i.cmm), 'unités par mois'),
      _Tuile(
        'Couverture',
        attente ? '…' : (couverture == null ? '—' : duree(couverture)),
        attente
            ? ''
            : couverture == null
            ? 'aucune vente'
            : i.couvertureTropLongue
            ? 'au-delà de la péremption'
            : 'stock ÷ CMJ',
        alerte: i?.couvertureTropLongue ?? false,
      ),
      _Tuile('Stock maximum', attente ? '…' : entier(i.stockMaximum), 'unités'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final parLigne = c.maxWidth >= 520 ? 4 : 2;
        final largeur = (c.maxWidth - 8 * (parLigne - 1)) / parLigne;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in tuiles)
              Container(
                key: ValueKey('tuile-${t.titre}'),
                width: largeur,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: t.alerte ? context.etats.critiqueDoux : context.schema.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.alerte ? context.etats.critique : context.couleurs.bord),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.titre, style: TextStyle(fontSize: 12, color: context.couleurs.encre2)),
                    const SizedBox(height: 4),
                    Text(
                      t.valeur,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: t.alerte ? context.etats.critique : null,
                      ),
                    ),
                    Text(
                      t.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.alerte ? context.etats.critique : context.couleurs.encre3,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tuile {
  const _Tuile(this.titre, this.valeur, this.detail, {this.alerte = false});
  final String titre, valeur, detail;
  final bool alerte;
}

/// Une ligne « libellé · valeur », avec une explication discrète.
class _Ligne extends StatelessWidget {
  const _Ligne(this.titre, this.valeur, {this.detail, this.cle});
  final String titre, valeur;
  final String? detail;
  final String? cle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: TextStyle(color: context.couleurs.encre2)),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(detail!, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valeur,
          key: cle == null ? null : ValueKey<String>(cle!),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// Carte blanche à lignes séparées.
class _Carte extends StatelessWidget {
  const _Carte(this.lignes);
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.schema.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.couleurs.bord),
    ),
    child: Column(
      children: [
        for (final (i, l) in lignes.indexed) ...[if (i > 0) const Divider(indent: 14, endIndent: 14), l],
      ],
    ),
  );
}

/// CMJ, délai de livraison, stock de sécurité, stock maximum.
class _Reappro extends ConsumerWidget {
  const _Reappro({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicateurs = ref.watch(indicateursProduitProvider(produit.id));
    return indicateurs.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (e, _) =>
          MessageErreur(erreur: e, reessayer: () => ref.invalidate(indicateursProduitProvider(produit.id))),
      data: (i) {
        final f = i.fournisseur;
        final livraison = i.dateLivraison;
        final jours = '${i.delaiLivraison} jour${i.delaiLivraison > 1 ? 's' : ''}';
        final classe = produit.classeAbc;
        final service = switch (classe) {
          'A' => '95 %',
          'C' => '85 %',
          _ => '90 %',
        };
        final seuil = produit.seuil;
        return _Carte([
          _Ligne(
            'Consommation journalière (CMJ)',
            '${decimal(i.cmj, chiffres: 2)} / jour',
            detail: i.moisHistorique < 12
                ? 'CMM ÷ 30, sur ${i.moisHistorique} mois de ventes'
                : 'CMM ÷ 30, ventes des 12 derniers mois',
            cle: 'cmj',
          ),
          _Ligne(
            'Délai de livraison',
            jours,
            detail: [
              f?.nom ?? 'Fournisseur inconnu',
              if (livraison != null) 'commande du jour livrée ${jourEtDate(livraison)}',
              if (f != null && !f.delaiSaisi) 'délai par défaut',
            ].join(' · '),
            cle: 'delai',
          ),
          _Ligne(
            'Stock de sécurité',
            entier(i.stockSecurite),
            detail:
                'Z × σ × √L, ${classe == null ? 'non classé' : 'classe $classe'}, $service de service'
                ' · simple (CMJ × ${decimal(i.delaiSecurite)} j) : ${entier(i.stockSecuriteSimple)}',
            cle: 'ss',
          ),
          _Ligne(
            'Stock maximum',
            entier(i.stockMaximum),
            detail: 'SS + CMM × ${decimal(i.periodeCommande)} jours entre deux commandes',
          ),
          _Ligne(
            "Seuil d'alerte EASYPHARM",
            seuil == null || seuil == 0 ? '—' : entier(seuil),
            detail: seuil == null || seuil == 0 ? 'non défini dans EASYPHARM' : null,
          ),
          _Ligne('Vendu sur 12 mois', entier(i.ventes12Mois), detail: 'quantité nette, retours déduits'),
        ]);
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
    return _Carte([for (final (i, (titre, valeur)) in lignes.indexed) _Ligne(titre, valeur, cle: 'prix-$i')]);
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
    final indicateurs = ref.watch(indicateursProduitProvider(widget.id)).value;
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
        if (indicateurs != null && indicateurs.qteARisque > 0) _BandeauRisque(indicateurs),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LigneLot(l, risque: indicateurs?.risque(l.id)),
                      ),
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

/// Quantité qui périmera avant d'être vendue, et ce qu'il faut faire.
class _BandeauRisque extends StatelessWidget {
  const _BandeauRisque(this.indicateurs);
  final IndicateursProduit indicateurs;

  @override
  Widget build(BuildContext context) {
    final e = context.etats;
    final q = indicateurs.qteARisque;
    return Container(
      key: const ValueKey('bandeau-risque'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: e.critiqueDoux,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: e.critique.withValues(alpha: .5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_bottom_rounded, color: e.critique),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entier(q)} unité${q > 1 ? 's' : ''} risque${q > 1 ? 'nt' : ''} de périmer avant d\'être '
                  'vendue${q > 1 ? 's' : ''} · ${dinars(indicateurs.valeurARisque)}',
                  style: TextStyle(color: e.critique, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'À traiter maintenant : retour fournisseur, échange avec une autre pharmacie '
                  'ou mise en avant.',
                  style: TextStyle(color: e.critique, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneLot extends StatelessWidget {
  const _LigneLot(this.lot, {this.risque});
  final Lot lot;
  final RisqueLot? risque;

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
                  if (!epuise && risque?.ecoulable != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      (risque!.aRisque ?? 0) > 0
                          ? '${entier(risque!.aRisque!)} à risque · ${entier(risque!.ecoulable!)} écoulables '
                                'en ${entier(risque!.dvr ?? 0)} j'
                          : 'Écoulé avant péremption (${entier(risque!.dvr ?? 0)} j restants)',
                      key: ValueKey('risque-lot-${lot.id}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (risque!.aRisque ?? 0) > 0 ? context.etats.critique : context.couleurs.encre2,
                      ),
                    ),
                  ],
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
