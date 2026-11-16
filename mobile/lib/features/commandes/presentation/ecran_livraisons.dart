import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../data/api/client_api.dart';
import '../../../data/api/commandes_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/commandes_providers.dart';

/// Largeur à partir de laquelle le taux de service s'affiche à côté de la liste.
const _largeurAvecCote = 1100.0;

/// « À commander | Livraisons » : en haut des deux écrans des commandes.
class OngletsCommandes extends ConsumerWidget {
  const OngletsCommandes({super.key, required this.livraisons});

  /// Vrai sur l'écran Livraisons.
  final bool livraisons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aVerifier = ref.watch(suiviProvider).value?.aVerifier ?? 0;
    Widget onglet(String texte, bool actif, String chemin, {int pastille = 0}) => InkWell(
      key: ValueKey('onglet-$chemin'),
      borderRadius: BorderRadius.circular(10),
      onTap: actif ? null : () => context.go(chemin),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? context.schema.surface : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: actif ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texte,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: actif ? context.schema.onSurface : context.couleurs.encre2,
              ),
            ),
            if (pastille > 0) ...[
              const SizedBox(width: 6),
              Container(
                key: const ValueKey('pastille-livraisons'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: context.etats.critique, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  '$pastille',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: context.couleurs.neutreDoux, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            onglet('À commander', !livraisons, '/commandes'),
            onglet('Livraisons', livraisons, '/commandes/livraisons', pastille: aVerifier),
          ],
        ),
      ),
    );
  }
}

/// Livraisons — design « par produit » retenu le 2026-11-16 : tuiles, liste
/// des produits non livrés (puis partiels, attendus, livrés), taux de service
/// des grossistes à droite sur PC, en bas sur portable.
class EcranLivraisons extends ConsumerStatefulWidget {
  const EcranLivraisons({super.key});

  @override
  ConsumerState<EcranLivraisons> createState() => _EtatEcranLivraisons();
}

class _EtatEcranLivraisons extends ConsumerState<EcranLivraisons> {
  EtatLivraison _filtre = EtatLivraison.manquante;

  @override
  Widget build(BuildContext context) {
    final suivi = ref.watch(suiviProvider);
    return LayoutBuilder(
      builder: (context, contraintes) {
        final large = contraintes.maxWidth >= _largeurAvecCote;
        final s = suivi.value;
        final liste = RefreshIndicator(
          onRefresh: () => ref.refresh(suiviProvider.future).catchError((_) => suivi.value!),
          child: ListView(
            padding: EdgeInsets.fromLTRB(large ? 28 : 16, 14, large ? 28 : 16, 32),
            children: [
              _EnTete(suivi: s),
              const OngletsCommandes(livraisons: true),
              ...suivi.when(
                skipLoadingOnReload: true,
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [MessageErreur(erreur: e, reessayer: () => ref.invalidate(suiviProvider))],
                data: (s) => _contenu(s, large),
              ),
            ],
          ),
        );
        if (!large || s == null || s.fournisseurs.isEmpty) return Scaffold(body: liste);
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: liste),
              VerticalDivider(width: 1, color: context.couleurs.bord),
              SizedBox(
                width: 320,
                child: ColoredBox(
                  color: context.schema.surface,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [_TauxService(suivi: s)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contenu(SuiviLivraisons s, bool large) {
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
    final lignes = s.lignesDe(_filtre);
    final e = context.etats;
    final taux = s.tauxService;
    return [
      _Tuiles(
        tuiles: [
          (
            cle: 'manquante',
            valeur: '${s.lignesDe(EtatLivraison.manquante).length}',
            texte: 'produits non livrés',
            couleur: e.critique,
            filtre: EtatLivraison.manquante,
          ),
          (
            cle: 'partielle',
            valeur: '${s.lignesDe(EtatLivraison.partielle).length}',
            texte: 'livrés en partie',
            couleur: e.alerte,
            filtre: EtatLivraison.partielle,
          ),
          (
            cle: 'attendue',
            valeur: '${s.lignesDe(EtatLivraison.attendue).length}',
            texte: 'attendus',
            couleur: null,
            filtre: EtatLivraison.attendue,
          ),
          (
            cle: 'taux',
            valeur: taux == null ? '—' : '$taux %',
            texte: 'taux de service',
            couleur: taux == null ? null : _couleurTaux(context, taux),
            filtre: null,
          ),
        ],
        actif: _filtre,
        choisir: (f) => setState(() => _filtre = f),
      ),
      const SizedBox(height: 14),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in EtatLivraison.values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey('filtre-${f.name}'),
                  label: Text('${f.pluriel} ${s.lignesDe(f).length}'),
                  selected: _filtre == f,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filtre = f),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      if (lignes.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Center(
            child: Text(switch (_filtre) {
              EtatLivraison.manquante => 'Tout ce qui devait arriver est arrivé.',
              EtatLivraison.partielle => 'Aucune livraison partielle.',
              EtatLivraison.attendue => 'Aucune livraison attendue.',
              EtatLivraison.livree => 'Aucune ligne livrée sur la période.',
            }, style: TextStyle(color: context.couleurs.encre2)),
          ),
        )
      else
        Container(
          decoration: BoxDecoration(
            color: context.schema.surface,
            border: Border.all(color: context.couleurs.bord),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, l) in lignes.indexed) ...[
                if (i > 0) Divider(height: 1, color: context.couleurs.bord),
                _Ligne(l, large: large),
              ],
            ],
          ),
        ),
      if (_filtre == EtatLivraison.manquante && lignes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Text(
            'Ces produits sont reproposés dans la commande de ce soir.',
            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
          ),
        ),
      if (!large && s.fournisseurs.isNotEmpty) ...[const SizedBox(height: 22), _TauxService(suivi: s)],
    ];
  }
}

Color _couleurTaux(BuildContext context, int taux) =>
    taux >= 90 ? context.etats.bon : (taux >= 70 ? context.etats.alerte : context.etats.critique);

class _EnTete extends StatelessWidget {
  const _EnTete({this.suivi});
  final SuiviLivraisons? suivi;

