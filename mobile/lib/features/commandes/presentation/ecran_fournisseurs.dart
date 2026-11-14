import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/pastille_etat.dart';
import '../../../data/api/client_api.dart';
import '../../../data/api/commandes_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../reglages/application/reglages_providers.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/commandes_providers.dart';
import 'ecran_commandes.dart' show InitialeFournisseur, montrerErreur;

enum _Filtre { actifs, inactifs, tous }

/// Fournisseurs et validation (Préférences) : tous les fournisseurs
/// d'EASYPHARM, actifs d'abord. Sans réglage du titulaire, un fournisseur
/// est actif s'il a livré dans les 30 derniers jours (« auto »). Le
/// titulaire règle le type, l'activité et le numéro WhatsApp, et désigne les
/// employés qui peuvent valider une commande.
class EcranFournisseurs extends ConsumerStatefulWidget {
  const EcranFournisseurs({super.key});

  @override
  ConsumerState<EcranFournisseurs> createState() => _EcranFournisseursState();
}

class _EcranFournisseursState extends ConsumerState<EcranFournisseurs> {
  _Filtre _filtre = _Filtre.actifs;
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final liste = ref.watch(fournisseursCommandeProvider);
    final modifiable = ref.watch(peutModifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fournisseurs et validation'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/preferences'),
        ),
      ),
      body: liste.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: MessageErreur(erreur: e, reessayer: () => ref.invalidate(fournisseursCommandeProvider)),
        ),
        data: (tous) {
          final actifs = tous.where((f) => f.actif).length;
          final cherche = _recherche.trim().toLowerCase();
          final visibles = [
            for (final f in tous)
              if ((_filtre == _Filtre.tous || f.actif == (_filtre == _Filtre.actifs)) &&
                  (cherche.isEmpty || (f.nom ?? '').toLowerCase().contains(cherche)))
                f,
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Seuls les fournisseurs actifs reçoivent un panier. Par défaut, un fournisseur sans '
                        'commande depuis 30 jours est inactif ; le titulaire peut le changer.',
                        style: TextStyle(color: context.couleurs.encre2),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const ValueKey('recherche-fournisseur'),
                        onChanged: (t) => setState(() => _recherche = t),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Chercher un fournisseur',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final (f, libelle) in [
                            (_Filtre.actifs, 'Actifs ($actifs)'),
                            (_Filtre.inactifs, 'Inactifs (${tous.length - actifs})'),
                            (_Filtre.tous, 'Tous (${tous.length})'),
                          ])
                            ChoiceChip(
                              key: ValueKey('filtre-${f.name}'),
                              label: Text(libelle),
                              selected: _filtre == f,
                              onSelected: (_) => setState(() => _filtre = f),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (visibles.isEmpty)
                        const MessageVide(titre: 'Aucun fournisseur', texte: 'Rien ne correspond.')
                      else
                        _Cadre(enfants: [for (final f in visibles) _LigneFournisseur(f, modifiable: modifiable)]),
                      const SizedBox(height: 28),
                      const _Valideurs(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cadre extends StatelessWidget {
  const _Cadre({required this.enfants});
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.schema.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.couleurs.bord),
    ),
    child: Column(
      children: [
        for (final (i, e) in enfants.indexed) ...[if (i > 0) Divider(height: 1, color: context.couleurs.bord), e],
      ],
    ),
  );
}

class _LigneFournisseur extends ConsumerWidget {
  const _LigneFournisseur(this.f, {required this.modifiable});
  final FournisseurReglage f;
  final bool modifiable;

