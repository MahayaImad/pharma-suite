import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../domain/format.dart';
import '../../../domain/stock.dart';
import '../application/stock_providers.dart';
import 'elements_stock.dart';
import 'fiche_produit.dart';

/// Largeur à partir de laquelle la fiche s'ouvre à côté de la liste.
const _largeurDeuxVolets = 980.0;

/// Écran Stock : ce qui est à traiter d'abord, puis tout le stock ; et la
/// fiche du produit [selection] s'il y en a un. Sur grand écran la fiche est
/// à côté de la liste ; sur portable elle prend tout l'écran.
class EcranStock extends StatelessWidget {
  const EcranStock({super.key, this.selection});

  final int? selection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        if (contraintes.maxWidth >= _largeurDeuxVolets) {
          return Scaffold(
            body: Row(
              children: [
                Expanded(child: _Liste(selection: selection)),
                const VerticalDivider(),
                SizedBox(
                  width: (contraintes.maxWidth * 0.42).clamp(420, 560),
                  child: selection == null
                      ? const _AucuneSelection()
                      : FicheProduit(key: ValueKey(selection), id: selection!, enPanneau: true),
                ),
              ],
            ),
          );
        }
        if (selection != null) return FicheProduit(key: ValueKey(selection), id: selection!);
        return const Scaffold(body: _Liste());
      },
    );
  }
}

class _AucuneSelection extends StatelessWidget {
  const _AucuneSelection();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.schema.surface,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_outlined, size: 40, color: context.couleurs.encre3),
          const SizedBox(height: 10),
          Text(
            'Choisissez un produit pour voir sa fiche et ses lots.',
            style: TextStyle(color: context.couleurs.encre2),
          ),
        ],
      ),
    ),
  );
}

/// Message des actions qui dépendent du module Commandes, pas encore là.
void bientotCommandes(BuildContext context) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(const SnackBar(content: Text('Le module Commandes arrive bientôt.')));

class _Liste extends ConsumerStatefulWidget {
  const _Liste({this.selection});
  final int? selection;

  @override
  ConsumerState<_Liste> createState() => _ListeState();
}

class _ListeState extends ConsumerState<_Liste> {
  final _recherche = TextEditingController();
  Timer? _attente;

  @override
  void initState() {
    super.initState();
    _recherche.text = ref.read(filtreProduitsProvider).recherche;
  }

  @override
  void dispose() {
    _attente?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  /// La recherche part 300 ms après la dernière frappe.
  void _chercher(String texte) {
    _attente?.cancel();
    _attente = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(filtreProduitsProvider.notifier).chercher(texte),
    );
    setState(() {}); // bouton « effacer »
  }

  void _effacerRecherche() {
    _attente?.cancel();
    _recherche.clear();
    ref.read(filtreProduitsProvider.notifier).chercher('');
    setState(() {});
  }

  void _effacerTout() {
    _recherche.clear();
    ref.read(filtreProduitsProvider.notifier).effacer();
    setState(() {});
  }

