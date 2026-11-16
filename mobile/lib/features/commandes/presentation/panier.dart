import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/themes.dart';
import '../../../data/api/client_api.dart';
import '../../../data/api/commandes_api.dart';
import '../../../data/api/stock_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../../domain/stock.dart';
import '../../stock/presentation/ecran_stock.dart' show nomLisible;
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/commandes_providers.dart';
import 'ecran_commandes.dart';

/// Panier d'un fournisseur (design « épuré », 2026-11-15) : en-tête avec le
/// total, filtres rapides, une ligne par produit (raison du calcul, jauge,
/// − / +, montant, ⇄ génériques, poignée pour glisser vers un autre
/// grossiste sur PC), et en bas une barre fixe avec le total et l'action de
/// l'étape. Une proposition devient brouillon au premier geste.
class PanierFournisseur extends ConsumerWidget {
  const PanierFournisseur({super.key, required this.idFournisseur, this.enPanneau = false});

  final int idFournisseur;

  /// À côté de la liste (PC) : pas de barre de titre avec retour.
  final bool enPanneau;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journee = ref.watch(journeeProvider);
    final panier = journee.value?.panier(idFournisseur);
    return Scaffold(
      backgroundColor: context.schema.surface,
      appBar: enPanneau
          ? null
          : AppBar(
              backgroundColor: context.schema.surface,
              leading: IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/commandes'),
              ),
              title: Text(libelleProduit(panier?.fournisseur.nom ?? 'Panier')),
              actions: [if (panier != null) _MenuPanier(panier: panier)],
            ),
      body: journee.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(journeeProvider)),
        data: (j) => panier == null
            ? MessageVide(
                titre: 'Rien chez ce fournisseur',
                texte: 'Aucune ligne à commander chez lui ce soir.',
                action: OutlinedButton(onPressed: () => context.go('/commandes'), child: const Text('Retour')),
              )
            : _Contenu(key: ValueKey(idFournisseur), panier: panier, enPanneau: enPanneau),
      ),
      bottomNavigationBar: panier == null || journee.value == null
          ? null
          : _BarreTotal(panier: panier, journee: journee.value!),
    );
  }
}

enum _Filtre {
  tout('Tout'),
  ruptures('Ruptures'),
  modifiees('Modifiées'),
  generiques('Génériques');

  const _Filtre(this.libelle);
  final String libelle;

  bool garde(LigneCommande l) => switch (this) {
    _Filtre.tout => true,
    _Filtre.ruptures => l.rupture,
    _Filtre.modifiees => l.modifiee,
    _Filtre.generiques => l.codeDci != null,
  };
}

class _Contenu extends ConsumerStatefulWidget {
  const _Contenu({super.key, required this.panier, required this.enPanneau});
  final Panier panier;
  final bool enPanneau;

