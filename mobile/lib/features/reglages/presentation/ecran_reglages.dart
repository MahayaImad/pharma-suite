import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../data/api/calendrier_api.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/calendrier.dart';
import '../../../domain/format.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur;
import '../application/reglages_providers.dart';

/// Calendrier de l'officine (gardes, Ramadan et Aïd, jours fériés) et
/// constantes du calcul des commandes. Lecture pour tous, modification par
/// le titulaire.
class EcranReglages extends ConsumerWidget {
  const EcranReglages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier et réglages'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/preferences'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'La demande change les jours de garde, pendant Ramadan et les fêtes : ces dates '
                    'servent au calcul des quantités à commander.',
                    style: TextStyle(color: context.couleurs.encre2),
                  ),
                  if (!modifiable) ...[const SizedBox(height: 12), const _LectureSeule()],
                  const SizedBox(height: 16),
                  const _SectionGardes(),
                  const SizedBox(height: 16),
                  const _SectionEvenements(),
                  const SizedBox(height: 16),
                  const _SectionFeries(),
                  const SizedBox(height: 16),
                  const _SectionReglages(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LectureSeule extends StatelessWidget {
  const _LectureSeule();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: context.couleurs.neutreDoux, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(Icons.lock_outline, size: 18, color: context.couleurs.encre2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Lecture seule : seul le titulaire modifie ces réglages.',
            style: TextStyle(color: context.couleurs.encre2),
          ),
        ),
      ],
    ),
  );
}

// ── Outils communs ──────────────────────────────────────────────────────────

const _joursCourts = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

/// « sam. 07/11/2026 ».
String _dateCourte(DateTime d) => '${_joursCourts[d.weekday - 1]} ${date(d)}';

/// Lance une modification, rafraîchit [aRafraichir], signale une erreur.
Future<bool> _executer(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(CalendrierApi api) action,
  ProviderOrFamily aRafraichir,
) async {
  final messager = ScaffoldMessenger.of(context);
  try {
    await action(ref.read(calendrierApiProvider));
    ref.invalidate(aRafraichir);
    return true;
  } catch (e) {
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
    return false;
  }
}

/// Carte d'une section : titre, explication, contenu, bouton d'ajout.
class _Section extends ConsumerWidget {
  const _Section({
    required this.cle,
    required this.icone,
    required this.titre,
    required this.explication,
    required this.contenu,
    this.ajouter,
  });

  final String cle;
  final IconData icone;
  final String titre, explication;
  final Widget contenu;
  final VoidCallback? ajouter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return Container(
      key: ValueKey('section-$cle'),
      decoration: BoxDecoration(
        color: context.schema.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.couleurs.bord),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.schema.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icone, color: context.schema.onPrimaryContainer, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(explication, style: TextStyle(fontSize: 12.5, color: context.couleurs.encre3)),
                    ],
                  ),
                ),
                if (ajouter != null && modifiable)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilledButton.tonalIcon(
                      key: ValueKey('ajouter-$cle'),
                      onPressed: ajouter,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter'),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          contenu,
        ],
      ),
    );
  }
}

/// Ligne d'une section : texte principal, détail, étiquettes, actions.
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.titre,
    this.detail,
    this.etiquettes = const [],
    this.fin,
    this.surAppui,
    this.cle,
  });

  final String titre;
  final String? detail;
  final List<Widget> etiquettes;
  final Widget? fin;
  final VoidCallback? surAppui;
  final String? cle;

  @override
  Widget build(BuildContext context) => InkWell(
    key: cle == null ? null : ValueKey<String>(cle!),
    onTap: surAppui,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(titre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ...etiquettes,
                  ],
                ),
                if (detail != null && detail!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(detail!, style: TextStyle(fontSize: 12.5, color: context.couleurs.encre3)),
                  ),
              ],
            ),
          ),
          ?fin,
        ],
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.texte, {this.couleur, this.fond});
  final String texte;
  final Color? couleur, fond;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: fond ?? context.couleurs.neutreDoux,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      texte,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: couleur ?? context.couleurs.encre2,
      ),
    ),
  );
}