  @override
  Widget build(BuildContext context) {
    final s = suivi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Livraisons',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700),
                ),
                if (s != null)
                  Text(
                    [
                      '${s.jours} derniers jours',
                      if (s.donneesDu != null)
                        'réceptions EASYPHARM lues ${horodatage(s.donneesDu!, DateTime.now().toUtc())}',
                    ].join(' · '),
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

typedef _Tuile = ({String cle, String valeur, String texte, Color? couleur, EtatLivraison? filtre});

class _Tuiles extends StatelessWidget {
  const _Tuiles({required this.tuiles, required this.actif, required this.choisir});
  final List<_Tuile> tuiles;
  final EtatLivraison actif;
  final ValueChanged<EtatLivraison> choisir;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final parRang = c.maxWidth >= 640 ? 4 : 2;
      final largeur = (c.maxWidth - 12 * (parRang - 1)) / parRang;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final t in tuiles)
            SizedBox(
              width: largeur,
              child: Material(
                color: context.schema.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: t.filtre != null && t.filtre == actif
                        ? (t.couleur ?? context.schema.primary)
                        : context.couleurs.bord,
                    width: t.filtre != null && t.filtre == actif ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('tuile-${t.cle}'),
                  onTap: t.filtre == null ? null : () => choisir(t.filtre!),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.valeur,
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: t.couleur,
                          ),
                        ),
                        Text(t.texte, style: TextStyle(fontSize: 12, color: context.couleurs.encre2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Pastille extends StatelessWidget {
  const _Pastille(this.texte, this.couleur, this.fond);
  final String texte;
  final Color couleur, fond;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(99)),
    child: Text(
      texte,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: couleur),
    ),
  );
}

class _Ligne extends ConsumerWidget {
  const _Ligne(this.l, {required this.large});
  final LigneLivraison l;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ligne = l.ligne;
    final commande = l.commande;
    final e = context.etats;
    final (couleur, fond) = switch (ligne.etat) {
      EtatLivraison.manquante => (e.critique, e.critiqueDoux),
      EtatLivraison.partielle => (e.alerte, e.alerteDoux),
      EtatLivraison.livree => (e.bon, e.bonDoux),
      EtatLivraison.attendue => (context.couleurs.encre2, context.couleurs.neutreDoux),
    };
    final prevue = commande.livraisonPrevue;
    final detail = [
      'stock ${ligne.stock}',
      commande.fournisseur.nom ?? 'Fournisseur',
      'commande du ${jourMois(commande.jour)}',
      if (ligne.etat == EtatLivraison.attendue && prevue != null) 'prévue ${jourEtDate(prevue)}',
      if (ligne.recuLe != null) 'reçu le ${jourMois(ligne.recuLe!)}',
    ].join(' · ');
    final aRecommander = ligne.etat == EtatLivraison.manquante || ligne.etat == EtatLivraison.partielle;
    final pastilles = Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _Pastille(ligne.etat == EtatLivraison.partielle ? 'Reste ${ligne.reste}' : ligne.etat.libelle, couleur, fond),
        if (ligne.tension == 'proposee')
          _Pastille('Tension ?', context.schema.onPrimaryContainer, context.schema.primaryContainer)
        else if (ligne.tension == 'confirmee')
          _Pastille('En tension', context.schema.onPrimaryContainer, context.schema.primaryContainer),
      ],
    );
    final quantite = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${ligne.recu}',
            style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14),
          ),
          TextSpan(
            text: ' / ${ligne.qte}',
            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
          ),
        ],
      ),
    );
    final bouton = aRecommander
        ? FilledButton.tonal(
            key: ValueKey('autre-${ligne.idNom}'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () => _autreGrossiste(context, ref),
            child: const Text('Autre grossiste'),
          )
        : null;
    final produit = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          libelleProduit(ligne.nom ?? 'Produit ${ligne.idNom}'),
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
    );
    return Padding(
      key: ValueKey('livraison-${ligne.idNom}-${commande.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: large
          ? Row(
              children: [
                Expanded(child: produit),
                const SizedBox(width: 14),
                SizedBox(
                  width: 70,
                  child: Align(alignment: Alignment.centerRight, child: quantite),
                ),
                const SizedBox(width: 14),
                SizedBox(width: 170, child: pastilles),
                SizedBox(
                  width: 150,
                  child: Align(alignment: Alignment.centerRight, child: bouton),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: produit),
                    const SizedBox(width: 10),
                    quantite,
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: pastilles),
                    ?bouton,
                  ],
                ),
              ],
            ),
    );
  }

  /// Choisit un autre grossiste actif, puis ajoute le reste à son brouillon du jour.
  Future<void> _autreGrossiste(BuildContext context, WidgetRef ref) async {
    final messager = ScaffoldMessenger.of(context);
    final routeur = GoRouter.of(context);
    final List<FournisseurReglage> tous;
    try {
      tous = await ref.read(fournisseursCommandeProvider.future);
    } catch (err) {
      messager.showSnackBar(SnackBar(content: Text(ErreurApi.depuis(err).message)));
      return;
    }
    if (!context.mounted) return;
    final autres = tous.where((f) => f.actif && f.id != l.commande.fournisseur.id).toList();
    final reste = l.ligne.reste > 0 ? l.ligne.reste : l.ligne.qte;
    final choisi = await showDialog<FournisseurReglage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Commander $reste boîte${reste > 1 ? 's' : ''} chez…'),
        children: [
          if (autres.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Aucun autre grossiste actif. Activez-en un dans Préférences › Fournisseurs.'),
            ),
          for (final f in autres)
            SimpleDialogOption(
              key: ValueKey('vers-${f.id}'),
              onPressed: () => Navigator.pop(context, f),
              child: Text(f.nom ?? 'Fournisseur ${f.id}'),
            ),
        ],
      ),
    );
    if (choisi == null) return;
    try {
      final a = await ref.read(commandesApiProvider).ajouter(l.ligne.idNom, qte: reste, idFournisseur: choisi.id);
      ref.invalidate(journeeProvider);
      final chez = a.fournisseur ?? choisi.nom ?? 'ce grossiste';
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              a.dejaPresent
                  ? 'Déjà dans la commande de $chez : quantité mise à ${a.qte}.'
                  : 'Ajouté à la commande de $chez : ${a.qte} boîte${a.qte > 1 ? 's' : ''}.',
            ),
            action: SnackBarAction(label: 'Voir', onPressed: () => routeur.go('/commandes/${a.idFournisseur}')),
          ),
        );
    } catch (err) {
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(err).message)));
    }
  }
}

