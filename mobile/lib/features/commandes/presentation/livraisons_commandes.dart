import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/commandes_providers.dart';
import 'ecran_livraisons.dart';

/// Largeur à partir de laquelle la commande s'ouvre à côté de la liste.
const _largeurDeuxVolets = 980.0;

/// Livraisons, vue « par commande » : à gauche les commandes envoyées (à
/// vérifier, attendues, livrées), à droite les lignes de la commande
/// [selection], ce qui manque d'abord. Sur portable, la liste puis la
/// commande en plein écran.
class EcranLivraisonsParCommande extends ConsumerWidget {
  const EcranLivraisonsParCommande({super.key, this.selection});

  final int? selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suivi = ref.watch(suiviProvider);
    return LayoutBuilder(
      builder: (context, contraintes) {
        final large = contraintes.maxWidth >= _largeurDeuxVolets;
        final s = suivi.value;
        // Sur PC, sans choix : la première commande à vérifier, sinon la plus récente.
        final choisie = s == null
            ? null
            : (selection != null
                  ? s.commande(selection!)
                  : (large ? (_aVerifier(s).firstOrNull ?? s.commandes.firstOrNull) : null));
        if (!large && selection != null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/commandes/livraisons/commandes'),
              ),
              title: const Text('Livraison'),
            ),
            body: suivi.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(suiviProvider)),
              data: (s) => choisie == null
                  ? const MessageVide(titre: 'Commande introuvable', texte: 'Elle n\'est plus dans la période suivie.')
                  : _DetailCommande(suivi: s, commande: choisie, large: false),
            ),
          );
        }
        final liste = RefreshIndicator(
          onRefresh: () => ref.refresh(suiviProvider.future).catchError((_) => suivi.value!),
          child: ListView(
            padding: EdgeInsets.fromLTRB(large ? 20 : 16, 14, large ? 20 : 16, 32),
            children: [
              EnTeteLivraisons(suivi: s),
              const OngletsCommandes(livraisons: true),
              if (s != null && s.commandes.isNotEmpty) const BasculeVueLivraisons(parCommande: true),
              ...suivi.when(
                skipLoadingOnReload: true,
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [MessageErreur(erreur: e, reessayer: () => ref.invalidate(suiviProvider))],
                data: (s) => _groupes(context, s, choisie?.id),
              ),
            ],
          ),
        );
        if (!large) return Scaffold(body: liste);
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 400, child: liste),
              VerticalDivider(width: 1, color: context.couleurs.bord),
              Expanded(
                child: ColoredBox(
                  color: context.schema.surface,
                  child: s == null || choisie == null
                      ? const SizedBox.shrink()
                      : _DetailCommande(key: ValueKey(choisie.id), suivi: s, commande: choisie, large: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static List<CommandeSuivie> _aVerifier(SuiviLivraisons s) => [
    for (final c in s.commandes)
      if (c.etat == EtatLivraison.partielle || c.etat == EtatLivraison.manquante) c,
  ];

  List<Widget> _groupes(BuildContext context, SuiviLivraisons s, int? choisie) {
    if (s.commandes.isEmpty) {
      return [
        MessageVide(
          titre: 'Aucune commande envoyée',
          texte:
              'Les commandes validées ou envoyées des ${s.jours} derniers jours apparaîtront ici, '
              'rapprochées des réceptions saisies dans EASYPHARM.',
        ),
      ];
    }
    final groupes = [
      ('À vérifier', _aVerifier(s)),
      (
        'Attendues',
        [
          for (final c in s.commandes)
            if (c.etat == EtatLivraison.attendue) c,
        ],
      ),
      (
        'Livrées',
        [
          for (final c in s.commandes)
            if (c.etat == EtatLivraison.livree) c,
        ],
      ),
    ];
    return [
      for (final (titre, commandes) in groupes)
        if (commandes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
            child: Text(
              titre.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: context.couleurs.encre3,
              ),
            ),
          ),
          for (final c in commandes) _CarteCommande(commande: c, choisie: c.id == choisie),
        ],
    ];
  }
}