class _Vide extends StatelessWidget {
  const _Vide(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    child: Text(texte, style: TextStyle(color: context.couleurs.encre3)),
  );
}

Widget _etat<T>(AsyncValue<T> v, WidgetRef ref, ProviderOrFamily p, Widget Function(T) data) => v.when(
  data: data,
  loading: () => const Padding(
    padding: EdgeInsets.all(20),
    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
  ),
  error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(p)),
);

Future<bool> _confirmerSuppression(BuildContext context, String quoi) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(quoi),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer')),
        ],
      ),
    ) ??
    false;

/// Champ de date qui ouvre le calendrier.
class _ChoixDate extends StatelessWidget {
  const _ChoixDate({required this.libelle, required this.valeur, required this.surChoix});
  final String libelle;
  final DateTime? valeur;
  final ValueChanged<DateTime> surChoix;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: ValueKey('choix-$libelle'),
    style: OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: const Icon(Icons.event_outlined, size: 18),
    label: Text(valeur == null ? libelle : _dateCourte(valeur!)),
    onPressed: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: valeur ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        helpText: libelle,
      );
      if (d != null) surChoix(d);
    },
  );
}

// ── Gardes ──────────────────────────────────────────────────────────────────

class _SectionGardes extends ConsumerWidget {
  const _SectionGardes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return _Section(
      cle: 'gardes',
      icone: Icons.nightlight_outlined,
      titre: 'Gardes',
      explication: 'Soirée jusqu\'à 23 h, 24 h sur 24, ou ouverture un jour de fermeture.',
      ajouter: () => _dialogueGarde(context, ref),
      contenu: _etat(ref.watch(gardesProvider), ref, gardesProvider, (gardes) {
        if (gardes.isEmpty) return const _Vide('Aucune garde enregistrée.');
        final aujourdhui = DateUtils.dateOnly(DateTime.now());
        final aVenir = gardes.where((g) => !g.date.isBefore(aujourdhui)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final passees = gardes.where((g) => g.date.isBefore(aujourdhui)).toList();
        final aConfirmer = passees.where((g) => g.aConfirmer).length;
        Widget ligne(Garde g) => _Ligne(
          cle: 'garde-${jourApi(g.date)}',
          titre: _dateCourte(g.date),
          detail: [g.type.detail, if (g.note != null && g.note!.isNotEmpty) g.note!].join(' · '),
          etiquettes: [
            _Badge(
              g.type.libelle,
              couleur: context.schema.onPrimaryContainer,
              fond: context.schema.primaryContainer,
            ),
            if (g.aConfirmer)
              _Badge('à confirmer', couleur: context.etats.alerte, fond: context.etats.alerteDoux),
          ],
          surAppui: modifiable ? () => _dialogueGarde(context, ref, garde: g) : null,
          fin: modifiable && g.aConfirmer
              ? TextButton(
                  onPressed: () => _executer(
                    context,
                    ref,
                    (api) => api.enregistrerGarde(g.date, g.type, note: g.note),
                    gardesProvider,
                  ),
                  child: const Text('Confirmer'),
                )
              : null,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SousTitre('À venir', compte: aVenir.length),
            if (aVenir.isEmpty) const _Vide('Aucune garde à venir saisie.') else ...aVenir.map(ligne),
            _SousTitre(
              'Passées',
              compte: passees.length,
              detail: aConfirmer > 0 ? '$aConfirmer retrouvées dans les ventes, à confirmer' : null,
            ),
            ...passees.take(12).map(ligne),
            if (passees.length > 12)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  '… et ${passees.length - 12} plus anciennes.',
                  style: TextStyle(color: context.couleurs.encre3, fontSize: 12.5),
                ),
              ),
            const SizedBox(height: 6),
          ],
        );
      }),
    );
  }
}