  @override
  ConsumerState<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends ConsumerState<_Contenu> {
  _Filtre _filtre = _Filtre.tout;

  @override
  Widget build(BuildContext context) {
    final p = widget.panier;
    final large = widget.enPanneau;
    final lignes = [
      for (final l in p.lignes)
        if (_filtre.garde(l)) l,
    ];
    final marge = large ? 28.0 : 16.0;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(marge, large ? 20 : 6, large ? 16 : marge, 12),
          child: Row(
            children: [
              if (large) ...[InitialeFournisseur(fournisseur: p.fournisseur, taille: 44), const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (large)
                      Text(
                        libelleProduit(p.fournisseur.nom ?? 'Fournisseur ${p.fournisseur.id}'),
                        style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 21),
                      ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PastilleEtape(p.etape),
                        if (p.livraisonPrevue != null)
                          Text(
                            'livraison ${jourEtDate(p.livraisonPrevue!)}',
                            style: TextStyle(color: context.couleurs.encre3, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dinars(p.montant.round()),
                      style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: large ? 22 : 18),
                    ),
                    Text(
                      [
                        '${p.nbLignes} ligne${p.nbLignes > 1 ? 's' : ''}',
                        '${entier(p.boites)} boîtes',
                        if (p.ruptures > 0) '${p.ruptures} rupture${p.ruptures > 1 ? 's' : ''}',
                      ].join(' · '),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                    ),
                  ],
                ),
              ),
              if (large) _MenuPanier(panier: p),
            ],
          ),
        ),
        Divider(height: 1, color: context.couleurs.bord),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(marge, 12, marge, 6),
          child: Row(
            children: [
              for (final f in _Filtre.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _Puce(
                    cle: 'filtre-${f.name}',
                    texte: '${f.libelle} (${p.lignes.where(f.garde).length})',
                    choisie: _filtre == f,
                    surAppui: () => setState(() => _filtre = f),
                  ),
                ),
            ],
          ),
        ),
        if (p.etape == EtapePanier.validee)
          Padding(
            padding: EdgeInsets.fromLTRB(marge, 6, marge, 0),
            child: Text(
              'Validée${p.commande?.validePar != null ? ' par ${p.commande!.validePar}' : ''}. '
              'Pour la corriger, rouvrez-la (menu ⋮).',
              style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
            ),
          ),
        if (lignes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text('Aucune ligne.', style: TextStyle(color: context.couleurs.encre3)),
            ),
          ),
        for (final l in lignes) LigneDuPanier(panier: p, ligne: l, large: large),
        if (p.modifiable)
          Padding(
            padding: EdgeInsets.fromLTRB(marge - 8, 10, marge, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('bouton-ajouter-produit'),
                onPressed: () => _ajouterProduit(context, ref, p),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un produit'),
              ),
            ),
          ),
      ],
    );
  }
}

class _Puce extends StatelessWidget {
  const _Puce({required this.cle, required this.texte, required this.choisie, required this.surAppui});
  final String cle, texte;
  final bool choisie;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) => Material(
    color: choisie ? context.schema.onSurface : context.couleurs.neutreDoux,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      key: ValueKey(cle),
      borderRadius: BorderRadius.circular(999),
      onTap: surAppui,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(
          texte,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: choisie ? context.schema.surface : context.couleurs.encre2,
          ),
        ),
      ),
    ),
  );
}

// ── Une ligne ───────────────────────────────────────────────────────────────

class LigneDuPanier extends ConsumerWidget {
  const LigneDuPanier({super.key, required this.panier, required this.ligne, this.large = false});
  final Panier panier;
  final LigneCommande ligne;
  final bool large;

  Future<void> _changer(BuildContext context, WidgetRef ref, int qte) async {
    try {
      await ref.read(journeeProvider.notifier).modifier(panier, ligne, qte);
    } catch (e) {
      if (context.mounted) montrerErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ligne;
    final modifiable = panier.modifiable;
    final nom = Row(
      children: [
        if (l.rupture)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Tooltip(
              message: 'Rupture',
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: context.etats.critique, shape: BoxShape.circle),
              ),
            ),
          ),
        Flexible(
          child: Text(
            libelleProduit(l.nom ?? 'Produit ${l.idNom}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        if (l.enTension)
          Container(
            key: ValueKey('quota-${l.idNom}'),
            margin: const EdgeInsets.only(left: 7),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: context.etats.alerteDoux, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Quota',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.etats.alerte),
            ),
          ),
      ],
    );
    final raison = Text.rich(
      TextSpan(
        text: l.explication,
        children: [
          if (l.modifiee && !l.ajoutManuel)
            TextSpan(
              text: ' · modifié (proposé ${l.qteProposee})',
              style: TextStyle(color: context.etats.alerte, fontWeight: FontWeight.w700),
            ),
        ],
      ),
      maxLines: large ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
    );
    final quantite = modifiable
        ? Pas(cle: 'pas-${l.idNom}', valeur: l.qte, surChangement: (q) => _changer(context, ref, q))
        : SizedBox(
            width: 40,
            child: Text(
              '${l.qte}',
              key: ValueKey('qte-${l.idNom}'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          );

    final rangee = InkWell(
      key: ValueKey('ligne-${l.idNom}'),
      onTap: () => _actionsLigne(context, ref, panier, l),
      child: Container(
        padding: EdgeInsets.fromLTRB(large ? 14 : 16, 10, large ? 18 : 16, 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.couleurs.neutreDoux)),
        ),
        child: Row(
          children: [
            if (large)
              SizedBox(
                width: 22,
                child: modifiable ? _Poignee(panier: panier, ligne: l) : null,
              ),
            if (large) const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [nom, const SizedBox(height: 2), raison],
              ),
            ),
            if (large) ...[const SizedBox(width: 12), SizedBox(width: 80, child: JaugeCommande(ligne: l))],
            const SizedBox(width: 12),
            quantite,
            if (large) ...[
              SizedBox(
                width: 92,
                child: Text(
                  dinars(l.montant.round()),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, color: context.couleurs.encre2),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 34,
                child: l.codeDci != null && modifiable ? BoutonGeneriques(panier: panier, ligne: l) : null,
              ),
            ],
          ],
        ),
      ),
    );
    return rangee;
  }
}

