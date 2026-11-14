import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../data/api/client_api.dart';
import '../../../data/api/stock_api.dart';
import '../../../domain/format.dart';
import '../../../domain/stock.dart';
import '../../stock/application/stock_providers.dart';
import '../../stock/presentation/ecran_stock.dart' show nomLisible;
import '../../stock/presentation/elements_stock.dart' show IconeFamille, MessageErreur, MessageVide;
import '../application/reglages_providers.dart';

/// Consommables donnés (jamais vendus, sortis du stock par ajustement) :
/// ceux que la détection propose, à confirmer ou refuser d'un geste, puis
/// ceux qui sont confirmés. Seul le titulaire décide.
class EcranConsommables extends ConsumerWidget {
  const EcranConsommables({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    final liste = ref.watch(consommablesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consommables'),
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
          child: MessageErreur(erreur: e, reessayer: () => ref.invalidate(consommablesProvider)),
        ),
        data: (tous) {
          final aConfirmer = tous.where((c) => !c.confirme).toList();
          final confirmes = tous.where((c) => c.confirme).toList();
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
                        'Produits achetés mais jamais vendus, donnés (aiguilles, sachets, lecteurs…) et '
                        'sortis du stock par ajustement. Un consommable n\'est compté ni comme une perte '
                        'ni comme un surstock.',
                        style: TextStyle(color: context.couleurs.encre2),
                      ),
                      const SizedBox(height: 16),
                      _Bloc(
                        cle: 'a-confirmer',
                        titre: 'À confirmer',
                        compte: aConfirmer.length,
                        vide: 'Rien à confirmer.',
                        lignes: [for (final c in aConfirmer) _LigneConsommable(c, modifiable: modifiable)],
                      ),
                      const SizedBox(height: 16),
                      _Bloc(
                        cle: 'confirmes',
                        titre: 'Consommables',
                        compte: confirmes.length,
                        vide: 'Aucun consommable confirmé.',
                        lignes: [for (final c in confirmes) _LigneConsommable(c, modifiable: modifiable)],
                      ),
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

class _Bloc extends StatelessWidget {
  const _Bloc({required this.cle, required this.titre, required this.compte, required this.vide, required this.lignes});

  final String cle, titre, vide;
  final int compte;
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('bloc-$cle'),
    decoration: BoxDecoration(
      color: context.schema.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.couleurs.bord),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Text(
                titre,
                style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text('$compte', style: TextStyle(color: context.couleurs.encre3)),
            ],
          ),
        ),
        const Divider(),
        if (lignes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: MessageVide(titre: vide, texte: ''),
          )
        else
          ...lignes,
      ],
    ),
  );
}

class _LigneConsommable extends ConsumerWidget {
  const _LigneConsommable(this.c, {required this.modifiable});
  final Consommable c;
  final bool modifiable;

  Future<void> _decider(BuildContext context, WidgetRef ref, bool oui) async {
    final messager = ScaffoldMessenger.of(context);
    try {
      await ref.read(stockApiProvider).deciderConsommable(c.id, oui);
      ref.invalidate(consommablesProvider);
      ref.invalidate(aTraiterProvider);
      ref.invalidate(ficheProduitProvider(c.id));
    } catch (e) {
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nom = nomLisible(Produit(id: c.id, nom: c.nom, dosage: c.dosage, formeAbr: c.formeAbr));
    return InkWell(
      key: ValueKey('consommable-${c.id}'),
      onTap: () => context.go('/stock/${c.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            IconeFamille(c.idFamille, taille: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${entier(c.unitesAjustees)} donnés en 12 mois · ${entier(c.stock)} en stock',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: context.couleurs.encre3),
                  ),
                ],
              ),
            ),
            if (modifiable && !c.confirme) ...[
              TextButton(
                key: ValueKey('non-${c.id}'),
                style: TextButton.styleFrom(foregroundColor: context.couleurs.encre2),
                onPressed: () => _decider(context, ref, false),
                child: const Text('Non'),
              ),
              TextButton(
                key: ValueKey('oui-${c.id}'),
                onPressed: () => _decider(context, ref, true),
                child: const Text('Confirmer'),
              ),
            ] else if (modifiable)
              IconButton(
                key: ValueKey('retirer-${c.id}'),
                tooltip: 'Ce n\'est pas un consommable',
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => _decider(context, ref, false),
              ),
          ],
        ),
      ),
    );
  }
}

/// Accès depuis les préférences, avec le nombre à confirmer.
class EntreeConsommables extends ConsumerWidget {
  const EntreeConsommables({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aConfirmer = ref.watch(consommablesProvider).value?.where((c) => !c.confirme).length ?? 0;
    return Material(
      color: context.schema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.couleurs.bord),
      ),
      child: InkWell(
        key: const ValueKey('entree-consommables'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/preferences/consommables'),
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
                child: Icon(Icons.volunteer_activism_outlined, color: context.schema.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consommables', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Produits donnés, jamais vendus : ni pertes ni surstock',
                      style: TextStyle(color: context.couleurs.encre2, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (aConfirmer > 0)
                Container(
                  key: const ValueKey('compte-a-confirmer'),
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
