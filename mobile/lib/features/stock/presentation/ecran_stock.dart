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

/// Écran Stock : la liste, et la fiche du produit [selection] s'il y en a un.
/// Sur grand écran les deux sont côte à côte ; sur portable la fiche prend
/// tout l'écran, avec un retour vers la liste.
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
  }

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(listeProduitsProvider);
    final filtre = ref.watch(filtreProduitsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(resumeStockProvider);
        ref.invalidate(listeProduitsProvider);
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _ChampRecherche(
                  controleur: _recherche,
                  surSaisie: _chercher,
                  surEffacer: _effacerRecherche,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _Familles()),
            SliverToBoxAdapter(
              child: _EtatsEtTri(filtre: filtre, liste: liste.value),
            ),
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
                      action: OutlinedButton(
                        onPressed: _effacerTout,
                        child: const Text('Effacer les filtres'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: l.produits.length + (l.complete ? 0 : 1),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => i == l.produits.length
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                            )
                          : LigneProduit(
                              produit: l.produits[i],
                              choisi: l.produits[i].id == widget.selection,
                            ),
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
                  child: MessageErreur(
                    erreur: e,
                    reessayer: () {
                      ref.invalidate(resumeStockProvider);
                      ref.invalidate(listeProduitsProvider);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre, heure des données et valeur du stock.
class _EnTete extends ConsumerWidget {
  const _EnTete();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeStockProvider).value;
    final donnees = resume?.donneesDu;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Stock',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),
              const BoutonPreferences(),
            ],
          ),
          if (resume != null) ...[
            Row(
              children: [
                Icon(Icons.sync_rounded, size: 15, color: context.couleurs.encre3),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    donnees == null
                        ? 'Stock pas encore calculé par la synchronisation'
                        : 'Données EASYPHARM ${horodatage(donnees, DateTime.now().toUtc())}',
                    key: const ValueKey('horodatage'),
                    style: TextStyle(fontSize: 13, color: context.couleurs.encre2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Padding(padding: const EdgeInsets.only(right: 8), child: _TuileValeur(resume)),
          ],
        ],
      ),
    );
  }
}

class _TuileValeur extends StatelessWidget {
  const _TuileValeur(this.resume);
  final ResumeStock resume;

  @override
  Widget build(BuildContext context) {
    final fond = context.couleurs.tuilePrincipale;
    final sur = context.couleurs.surTuilePrincipale;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [fond, Color.lerp(fond, Colors.black, .22)!],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Valeur du stock, prix d'achat",
                  style: TextStyle(color: sur.withValues(alpha: .8), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  dinarsCourt(resume.valeurAchat),
                  style: TextStyle(color: sur, fontFamily: 'Sora', fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dinarsCourt(resume.valeurVente)} au prix de vente',
                  style: TextStyle(color: sur.withValues(alpha: .8), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 56, color: sur.withValues(alpha: .25)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entier(resume.produitsEnStock),
                style: TextStyle(color: sur, fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Text(
                'produits\nen stock',
                style: TextStyle(color: sur.withValues(alpha: .8), fontSize: 12, height: 1.25),
              ),
            ],
          ),
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
        hintText: 'Nom, DCI ou code-barres',
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

/// Une pastille par famille : le premier axe de navigation du stock.
class _Familles extends ConsumerWidget {
  const _Familles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familles = ref.watch(resumeStockProvider).value?.familles ?? const [];
    final choisie = ref.watch(filtreProduitsProvider.select((f) => f.idFamille));
    final visibles = familles.where((f) => f.produitsActifs > 0 || f.id == choisie).toList();
    if (visibles.isEmpty) return const SizedBox(height: 12);

    void choisir(int? id) => ref.read(filtreProduitsProvider.notifier).famille(id);
    return SizedBox(
      height: 56,
      child: ListView(
        key: const ValueKey('familles'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        children: [
          _Pastille(texte: 'Toutes', choisie: choisie == null, surChoix: () => choisir(null)),
          for (final f in visibles)
            if (f.id != null)
              _Pastille(
                texte: libelle(f.famille),
                compte: f.produitsEnStock,
                choisie: choisie == f.id,
                surChoix: () => choisir(choisie == f.id ? null : f.id),
              ),
        ],
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.texte, required this.choisie, required this.surChoix, this.compte});

  final String texte;
  final int? compte;
  final bool choisie;
  final VoidCallback surChoix;

  @override
  Widget build(BuildContext context) {
    final s = context.schema;
    final texteCouleur = choisie ? s.onPrimary : context.couleurs.encre2;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: choisie ? s.primary : s.surface,
        shape: StadiumBorder(side: BorderSide(color: choisie ? s.primary : context.couleurs.bord)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: surChoix,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  texte,
                  style: TextStyle(color: texteCouleur, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (compte != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    entier(compte!),
                    style: TextStyle(color: texteCouleur.withValues(alpha: .7), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filtre d'état (segments) et ordre de la liste.
class _EtatsEtTri extends ConsumerWidget {
  const _EtatsEtTri({required this.filtre, required this.liste});

  final FiltreProduits filtre;
  final ListeProduits? liste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notif = ref.read(filtreProduitsProvider.notifier);
    final total = liste?.total;
    final filtres = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in <FiltreEtat?>[null, ...FiltreEtat.values])
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _Segment(
                        texte: e?.libelle ?? 'Actifs',
                        choisi: filtre.etat == e,
                        surChoix: () => notif.etat(e),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filtres,
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  total == null ? ' ' : '${entier(total)} produit${total > 1 ? 's' : ''}',
                  key: const ValueKey('nombre-produits'),
                  style: TextStyle(fontSize: 12, color: context.couleurs.encre3, fontWeight: FontWeight.w600),
                ),
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
                      Icon(Icons.swap_vert_rounded, size: 18, color: context.couleurs.encre2),
                      const SizedBox(width: 4),
                      Text(
                        filtre.tri.libelle,
                        style: TextStyle(
                          color: context.couleurs.encre2,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.texte, required this.choisi, required this.surChoix});

  final String texte;
  final bool choisi;
  final VoidCallback surChoix;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: surChoix,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: choisi ? context.schema.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: choisi ? context.schema.onPrimaryContainer : context.couleurs.encre2,
        ),
      ),
    ),
  );
}

/// Un produit dans la liste.
class LigneProduit extends StatelessWidget {
  const LigneProduit({super.key, required this.produit, this.choisi = false});

  final Produit produit;
  final bool choisi;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final sousTitre = [p.dci, p.labo].where((t) => t != null && t.trim().isNotEmpty).join(' · ');
    final derniere = p.derniereVente;
    return Material(
      color: context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: choisi ? context.schema.primary : context.couleurs.bord,
          width: choisi ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        key: ValueKey('produit-${p.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/stock/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      p.designation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.25),
                    ),
                  ),
                  const SizedBox(width: 8),
                  EtiquetteClasse(p),
                ],
              ),
              if (sousTitre.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sousTitre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: context.couleurs.encre2),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Row(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: c.maxWidth),
                            child: PastilleStock(produit: p),
                          ),
                          if (derniere != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                depuis(derniere, DateTime.now()),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    p.prixVente > 0 ? dinars(p.prixVente) : '—',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ],
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
        Row(children: [Squelette(largeur: 90, hauteur: 20), Spacer(), Squelette(largeur: 60, hauteur: 14)]),
      ],
    ),
  );
}
