import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/format.dart';
import '../../../domain/inventaire.dart';
import '../../../domain/stock.dart';
import '../../commandes/presentation/panier.dart' show ChoixProduit;
import '../../stock/presentation/ecran_stock.dart' show nomLisible;
import '../../stock/presentation/elements_stock.dart' show Etiquette, MessageErreur, MessageVide;
import '../application/inventaire_providers.dart';

/// Largeur à partir de laquelle l'exactitude et les écarts s'affichent à côté.
const _largeurAvecCote = 1100.0;

/// Inventaire tournant — design « liste du jour » retenu le 2026-11-17 : les
/// produits à compter aujourd'hui (classe A souvent, suspects d'abord), un
/// chiffre par produit ; les comptés ; l'exactitude et les écarts à reporter
/// dans EASYPHARM (à droite sur PC, en bas sur portable).
class EcranInventaire extends ConsumerWidget {
  const EcranInventaire({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journee = ref.watch(inventaireProvider);
    return LayoutBuilder(
      builder: (context, contraintes) {
        final large = contraintes.maxWidth >= _largeurAvecCote;
        final j = journee.value;
        final liste = RefreshIndicator(
          onRefresh: () => ref.refresh(inventaireProvider.future).catchError((_) => journee.value!),
          child: ListView(
            padding: EdgeInsets.fromLTRB(large ? 28 : 16, 14, large ? 28 : 16, 32),
            children: [
              _EnTete(journee: j),
              ...journee.when(
                skipLoadingOnReload: true,
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [MessageErreur(erreur: e, reessayer: () => ref.invalidate(inventaireProvider))],
                data: (j) => _contenu(context, j, large),
              ),
            ],
          ),
        );
        if (!large || j == null) return Scaffold(body: liste);
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: liste),
                ),
              ),
              VerticalDivider(width: 1, color: context.couleurs.bord),
              SizedBox(
                width: 340,
                child: ColoredBox(
                  color: context.schema.surface,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [_Cote(journee: j)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contenu(BuildContext context, JourneeInventaire j, bool large) {
    final p = j.progression;
    return [
      if (p.total > 0) _Progression(progression: p),
      if (j.aCompter.isNotEmpty) ...[
        _Titre('À compter · ${j.aCompter.length}'),
        _Carte(
          children: [for (final a in j.aCompter) _LigneACompter(key: ValueKey('a-compter-${a.idNom}'), produit: a)],
        ),
      ] else if (p.total > 0)
        const Padding(
          padding: EdgeInsets.only(top: 18),
          child: MessageVide(titre: 'Liste du jour terminée', texte: 'Tous les produits de la liste sont comptés.'),
        )
      else
        const MessageVide(
          titre: 'Rien à compter aujourd\'hui',
          texte: 'Tous les produits ont été comptés récemment. Vous pouvez compter un autre produit.',
        ),
      if (j.comptes.isNotEmpty) ...[
        _Titre('Comptés aujourd\'hui · ${j.comptes.length}'),
        _Carte(children: [for (final c in j.comptes) _LigneComptee(comptage: c)]),
      ],
      if (!large) ...[const SizedBox(height: 24), _Cote(journee: j)],
    ];
  }
}

class _EnTete extends ConsumerWidget {
  const _EnTete({this.journee});
  final JourneeInventaire? journee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final j = journee;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventaire',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700),
                ),
                if (j != null)
                  Text(
                    '${jourEtDate(j.jour)} · ${j.progression.total} produit${j.progression.total > 1 ? 's' : ''} '
                    'à compter aujourd\'hui',
                    key: const ValueKey('sous-titre-inventaire'),
                    style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('compter-autre'),
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Compter un autre produit'),
                  onPressed: () => _compterAutre(context, ref),
                ),
              ],
            ),
          ),
          const BoutonPreferences(),
        ],
      ),
    );
  }

  Future<void> _compterAutre(BuildContext context, WidgetRef ref) async {
    final p = await showDialog<Produit>(
      context: context,
      builder: (_) => const ChoixProduit(titre: 'Compter un produit'),
    );
    if (p == null || !context.mounted) return;
    final theorique = p.stock.round();
    final compte = await _saisirQuantite(context, nomLisible(p), theorique);
    if (compte == null || !context.mounted) return;
    await _enregistrer(context, ref, p.id, nomLisible(p), theorique, compte);
  }
}

class _Progression extends StatelessWidget {
  const _Progression({required this.progression});
  final Progression progression;

  @override
  Widget build(BuildContext context) {
    final p = progression;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: context.schema.surface,
        border: Border.all(color: context.couleurs.bord),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  key: const ValueKey('progression'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${p.comptes} / ${p.total}',
                        style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const TextSpan(text: ' comptés'),
                    ],
                  ),
                ),
              ),
              Text(
                p.ecarts == 0 ? 'aucun écart' : '${p.ecarts} écart${p.ecarts > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 13, color: p.ecarts > 0 ? context.etats.critique : context.couleurs.encre3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.total == 0 ? 0 : p.comptes / p.total,
              minHeight: 6,
              backgroundColor: context.couleurs.neutreDoux,
              color: context.etats.bon,
            ),
          ),
        ],
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
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