  void _rafraichir() {
    ref.invalidate(resumeStockProvider);
    ref.invalidate(aTraiterProvider);
    ref.invalidate(listeProduitsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(listeProduitsProvider);
    final filtre = ref.watch(filtreProduitsProvider);
    // Sans recherche ni filtre d'état : d'abord ce qui est à traiter.
    final accueil = filtre.etat == null && filtre.recherche.trim().isEmpty && filtre.labo == null;

    return RefreshIndicator(
      onRefresh: () async {
        _rafraichir();
        await ref.read(listeProduitsProvider.future).catchError((_) => const ListeProduits());
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 600) ref.read(listeProduitsProvider.notifier).chargerSuite();
          return false;
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _EnTete()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _ChampRecherche(controleur: _recherche, surSaisie: _chercher, surEffacer: _effacerRecherche),
              ),
            ),
            SliverToBoxAdapter(child: _Tuiles(choisi: filtre.etat)),
            if (accueil) const SliverToBoxAdapter(child: _Groupes()),
            SliverToBoxAdapter(
              child: _TitreListe(filtre: filtre, total: liste.value?.total, surEffacer: _effacerTout),
            ),
            if (accueil) const SliverToBoxAdapter(child: _Familles()),
            ...liste.when(
              skipLoadingOnReload: false,
              data: (l) => [
                if (l.produits.isEmpty)
                  SliverToBoxAdapter(
                    child: MessageVide(
                      titre: 'Aucun produit',
                      texte: filtre.recherche.isNotEmpty
                          ? 'Rien ne correspond à « ${filtre.recherche} ».'
                          : 'Aucun produit ne correspond à ces filtres.',
                      action: OutlinedButton(onPressed: _effacerTout, child: const Text('Effacer les filtres')),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: l.produits.length + (l.complete ? 0 : 1),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => i == l.produits.length
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                            )
                          : LigneProduit(produit: l.produits[i], choisi: l.produits[i].id == widget.selection),
                    ),
                  ),
              ],
              loading: () => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, _) => const _LigneSquelette(),
                  ),
                ),
              ],
              error: (e, _) => [
                SliverToBoxAdapter(
                  child: MessageErreur(erreur: e, reessayer: _rafraichir),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre et heure des données.
class _EnTete extends ConsumerWidget {
  const _EnTete();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donnees = ref.watch(resumeStockProvider).value?.donneesDu;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        children: [
          const Text(
            'Stock',
            style: TextStyle(fontFamily: 'Sora', fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          const Spacer(),
          if (donnees != null)
            Flexible(
              flex: 4,
              child: Tooltip(
                message: 'Heure du dernier calcul du stock EASYPHARM',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: context.etats.bon, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Données ${horodatage(donnees, DateTime.now().toUtc())}',
                        key: const ValueKey('horodatage'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 4),
          const BoutonPreferences(),
        ],
      ),
    );
  }
}

class _ChampRecherche extends StatelessWidget {
  const _ChampRecherche({required this.controleur, required this.surSaisie, required this.surEffacer});

  final TextEditingController controleur;
  final ValueChanged<String> surSaisie;
  final VoidCallback surEffacer;

  @override
  Widget build(BuildContext context) {
    final bord = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.couleurs.bord),
    );
    return TextField(
      key: const ValueKey('champ-recherche'),
      controller: controleur,
      onChanged: surSaisie,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Chercher un produit, une DCI, un code-barres',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controleur.text.isEmpty
            ? null
            : IconButton(tooltip: 'Effacer', icon: const Icon(Icons.close_rounded), onPressed: surEffacer),
        filled: true,
        fillColor: context.schema.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: bord,
        enabledBorder: bord,
        focusedBorder: bord.copyWith(borderSide: BorderSide(color: context.schema.primary, width: 1.6)),
      ),
    );
  }
}

