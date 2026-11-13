import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../core/widgets/pastille_etat.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/commandes_providers.dart';
import 'panier.dart';

/// Largeur à partir de laquelle le panier s'ouvre à côté des fournisseurs.
const _largeurDeuxVolets = 980.0;

/// Commandes du soir (proposition 1 retenue le 2026-11-13) : le budget du
/// mois, puis une carte par grossiste, pharmaceutiques puis
/// parapharmaceutiques ; le panier du fournisseur [selection] à côté sur
/// PC, en plein écran sur portable.
class EcranCommandes extends StatelessWidget {
  const EcranCommandes({super.key, this.selection});

  final int? selection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, contraintes) {
        if (contraintes.maxWidth >= _largeurDeuxVolets) {
          return Scaffold(
            body: Row(
              children: [
                Expanded(child: _Fournisseurs(selection: selection)),
                const VerticalDivider(),
                SizedBox(
                  width: (contraintes.maxWidth * 0.4).clamp(440, 560),
                  child: selection == null
                      ? const _AucunPanier()
                      : PanierFournisseur(key: ValueKey(selection), idFournisseur: selection!, enPanneau: true),
                ),
              ],
            ),
          );
        }
        if (selection != null) return PanierFournisseur(key: ValueKey(selection), idFournisseur: selection!);
        return Scaffold(body: _Fournisseurs(selection: selection));
      },
    );
  }
}

class _AucunPanier extends StatelessWidget {
  const _AucunPanier();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.schema.surface,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 40, color: context.couleurs.encre3),
            const SizedBox(height: 10),
            Text(
              'Choisissez un fournisseur pour voir son panier.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.couleurs.encre2),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Fournisseurs extends ConsumerWidget {
  const _Fournisseurs({this.selection});
  final int? selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journee = ref.watch(journeeProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(journeeProvider.future).catchError((_) => journee.value!),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _EnTete(journee: journee.value)),
          ...journee.when(
            skipLoadingOnReload: true,
            loading: () => [const SliverToBoxAdapter(child: _Chargement())],
            error: (e, _) => [
              SliverToBoxAdapter(
                child: MessageErreur(erreur: e, reessayer: () => ref.invalidate(journeeProvider)),
              ),
            ],
            data: (j) => _contenu(context, ref, j),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenu(BuildContext context, WidgetRef ref, JourneeCommandes j) {
    if (j.ferme) {
      return const [
        SliverToBoxAdapter(
          child: MessageVide(titre: 'Pas de commande aujourd\'hui', texte: 'Les grossistes sont fermés le vendredi.'),
        ),
      ];
    }
    final avertissements = [
      if (j.psychotropes.isNotEmpty)
        _Avertissement(
          cle: 'psychotropes',
          texte: '${j.psychotropes.length} psychotrope${j.psychotropes.length > 1 ? 's' : ''}',
          suite: ' à commander dans EASYPHARM (bon spécial)',
          lignes: j.psychotropes,
        ),
      if (j.sansFournisseur.isNotEmpty)
        _Avertissement(
          cle: 'sans-fournisseur',
          texte: '${j.sansFournisseur.length} produit${j.sansFournisseur.length > 1 ? 's' : ''}',
          suite: ' sans fournisseur actif',
          lignes: j.sansFournisseur,
        ),
    ];
    return [
      SliverToBoxAdapter(child: _BandeBudget(journee: j)),
      if (j.aPreparer) const SliverToBoxAdapter(child: _BoutonPreparer()),
      if (j.paniers.isEmpty)
        const SliverToBoxAdapter(
          child: MessageVide(
            titre: 'Rien à commander ce soir',
            texte: 'Aucun produit ne passe sous son niveau de réapprovisionnement.',
          ),
        ),
      for (final type in TypeFournisseur.values)
        if (j.paniersDe(type).isNotEmpty) ...[
          SliverToBoxAdapter(child: _TitreSection(type.libelle)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 168,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: j.paniersDe(type).length,
              itemBuilder: (context, i) {
                final p = j.paniersDe(type)[i];
                return CarteFournisseur(panier: p, choisi: p.fournisseur.id == selection);
              },
            ),
          ),
        ],
      if (avertissements.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Wrap(spacing: 10, runSpacing: 10, children: avertissements),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({this.journee});
  final JourneeCommandes? journee;

  @override
  Widget build(BuildContext context) {
    final j = journee;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commandes',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 26, fontWeight: FontWeight.w700),
                ),
                if (j != null)
                  Text(
                    [
                      'Commande du ${jourEtDate(j.jour)}',
                      if (j.donneesDu != null) 'données ${horodatage(j.donneesDu!, DateTime.now().toUtc())}',
                    ].join(' · '),
                    key: const ValueKey('sous-titre-commandes'),
                    style: TextStyle(fontSize: 13, color: context.couleurs.encre3),
                  ),
              ],
            ),
          ),
          const BoutonPreferences(),
        ],
      ),
    );
  }
}

