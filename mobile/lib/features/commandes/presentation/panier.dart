import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/pastille_etat.dart';
import '../../../data/api/client_api.dart';
import '../../../data/api/commandes_api.dart';
import '../../../data/api/stock_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../../domain/stock.dart';
import '../../stock/presentation/ecran_stock.dart' show nomLisible;
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide, Etiquette;
import '../application/commandes_providers.dart';
import 'ecran_commandes.dart';

/// Panier d'un fournisseur : les lignes (quantité modifiable en brouillon,
/// avec la raison du calcul), et en bas une barre fixe avec le total et
/// l'action de l'étape : préparer, valider, envoyer par WhatsApp.
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
      backgroundColor: enPanneau ? context.schema.surface : null,
      appBar: enPanneau
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/commandes'),
              ),
              title: Text(panier?.fournisseur.nom ?? 'Panier'),
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
            : _Contenu(panier: panier, journee: j, enPanneau: enPanneau),
      ),
      bottomNavigationBar: panier == null || journee.value == null
          ? null
          : _BarreTotal(panier: panier, journee: journee.value!),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.panier, required this.journee, required this.enPanneau});
  final Panier panier;
  final JourneeCommandes journee;
  final bool enPanneau;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = panier;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            InitialeFournisseur(fournisseur: p.fournisseur, taille: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (enPanneau)
                    Text(
                      p.fournisseur.nom ?? 'Fournisseur ${p.fournisseur.id}',
                      style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                  Text(
                    [
                      p.fournisseur.type.libelle,
                      if (p.livraisonPrevue != null) 'livraison ${jourEtDate(p.livraisonPrevue!)}',
                    ].join(' · '),
                    style: TextStyle(color: context.couleurs.encre3, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  PastilleEtape(p.etape),
                ],
              ),
            ),
            if (enPanneau) _MenuPanier(panier: p),
          ],
        ),
        const SizedBox(height: 14),
        _Chiffres(panier: p),
        if (p.etape == EtapePanier.propose && p.lignes.isNotEmpty)
          _Bandeau(
            icone: Icons.info_outline_rounded,
            texte:
                'Proposition calculée ce soir. « Préparer » l\'enregistre en brouillon : '
                'vous pourrez alors changer les quantités.',
          ),
        if (p.etape == EtapePanier.validee)
          _Bandeau(
            icone: Icons.verified_outlined,
            texte:
                'Validée${p.commande?.validePar != null ? ' par ${p.commande!.validePar}' : ''}. '
                'Pour la corriger, rouvrez-la (menu ⋮).',
          ),
        const SizedBox(height: 6),
        for (final l in p.lignes) LigneDuPanier(panier: p, ligne: l),
        if (p.modifiable) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const ValueKey('bouton-ajouter-produit'),
              onPressed: () => _ajouterProduit(context, ref, p),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un produit'),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chiffres extends StatelessWidget {
  const _Chiffres({required this.panier});
  final Panier panier;

  @override
  Widget build(BuildContext context) {
    Widget case_(String titre, String valeur, {bool dernier = false}) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          border: dernier ? null : Border(right: BorderSide(color: context.couleurs.bord)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: TextStyle(fontSize: 11, color: context.couleurs.encre3)),
            Text(
              valeur,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.couleurs.bord),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          case_('Lignes', entier(panier.nbLignes)),
          case_('Boîtes', entier(panier.boites)),
          case_('Ruptures', entier(panier.ruptures), dernier: true),
        ],
      ),
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.icone, required this.texte});
  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: context.schema.primaryContainer, borderRadius: BorderRadius.circular(12)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: context.schema.onPrimaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texte, style: TextStyle(fontSize: 13, color: context.schema.onPrimaryContainer)),
        ),
      ],
    ),
  );
}

// ── Une ligne ───────────────────────────────────────────────────────────────

class LigneDuPanier extends ConsumerWidget {
  const LigneDuPanier({super.key, required this.panier, required this.ligne});
  final Panier panier;
  final LigneCommande ligne;

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
    final type = l.raison?.type;
    return Container(
      key: ValueKey('ligne-${l.idNom}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.couleurs.bord)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libelleProduit(l.nom ?? 'Produit ${l.idNom}'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (l.rupture) const PastilleEtat(niveau: NiveauEtat.critique, libelle: 'Rupture'),
                        if (l.classeAbc != null && l.classeAbc!.isNotEmpty)
                          Etiquette(l.classeAbc!, accent: l.classeAbc == 'A'),
                        if (type != null && type.isNotEmpty) Etiquette(libelleTypeDemande(type)),
                        if (!l.rupture) Etiquette('stock ${entier(l.stock)}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              panier.modifiable
                  ? Pas(cle: 'pas-${l.idNom}', valeur: l.qte, surChangement: (q) => _changer(context, ref, q))
                  : Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${l.qte}',
                        key: ValueKey('qte-${l.idNom}'),
                        style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 20),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: l.explication,
                    children: [
                      if (l.modifiee && !l.ajoutManuel)
                        TextSpan(
                          text: '  · modifié (proposé ${l.qteProposee})',
                          style: TextStyle(color: context.etats.alerte, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                  style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                ),
              ),
              Text(dinars(l.montant.round()), style: TextStyle(fontSize: 12, color: context.couleurs.encre2)),
            ],
          ),
          const SizedBox(height: 8),
          JaugeCommande(ligne: l),
        ],
      ),
    );
  }
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
      width: 36,
      height: 36,
      child: Material(
        color: context.schema.primaryContainer,
        child: InkWell(
          key: ValueKey('$cle-$suffixe'),
          onTap: action,
          child: Tooltip(
            message: aide,
            child: Icon(icone, size: 18, color: context.schema.onPrimaryContainer),
          ),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.couleurs.bord),
          borderRadius: BorderRadius.circular(10),
        ),
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
              width: 40,
              child: Text(
                '$valeur',
                key: ValueKey('$cle-valeur'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            bouton(Icons.add, 'plus', 'Une boîte de plus', () => surChangement(valeur + 1)),
          ],
        ),
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
  final id = panier.commande?.id;
  if (id == null) return;
  final choisi = await showDialog<Produit>(context: context, builder: (_) => const _ChoixProduit());
  if (choisi == null) return;
  try {
    await ref.read(journeeProvider.notifier).ajouter(id, choisi.id, 1);
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
