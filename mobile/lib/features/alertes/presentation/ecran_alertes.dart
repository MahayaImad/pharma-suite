import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../data/api/client_api.dart';
import '../../../data/api/commandes_api.dart';
import '../../../domain/alertes.dart';
import '../../../domain/format.dart';
import '../../commandes/application/commandes_providers.dart';
import '../../commandes/presentation/commander.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/alertes_providers.dart';

/// Largeur à partir de laquelle « En bref » s'affiche à côté de la liste.
const _largeurAvecCote = 1100.0;

/// Alertes — design « par priorité » retenu le 2026-11-17 : une seule liste,
/// aujourd'hui, cette semaine, à surveiller ; filtres par famille ; chaque
/// alerte a son action. Chiffres clés à droite sur PC, en bas sur portable.
class EcranAlertes extends ConsumerStatefulWidget {
  const EcranAlertes({super.key});

  @override
  ConsumerState<EcranAlertes> createState() => _EtatEcranAlertes();
}

class _EtatEcranAlertes extends ConsumerState<EcranAlertes> {
  TypeAlerte? _filtre;

  @override
  Widget build(BuildContext context) {
    final alertes = ref.watch(alertesProvider);
    return LayoutBuilder(
      builder: (context, contraintes) {
        final large = contraintes.maxWidth >= _largeurAvecCote;
        final l = alertes.value;
        final liste = RefreshIndicator(
          onRefresh: () => ref.refresh(alertesProvider.future).catchError((_) => alertes.value!),
          child: ListView(
            padding: EdgeInsets.fromLTRB(large ? 28 : 16, 14, large ? 28 : 16, 32),
            children: [
              _EnTete(liste: l),
              ...alertes.when(
                skipLoadingOnReload: true,
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [MessageErreur(erreur: e, reessayer: () => ref.invalidate(alertesProvider))],
                data: (l) => _contenu(l, large),
              ),
            ],
          ),
        );
        if (!large || l == null) return Scaffold(body: liste);
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: liste),
              VerticalDivider(width: 1, color: context.couleurs.bord),
              SizedBox(
                width: 300,
                child: ColoredBox(
                  color: context.schema.surface,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [_EnBref(liste: l)],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contenu(ListeAlertes l, bool large) {
    if (l.alertes.isEmpty) {
      return const [
        MessageVide(
          titre: 'Rien à signaler',
          texte: 'Aucune rupture, aucune livraison en retard, aucune péremption proche.',
        ),
      ];
    }
    Widget puce(String texte, TypeAlerte? type) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        key: ValueKey('filtre-${type?.name ?? 'toutes'}'),
        borderRadius: BorderRadius.circular(99),
        onTap: () => setState(() => _filtre = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _filtre == type ? context.schema.onSurface : context.couleurs.neutreDoux,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$texte ${l.nombre(type)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _filtre == type ? context.schema.surface : context.couleurs.encre2,
            ),
          ),
        ),
      ),
    );
    final e = context.etats;
    final teintes = {
      NiveauAlerte.aujourdhui: e.critique,
      NiveauAlerte.semaine: e.alerte,
      NiveauAlerte.surveiller: context.couleurs.encre3,
    };
    final groupes = [for (final n in NiveauAlerte.values) (n, l.de(n, _filtre))];
    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            puce('Toutes', null),
            for (final t in TypeAlerte.values)
              if (l.nombre(t) > 0) puce(t.libelle, t),
          ],
        ),
      ),
      for (final (niveau, alertes) in groupes)
        if (alertes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
            child: Text(
              '${niveau.libelle.toUpperCase()} · ${alertes.length}',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: teintes[niveau],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.schema.surface,
              border: Border.all(color: context.couleurs.bord),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, a) in alertes.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.couleurs.bord),
                  _LigneAlerte(alerte: a, large: large, peutDecider: l.peutDecider),
                ],
              ],
            ),
          ),
        ],
      if (!large) ...[const SizedBox(height: 24), _EnBref(liste: l)],
    ];
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({this.liste});
  final ListeAlertes? liste;

  @override
  Widget build(BuildContext context) {
    final l = liste;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alertes',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700),
                ),
                if (l != null)
                  Text(
                    [
                      jourEtDate(l.jour),
                      '${l.alertes.length} à traiter',
                      if (l.donneesDu != null) 'données ${horodatage(l.donneesDu!, DateTime.now().toUtc())}',
                    ].join(' · '),
                    key: const ValueKey('sous-titre-alertes'),
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

class _LigneAlerte extends ConsumerWidget {
  const _LigneAlerte({required this.alerte, required this.large, required this.peutDecider});
  final Alerte alerte;
  final bool large;
  final bool peutDecider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = alerte;
    final e = context.etats;
    const violet = Color(0xFF6B3FC4);
    final (couleur, fond) = switch (a.niveau) {
      _ when a.icone == 'tension' => (violet, violet.withValues(alpha: 0.14)),
      NiveauAlerte.aujourdhui when a.type == TypeAlerte.peremption => (e.alerte, e.alerteDoux),
      NiveauAlerte.aujourdhui => (e.critique, e.critiqueDoux),
      NiveauAlerte.semaine => (e.alerte, e.alerteDoux),
      NiveauAlerte.surveiller => (context.couleurs.encre2, context.couleurs.neutreDoux),
    };
    final icone = switch (a.icone) {
      'rupture' => Icons.priority_high_rounded,
      'livraison' => Icons.local_shipping_outlined,
      'peremption' => Icons.hourglass_bottom_rounded,
      'seuil' => Icons.south_rounded,
      'tension' => Icons.help_outline_rounded,
      'confirmer' => Icons.check_rounded,
      'surstock' => Icons.layers_outlined,
      'synchro' => Icons.sync_problem_rounded,
      _ => Icons.notifications_none_rounded,
    };
    final texte = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a.titreComplet,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          a.detail,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
        ),
      ],
    );
    final pastille = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(12)),
      child: Icon(icone, size: 20, color: couleur),
    );
    final actions = _actions(context, ref);
    return Padding(
      key: ValueKey('alerte-${a.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: large
          ? Row(
              children: [
                pastille,
                const SizedBox(width: 14),
                Expanded(child: texte),
                const SizedBox(width: 14),
                ...actions,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pastille,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      texte,
                      if (actions.isNotEmpty) ...[const SizedBox(height: 8), Wrap(spacing: 8, children: actions)],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final a = alerte;
    const compact = ButtonStyle(visualDensity: VisualDensity.compact);
    switch (a.action.sorte) {
      case SorteAction.aucune:
        return const [];
      case SorteAction.commander:
        return [
          FilledButton(
            key: ValueKey('action-${a.id}'),
            style: compact,
            onPressed: a.idNom == null
                ? null
                : () async {
                    await commanderProduit(context, ref, a.idNom!);
                    ref.invalidate(alertesProvider);
                  },
            child: Text(a.action.libelle),
          ),
        ];
      case SorteAction.ouvrir:
        final route = a.action.route;
        final bouton = a.niveau == NiveauAlerte.surveiller
            ? OutlinedButton(
                key: ValueKey('action-${a.id}'),
                style: compact,
                onPressed: route == null ? null : () => _ouvrir(context, route),
                child: Text(a.action.libelle),
              )
            : FilledButton.tonal(
                key: ValueKey('action-${a.id}'),
                style: compact,
                onPressed: route == null ? null : () => _ouvrir(context, route),
                child: Text(a.action.libelle),
              );
        return [bouton];
      case SorteAction.tension:
        return [
          OutlinedButton(
            key: ValueKey('ecarter-${a.id}'),
            style: compact,
            onPressed: () => _tension(context, ref, false),
            child: const Text('Écarter'),
          ),
          if (large) const SizedBox(width: 8),
          FilledButton.tonal(
            key: ValueKey('action-${a.id}'),
            style: compact,
            onPressed: () => _tension(context, ref, true),
            child: Text(a.action.libelle),
          ),
        ];
    }
  }

  /// Les Préférences s'empilent (retour possible) ; le reste remplace l'écran.
  void _ouvrir(BuildContext context, String route) =>
      route.startsWith('/preferences') ? context.push(route) : context.go(route);

  Future<void> _tension(BuildContext context, WidgetRef ref, bool tension) async {
    final messager = ScaffoldMessenger.of(context);
    try {
      await ref.read(commandesApiProvider).reglerTension(alerte.idNom!, tension);
      ref
        ..invalidate(alertesProvider)
        ..invalidate(tensionsProvider)
        ..invalidate(journeeProvider);
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tension
                  ? '${libelleProduit(alerte.sujet ?? '')} : tension confirmée, couverture allongée.'
                  : '${libelleProduit(alerte.sujet ?? '')} : tension écartée.',
            ),
          ),
        );
    } catch (err) {
      messager
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(err).message)));
    }
  }
}