class _Carte extends StatelessWidget {
  const _Carte({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.schema.surface,
      border: Border.all(color: context.couleurs.bord),
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (i, c) in children.indexed) ...[if (i > 0) Divider(height: 1, color: context.couleurs.bord), c],
      ],
    ),
  );
}

/// Nom puis étiquette de classe, dans le même texte : l'étiquette suit le
/// dernier mot au lieu de couper le nom sur portable.
Widget _nomEtClasse(String nom, String? classe) => Text.rich(
  TextSpan(
    children: [
      TextSpan(text: nom),
      if (classe != null && classe.isNotEmpty)
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Etiquette(classe, accent: classe == 'A'),
          ),
        ),
    ],
  ),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
);

/// Un produit à compter : le stock d'EASYPHARM comme point de départ, − / +,
/// ou appui sur le chiffre pour le taper ; ✓ enregistre.
class _LigneACompter extends ConsumerStatefulWidget {
  const _LigneACompter({super.key, required this.produit});
  final ProduitACompter produit;

  @override
  ConsumerState<_LigneACompter> createState() => _EtatLigneACompter();
}

class _EtatLigneACompter extends ConsumerState<_LigneACompter> {
  late int _compte = widget.produit.stockTheorique;
  bool _envoi = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.produit;
    final detail = ['EASYPHARM : ${a.stockTheorique}', a.raison].join(' · ');
    final ecart = _compte != a.stockTheorique;
    Widget bouton(IconData icone, VoidCallback? f, String cle) => SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        key: ValueKey('$cle-${a.idNom}'),
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: f,
        icon: Icon(icone),
      ),
    );
    final saisie = Container(
      decoration: BoxDecoration(color: context.couleurs.neutreDoux, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          bouton(Icons.remove, _compte > 0 ? () => setState(() => _compte--) : null, 'moins'),
          InkWell(
            key: ValueKey('quantite-${a.idNom}'),
            onTap: () async {
              final q = await _saisirQuantite(context, a.nomLisible, _compte);
              if (q != null) setState(() => _compte = q);
            },
            child: SizedBox(
              width: 44,
              child: Text(
                '$_compte',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: ecart ? context.etats.critique : null,
                ),
              ),
            ),
          ),
          bouton(Icons.add, () => setState(() => _compte++), 'plus'),
        ],
      ),
    );
    final valider = SizedBox(
      width: 40,
      height: 40,
      child: IconButton.filledTonal(
        key: ValueKey('valider-${a.idNom}'),
        tooltip: 'Enregistrer le comptage',
        style: IconButton.styleFrom(
          backgroundColor: context.etats.bonDoux,
          foregroundColor: context.etats.bon,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _envoi
            ? null
            : () async {
                setState(() => _envoi = true);
                await _enregistrer(context, ref, a.idNom, a.nomLisible, a.stockTheorique, _compte);
                if (mounted) setState(() => _envoi = false);
              },
        icon: const Icon(Icons.check_rounded),
      ),
    );
    final texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _nomEtClasse(a.nomLisible, a.classe),
        const SizedBox(height: 2),
        Text(detail, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: texte),
          const SizedBox(width: 10),
          saisie,
          const SizedBox(width: 8),
          valider,
        ],
      ),
    );
  }
}

/// Saisie au clavier d'une quantité comptée.
Future<int?> _saisirQuantite(BuildContext context, String nom, int depart) {
  final champ = TextEditingController(text: '$depart');
  return showDialog<int>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(nom),
      content: TextField(
        key: const ValueKey('saisie-quantite'),
        controller: champ,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'Boîtes comptées (rayon et réserve)'),
        onSubmitted: (v) => Navigator.pop(d, int.tryParse(v)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Annuler')),
        FilledButton(
          key: const ValueKey('saisie-ok'),
          onPressed: () => Navigator.pop(d, int.tryParse(champ.text)),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Enregistre un comptage ; s'il y a un écart, demande d'abord sa cause.
Future<void> _enregistrer(BuildContext context, WidgetRef ref, int idNom, String nom, int theorique, int compte) async {
  final messager = ScaffoldMessenger.of(context);
  CauseEcart? cause;
  if (compte != theorique) {
    messager.hideCurrentSnackBar(); // il masquerait le bas de la feuille
    final ecart = compte - theorique;
    final choix = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  '$nom : écart ${ecart > 0 ? '+' : '−'}${ecart.abs()}',
                  style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Compté $compte, EASYPHARM $theorique. Une cause ?',
                  style: TextStyle(fontSize: 13, color: c.couleurs.encre3),
                ),
              ),
              for (final k in CauseEcart.values)
                ListTile(key: ValueKey('cause-${k.name}'), title: Text(k.libelle), onTap: () => Navigator.pop(c, k)),
              ListTile(
                key: const ValueKey('cause-aucune'),
                title: const Text('Enregistrer sans cause'),
                textColor: c.couleurs.encre2,
                onTap: () => Navigator.pop(c, 'aucune'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choix == null) return;
    cause = choix is CauseEcart ? choix : null;
  }
  try {
    final c = await ref.read(inventaireProvider.notifier).compter(idNom, compte, cause: cause);
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            c.ecart == 0 ? '$nom : juste.' : '$nom : ${c.libelleEcart.toLowerCase()}, à corriger dans EASYPHARM.',
          ),
        ),
      );
  } catch (e) {
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
  }
}