/// Poignée ⋮⋮ : glisser la ligne sur un autre grossiste de la colonne de gauche.
class _Poignee extends StatelessWidget {
  const _Poignee({required this.panier, required this.ligne});
  final Panier panier;
  final LigneCommande ligne;

  @override
  Widget build(BuildContext context) {
    final fantome = Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: context.schema.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.schema.primary, width: 1.5),
        ),
        child: Text(
          '${libelleProduit(ligne.nom ?? '')} · ${ligne.qte}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
    return Draggable<LigneTiree>(
      key: ValueKey('poignee-${ligne.idNom}'),
      data: (ligne: ligne, de: panier.fournisseur.id),
      feedback: fantome,
      childWhenDragging: Icon(Icons.drag_indicator, size: 18, color: context.schema.primary),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Tooltip(
          message: 'Glisser vers un autre grossiste',
          child: Icon(Icons.drag_indicator, size: 18, color: context.couleurs.encre3),
        ),
      ),
    );
  }
}

/// Remplace [ligne] par le générique [m], avec un message (ou l'erreur).
Future<void> _remplacerPar(
  BuildContext context,
  WidgetRef ref,
  Panier panier,
  LigneCommande ligne,
  MembreGenerique m,
) async {
  try {
    await ref.read(journeeProvider.notifier).remplacer(panier, ligne, m.idNom);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${libelleProduit(ligne.nom ?? '')} remplacé par ${libelleProduit(m.nom ?? '')}.')),
        );
    }
  } catch (e) {
    if (context.mounted) montrerErreur(context, e);
  }
}

/// ⇄ : les autres génériques de la même DCI, pour remplacer la ligne.
class BoutonGeneriques extends ConsumerStatefulWidget {
  const BoutonGeneriques({super.key, required this.panier, required this.ligne});
  final Panier panier;
  final LigneCommande ligne;

  @override
  ConsumerState<BoutonGeneriques> createState() => _BoutonGeneriquesState();
}

class _BoutonGeneriquesState extends ConsumerState<BoutonGeneriques> {
  final _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final ligne = widget.ligne;
    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(-280, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(context.schema.surface),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      ),
      menuChildren: [
        SizedBox(
          width: 320,
          child: Consumer(
            builder: (_, ref, _) => _GeneriquesDe(
              ligne: ligne,
              surChoix: (m) {
                _menu.close();
                _remplacerPar(context, ref, widget.panier, ligne, m);
              },
            ),
          ),
        ),
      ],
      builder: (context, menu, _) => IconButton(
        key: ValueKey('generiques-${ligne.idNom}'),
        tooltip: 'Changer de générique',
        visualDensity: VisualDensity.compact,
        isSelected: menu.isOpen,
        icon: Icon(Icons.swap_horiz_rounded, size: 20, color: context.couleurs.encre3),
        selectedIcon: Icon(Icons.swap_horiz_rounded, size: 20, color: context.schema.primary),
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}

/// Liste des autres génériques de la DCI de [ligne] (chargée à l'ouverture).
class _GeneriquesDe extends ConsumerWidget {
  const _GeneriquesDe({required this.ligne, required this.surChoix});
  final LigneCommande ligne;
  final ValueChanged<MembreGenerique> surChoix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(generiquesProvider(ligne.idNom))
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
          error: (e, _) => Padding(padding: const EdgeInsets.all(14), child: Text(ErreurApi.depuis(e).message)),
          data: (g) {
            final autres = [
              for (final m in g.membres)
                if (m.idNom != ligne.idNom) m,
            ];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Text(
                    'AUTRES GÉNÉRIQUES${g.code != null ? ' · ${g.code}' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: context.couleurs.encre3,
                    ),
                  ),
                ),
                if (autres.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    child: Text('Aucun autre générique actif.', style: TextStyle(color: context.couleurs.encre2)),
                  ),
                for (final m in autres)
                  InkWell(
                    key: ValueKey('remplacer-par-${m.idNom}'),
                    onTap: () => surChoix(m),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            libelleProduit(m.nom ?? 'Produit ${m.idNom}'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            [
                              m.garde ? 'gardé' : 'non recommandé',
                              '${entier(m.ventes12m)} vendus / an',
                              'stock ${entier(m.stock)}',
                            ].join(' · '),
                            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
            );
          },
        );
  }
}