  Future<void> _regler(
    BuildContext context,
    WidgetRef ref, {
    TypeFournisseur? type,
    bool? actif,
    String? whatsapp,
  }) async {
    try {
      await ref
          .read(commandesApiProvider)
          .reglerFournisseur(f.id, type ?? f.type, actif ?? f.actif, whatsapp ?? f.whatsapp);
      ref.invalidate(fournisseursCommandeProvider);
      ref.invalidate(journeeProvider);
    } catch (e) {
      if (context.mounted) montrerErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final derniere = f.derniereCommande;
    return InkWell(
      key: ValueKey('fournisseur-${f.id}'),
      onTap: modifiable ? () => _dialogue(context, ref) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Opacity(
              opacity: f.actif ? 1 : 0.5,
              child: InitialeFournisseur(fournisseur: f.commePanier, taille: 38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.nom ?? 'Fournisseur ${f.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: f.actif ? null : context.couleurs.encre2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      f.type.libelle,
                      derniere == null ? 'jamais livré' : 'dernière commande ${depuis(derniere, DateTime.now())}',
                      if (f.whatsapp != null && f.whatsapp!.trim().isNotEmpty) 'WhatsApp ${f.whatsapp}',
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                  ),
                  if (f.auto)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Réglage automatique',
                        style: TextStyle(fontSize: 11, color: context.couleurs.encre3, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              key: ValueKey('actif-${f.id}'),
              value: f.actif,
              onChanged: modifiable ? (v) => _regler(context, ref, actif: v) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogue(BuildContext context, WidgetRef ref) async {
    var type = f.type;
    final numero = TextEditingController(text: f.whatsapp ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, majour) => AlertDialog(
          title: Text(f.nom ?? 'Fournisseur'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Type de grossiste'),
                const SizedBox(height: 8),
                SegmentedButton<TypeFournisseur>(
                  segments: [for (final t in TypeFournisseur.values) ButtonSegment(value: t, label: Text(t.libelle))],
                  selected: {type},
                  onSelectionChanged: (v) => majour(() => type = v.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('numero-whatsapp'),
                  controller: numero,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro WhatsApp',
                    hintText: '0550 12 34 56',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await _regler(context, ref, type: type, whatsapp: numero.text.trim());
    }
  }
}

// ── Valideurs ──────────────────────────────────────────────────────────────

class _Valideurs extends ConsumerWidget {
  const _Valideurs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    final valideurs = ref.watch(valideursProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Validation des commandes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Le titulaire valide toujours. Il peut désigner des employés qui valident aussi.',
          style: TextStyle(color: context.couleurs.encre2),
        ),
        const SizedBox(height: 12),
        valideurs.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(valideursProvider)),
          data: (liste) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const PastilleEtat(niveau: NiveauEtat.bon, libelle: 'Titulaire', icone: Icons.verified_user_outlined),
              for (final u in liste)
                InputChip(
                  key: ValueKey('valideur-$u'),
                  label: Text(u),
                  onDeleted: modifiable ? () => _retirer(context, ref, u) : null,
                ),
              if (modifiable)
                ActionChip(
                  key: const ValueKey('ajouter-valideur'),
                  avatar: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('Désigner un employé'),
                  onPressed: () => _ajouter(context, ref, liste),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _retirer(BuildContext context, WidgetRef ref, String username) async {
    try {
      await ref.read(commandesApiProvider).retirerValideur(username);
      ref.invalidate(valideursProvider);
    } catch (e) {
      if (context.mounted) montrerErreur(context, e);
    }
  }

  Future<void> _ajouter(BuildContext context, WidgetRef ref, List<String> deja) async {
    final choisi = await showDialog<String>(
      context: context,
      builder: (d) => Consumer(
        builder: (d, ref, _) => AlertDialog(
          title: const Text('Désigner un employé'),
          content: SizedBox(
            width: 380,
            height: 320,
            child: ref
                .watch(comptesProvider)
                .when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(ErreurApi.depuis(e).message)),
                  data: (comptes) {
                    final possibles = [
                      for (final c in comptes)
                        if (c.actif && c.role != 'admin' && c.role != 'sync_agent' && !deja.contains(c.username)) c,
                    ];
                    if (possibles.isEmpty) return const Center(child: Text('Aucun autre compte.'));
                    return ListView(
                      children: [
                        for (final c in possibles)
                          ListTile(
                            key: ValueKey('compte-${c.username}'),
                            leading: const Icon(Icons.person_outline),
                            title: Text(c.libelle),
                            onTap: () => Navigator.pop(d, c.username),
                          ),
                      ],
                    );
                  },
                ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Fermer'))],
        ),
      ),
    );
    if (choisi == null) return;
    try {
      await ref.read(commandesApiProvider).ajouterValideur(choisi);
      ref.invalidate(valideursProvider);
    } catch (e) {
      if (context.mounted) montrerErreur(context, e);
    }
  }
}

/// Accès depuis les préférences.
class EntreeFournisseurs extends ConsumerWidget {
  const EntreeFournisseurs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actifs = ref.watch(fournisseursCommandeProvider).value?.where((f) => f.actif).length;
    return Material(
      color: context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.couleurs.bord),
      ),
      child: InkWell(
        key: const ValueKey('entree-fournisseurs'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/preferences/fournisseurs'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.schema.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping_outlined, color: context.schema.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fournisseurs et validation',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (actifs != null) '${entier(actifs)} actifs',
                        'type, WhatsApp, qui valide les commandes',
                      ].join(' · '),
                      style: TextStyle(color: context.couleurs.encre2, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.couleurs.encre3),
            ],
          ),
        ),
      ),
    );
  }
}