class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
    child: Column(
      children: [
        const CircularProgressIndicator(strokeWidth: 2.5),
        const SizedBox(height: 16),
        Text(
          'Calcul des quantités à commander…\nLe premier calcul de la journée peut prendre une minute.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.couleurs.encre2),
        ),
      ],
    ),
  );
}

// ── Budget ──────────────────────────────────────────────────────────────────

const _mois = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

class _BandeBudget extends StatelessWidget {
  const _BandeBudget({required this.journee});
  final JourneeCommandes journee;

  @override
  Widget build(BuildContext context) {
    final b = journee.budget;
    const blanc = Colors.white;
    final doux = Colors.white.withValues(alpha: 0.82);
    Widget chiffre(String titre, String valeur, {String? suite, Key? cle}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: TextStyle(color: doux, fontSize: 12)),
        const SizedBox(height: 2),
        Text.rich(
          key: cle,
          TextSpan(
            text: valeur,
            style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, color: blanc),
            children: [
              if (suite != null)
                TextSpan(
                  text: suite,
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w500, color: doux),
                ),
            ],
          ),
        ),
      ],
    );
    final depense = b.fixe ? (b.depense / b.budget).clamp(0.0, 1.0) : 0.0;
    final propose = b.fixe ? (b.propose / b.budget).clamp(0.0, 1.0 - depense) : 0.0;
    return Container(
      key: const ValueKey('bande-budget'),
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.schema.primary, Color.lerp(context.schema.primary, Colors.black, 0.28)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              if (b.fixe)
                chiffre(
                  'Budget de ${_mois[journee.jour.month - 1]}',
                  dinarsCourt(b.depense).replaceAll(' DA', ''),
                  suite: ' sur ${dinarsCourt(b.budget)}',
                )
              else
                chiffre('Achats de ${_mois[journee.jour.month - 1]}', dinarsCourt(b.depense)),
              chiffre('Proposé ce soir', dinarsCourt(b.propose), cle: const ValueKey('budget-propose')),
              if (b.fixe) chiffre('Reste après', dinarsCourt(b.resteApres), cle: const ValueKey('budget-reste')),
            ],
          ),
          const SizedBox(height: 14),
          if (b.fixe) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.18))),
                    FractionallySizedBox(
                      widthFactor: (depense + propose).clamp(0.0, 1.0),
                      heightFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: ColoredBox(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    FractionallySizedBox(
                      widthFactor: depense,
                      heightFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: const ColoredBox(color: blanc),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('■ reçu et engagé   ▨ proposé ce soir', style: TextStyle(color: doux, fontSize: 12)),
          ] else
            Text(
              'Aucun budget fixé : le titulaire le règle dans Préférences › Calendrier et réglages.',
              style: TextStyle(color: doux, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _BoutonPreparer extends ConsumerStatefulWidget {
  const _BoutonPreparer();

  @override
  ConsumerState<_BoutonPreparer> createState() => _BoutonPreparerState();
}

class _BoutonPreparerState extends ConsumerState<_BoutonPreparer> {
  bool _enCours = false;

  Future<void> _preparer() async {
    setState(() => _enCours = true);
    try {
      await ref.read(journeeProvider.notifier).preparer();
    } catch (e) {
      if (mounted) montrerErreur(context, e);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: FilledButton.icon(
      key: const ValueKey('bouton-preparer'),
      onPressed: _enCours ? null : _preparer,
      icon: _enCours
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.playlist_add_check_rounded),
      label: const Text('Préparer toutes les commandes'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    ),
  );
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 20, 16, 10),
    child: Text(
      texte.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Sora',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: context.couleurs.encre3,
      ),
    ),
  );
}

// ── Carte d'un fournisseur ──────────────────────────────────────────────────

/// Couleurs de l'initiale : bleu pour un grossiste pharmaceutique, rose pour
/// un parapharmaceutique.
({Color fond, Color texte}) couleursFournisseur(BuildContext context, TypeFournisseur type) =>
    type == TypeFournisseur.pharma
    ? (fond: context.schema.primaryContainer, texte: context.schema.onPrimaryContainer)
    : (fond: const Color(0xFFFBE5EF), texte: const Color(0xFFB2336A));

class InitialeFournisseur extends StatelessWidget {
  const InitialeFournisseur({super.key, required this.fournisseur, this.taille = 40});
  final FournisseurPanier fournisseur;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final c = couleursFournisseur(context, fournisseur.type);
    final nom = (fournisseur.nom ?? '?').trim();
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.fond, borderRadius: BorderRadius.circular(taille * 0.3)),
      child: Text(
        nom.isEmpty ? '?' : nom[0].toUpperCase(),
        style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: taille * 0.4, color: c.texte),
      ),
    );
  }
}

