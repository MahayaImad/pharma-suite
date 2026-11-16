import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/commandes_providers.dart';
import 'ecran_livraisons.dart';
import 'panier.dart';

/// Largeur à partir de laquelle le panier s'ouvre à côté des fournisseurs.
const _largeurDeuxVolets = 980.0;

/// Ligne en train d'être glissée d'un panier vers un autre grossiste (PC).
typedef LigneTiree = ({LigneCommande ligne, int de});

/// Commandes du soir — design « épuré, deux volets » retenu le 2026-11-15.
/// À gauche : budget, « Préparer », les grossistes en lignes compactes (cibles
/// du glisser-déposer) ; à droite le panier du grossiste [selection]. Sur
/// portable, la liste puis le panier en plein écran.
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 400, child: _Fournisseurs(selection: selection, large: true)),
                VerticalDivider(width: 1, color: context.couleurs.bord),
                Expanded(
                  child: selection == null
                      ? const _AucunPanier()
                      : PanierFournisseur(key: ValueKey(selection), idFournisseur: selection!, enPanneau: true),
                ),
              ],
            ),
          );
        }
        if (selection != null) return PanierFournisseur(key: ValueKey(selection), idFournisseur: selection!);
        return Scaffold(body: _Fournisseurs(selection: selection, large: false));
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
  const _Fournisseurs({this.selection, required this.large});
  final int? selection;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journee = ref.watch(journeeProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(journeeProvider.future).catchError((_) => journee.value!),
      child: ListView(
        padding: EdgeInsets.fromLTRB(large ? 20 : 16, 14, large ? 20 : 16, 32),
        children: [
          _EnTete(journee: journee.value),
          const OngletsCommandes(livraisons: false),
          ...journee.when(
            skipLoadingOnReload: true,
            loading: () => [const _Chargement()],
            error: (e, _) => [MessageErreur(erreur: e, reessayer: () => ref.invalidate(journeeProvider))],
            data: (j) => _contenu(context, j),
          ),
        ],
      ),
    );
  }

  List<Widget> _contenu(BuildContext context, JourneeCommandes j) {
    if (j.ferme) {
      return const [
        MessageVide(titre: 'Pas de commande aujourd\'hui', texte: 'Les grossistes sont fermés le vendredi.'),
      ];
    }
    final aSignaler = [
      if (j.psychotropes.isNotEmpty)
        _Avertissement(
          cle: 'psychotropes',
          texte: '${j.psychotropes.length} psychotrope${j.psychotropes.length > 1 ? 's' : ''}',
          suite: ' à commander dans EASYPHARM',
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
      _Budget(journee: j),
      if (j.aPreparer) const _BoutonPreparer(),
      if (j.paniers.isEmpty)
        const MessageVide(
          titre: 'Rien à commander ce soir',
          texte: 'Aucun produit ne passe sous son niveau de réapprovisionnement.',
        ),
      for (final type in TypeFournisseur.values)
        if (j.paniersDe(type).isNotEmpty) ...[
          _TitreSection(type.libelle),
          for (final p in j.paniersDe(type))
            LigneFournisseur(panier: p, choisi: p.fournisseur.id == selection, cibleDeplacement: large),
        ],
      if (aSignaler.isNotEmpty) ...[const SizedBox(height: 14), ...aSignaler],
      if (large && j.paniers.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 0),
          child: Text(
            '⋮⋮ Glissez une ligne du panier sur un fournisseur pour changer de grossiste.',
            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commandes',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700),
                ),
                if (j != null)
                  Text(
                    [
                      jourEtDate(j.jour),
                      if (j.donneesDu != null) 'données ${horodatage(j.donneesDu!, DateTime.now().toUtc())}',
                    ].join(' · '),
                    key: const ValueKey('sous-titre-commandes'),
                    style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
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
    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 8),
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

/// Budget du mois en une ligne et une barre fine : dépensé, proposé ce soir.
class _Budget extends StatelessWidget {
  const _Budget({required this.journee});
  final JourneeCommandes journee;

  @override
  Widget build(BuildContext context) {
    final b = journee.budget;
    final mois = _mois[journee.jour.month - 1];
    final depense = b.fixe ? (b.depense / b.budget).clamp(0.0, 1.0) : 0.0;
    final propose = b.fixe ? (b.propose / b.budget).clamp(0.0, 1.0 - depense) : 0.0;
    final petit = TextStyle(fontSize: 12, color: context.couleurs.encre2);
    const fort = TextStyle(fontWeight: FontWeight.w700);
    return Container(
      key: const ValueKey('bande-budget'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: context.schema.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.couleurs.bord),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: b.fixe ? 'Budget $mois · ' : 'Achats de $mois · '),
                      TextSpan(
                        text: b.fixe ? dinarsCourt(b.depense).replaceAll(' DA', '') : dinarsCourt(b.depense),
                        style: fort,
                      ),
                      if (b.fixe) TextSpan(text: ' / ${dinarsCourt(b.budget)}'),
                    ],
                  ),
                  style: petit,
                ),
              ),
              const SizedBox(width: 10),
              Text.rich(
                key: const ValueKey('budget-reste'),
                TextSpan(
                  children: b.fixe
                      ? [const TextSpan(text: 'reste après '), TextSpan(text: dinarsCourt(b.resteApres), style: fort)]
                      : [const TextSpan(text: 'ce soir '), TextSpan(text: dinarsCourt(b.propose), style: fort)],
                ),
                style: petit,
              ),
            ],
          ),
          if (b.fixe) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: context.couleurs.neutreDoux)),
                    FractionallySizedBox(
                      widthFactor: (depense + propose).clamp(0.0, 1.0),
                      heightFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: ColoredBox(color: context.schema.primary.withValues(alpha: 0.35)),
                    ),
                    FractionallySizedBox(
                      widthFactor: depense,
                      heightFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: ColoredBox(color: context.schema.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    padding: const EdgeInsets.only(bottom: 4),
    child: FilledButton.icon(
      key: const ValueKey('bouton-preparer'),
      onPressed: _enCours ? null : _preparer,
      icon: _enCours
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.playlist_add_check_rounded),
      label: const Text('Préparer toutes les commandes'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
    child: Text(
      texte.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Sora',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: context.couleurs.encre3,
      ),
    ),
  );
}

