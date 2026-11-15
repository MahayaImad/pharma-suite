import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/pastille_etat.dart';
import '../../../data/api/commandes_api.dart';
import '../../../domain/commandes.dart';
import '../../../domain/format.dart';
import '../../reglages/application/reglages_providers.dart' show peutModifierProvider;
import '../application/commandes_providers.dart';
import 'ecran_commandes.dart' show montrerErreur;

/// Fiche produit : les marques de même DCI et celles que la commande garde.
/// Classe chronique : toutes ; sinon les plus vendues parmi les disponibles,
/// les autres ne sont plus recommandées (leur demande passe aux gardées).
/// Le titulaire peut forcer le groupe et chaque marque.
class SectionGeneriques extends ConsumerWidget {
  const SectionGeneriques({super.key, required this.idNom});
  final int idNom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupe = ref.watch(generiquesProvider(idNom));
    return groupe.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (g) {
        if (!g.aPlusieursMarques) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            key: const ValueKey('section-generiques'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Génériques de la même DCI',
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              _CarteGroupe(groupe: g, idNom: idNom),
            ],
          ),
        );
      },
    );
  }
}

class _CarteGroupe extends ConsumerWidget {
  const _CarteGroupe({required this.groupe, required this.idNom});
  final GroupeGenerique groupe;
  final int idNom;

  Future<void> _faire(
    BuildContext context,
    WidgetRef ref,
    Future<GroupeGenerique> Function(CommandesApi) action,
  ) async {
    try {
      await action(ref.read(commandesApiProvider));
      ref.invalidate(generiquesProvider);
      ref.invalidate(journeeProvider);
    } catch (e) {
      if (context.mounted) montrerErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = groupe;
    final modifiable = ref.watch(peutModifierProvider);
    final regle = g.toutes
        ? (g.chronique && g.modeForce == null
              ? 'Classe ${g.classe} chronique : toutes les marques sont commandées (chaque patient garde la sienne).'
              : 'Toutes les marques sont commandées.')
        : 'Seules les ${g.nombreGardes} marques les plus vendues et disponibles sont commandées ; '
              'les autres s\'écoulent puis leur demande passe aux marques gardées.';
    return Container(
      decoration: BoxDecoration(
        color: context.schema.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.couleurs.bord),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code DCI ${g.code}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(regle, style: TextStyle(fontSize: 12, color: context.couleurs.encre2)),
                    ],
                  ),
                ),
                if (modifiable)
                  PopupMenuButton<String>(
                    key: const ValueKey('mode-groupe'),
                    tooltip: 'Règle de ce groupe',
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    onSelected: (v) => _faire(context, ref, (api) => api.modeGroupe(idNom, v == 'auto' ? null : v)),
                    itemBuilder: (_) => [
                      _choix('auto', g.modeForce == null, 'Automatique (selon la classe)'),
                      _choix('toutes', g.modeForce == 'toutes', 'Toutes les marques'),
                      _choix('quelques', g.modeForce == 'quelques', 'Seulement les plus vendues'),
                    ],
                  ),
              ],
            ),
          ),
          for (final m in g.membres) ...[
            const Divider(indent: 14, endIndent: 14, height: 1),
            _LigneMembre(membre: m, courant: m.idNom == idNom, modifiable: modifiable, groupe: this),
          ],
        ],
      ),
    );
  }
}

class _LigneMembre extends ConsumerWidget {
  const _LigneMembre({required this.membre, required this.courant, required this.modifiable, required this.groupe});
  final MembreGenerique membre;
  final bool courant, modifiable;
  final _CarteGroupe groupe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = membre;
    final etat = m.garde
        ? const PastilleEtat(niveau: NiveauEtat.bon, libelle: 'Commandé', icone: Icons.check_circle_outline)
        : const PastilleEtat(niveau: NiveauEtat.neutre, libelle: 'Non recommandé', icone: Icons.block);
    return InkWell(
      key: ValueKey('membre-${m.idNom}'),
      onTap: courant ? null : () => context.go('/stock/${m.idNom}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libelleProduit(m.nom ?? 'Produit ${m.idNom}'),
                    style: TextStyle(fontWeight: courant ? FontWeight.w800 : FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '${entier(m.ventes12m)} vendus sur 12 mois',
                      'stock ${entier(m.stock)}',
                      if (m.choix == 'garder') 'toujours gardé',
                      if (m.choix == 'exclure') 'exclu par le titulaire',
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                  ),
                ],
              ),
            ),
            etat,
            if (modifiable)
              PopupMenuButton<String>(
                key: ValueKey('choix-${m.idNom}'),
                tooltip: 'Choix pour cette marque',
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (v) =>
                    groupe._faire(context, ref, (api) => api.choisirGenerique(m.idNom, v == 'auto' ? null : v)),
                itemBuilder: (_) => [
                  _choix('auto', m.choix == null, 'Automatique'),
                  _choix('garder', m.choix == 'garder', 'Toujours commander'),
                  _choix('exclure', m.choix == 'exclure', 'Ne plus commander'),
                ],
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Entrée de menu avec une coche devant le choix actuel.
PopupMenuItem<String> _choix(String valeur, bool coche, String libelle) => PopupMenuItem(
  value: valeur,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 28, child: coche ? const Icon(Icons.check, size: 18) : null),
      Flexible(child: Text(libelle, overflow: TextOverflow.ellipsis)),
    ],
  ),
);