/// Trois tuiles : ruptures, sous le seuil, valeur à risque de péremption.
/// Chacune filtre la liste.
class _Tuiles extends ConsumerWidget {
  const _Tuiles({required this.choisi});
  final FiltreEtat? choisi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(aTraiterProvider).value?.compteurs;
    final notif = ref.read(filtreProduitsProvider.notifier);
    void basculer(FiltreEtat e) => notif.etat(choisi == e ? null : e);
    final tuiles = [
      (
        FiltreEtat.rupture,
        c == null ? '…' : entier(c.ruptures),
        'ruptures à commander',
        const [Color(0xFFC62F2F), Color(0xFFE0574F)],
        Icons.remove_circle_outline,
      ),
      (
        FiltreEtat.sousSeuil,
        c == null ? '…' : entier(c.sousSeuil),
        'sous le seuil',
        const [Color(0xFFB26A00), Color(0xFFE79A00)],
        Icons.trending_down,
      ),
      (
        FiltreEtat.aRisque,
        c == null ? '…' : dinarsCourt(c.valeurARisque).replaceAll(' DA', ''),
        'DA à risque de péremption',
        const [Color(0xFF5B33B0), Color(0xFF7A4DD1)],
        Icons.hourglass_bottom_rounded,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          for (final (i, (etat, valeur, texte, couleurs, icone)) in tuiles.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _Tuile(
                cle: 'tuile-${etat.api}',
                valeur: valeur,
                texte: texte,
                couleurs: couleurs,
                icone: icone,
                choisie: choisi == etat,
                surChoix: () => basculer(etat),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  const _Tuile({
    required this.cle,
    required this.valeur,
    required this.texte,
    required this.couleurs,
    required this.icone,
    required this.choisie,
    required this.surChoix,
  });

  final String cle, valeur, texte;
  final List<Color> couleurs;
  final IconData icone;
  final bool choisie;
  final VoidCallback surChoix;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey(cle),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: couleurs),
          border: choisie ? Border.all(color: context.schema.onSurface, width: 2.5) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: surChoix,
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -12,
                child: Icon(icone, size: 64, color: Colors.white.withValues(alpha: .13)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valeur,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      texte,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 12, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// À commander, péremption à risque, surstock : les premiers de chaque
/// groupe, avec l'action proposée.
class _Groupes extends ConsumerWidget {
  const _Groupes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aTraiter = ref.watch(aTraiterProvider);
    final notif = ref.read(filtreProduitsProvider.notifier);
    return aTraiter.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(aTraiterProvider)),
      data: (a) {
        final c = a.compteurs;
        if (c.aCommander == 0 && c.aRisque == 0 && c.surstock == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (a.aCommander.isNotEmpty)
                _Groupe(
                  titre: 'À commander',
                  nombre: c.aCommander,
                  signal: Signal.rupture,
                  produits: a.aCommander,
                  toutVoir: () => notif.etat(FiltreEtat.aCommander),
                  raison: (p) => p.etat == EtatStock.rupture
                      ? 'Rupture · ${decimal(p.cmm)} vendus par mois'
                      : '${entier(p.stock)} en stock, seuil ${entier(p.seuil ?? 0)}'
                            '${p.couverture == null ? '' : ' · ${p.couverture} j de couverture'}',
                  action: (p) => _BoutonAction('Commander', plein: true, surAppui: () => bientotCommandes(context)),
                ),
              if (a.aRisque.isNotEmpty)
                _Groupe(
                  titre: 'Péremption à risque',
                  nombre: c.aRisque,
                  signal: Signal.risque,
                  produits: a.aRisque,
                  toutVoir: () => notif.etat(FiltreEtat.aRisque),
                  raison: (p) =>
                      '${entier(p.qteARisque)} unité${p.qteARisque > 1 ? 's' : ''} périmer${p.qteARisque > 1 ? 'ont' : 'a'} '
                      'avant d\'être vendue${p.qteARisque > 1 ? 's' : ''} · ${dinars(p.valeurARisque)}',
                  action: (p) => _BoutonAction(
                    'Que faire ?',
                    plein: true,
                    couleur: couleursSignal(context, Signal.risque).texte,
                    surAppui: () => context.go('/stock/${p.id}'),
                  ),
                ),
              if (a.surstock.isNotEmpty)
                _Groupe(
                  titre: 'Surstock',
                  nombre: c.surstock,
                  signal: Signal.surstock,
                  produits: a.surstock,
                  toutVoir: () => notif.etat(FiltreEtat.surstock),
                  raison: (p) =>
                      '${entier(p.qteSurstock)} au-delà du maximum · ${dinars(p.valeurSurstock)} immobilisés',
                  action: (p) => _BoutonAction('Voir', surAppui: () => context.go('/stock/${p.id}')),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Groupe extends StatelessWidget {
  const _Groupe({
    required this.titre,
    required this.nombre,
    required this.signal,
    required this.produits,
    required this.toutVoir,
    required this.raison,
    required this.action,
  });

  final String titre;
  final int nombre;
  final Signal signal;
  final List<Produit> produits;
  final VoidCallback toutVoir;
  final String Function(Produit) raison;
  final Widget Function(Produit) action;

  @override
  Widget build(BuildContext context) {
    final c = couleursSignal(context, signal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: c.fond, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        entier(nombre),
                        style: TextStyle(color: c.texte, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: toutVoir, child: const Text('Tout voir')),
            ],
          ),
          const SizedBox(height: 4),
          for (final p in produits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CarteAction(produit: p, raison: raison(p), couleur: c.texte, action: action(p)),
            ),
        ],
      ),
    );
  }
}

class _CarteAction extends StatelessWidget {
  const _CarteAction({required this.produit, required this.raison, required this.couleur, required this.action});

  final Produit produit;
  final String raison;
  final Color couleur;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    return Material(
      color: context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.couleurs.bord),
      ),
      child: InkWell(
        key: ValueKey('action-${p.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/stock/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              IconeFamille(p.idFamille),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomLisible(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      raison,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: couleur, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonAction extends StatelessWidget {
  const _BoutonAction(this.texte, {required this.surAppui, this.plein = false, this.couleur});

  final String texte;
  final VoidCallback surAppui;
  final bool plein;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      backgroundColor: couleur == null ? null : WidgetStatePropertyAll(couleur),
    );
    return plein
        ? FilledButton(onPressed: surAppui, style: style, child: Text(texte))
        : FilledButton.tonal(onPressed: surAppui, style: style, child: Text(texte));
  }
}

/// « Tout le stock » ou le filtre en cours, et l'ordre de la liste.
class _TitreListe extends ConsumerWidget {
  const _TitreListe({required this.filtre, required this.total, required this.surEffacer});

  final FiltreProduits filtre;
  final int? total;
  final VoidCallback surEffacer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notif = ref.read(filtreProduitsProvider.notifier);
    final recherche = filtre.recherche.trim();
    final titre = filtre.etat?.libelle ?? (recherche.isNotEmpty ? 'Résultats' : 'Tout le stock');
    final filtreActif = filtre.etat != null || recherche.isNotEmpty;
    final labo = filtre.labo;
    final ligne = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    titre,
                    key: const ValueKey('titre-liste'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (total != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.couleurs.neutreDoux,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entier(total!),
                      key: const ValueKey('nombre-produits'),
                      style: TextStyle(color: context.couleurs.encre2, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                if (filtreActif)
                  IconButton(
                    tooltip: 'Retirer le filtre',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: surEffacer,
                  ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('bouton-labo'),
            tooltip: 'Filtrer par laboratoire',
            visualDensity: VisualDensity.compact,
            isSelected: labo != null,
            icon: const Icon(Icons.factory_outlined, size: 20),
            selectedIcon: Icon(Icons.factory, size: 20, color: context.schema.primary),
            onPressed: () => choisirLaboratoire(context, ref),
          ),
          PopupMenuButton<TriProduits>(
            tooltip: 'Trier',
            initialValue: filtre.tri,
            onSelected: notif.trier,
            itemBuilder: (_) => [
              for (final t in TriProduits.values)
                PopupMenuItem(value: t, child: Text('Trier par ${t.libelle.toLowerCase()}')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trier par ${filtre.tri.libelle.toLowerCase()}',
                    style: TextStyle(color: context.schema.primary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: context.schema.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (labo == null) return ligne;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ligne,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: InputChip(
            key: const ValueKey('puce-labo'),
            avatar: const Icon(Icons.factory_outlined, size: 16),
            label: Text(libelle(labo)),
            onDeleted: () => notif.labo(null),
            deleteButtonTooltipMessage: 'Tous les laboratoires',
          ),
        ),
      ],
    );
  }
}

/// Choix du laboratoire : liste cherchable des laboratoires des produits actifs.
Future<void> choisirLaboratoire(BuildContext context, WidgetRef ref) async {
  final choisi = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ChoixLaboratoire(),
  );
  if (choisi != null) ref.read(filtreProduitsProvider.notifier).labo(choisi);
}

class _ChoixLaboratoire extends ConsumerStatefulWidget {
  const _ChoixLaboratoire();

  @override
  ConsumerState<_ChoixLaboratoire> createState() => _ChoixLaboratoireState();
}

class _ChoixLaboratoireState extends ConsumerState<_ChoixLaboratoire> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final labos = ref.watch(laboratoiresProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, defilement) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const ValueKey('recherche-labo'),
              autofocus: false,
              onChanged: (t) => setState(() => _recherche = t),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Chercher un laboratoire',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          Expanded(
            child: labos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(laboratoiresProvider)),
              data: (tous) {
                final q = _recherche.trim().toLowerCase();
                final visibles = [
                  for (final l in tous)
                    if (q.isEmpty || l.labo.toLowerCase().contains(q)) l,
                ];
                if (visibles.isEmpty) {
                  return const MessageVide(titre: 'Aucun laboratoire', texte: 'Rien ne correspond.');
                }
                return ListView.builder(
                  controller: defilement,
                  itemCount: visibles.length,
                  itemBuilder: (context, i) {
                    final l = visibles[i];
                    return ListTile(
                      key: ValueKey('labo-${l.labo}'),
                      title: Text(libelle(l.labo)),
                      trailing: Text(
                        '${entier(l.produitsActifs)} produits',
                        style: TextStyle(color: context.couleurs.encre3, fontSize: 12),
                      ),
                      onTap: () => Navigator.pop(context, l.labo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Une pastille par famille, au-dessus de « Tout le stock ».
class _Familles extends ConsumerWidget {
  const _Familles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familles = ref.watch(resumeStockProvider).value?.familles ?? const [];
    final choisie = ref.watch(filtreProduitsProvider.select((f) => f.idFamille));
    final visibles = familles.where((f) => f.id != null && (f.produitsActifs > 0 || f.id == choisie)).toList();
    if (visibles.isEmpty) return const SizedBox(height: 8);

    void choisir(int? id) => ref.read(filtreProduitsProvider.notifier).famille(id);
    return SizedBox(
      height: 52,
      child: ListView(
        key: const ValueKey('familles'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        children: [
          _PastilleFamille(texte: 'Toutes', choisie: choisie == null, surChoix: () => choisir(null)),
          for (final f in visibles)
            _PastilleFamille(
              texte: libelle(f.famille),
              idFamille: f.id,
              choisie: choisie == f.id,
              surChoix: () => choisir(choisie == f.id ? null : f.id),
            ),
        ],
      ),
    );
  }
}

class _PastilleFamille extends StatelessWidget {
  const _PastilleFamille({required this.texte, required this.choisie, required this.surChoix, this.idFamille});

  final String texte;
  final int? idFamille;
  final bool choisie;
  final VoidCallback surChoix;

  @override
  Widget build(BuildContext context) {
    final s = context.schema;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: choisie ? s.primary : s.surface,
        shape: StadiumBorder(side: BorderSide(color: choisie ? s.primary : context.couleurs.bord)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: surChoix,
          child: Padding(
            padding: EdgeInsets.fromLTRB(idFamille == null ? 14 : 10, 0, 14, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (idFamille != null) ...[
                  Icon(
                    visuelFamille(idFamille).icone,
                    size: 16,
                    color: choisie ? s.onPrimary : visuelFamille(idFamille).couleur,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  texte,
                  style: TextStyle(
                    color: choisie ? s.onPrimary : context.couleurs.encre2,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nom lisible : « DOLIPRANE » → « Doliprane », dosage compris.
String nomLisible(Produit p) {
  final brut = [p.nom, if (p.dosage != null && p.dosage!.isNotEmpty && !p.nom.contains(p.dosage!)) p.dosage!].join(' ');
  return libelleProduit(brut);
}

/// Un produit dans la liste, avec la jauge de son stock.
class LigneProduit extends StatelessWidget {
  const LigneProduit({super.key, required this.produit, this.choisi = false});

  final Produit produit;
  final bool choisi;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final sousTitre = [
      if (p.dci != null && p.dci!.trim().isNotEmpty) libelleProduit(p.dci!),
      if (p.labo != null && p.labo!.trim().isNotEmpty) libelleProduit(p.labo!),
    ].join(' · ');
    final nom = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nomLisible(p),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        if (sousTitre.isNotEmpty)
          Text(
            sousTitre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
          ),
      ],
    );
    final prix = Text(
      p.prixVente > 0 ? dinars(p.prixVente) : '—',
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
    return Material(
      color: choisi ? context.schema.primaryContainer.withValues(alpha: .45) : context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: choisi ? context.schema.primary : context.couleurs.bord, width: choisi ? 1.6 : 1),
      ),
      child: InkWell(
        key: ValueKey('produit-${p.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/stock/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 640) {
                return Row(
                  children: [
                    IconeFamille(p.idFamille, taille: 38),
                    const SizedBox(width: 12),
                    Expanded(flex: 5, child: nom),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: JaugeStock(produit: p)),
                    SizedBox(
                      width: 78,
                      child: Text(
                        p.couverture == null ? '—' : '${p.couverture} j',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: context.couleurs.encre2, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      child: Align(alignment: Alignment.centerRight, child: prix),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 150,
                      child: Align(alignment: Alignment.centerRight, child: PastilleSignal(p.signal)),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconeFamille(p.idFamille, taille: 38),
                      const SizedBox(width: 12),
                      Expanded(child: nom),
                      const SizedBox(width: 8),
                      PastilleSignal(p.signal),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: JaugeStock(produit: p)),
                      const SizedBox(width: 16),
                      prix,
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LigneSquelette extends StatelessWidget {
  const _LigneSquelette();

  @override
  Widget build(BuildContext context) => Container(
    height: 92,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.schema.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.couleurs.bord),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Squelette(largeur: 200, hauteur: 14),
        SizedBox(height: 8),
        Squelette(largeur: 140),
        Spacer(),
        Row(
          children: [
            Expanded(child: Squelette(largeur: 200, hauteur: 6)),
            SizedBox(width: 60),
          ],
        ),
      ],
    ),
  );
}