/// Actions d'une ligne (appui sur la ligne ; seul accès sur portable) :
/// changer de générique, changer de grossiste, retirer.
Future<void> _actionsLigne(BuildContext context, WidgetRef ref, Panier panier, LigneCommande ligne) async {
  final choix = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
            child: Text(
              libelleProduit(ligne.nom ?? ''),
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              '${ligne.qte} boîte${ligne.qte > 1 ? 's' : ''} · ${libelleProduit(panier.fournisseur.nom ?? '')}',
              style: TextStyle(fontSize: 12, color: c.couleurs.encre3),
            ),
          ),
          ListTile(
            key: const ValueKey('action-ligne-calcul'),
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Pourquoi cette quantité ?'),
            onTap: () => Navigator.pop(c, 'calcul'),
          ),
          if (panier.modifiable && ligne.codeDci != null)
            ListTile(
              key: const ValueKey('action-ligne-generique'),
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Changer de générique'),
              onTap: () => Navigator.pop(c, 'generique'),
            ),
          if (panier.modifiable) ...[
            ListTile(
              key: const ValueKey('action-ligne-grossiste'),
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Changer de grossiste'),
              onTap: () => Navigator.pop(c, 'grossiste'),
            ),
            ListTile(
              key: const ValueKey('action-ligne-retirer'),
              leading: const Icon(Icons.delete_outline),
              title: const Text('Retirer de la commande'),
              onTap: () => Navigator.pop(c, 'retirer'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || choix == null) return;
  switch (choix) {
    case 'calcul':
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (c) => _DetailCalcul(ligne: ligne),
      );
    case 'generique':
      final m = await showModalBottomSheet<MembreGenerique>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: _GeneriquesDe(ligne: ligne, surChoix: (m) => Navigator.pop(c, m)),
        ),
      );
      if (m != null && context.mounted) await _remplacerPar(context, ref, panier, ligne, m);
    case 'grossiste':
      final vers = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (c) => _ChoixGrossiste(actuel: panier.fournisseur.id),
      );
      if (vers == null) return;
      try {
        await ref.read(journeeProvider.notifier).deplacer(ligne, panier.fournisseur.id, vers);
      } catch (e) {
        if (context.mounted) montrerErreur(context, e);
      }
    case 'retirer':
      try {
        await ref.read(journeeProvider.notifier).modifier(panier, ligne, 0);
      } catch (e) {
        if (context.mounted) montrerErreur(context, e);
      }
  }
}