// ── Un fournisseur ─────────────────────────────────────────────────────────

/// Couleurs des initiales : bleu pour un grossiste pharmaceutique, rose pour
/// un parapharmaceutique.
({Color fond, Color texte}) couleursFournisseur(BuildContext context, TypeFournisseur type) =>
    type == TypeFournisseur.pharma
    ? (fond: context.schema.primaryContainer, texte: context.schema.onPrimaryContainer)
    : (fond: const Color(0xFFFBE5EF), texte: const Color(0xFFB2336A));

/// « Grossiste Atlas » → « GA ».
String initiales(String? nom) {
  final mots = (nom ?? '?').trim().split(RegExp(r'[\s\-]+')).where((m) => m.isNotEmpty).toList();
  if (mots.isEmpty) return '?';
  if (mots.length == 1) return mots.first.substring(0, mots.first.length < 2 ? 1 : 2).toUpperCase();
  return (mots[0][0] + mots[1][0]).toUpperCase();
}

class InitialeFournisseur extends StatelessWidget {
  const InitialeFournisseur({super.key, required this.fournisseur, this.taille = 40});
  final FournisseurPanier fournisseur;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final c = couleursFournisseur(context, fournisseur.type);
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.fond, borderRadius: BorderRadius.circular(taille * 0.3)),
      child: Text(
        initiales(fournisseur.nom),
        style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: taille * 0.33, color: c.texte),
      ),
    );
  }
}

/// Étape d'un panier en petite pastille de couleur.
class PastilleEtape extends StatelessWidget {
  const PastilleEtape(this.etape, {super.key});
  final EtapePanier etape;