/// Pastille de l'étape d'un panier.
class PastilleEtape extends StatelessWidget {
  const PastilleEtape(this.etape, {super.key});
  final EtapePanier etape;

  @override
  Widget build(BuildContext context) => switch (etape) {
    EtapePanier.propose => const PastilleEtat(
      niveau: NiveauEtat.neutre,
      libelle: 'Proposé',
      icone: Icons.auto_awesome_outlined,
    ),
    EtapePanier.brouillon => const PastilleEtat(
      niveau: NiveauEtat.alerte,
      libelle: 'Brouillon',
      icone: Icons.edit_note_rounded,
    ),
    EtapePanier.validee => const PastilleEtat(niveau: NiveauEtat.bon, libelle: 'Validée'),
    EtapePanier.envoyee => const PastilleEtat(niveau: NiveauEtat.bon, libelle: 'Envoyée', icone: Icons.send_rounded),
  };
}

class CarteFournisseur extends StatelessWidget {
  const CarteFournisseur({super.key, required this.panier, this.choisi = false});
  final Panier panier;
  final bool choisi;

  @override
  Widget build(BuildContext context) {
    final p = panier;
    final f = p.fournisseur;
    return Material(
      color: context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: choisi ? context.schema.primary : context.couleurs.bord, width: choisi ? 1.6 : 1),
      ),
      child: InkWell(
        key: ValueKey('carte-fournisseur-${f.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go('/commandes/${f.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialeFournisseur(fournisseur: f, taille: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.nom ?? 'Fournisseur ${f.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        if (p.livraisonPrevue != null)
                          Text(
                            'livraison ${jourEtDate(p.livraisonPrevue!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                dinars(p.montant.round()),
                style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 20),
              ),
              Text(
                '${p.nbLignes} ligne${p.nbLignes > 1 ? 's' : ''} · ${entier(p.boites)} boîte${p.boites > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  PastilleEtape(p.etape),
                  if (p.ruptures > 0)
                    PastilleEtat(
                      niveau: NiveauEtat.critique,
                      libelle: '${p.ruptures} rupture${p.ruptures > 1 ? 's' : ''}',
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

// ── Psychotropes, sans fournisseur ──────────────────────────────────────────

class _Avertissement extends StatelessWidget {
  const _Avertissement({required this.cle, required this.texte, required this.suite, required this.lignes});
  final String cle, texte, suite;
  final List<LigneCommande> lignes;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 240, maxWidth: 420),
    child: Material(
      color: context.etats.alerteDoux,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('avertissement-$cle'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (c) => _ListeAvertissement(titre: '$texte$suite', lignes: lignes),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: context.etats.alerteIcone),
              const SizedBox(width: 10),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: texte,
                        style: TextStyle(fontWeight: FontWeight.w700, color: context.etats.alerte),
                      ),
                      TextSpan(text: suite),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.couleurs.encre3),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ListeAvertissement extends StatelessWidget {
  const _ListeAvertissement({required this.titre, required this.lignes});
  final String titre;
  final List<LigneCommande> lignes;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.92,
    builder: (context, defilement) => ListView(
      controller: defilement,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          titre,
          style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        for (final l in lignes)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(libelleProduit(l.nom ?? 'Produit ${l.idNom}')),
            subtitle: Text(
              [
                if (l.fournisseur != null) l.fournisseur!,
                'stock ${entier(l.stock)}',
                if (l.explication.isNotEmpty) l.explication,
              ].join(' · '),
            ),
            trailing: Text(
              '${l.qte}',
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
      ],
    ),
  );
}

/// Message d'erreur en bas de l'écran.
void montrerErreur(BuildContext context, Object erreur) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(erreur).message)));
}