/// « Pourquoi cette quantité ? » : d'où vient le rythme, comparé à la
/// moyenne sur 12 mois.
class _DetailCalcul extends ConsumerWidget {
  const _DetailCalcul({required this.ligne});
  final LigneCommande ligne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ref
          .watch(calculProvider(ligne.idNom))
          .when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
            error: (e, _) => Padding(padding: const EdgeInsets.all(20), child: Text(ErreurApi.depuis(e).message)),
            data: (d) {
              final lent = d.type == 'lent';
              final ecart = d.moyenne12m > 0 ? d.rythme / d.moyenne12m : 0.0;
              final fort = !lent && ecart >= 1.8;
              Widget l(String titre, String valeur, {String? detail, bool accent = false}) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titre, style: TextStyle(color: context.couleurs.encre2)),
                          if (detail != null)
                            Text(detail, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                        ],
                      ),
                    ),
                    Text(
                      valeur,
                      style: TextStyle(fontWeight: FontWeight.w700, color: accent ? context.etats.alerte : null),
                    ),
                  ],
                ),
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  key: const ValueKey('detail-calcul'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      libelleProduit(d.nom ?? ligne.nom ?? ''),
                      style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type ${libelleTypeDemande(d.type)} · ${d.joursVente12m} jours de vente sur 12 mois',
                      style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                    ),
                    const SizedBox(height: 10),
                    if (lent)
                      l(
                        'Produit à vente rare',
                        '1 boîte',
                        detail: 'gardée en rayon s\'il s\'est vendu dans les 6 derniers mois',
                      )
                    else
                      l(
                        'Rythme utilisé',
                        '${decimal(d.rythme, chiffres: 2)} / jour',
                        detail:
                            'hors ruptures ${decimal(d.moyenneHorsRuptures, chiffres: 2)} sur ${d.joursRetenus} j · '
                            'brute ${decimal(d.moyenneBrute, chiffres: 2)} · ramené vers la brute (poids 14 j)',
                        accent: fort,
                      ),
                    l(
                      'Moyenne sur 12 mois',
                      '${decimal(d.moyenne12m, chiffres: 2)} / jour',
                      detail: '${decimal(d.ventes12m)} vendus · CMM ${decimal(d.cmm)}',
                    ),
                    const Divider(),
                    if (d.decision != null && (d.decision!.maxi > 0 || d.decision!.mini > 0)) ...[
                      l(
                        'Point de commande (mini)',
                        decimal(d.decision!.mini, chiffres: 0),
                        detail: [
                          'demande jusqu\'à la livraison suivante + sécurité',
                          if (d.decision!.ordonnance > 1) 'au moins une ordonnance de ${d.decision!.ordonnance}',
                        ].join(' · '),
                      ),
                      l(
                        'Stock maximum',
                        decimal(d.decision!.groupe != null ? d.decision!.maxiGroupe : d.decision!.maxi, chiffres: 0),
                        detail: [
                          '${d.decision!.couverture} jours de couverture${d.decision!.tension ? ' (en tension)' : ''}',
                          if (d.decision!.groupe != null) 'pour toute la DCI ${d.decision!.groupe}',
                        ].join(' · '),
                      ),
                      if (d.decision!.lot > 0) l('Lot habituel appliqué', '${d.decision!.lot}'),
                      const Divider(),
                    ],
                    l('Fenêtre', '${d.fenetreJours} jours', detail: '${d.joursOuverts} jours ouverts'),
                    l(
                      'Jours exclus (rupture)',
                      '${d.joursExclusRupture}',
                      detail: 'stock nul dans l\'historique ${d.joursStockNul} j : la demande y est inconnue',
                      accent: d.joursExclusRupture > d.joursRetenus,
                    ),
                    if (d.reprisGeneriques > 0) l('Repris de génériques remplacés', decimal(d.reprisGeneriques)),
                    if (d.plusGrossesVentes.isNotEmpty)
                      l(
                        'Plus grosses ventes',
                        '',
                        detail: [for (final v in d.plusGrossesVentes) '${v['date']} : ${decimal(v['qte'] as num)}']
                            .join(' · '),
                      ),
                    if (fort)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.etats.alerteDoux,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Le rythme est ${decimal(ecart)} fois la moyenne sur 12 mois'
                          '${d.joursExclusRupture > d.joursRetenus ? ' : la plupart des jours sont exclus pour rupture, il ne reste presque que des jours de vente.' : '.'}',
                          style: TextStyle(fontSize: 13, color: context.etats.alerte),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

/// Grossistes actifs, pour y déplacer une ligne.
class _ChoixGrossiste extends ConsumerWidget {
  const _ChoixGrossiste({required this.actuel});
  final int actuel;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.92,
    builder: (context, defilement) => ref
        .watch(fournisseursCommandeProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          error: (e, _) => Center(child: Text(ErreurApi.depuis(e).message)),
          data: (tous) => ListView(
            controller: defilement,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Changer de grossiste',
                  style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              for (final f in tous)
                if (f.actif && f.id != actuel)
                  ListTile(
                    key: ValueKey('vers-${f.id}'),
                    leading: InitialeFournisseur(fournisseur: f.commePanier, taille: 34),
                    title: Text(libelleProduit(f.nom ?? 'Fournisseur ${f.id}')),
                    subtitle: Text(f.type.libelle),
                    onTap: () => Navigator.pop(context, f.id),
                  ),
            ],
          ),
        ),
  );
}