  @override
  Widget build(BuildContext context) {
    final e = context.etats;
    final (fond, texte) = switch (etape) {
      EtapePanier.propose => (context.couleurs.neutreDoux, context.couleurs.encre2),
      EtapePanier.brouillon => (e.alerteDoux, e.alerte),
      EtapePanier.validee => (e.bonDoux, e.bon),
      EtapePanier.envoyee => (const Color(0xFFEEE7FB), const Color(0xFF6B3FC4)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(999)),
      child: Text(
        etape.libelle,
        style: TextStyle(color: texte, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Un grossiste en une ligne : initiales, nom, lignes et livraison, montant
/// et étape. Sur PC, c'est aussi une cible : on y dépose une ligne glissée
/// depuis un autre panier pour changer de grossiste.
class LigneFournisseur extends ConsumerWidget {
  const LigneFournisseur({super.key, required this.panier, this.choisi = false, this.cibleDeplacement = false});
  final Panier panier;
  final bool choisi, cibleDeplacement;

  bool get _accepte => panier.etape == EtapePanier.propose || panier.etape == EtapePanier.brouillon;

  Future<void> _deposer(BuildContext context, WidgetRef ref, LigneTiree t) async {
    try {
      await ref.read(journeeProvider.notifier).deplacer(t.ligne, t.de, panier.fournisseur.id);
      if (context.mounted) annoncerDeplacement(context, ref, t.ligne, panier.fournisseur);
    } catch (e) {
      if (context.mounted) montrerErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget ligne(bool survol) {
      final p = panier;
      final f = p.fournisseur;
      final bord = survol ? context.schema.primary : (choisi ? context.schema.primary : Colors.transparent);
      return Material(
        color: survol
            ? context.schema.primaryContainer.withValues(alpha: 0.5)
            : (choisi ? context.schema.surface : Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: bord, width: choisi || survol ? 1.5 : 0),
        ),
        child: InkWell(
          key: ValueKey('carte-fournisseur-${f.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/commandes/${f.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                InitialeFournisseur(fournisseur: f, taille: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libelleProduit(f.nom ?? 'Fournisseur ${f.id}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 1),
                      survol
                          ? Text(
                              'Déposer ici',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.schema.primary,
                              ),
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: [
                                      '${p.nbLignes} ligne${p.nbLignes > 1 ? 's' : ''}',
                                      if (p.livraisonPrevue != null) jourEtDate(p.livraisonPrevue!),
                                    ].join(' · '),
                                  ),
                                  if (p.ruptures > 0)
                                    TextSpan(
                                      text: ' · ${p.ruptures} rupt.',
                                      style: TextStyle(color: context.etats.critique, fontWeight: FontWeight.w700),
                                    ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dinars(p.montant.round()),
                      style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    PastilleEtape(p.etape),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final contenu = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: cibleDeplacement
          ? DragTarget<LigneTiree>(
              onWillAcceptWithDetails: (d) => _accepte && d.data.de != panier.fournisseur.id,
              onAcceptWithDetails: (d) => _deposer(context, ref, d.data),
              builder: (context, candidats, _) => ligne(candidats.isNotEmpty),
            )
          : ligne(false),
    );
    return contenu;
  }
}

// ── Psychotropes, sans fournisseur ──────────────────────────────────────────

class _Avertissement extends StatelessWidget {
  const _Avertissement({required this.cle, required this.texte, required this.suite, required this.lignes});
  final String cle, texte, suite;
  final List<LigneCommande> lignes;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: context.etats.alerteDoux.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('avertissement-$cle'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (c) => _ListeAvertissement(titre: '$texte$suite', lignes: lignes),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: context.etats.alerteIcone),
              const SizedBox(width: 10),
              Expanded(
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
                  style: const TextStyle(fontSize: 13),
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

/// Après un changement de grossiste : le dit, et propose de retenir ce
/// grossiste pour les soirs suivants (sinon le changement ne vaut que ce soir).
void annoncerDeplacement(BuildContext context, WidgetRef ref, LigneCommande ligne, FournisseurPanier vers) {
  final messager = ScaffoldMessenger.of(context);
  final chez = libelleProduit(vers.nom ?? '');
  messager
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('${libelleProduit(ligne.nom ?? '')} passe chez $chez, pour ce soir. Le retenir pour la suite ?'),
        action: SnackBarAction(
          label: 'Toujours',
          onPressed: () async {
            try {
              await ref.read(journeeProvider.notifier).preferer(ligne.idNom, vers.id);
              messager.showSnackBar(
                SnackBar(content: Text('${libelleProduit(ligne.nom ?? '')} sera désormais commandé chez $chez.')),
              );
            } catch (e) {
              messager.showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
            }
          },
        ),
      ),
    );
}