class _EnBref extends StatelessWidget {
  const _EnBref({required this.liste});
  final ListeAlertes liste;

  @override
  Widget build(BuildContext context) {
    final b = liste.bref;
    final e = context.etats;
    final du = liste.donneesDu;
    final retard = du == null || DateTime.now().toUtc().difference(du.toUtc()) > const Duration(hours: 3);
    final lignes = <(String, String, Color?)>[
      ('Ruptures', '${b.ruptures}', b.ruptures > 0 ? e.critique : null),
      ('Rupture sous 2 jours', '${b.rupturesImminentes}', b.rupturesImminentes > 0 ? e.critique : null),
      ('Valeur à risque de péremption', dinars(b.valeurARisque.round()), b.valeurARisque > 0 ? e.alerte : null),
      ('Commandes non livrées', '${b.commandesNonLivrees}', b.commandesNonLivrees > 0 ? e.critique : null),
      if (b.budgetPct != null) ('Budget du mois', '${b.budgetPct} %', b.budgetPct! > 100 ? e.critique : null),
      (
        'Dernière synchronisation',
        du == null ? 'inconnue' : horodatage(du, DateTime.now().toUtc()),
        retard ? e.critique : e.bon,
      ),
    ];
    return Column(
      key: const ValueKey('en-bref'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'En bref',
          style: TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
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
                  const SizedBox(width: 10),
                  Text(
                    valeur,
                    style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14, color: couleur),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