/// Stock actuel (plein), quantité commandée (clair), et repère du stock de
/// sécurité, sur l'échelle du niveau cible.
class JaugeCommande extends StatelessWidget {
  const JaugeCommande({super.key, required this.ligne});
  final LigneCommande ligne;

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    final r = l.raison;
    final echelle = [r?.cible ?? 0, (l.stock + l.qte).toDouble(), 1.0].reduce((a, b) => a > b ? a : b);
    final stock = (l.stock.clamp(0, 1 << 30) / echelle).clamp(0.0, 1.0);
    final commande = (l.qte / echelle).clamp(0.0, 1.0 - stock);
    final securite = ((r?.securite ?? 0) / echelle).clamp(0.0, 1.0);
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 2,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.couleurs.neutreDoux, borderRadius: BorderRadius.circular(6)),
              ),
            ),
            Positioned(
              left: c.maxWidth * stock,
              width: c.maxWidth * commande,
              top: 2,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.schema.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Positioned(
              left: 0,
              width: c.maxWidth * stock,
              top: 2,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(color: context.schema.primary, borderRadius: BorderRadius.circular(6)),
              ),
            ),
            if (securite > 0)
              Positioned(
                left: (c.maxWidth * securite - 1).clamp(0, c.maxWidth - 2),
                width: 2,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: context.etats.alerteIcone),
              ),
          ],
        ),
      ),
    );
  }
}

/// − quantité + ; à 1, « − » retire la ligne.
class Pas extends StatelessWidget {
  const Pas({super.key, required this.cle, required this.valeur, required this.surChangement});
  final String cle;
  final int valeur;
  final ValueChanged<int> surChangement;

  @override
  Widget build(BuildContext context) {
    Widget bouton(IconData icone, String suffixe, String aide, VoidCallback action) => SizedBox(
      width: 30,
      height: 30,
      child: InkWell(
        key: ValueKey('$cle-$suffixe'),
        borderRadius: BorderRadius.circular(8),
        onTap: action,
        child: Tooltip(
          message: aide,
          child: Icon(icone, size: 16, color: context.couleurs.encre2),
        ),
      ),
    );
    return Material(
      color: context.couleurs.neutreDoux,
      borderRadius: BorderRadius.circular(9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          bouton(
            valeur <= 1 ? Icons.delete_outline : Icons.remove,
            'moins',
            valeur <= 1 ? 'Retirer' : 'Une boîte de moins',
            () => surChangement(valeur - 1),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$valeur',
              key: ValueKey('$cle-valeur'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          bouton(Icons.add, 'plus', 'Une boîte de plus', () => surChangement(valeur + 1)),
        ],
      ),
    );
  }
}

// ── Barre fixe du bas ───────────────────────────────────────────────────────

class _BarreTotal extends ConsumerStatefulWidget {
  const _BarreTotal({required this.panier, required this.journee});
  final Panier panier;
  final JourneeCommandes journee;

  @override
  ConsumerState<_BarreTotal> createState() => _BarreTotalState();
}

class _BarreTotalState extends ConsumerState<_BarreTotal> {
  bool _enCours = false;