/// Couleur et fond d'un état de livraison.
(Color, Color) _couleurs(BuildContext context, EtatLivraison etat) {
  final e = context.etats;
  return switch (etat) {
    EtatLivraison.manquante => (e.critique, e.critiqueDoux),
    EtatLivraison.partielle => (e.alerte, e.alerteDoux),
    EtatLivraison.livree => (e.bon, e.bonDoux),
    EtatLivraison.attendue => (context.couleurs.encre2, context.couleurs.neutreDoux),
  };
}

class _CarteCommande extends StatelessWidget {
  const _CarteCommande({required this.commande, required this.choisie});
  final CommandeSuivie commande;
  final bool choisie;

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final (couleur, fond) = _couleurs(context, c.etat);
    final nom = libelleProduit(c.fournisseur.nom ?? 'Fournisseur');
    final initiales = nom.replaceAll(RegExp('[^A-Za-zÀ-ÿ]'), '').padRight(2).substring(0, 2).toUpperCase();
    final total = c.lignes.length;
    final prevue = c.livraisonPrevue;
    final recue = c.recueLe;
    final (pastille, compte) = switch (c.etat) {
      EtatLivraison.partielle => ('Partielle', '${c.livrees} / $total ligne${total > 1 ? 's' : ''}'),
      EtatLivraison.manquante => ('Rien reçu', '0 / $total ligne${total > 1 ? 's' : ''}'),
      EtatLivraison.livree => ('Complète', '$total ligne${total > 1 ? 's' : ''}'),
      EtatLivraison.attendue => (
        prevue == null ? 'Attendue' : jourEtDate(prevue),
        '$total ligne${total > 1 ? 's' : ''}',
      ),
    };
    final detail = [
      'du ${jourMois(c.jour)}',
      if (c.etat == EtatLivraison.livree && recue != null)
        'reçue le ${jourMois(recue)}'
      else if (prevue != null)
        'prévue le ${jourMois(prevue)}',
    ].join(' · ');
    final aVerifier = c.etat == EtatLivraison.partielle || c.etat == EtatLivraison.manquante;
    final e = context.etats;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: choisie ? context.schema.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: choisie ? context.schema.primary : Colors.transparent, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('commande-suivie-${c.id}'),
          onTap: () => context.go('/commandes/livraisons/commandes/${c.id}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(11)),
                  child: Text(
                    initiales,
                    style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 12, color: couleur),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                      ),
                      if (aVerifier) ...[
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final (etat, teinte) in [
                                  (EtatLivraison.livree, e.bon),
                                  (EtatLivraison.partielle, e.alerte),
                                  (EtatLivraison.manquante, e.critique),
                                ])
                                  if (c.lignesDe(etat).isNotEmpty)
                                    Expanded(
                                      flex: c.lignesDe(etat).length,
                                      child: ColoredBox(color: teinte),
                                    ),
                              ],
                            ),
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
                    PastilleLivraison(pastille, couleur, fond),
                    const SizedBox(height: 4),
                    Text(compte, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailCommande extends ConsumerStatefulWidget {
  const _DetailCommande({super.key, required this.suivi, required this.commande, required this.large});
  final SuiviLivraisons suivi;
  final CommandeSuivie commande;
  final bool large;

  @override
  ConsumerState<_DetailCommande> createState() => _EtatDetailCommande();
}

class _EtatDetailCommande extends ConsumerState<_DetailCommande> {
  bool _livreesOuvertes = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final s = widget.suivi;
    final marge = widget.large ? 28.0 : 16.0;
    final nom = libelleProduit(c.fournisseur.nom ?? 'Fournisseur');
    final taux = s.tauxDe(c.fournisseur.id);
    final prevue = c.livraisonPrevue;
    final aRecommander = c.aRecommander;
    final gris = TextStyle(fontSize: 13, color: context.couleurs.encre3);
    final montant = Column(
      crossAxisAlignment: widget.large ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          dinars(c.montantRecu.round()),
          key: const ValueKey('montant-recu'),
          style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text('reçu sur ${dinars(c.montant.round())}', style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
      ],
    );
    final titre = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$nom · commande du ${jourMois(c.jour)}',
          style: const TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(
            style: gris,
            children: [
              TextSpan(
                text: [
                  '${c.lignes.length} ligne${c.lignes.length > 1 ? 's' : ''}',
                  if (prevue != null) 'livraison prévue ${jourEtDate(prevue)}',
                  if (taux != null) 'taux de service sur ${s.jours} jours : ',
                ].join(' · '),
              ),
              if (taux != null)
                TextSpan(
                  text: '$taux %',
                  style: TextStyle(fontWeight: FontWeight.w700, color: couleurTaux(context, taux)),
                ),
            ],
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(marge, widget.large ? 22 : 12, marge, 14),
          child: widget.large
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: titre),
                    const SizedBox(width: 14),
                    montant,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titre, const SizedBox(height: 10), montant],
                ),
        ),
        Divider(height: 1, color: context.couleurs.bord),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              for (final etat in EtatLivraison.values)
                if (c.lignesDe(etat).isNotEmpty) ...[
                  _TitreEtat(
                    etat: etat,
                    nombre: c.lignesDe(etat).length,
                    marge: marge,
                    ouvert: etat != EtatLivraison.livree || _livreesOuvertes || c.etat == EtatLivraison.livree,
                    basculer: etat == EtatLivraison.livree && c.etat != EtatLivraison.livree
                        ? () => setState(() => _livreesOuvertes = !_livreesOuvertes)
                        : null,
                  ),
                  if (etat != EtatLivraison.livree || _livreesOuvertes || c.etat == EtatLivraison.livree)
                    for (final l in c.lignesDe(etat))
                      _LigneCommande(ligne: l, marge: marge, sansLivraison: s.commandesSansLivraison(l.idNom)),
                ],
            ],
          ),
        ),
        if (aRecommander.isNotEmpty) ...[
          Divider(height: 1, color: context.couleurs.bord),
          Padding(
            padding: EdgeInsets.fromLTRB(marge, 12, marge, 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 8,
              children: [
                Text(
                  'Les ${aRecommander.length} produits non livrés seront reproposés ce soir.',
                  style: TextStyle(fontSize: 13, color: context.couleurs.encre2),
                ),
                OutlinedButton(
                  key: const ValueKey('recommander-ailleurs'),
                  onPressed: () => recommanderAilleurs(context, ref, c.fournisseur.id, [
                    for (final l in aRecommander) (idNom: l.idNom, qte: l.reste > 0 ? l.reste : l.qte),
                  ]),
                  child: const Text('Recommander chez un autre grossiste'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TitreEtat extends StatelessWidget {
  const _TitreEtat({
    required this.etat,
    required this.nombre,
    required this.marge,
    required this.ouvert,
    this.basculer,
  });
  final EtatLivraison etat;
  final int nombre;
  final double marge;
  final bool ouvert;
  final VoidCallback? basculer;

  @override
  Widget build(BuildContext context) {
    final (couleur, _) = _couleurs(context, etat);
    return InkWell(
      key: ValueKey('section-${etat.name}'),
      onTap: basculer,
      child: Padding(
        padding: EdgeInsets.fromLTRB(marge, 16, marge, 8),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '${etat.libelle.toUpperCase()} · $nombre',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: couleur,
              ),
            ),
            const Spacer(),
            if (basculer != null)
              Text(ouvert ? 'Masquer' : 'Afficher ›', style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
          ],
        ),
      ),
    );
  }
}

class _LigneCommande extends StatelessWidget {
  const _LigneCommande({required this.ligne, required this.marge, required this.sansLivraison});
  final LigneSuivie ligne;
  final double marge;
  final int sansLivraison;

  @override
  Widget build(BuildContext context) {
    final l = ligne;
    final (couleur, fond) = _couleurs(context, l.etat);
    final detail = [
      'stock ${l.stock}',
      if (l.recuLe != null) 'reçu le ${jourMois(l.recuLe!)}',
      if (l.etat == EtatLivraison.manquante && sansLivraison > 1) '$sansLivraisonᵉ commande sans livraison',
      if (l.tension == 'proposee') 'proposé en tension',
      if (l.tension == 'confirmee') 'en tension',
    ].join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.couleurs.bord.withValues(alpha: 0.6))),
      ),
      child: Padding(
        key: ValueKey('ligne-suivie-${l.idNom}'),
        padding: EdgeInsets.symmetric(horizontal: marge, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelleProduit(l.nom ?? 'Produit ${l.idNom}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${l.recu}',
                  style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text('/ ${l.qte}', style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
              ],
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 96,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PastilleLivraison(
                  l.etat == EtatLivraison.partielle ? 'Reste ${l.reste}' : l.etat.libelle,
                  couleur,
                  fond,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