class _TauxService extends StatelessWidget {
  const _TauxService({required this.suivi});
  final SuiviLivraisons suivi;

  @override
  Widget build(BuildContext context) {
    // Le meilleur d'abord.
    final liste = [...suivi.fournisseurs]..sort((a, b) => (b.tauxQuantite ?? 0).compareTo(a.tauxQuantite ?? 0));
    return Column(
      key: const ValueKey('taux-service'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Taux de service',
          style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700),
        ),
        Text(
          'quantités reçues ÷ commandées, ${suivi.jours} jours',
          style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
        ),
        for (final f in liste) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  f.nom ?? 'Fournisseur ${f.id}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                f.tauxQuantite == null ? '—' : '${f.tauxQuantite} %',
                key: ValueKey('taux-${f.id}'),
                style: TextStyle(fontWeight: FontWeight.w700, color: _couleurTaux(context, f.tauxQuantite ?? 0)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (f.tauxQuantite ?? 0) / 100,
              minHeight: 6,
              backgroundColor: context.couleurs.neutreDoux,
              color: _couleurTaux(context, f.tauxQuantite ?? 0),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${f.commandes} commande${f.commandes > 1 ? 's' : ''} · ${f.lignes} ligne${f.lignes > 1 ? 's' : ''}'
            '${f.tauxLignes == null ? '' : ' · ${f.tauxLignes} % livrées en entier'}',
            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
          ),
        ],
      ],
    );
  }
}