  Future<void> _faire(Future<void> Function(JourneeController c) action) async {
    setState(() => _enCours = true);
    try {
      await action(ref.read(journeeProvider.notifier));
    } catch (e) {
      if (mounted) montrerErreur(context, e);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// L'appel au serveur tourne avec l'indicateur ; WhatsApp et le bon
  /// s'ouvrent ensuite, l'indicateur arrêté.
  Future<void> _envoyer(int idCommande) async {
    BonCommande? bon;
    await _faire((c) async => bon = await c.envoyer(idCommande));
    if (bon != null && mounted) await ouvrirWhatsapp(context, ref, bon!);
  }

  Future<void> _revoir(int idCommande) async {
    BonCommande? bon;
    await _faire((c) async => bon = await ref.read(commandesApiProvider).bon(idCommande));
    if (bon != null && mounted) await afficherBon(context, bon!);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.panier;
    final id = p.commande?.id;
    final Widget action = switch (p.etape) {
      EtapePanier.propose when widget.journee.peutValider => FilledButton.icon(
        key: const ValueKey('action-valider'),
        onPressed: _enCours || p.lignes.isEmpty
            ? null
            : () => _faire((c) async => c.valider((await c.brouillonDe(p)).commande!.id)),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Valider'),
      ),
      EtapePanier.propose => FilledButton.icon(
        key: const ValueKey('action-preparer'),
        onPressed: _enCours || p.lignes.isEmpty ? null : () => _faire((c) => c.preparer()),
        icon: const Icon(Icons.playlist_add_check_rounded),
        label: const Text('Préparer'),
      ),
      EtapePanier.brouillon when widget.journee.peutValider => FilledButton.icon(
        key: const ValueKey('action-valider'),
        onPressed: _enCours || p.lignes.isEmpty ? null : () => _faire((c) => c.valider(id!)),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Valider'),
      ),
      EtapePanier.brouillon => Text(
        'À valider par le titulaire',
        key: const ValueKey('action-attente'),
        style: TextStyle(color: context.couleurs.encre3, fontSize: 13),
      ),
      EtapePanier.validee => FilledButton.icon(
        key: const ValueKey('action-envoyer'),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FA855), foregroundColor: Colors.white),
        onPressed: _enCours ? null : () => _envoyer(id!),
        icon: const Icon(Icons.send_rounded),
        label: const Text('Envoyer par WhatsApp'),
      ),
      EtapePanier.envoyee => OutlinedButton.icon(
        key: const ValueKey('action-revoir'),
        onPressed: _enCours ? null : () => _revoir(id!),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Revoir le bon'),
      ),
    };
    return Material(
      color: context.schema.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.couleurs.bord)),
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dinars(p.montant.round()),
                    key: const ValueKey('total-panier'),
                    style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                  Text(
                    '${p.nbLignes} ligne${p.nbLignes > 1 ? 's' : ''} · ${entier(p.boites)} boîtes',
                    style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                  ),
                ],
              ),
            ),
            if (_enCours && p.etape != EtapePanier.propose)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            Flexible(
              child: Align(alignment: Alignment.centerRight, heightFactor: 1, child: action),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuPanier extends ConsumerWidget {
  const _MenuPanier({required this.panier});
  final Panier panier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = panier.commande;
    final peutValider = ref.watch(journeeProvider).value?.peutValider ?? false;
    if (c == null) return const SizedBox.shrink();
    final rouvrir = panier.etape == EtapePanier.validee && peutValider;
    final annuler = panier.etape == EtapePanier.brouillon || (panier.etape == EtapePanier.validee && peutValider);
    if (!rouvrir && !annuler) return const SizedBox.shrink();
    Future<void> faire(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) montrerErreur(context, e);
      }
    }

    return PopupMenuButton<String>(
      key: const ValueKey('menu-panier'),
      tooltip: 'Plus',
      onSelected: (choix) async {
        final ctrl = ref.read(journeeProvider.notifier);
        if (choix == 'rouvrir') await faire(() => ctrl.rouvrir(c.id));
        if (choix == 'annuler' && context.mounted) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (d) => AlertDialog(
              title: const Text('Annuler cette commande ?'),
              content: const Text(
                'Le brouillon est abandonné. Ses produits seront de nouveau proposés au prochain calcul.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Garder')),
                FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Annuler la commande')),
              ],
            ),
          );
          if (ok == true) await faire(() => ctrl.annuler(c.id));
        }
      },
      itemBuilder: (_) => [
        if (rouvrir) const PopupMenuItem(value: 'rouvrir', child: Text('Rouvrir pour corriger')),
        if (annuler) const PopupMenuItem(value: 'annuler', child: Text('Annuler la commande')),
      ],
    );
  }
}

// ── Bon de commande ─────────────────────────────────────────────────────────

/// Ouvre un lien hors de l'application (WhatsApp) ; remplacé dans les tests.
final ouvreurLienProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (lien) => launchUrl(lien, mode: LaunchMode.externalApplication),
);