String _heure(DateTime? utc) {
  if (utc == null) return '';
  final h = heureAlger(utc);
  return '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
}

class _PastilleEcart extends StatelessWidget {
  const _PastilleEcart(this.comptage);
  final Comptage comptage;

  @override
  Widget build(BuildContext context) {
    final juste = comptage.ecart == 0;
    final (couleur, fond) = juste
        ? (context.etats.bon, context.etats.bonDoux)
        : (context.etats.critique, context.etats.critiqueDoux);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(99)),
      child: Text(
        comptage.libelleEcart,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: couleur),
      ),
    );
  }
}

class _LigneComptee extends ConsumerWidget {
  const _LigneComptee({required this.comptage});
  final Comptage comptage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = comptage;
    final detail = [
      'compté ${c.stockCompte}',
      'EASYPHARM ${c.stockTheorique}',
      if (c.cause != null) c.cause!.libelle.toLowerCase(),
      [if (c.comptePar != null) c.comptePar!, _heure(c.compteLe)].where((x) => x.isNotEmpty).join(', '),
      if (!c.dansLaListe) 'hors liste',
    ].where((x) => x.isNotEmpty).join(' · ');
    return Padding(
      key: ValueKey('compte-${c.idNom}'),
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nomEtClasse(c.nomLisible, c.classe),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PastilleEcart(c),
          IconButton(
            key: ValueKey('annuler-${c.idNom}'),
            tooltip: 'Annuler ce comptage',
            icon: Icon(Icons.undo_rounded, size: 18, color: context.couleurs.encre3),
            onPressed: () async {
              try {
                await ref.read(inventaireProvider.notifier).annuler(c.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Exactitude du stock et écarts à reporter dans EASYPHARM.
class _Cote extends ConsumerWidget {
  const _Cote({required this.journee});
  final JourneeInventaire journee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final x = journee.exactitude;
    final e = context.etats;
    final lignes = <(String, String, Color?)>[
      (
        'Exactitude ce mois',
        x.exactitudePct == null ? '—' : '${x.exactitudePct} %',
        x.exactitudePct == null
            ? null
            : (x.exactitudePct! >= 95 ? e.bon : (x.exactitudePct! >= 85 ? e.alerte : e.critique)),
      ),
      ('Produits comptés ce mois', '${x.comptesMois}', null),
      ('Classe A comptée (30 j)', x.classeAPct == null ? '—' : '${x.classeAPct} %', null),
      ('Écarts à corriger', '${x.aCorriger}', x.aCorriger > 0 ? e.critique : null),
    ];
    Widget titre(String t) => Text(
      t,
      style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700),
    );
    return Column(
      key: const ValueKey('exactitude'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titre('Exactitude du stock'),
        Text('part des produits comptés sans écart', style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
        const SizedBox(height: 4),
        for (final (libelle, valeur, couleur) in lignes)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.couleurs.bord)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(libelle, style: const TextStyle(fontSize: 13))),
                  Text(
                    valeur,
                    style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14, color: couleur),
                  ),
                ],
              ),
            ),
          ),
        if (journee.aCorriger.isNotEmpty) ...[
          const SizedBox(height: 22),
          titre('À corriger dans EASYPHARM'),
          Text(
            'PharmaSuite ne modifie pas EASYPHARM : reportez l\'écart, puis cochez.',
            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
          ),
          const SizedBox(height: 4),
          for (final c in journee.aCorriger)
            DecoratedBox(
              key: ValueKey('a-corriger-${c.id}'),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.couleurs.bord)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.nomLisible, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            '${c.stockTheorique} → ${c.stockCompte} · ${dinars(c.valeurEcart.abs().round())}'
                            ' · ${jourMois(c.jour)}',
                            style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${c.ecart > 0 ? '+' : '−'}${c.ecart.abs()}',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        color: c.ecart > 0 ? e.bon : e.critique,
                      ),
                    ),
                    IconButton(
                      key: ValueKey('corrige-${c.id}'),
                      tooltip: 'Reporté dans EASYPHARM',
                      icon: Icon(Icons.check_box_outline_blank_rounded, color: context.couleurs.encre3),
                      onPressed: () async {
                        try {
                          await ref.read(inventaireProvider.notifier).corriger(c.id, true);
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(ErreurApi.depuis(err).message)));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
