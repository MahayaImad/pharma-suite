import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../data/api/commandes_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../reglages/application/reglages_providers.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/commandes_providers.dart';
import 'ecran_commandes.dart' show montrerErreur;

/// Produits en tension (quota chez les grossistes, pénurie) : ceux que la
/// détection propose, à confirmer ou écarter, puis ceux qui sont confirmés.
/// Un produit en tension confirmé est commandé dès que possible, avec une
/// couverture plus longue (60 jours par défaut).
class EcranTensions extends ConsumerWidget {
  const EcranTensions({super.key});

  Future<void> _decider(BuildContext context, WidgetRef ref, Tension t, bool tension) async {
    try {
      await ref.read(commandesApiProvider).reglerTension(t.idNom, tension);
      ref.invalidate(tensionsProvider);
      ref.invalidate(tensionProduitProvider(t.idNom));
      ref.invalidate(journeeProvider);
    } catch (e) {
      if (context.mounted) montrerErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits en tension'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/preferences'),
        ),
      ),
      body: ref
          .watch(tensionsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: MessageErreur(erreur: e, reessayer: () => ref.invalidate(tensionsProvider)),
            ),
            data: (tous) {
              final aConfirmer = [
                for (final t in tous)
                  if (!t.confirme) t,
              ];
              final confirmes = [
                for (final t in tous)
                  if (t.confirme && t.tension) t,
              ];
              Widget ligne(Tension t) => ListTile(
                key: ValueKey('tension-${t.idNom}'),
                title: Text(libelleProduit(t.nom ?? 'Produit ${t.idNom}')),
                subtitle: Text(
                  [
                    'stock ${entier(t.stock)}',
                    if (t.motif != null) t.motif!,
                    if (t.source == 'saisie') 'marqué par le titulaire',
                  ].join(' · '),
                ),
                trailing: !modifiable
                    ? null
                    : t.confirme
                    ? TextButton(
                        key: ValueKey('lever-${t.idNom}'),
                        onPressed: () => _decider(context, ref, t, false),
                        child: const Text('Lever'),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            key: ValueKey('ecarter-${t.idNom}'),
                            onPressed: () => _decider(context, ref, t, false),
                            child: const Text('Écarter'),
                          ),
                          FilledButton.tonal(
                            key: ValueKey('confirmer-${t.idNom}'),
                            onPressed: () => _decider(context, ref, t, true),
                            child: const Text('Confirmer'),
                          ),
                        ],
                      ),
              );
              Widget bloc(String titre, List<Tension> liste, String vide) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text(
                      '$titre (${liste.length})',
                      style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.schema.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.couleurs.bord),
                    ),
                    child: liste.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(vide, style: TextStyle(color: context.couleurs.encre3)),
                          )
                        : Column(children: [for (final t in liste) ligne(t)]),
                  ),
                ],
              );
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
                            'Produits sous quota chez les grossistes ou en pénurie. Une fois confirmés, ils sont '
                            'commandés dès que possible, avec une couverture plus longue, et marqués « Quota » '
                            'dans le panier. Détection : longue rupture sans livraison malgré des ventes '
                            'régulières, ou « quota » dans EASYPHARM.',
                            style: TextStyle(color: context.couleurs.encre2),
                          ),
                          if (tous.isEmpty)
                            const MessageVide(titre: 'Aucun produit en tension', texte: 'Rien de détecté.')
                          else ...[
                            bloc('À confirmer', aConfirmer, 'Rien à confirmer.'),
                            bloc('En tension', confirmes, 'Aucun produit en tension.'),
                          ],
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

/// Accès depuis les préférences, avec le nombre à confirmer.
class EntreeTensions extends ConsumerWidget {
  const EntreeTensions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aConfirmer = ref.watch(tensionsProvider).value?.where((t) => !t.confirme).length ?? 0;
    return Material(
      color: context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.couleurs.bord),
      ),
      child: InkWell(
        key: const ValueKey('entree-tensions'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/preferences/tensions'),
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
                child: Icon(Icons.trending_down_rounded, color: context.schema.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Produits en tension', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Quotas et pénuries : commandés dès que possible',
                      style: TextStyle(color: context.couleurs.encre2, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (aConfirmer > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: context.etats.alerteDoux, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    '$aConfirmer à confirmer',
                    style: TextStyle(color: context.etats.alerte, fontWeight: FontWeight.w700, fontSize: 12),
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

/// Fiche produit : case « En tension » (titulaire).
class CaseTension extends ConsumerWidget {
  const CaseTension({super.key, required this.idNom});
  final int idNom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    final t = ref.watch(tensionProduitProvider(idNom)).value;
    final actif = t != null && t.confirme && t.tension;
    return Material(
      color: context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.couleurs.bord),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: const ValueKey('case-tension'),
        value: actif,
        onChanged: !modifiable || t == null
            ? null
            : (v) async {
                try {
                  await ref.read(commandesApiProvider).reglerTension(idNom, v);
                  ref.invalidate(tensionProduitProvider(idNom));
                  ref.invalidate(tensionsProvider);
                  ref.invalidate(journeeProvider);
                } catch (e) {
                  if (context.mounted) montrerErreur(context, e);
                }
              },
        title: const Text('En tension (quota, pénurie)', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          t != null && !t.confirme && t.tension
              ? 'Détecté : ${t.motif ?? ''}. À confirmer.'
              : 'Commandé dès que possible, avec une couverture plus longue.',
          style: TextStyle(fontSize: 12.5, color: context.couleurs.encre3),
        ),
      ),
    );
  }
}