/// Ouvre WhatsApp avec le bon prérempli, puis montre le bon (à copier si
/// WhatsApp ne s'est pas ouvert).
Future<void> ouvrirWhatsapp(BuildContext context, WidgetRef ref, BonCommande bon) async {
  var ouvert = false;
  try {
    ouvert = await ref.read(ouvreurLienProvider)(bon.lienWhatsapp);
  } catch (_) {
    ouvert = false;
  }
  if (context.mounted) await afficherBon(context, bon, whatsappOuvert: ouvert);
}

Future<void> afficherBon(BuildContext context, BonCommande bon, {bool? whatsappOuvert}) => showDialog<void>(
  context: context,
  builder: (d) => AlertDialog(
    title: Text('Bon · ${bon.fournisseur ?? ''}'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (whatsappOuvert == false)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'WhatsApp ne s\'est pas ouvert : copiez le bon et collez-le dans la conversation du grossiste.',
                style: TextStyle(color: d.etats.alerte, fontSize: 13),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFDCF8C6), borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: SelectableText(
                  bon.texte,
                  key: const ValueKey('texte-bon'),
                  style: const TextStyle(color: Color(0xFF1A2A1A), height: 1.45),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton.icon(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: bon.texte));
          if (d.mounted) {
            ScaffoldMessenger.of(d).showSnackBar(const SnackBar(content: Text('Bon copié.')));
          }
        },
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copier'),
      ),
      TextButton.icon(
        onPressed: () => ProviderScope.containerOf(d).read(ouvreurLienProvider)(bon.lienWhatsapp),
        icon: const Icon(Icons.chat_outlined),
        label: const Text('WhatsApp'),
      ),
      FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Fermer')),
    ],
  ),
);

// ── Ajout manuel ────────────────────────────────────────────────────────────

Future<void> _ajouterProduit(BuildContext context, WidgetRef ref, Panier panier) async {
  final choisi = await showDialog<Produit>(context: context, builder: (_) => const _ChoixProduit());
  if (choisi == null) return;
  try {
    final ctrl = ref.read(journeeProvider.notifier);
    final brouillon = await ctrl.brouillonDe(panier);
    await ctrl.ajouter(brouillon.commande!.id, choisi.id, 1);
  } catch (e) {
    if (context.mounted) montrerErreur(context, e);
  }
}

class _ChoixProduit extends ConsumerStatefulWidget {
  const _ChoixProduit();

  @override
  ConsumerState<_ChoixProduit> createState() => _ChoixProduitState();
}

class _ChoixProduitState extends ConsumerState<_ChoixProduit> {
  final _champ = TextEditingController();
  Timer? _attente;
  Future<PageProduits>? _resultats;

  @override
  void dispose() {
    _attente?.cancel();
    _champ.dispose();
    super.dispose();
  }

  void _chercher(String texte) {
    _attente?.cancel();
    _attente = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _resultats = texte.trim().length < 2
            ? null
            : ref.read(stockApiProvider).produits(FiltreProduits(recherche: texte.trim()), limite: 20);
      });
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ajouter un produit'),
    content: SizedBox(
      width: 420,
      height: 360,
      child: Column(
        children: [
          TextField(
            key: const ValueKey('recherche-ajout'),
            controller: _champ,
            autofocus: true,
            onChanged: _chercher,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Nom, DCI ou code-barres',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _resultats == null
                ? Center(
                    child: Text('Tapez au moins 2 lettres.', style: TextStyle(color: context.couleurs.encre3)),
                  )
                : FutureBuilder<PageProduits>(
                    future: _resultats,
                    builder: (context, s) {
                      if (s.hasError) return Center(child: Text(ErreurApi.depuis(s.error!).message));
                      if (!s.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
                      final items = s.data!.items;
                      if (items.isEmpty) return const Center(child: Text('Aucun produit.'));
                      return ListView(
                        children: [
                          for (final p in items)
                            ListTile(
                              key: ValueKey('choix-${p.id}'),
                              title: Text(nomLisible(p)),
                              subtitle: Text('stock ${entier(p.stock)}'),
                              onTap: () => Navigator.pop(context, p),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
  );
}