class _SousTitre extends StatelessWidget {
  const _SousTitre(this.texte, {this.compte, this.detail});
  final String texte;
  final int? compte;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
    child: Row(
      children: [
        Text(
          texte.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: .6,
            fontWeight: FontWeight.w700,
            color: context.couleurs.encre3,
          ),
        ),
        if (compte != null) ...[
          const SizedBox(width: 6),
          Text('$compte', style: TextStyle(fontSize: 11, color: context.couleurs.encre3)),
        ],
        if (detail != null) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              detail!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: context.etats.alerte, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    ),
  );
}

Future<void> _dialogueGarde(BuildContext context, WidgetRef ref, {Garde? garde}) async {
  DateTime? jour = garde?.date;
  var type = garde?.type ?? TypeGarde.soiree;
  final note = TextEditingController(text: garde?.note ?? '');
  await showDialog<void>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, majour) => AlertDialog(
        title: Text(garde == null ? 'Nouvelle garde' : 'Garde du ${_dateCourte(garde.date)}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (garde == null) ...[
                _ChoixDate(
                  libelle: 'Date de la garde',
                  valeur: jour,
                  surChoix: (d) => majour(() => jour = d),
                ),
                const SizedBox(height: 14),
              ],
              RadioGroup<TypeGarde>(
                groupValue: type,
                onChanged: (v) => majour(() => type = v!),
                child: Column(
                  children: [
                    for (final t in TypeGarde.values)
                      RadioListTile<TypeGarde>(
                        key: ValueKey('type-${t.api}'),
                        value: t,
                        title: Text(t.libelle),
                        subtitle: Text(t.detail),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('note-garde'),
                controller: note,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Note (facultatif)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (garde != null)
            TextButton(
              onPressed: () async {
                if (!await _confirmerSuppression(c, 'La garde du ${_dateCourte(garde.date)}.')) return;
                if (!c.mounted) return;
                if (await _executer(c, ref, (api) => api.supprimerGarde(garde.date), gardesProvider) &&
                    c.mounted) {
                  Navigator.pop(c);
                }
              },
              child: Text('Supprimer', style: TextStyle(color: c.etats.critique)),
            ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          FilledButton(
            key: const ValueKey('enregistrer'),
            onPressed: jour == null
                ? null
                : () async {
                    final ok = await _executer(
                      c,
                      ref,
                      (api) => api.enregistrerGarde(
                        jour!,
                        type,
                        note: note.text.trim().isEmpty ? null : note.text.trim(),
                      ),
                      gardesProvider,
                    );
                    if (ok && c.mounted) Navigator.pop(c);
                  },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

// ── Ramadan et Aïd ──────────────────────────────────────────────────────────

class _SectionEvenements extends ConsumerWidget {
  const _SectionEvenements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return _Section(
      cle: 'fetes',
      icone: Icons.brightness_3_outlined,
      titre: 'Ramadan et Aïd',
      explication: 'Leur date avance d\'environ 11 jours chaque année. Vérifiez-les à l\'annonce officielle.',
      ajouter: () => _dialogueEvenement(context, ref),
      contenu: _etat(ref.watch(evenementsProvider), ref, evenementsProvider, (evenements) {
        if (evenements.isEmpty) return const _Vide('Aucune fête saisie.');
        final parAnnee = <int, List<Evenement>>{};
        for (final e in evenements) {
          parAnnee.putIfAbsent(e.debut.year, () => []).add(e);
        }
        final annees = parAnnee.keys.toList()..sort((a, b) => b.compareTo(a));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in annees) ...[
              _SousTitre('$a'),
              for (final e in parAnnee[a]!..sort((x, y) => x.debut.compareTo(y.debut)))
                _Ligne(
                  cle: 'fete-${e.id}',
                  titre: e.type.libelle,
                  detail: '${date(e.debut)} → ${date(e.fin)} · ${e.jours} jour${e.jours > 1 ? 's' : ''}',
                  etiquettes: [
                    if (e.aVerifier)
                      _Badge('à vérifier', couleur: context.etats.alerte, fond: context.etats.alerteDoux),
                  ],
                  surAppui: modifiable ? () => _dialogueEvenement(context, ref, evenement: e) : null,
                ),
            ],
            const SizedBox(height: 6),
          ],
        );
      }),
    );
  }
}

Future<void> _dialogueEvenement(BuildContext context, WidgetRef ref, {Evenement? evenement}) async {
  var type = evenement?.type ?? TypeEvenement.ramadan;
  DateTimeRange? periode = evenement == null
      ? null
      : DateTimeRange(start: evenement.debut, end: evenement.fin);
  await showDialog<void>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, majour) => AlertDialog(
        title: Text(evenement == null ? 'Nouvelle fête' : evenement.type.libelle),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TypeEvenement>(
                segments: [
                  for (final t in TypeEvenement.values) ButtonSegment(value: t, label: Text(t.libelle)),
                ],
                selected: {type},
                showSelectedIcon: false,
                onSelectionChanged: (s) => majour(() => type = s.first),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const ValueKey('choix-periode'),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(
                  periode == null ? 'Choisir les dates' : '${date(periode!.start)} → ${date(periode!.end)}',
                ),
                onPressed: () async {
                  final p = await showDateRangePicker(
                    context: c,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialDateRange: periode,
                    helpText: type.libelle,
                  );
                  if (p != null) majour(() => periode = p);
                },
              ),
            ],
          ),
        ),
        actions: [
          if (evenement != null)
            TextButton(
              onPressed: () async {
                if (!await _confirmerSuppression(c, '${evenement.type.libelle} ${evenement.debut.year}.')) {
                  return;
                }
                if (!c.mounted) return;
                if (await _executer(
                      c,
                      ref,
                      (api) => api.supprimerEvenement(evenement.id),
                      evenementsProvider,
                    ) &&
                    c.mounted) {
                  Navigator.pop(c);
                }
              },
              child: Text('Supprimer', style: TextStyle(color: c.etats.critique)),
            ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          FilledButton(
            onPressed: periode == null
                ? null
                : () async {
                    final ok = await _executer(
                      c,
                      ref,
                      (api) =>
                          api.enregistrerEvenement(type, periode!.start, periode!.end, id: evenement?.id),
                      evenementsProvider,
                    );
                    if (ok && c.mounted) Navigator.pop(c);
                  },
            child: Text(evenement?.aVerifier == true ? 'Valider ces dates' : 'Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

// ── Jours fériés ────────────────────────────────────────────────────────────

class _SectionFeries extends ConsumerWidget {
  const _SectionFeries();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return _Section(
      cle: 'feries',
      icone: Icons.flag_outlined,
      titre: 'Jours fériés',
      explication: 'Fêtes à date fixe : 1er janvier, Yennayer, 1er mai, 5 juillet, 1er novembre…',
      ajouter: () => _dialogueFerie(context, ref),
      contenu: _etat(ref.watch(feriesProvider), ref, feriesProvider, (feries) {
        if (feries.isEmpty) return const _Vide('Aucun jour férié saisi.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final f in feries)
              _Ligne(
                cle: 'ferie-${f.id}',
                titre: _dateCourte(f.date),
                detail: f.label,
                fin: modifiable
                    ? IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          if (!await _confirmerSuppression(
                            context,
                            '${f.label ?? ''} ${date(f.date)}'.trim(),
                          )) {
                            return;
                          }
                          if (context.mounted) {
                            await _executer(context, ref, (api) => api.supprimerFerie(f.id), feriesProvider);
                          }
                        },
                      )
                    : null,
              ),
            const SizedBox(height: 6),
          ],
        );
      }),
    );
  }
}

Future<void> _dialogueFerie(BuildContext context, WidgetRef ref) async {
  DateTime? jour;
  final libelle = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, majour) => AlertDialog(
        title: const Text('Nouveau jour férié'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChoixDate(libelle: 'Date', valeur: jour, surChoix: (d) => majour(() => jour = d)),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('libelle-ferie'),
                controller: libelle,
                maxLength: 100,
                onChanged: (_) => majour(() {}),
                decoration: const InputDecoration(
                  labelText: 'Nom (ex. Yennayer)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          FilledButton(
            onPressed: jour == null || libelle.text.trim().isEmpty
                ? null
                : () async {
                    final ok = await _executer(
                      c,
                      ref,
                      (api) => api.ajouterFerie(jour!, libelle.text.trim()),
                      feriesProvider,
                    );
                    if (ok && c.mounted) Navigator.pop(c);
                  },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

// ── Calcul des commandes ────────────────────────────────────────────────────

const _reglagesConnus = {
  'periode_commande_jours': (
    'Période entre deux commandes',
    'jours',
    'Fixe le stock maximum : SS + CMM × période.',
  ),
  'delai_securite_jours': ('Délai de sécurité', 'jours', 'Stock de sécurité simple : CMJ × ce délai.'),
  'delai_livraison_jours': (
    'Délai de livraison par défaut',
    'jours ouvrés',
    'Pour un fournisseur sans délai saisi. Vendredi et samedi ne comptent pas.',
  ),
};

class _SectionReglages extends ConsumerWidget {
  const _SectionReglages();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return _Section(
      cle: 'reglages',
      icone: Icons.tune_rounded,
      titre: 'Calcul des commandes',
      explication: 'Constantes utilisées pour le stock de sécurité, le stock maximum et la livraison.',
      contenu: _etat(ref.watch(reglagesProvider), ref, reglagesProvider, (reglages) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in reglages)
              _Ligne(
                cle: 'reglage-${r.cle}',
                titre: _reglagesConnus[r.cle]?.$1 ?? r.description ?? r.cle,
                detail: _reglagesConnus[r.cle]?.$3,
                surAppui: modifiable ? () => _dialogueReglage(context, ref, r) : null,
                fin: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${decimal(r.valeur)} ${_reglagesConnus[r.cle]?.$2 ?? ''}'.trim(),
                    style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
        );
      }),
    );
  }
}

Future<void> _dialogueReglage(BuildContext context, WidgetRef ref, Reglage r) async {
  final champ = TextEditingController(text: decimal(r.valeur));
  final (titre, unite, explication) = _reglagesConnus[r.cle] ?? (r.cle, '', '');
  double? lire() => double.tryParse(champ.text.trim().replaceAll(',', '.'));
  await showDialog<void>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, majour) => AlertDialog(
        title: Text(titre),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(explication, style: TextStyle(color: c.couleurs.encre2)),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('valeur-reglage'),
                controller: champ,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => majour(() {}),
                decoration: InputDecoration(suffixText: unite, border: const OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          FilledButton(
            onPressed: (lire() ?? -1) < 0
                ? null
                : () async {
                    final ok = await _executer(
                      c,
                      ref,
                      (api) => api.modifierReglages({r.cle: lire()!}),
                      reglagesProvider,
                    );
                    if (ok && c.mounted) Navigator.pop(c);
                  },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

/// Accès depuis les préférences.
class EntreeReglages extends StatelessWidget {
  const EntreeReglages({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: context.schema.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: context.couleurs.bord),
    ),
    child: InkWell(
      key: const ValueKey('entree-reglages'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/preferences/reglages'),
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
              child: Icon(Icons.event_note_outlined, color: context.schema.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calendrier et réglages',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gardes, Ramadan et Aïd, jours fériés, calcul des commandes',
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
