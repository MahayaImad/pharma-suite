import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/format.dart';
import '../../../domain/paie.dart';
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/paie_providers.dart';
import 'radar_criteres.dart';

/// Largeur à partir de laquelle le bulletin s'ouvre à côté de la liste.
const _largeurDeuxVolets = 980.0;

/// Paie (brut) — design « liste + bulletin avec radar » retenu le 2026-11-18.
/// Titulaire seulement. À gauche le mois et les employés, à droite le
/// bulletin de l'employé [selection] ; sur portable, la liste puis le
/// bulletin en plein écran.
class EcranPaie extends ConsumerWidget {
  const EcranPaie({super.key, this.selection});

  final int? selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paie = ref.watch(paieProvider);
    return LayoutBuilder(
      builder: (context, c) {
        final large = c.maxWidth >= _largeurDeuxVolets;
        final p = paie.value;
        final choisi = p == null
            ? null
            : (selection != null ? p.employe(selection!) : (large ? p.employes.firstOrNull : null));
        if (!large && selection != null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/paie'),
              ),
              title: const Text('Bulletin'),
            ),
            body: paie.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(paieProvider)),
              data: (p) => choisi == null
                  ? const MessageVide(titre: 'Employé introuvable', texte: 'Il n\'est pas dans la paie de ce mois.')
                  : _Bulletin(paie: p, ligne: choisi, large: false),
            ),
          );
        }
        final liste = RefreshIndicator(
          onRefresh: () => ref.refresh(paieProvider.future).catchError((_) => paie.value!),
          child: ListView(
            padding: EdgeInsets.fromLTRB(large ? 20 : 16, 14, large ? 20 : 16, 32),
            children: [
              const _EnTete(),
              ...paie.when(
                skipLoadingOnReload: true,
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [MessageErreur(erreur: e, reessayer: () => ref.invalidate(paieProvider))],
                data: (p) => _employes(context, p, choisi?.employe.id),
              ),
            ],
          ),
        );
        if (!large) return Scaffold(body: liste);
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 390, child: liste),
              VerticalDivider(width: 1, color: context.couleurs.bord),
              Expanded(
                child: ColoredBox(
                  color: context.schema.surface,
                  child: p == null || choisi == null
                      ? const SizedBox.shrink()
                      : _Bulletin(key: ValueKey(choisi.employe.id), paie: p, ligne: choisi, large: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _employes(BuildContext context, PaieMois p, int? choisi) {
    if (p.employes.isEmpty) {
      return const [MessageVide(titre: 'Aucun employé', texte: 'Aucun employé actif et éligible pour ce mois.')];
    }
    Widget tuile(String valeur, String texte, String cle) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: context.schema.surface,
          border: Border.all(color: context.couleurs.bord),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Text(
                valeur,
                key: ValueKey(cle),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Text(texte, style: TextStyle(fontSize: 12, color: context.couleurs.encre2)),
          ],
        ),
      ),
    );
    return [
      Row(
        children: [
          tuile(dinars(p.totaux.brut.round()), 'masse salariale brute', 'masse-brute'),
          const SizedBox(width: 10),
          tuile(dinars(p.totaux.partVariable.round()), 'primes de rendement', 'total-primes'),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
        child: Text(
          '${p.employes.length} employé${p.employes.length > 1 ? 's' : ''}'
                  '${p.aVerifier > 0 ? ' · ${p.aVerifier} à vérifier' : ''}'
              .toUpperCase(),
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: context.couleurs.encre3,
          ),
        ),
      ),
      for (final e in p.employes) _CarteEmploye(ligne: e, choisi: e.employe.id == choisi),
    ];
  }
}

class _EnTete extends ConsumerWidget {
  const _EnTete();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(moisPaieProvider);
    Widget fleche(IconData icone, int pas, String cle) => SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        key: ValueKey(cle),
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
        onPressed: () {
          ref.read(moisPaieProvider.notifier).decaler(pas);
          if (GoRouterState.of(context).uri.path != '/paie') context.go('/paie');
        },
        child: Icon(icone, size: 18),
      ),
    );
    final mois = libelleMois(m.annee, m.mois);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paie',
                  style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700),
                ),
                Text(
                  'salaire brut · cotisations au comptable',
                  style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    fleche(Icons.chevron_left, -1, 'mois-precedent'),
                    const SizedBox(width: 10),
                    Text(
                      mois[0].toUpperCase() + mois.substring(1),
                      key: const ValueKey('mois-paie'),
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 10),
                    fleche(Icons.chevron_right, 1, 'mois-suivant'),
                  ],
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width < largeurPc)
            IconButton(
              tooltip: 'Retour',
              icon: const Icon(Icons.close),
              onPressed: () => context.canPop() ? context.pop() : context.go('/preferences'),
            ),
        ],
      ),
    );
  }
}

class _CarteEmploye extends StatelessWidget {
  const _CarteEmploye({required this.ligne, required this.choisi});
  final PaieEmploye ligne;
  final bool choisi;

  @override
  Widget build(BuildContext context) {
    final e = ligne.employe;
    final et = context.etats;
    final (texte, couleur, fond) = switch (ligne.etat) {
      EtatPaie.prete => ('Prête', et.bon, et.bonDoux),
      EtatPaie.aConfirmer => (
        '${ligne.jours.aConfirmer} jour${ligne.jours.aConfirmer > 1 ? 's' : ''} à confirmer',
        et.alerte,
        et.alerteDoux,
      ),
      EtatPaie.aCompleter => ('À compléter', et.critique, et.critiqueDoux),
      EtatPaie.aVerifier => ('À vérifier', et.alerte, et.alerteDoux),
    };
    final detail = [
      e.poste ?? 'Poste à renseigner',
      if (e.dateEntree != null && ligne.ancienneteAnnees > 0)
        '${ligne.ancienneteAnnees} an${ligne.ancienneteAnnees > 1 ? 's' : ''}',
      if (ligne.jours.contrat < ligne.jours.mois && e.dateEntree != null && e.dateEntree!.day > 1)
        'arrivée le ${jourMois(e.dateEntree!)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: choisi ? context.schema.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: choisi ? context.schema.primary : Colors.transparent, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('employe-paie-${e.id}'),
          onTap: () => context.go('/paie/${e.id}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ligne.etat == EtatPaie.prete ? context.schema.primaryContainer : fond,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    e.initiales,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: ligne.etat == EtatPaie.prete ? context.schema.onPrimaryContainer : couleur,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.nomComplet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(detail, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      e.posteCode == null ? '—' : entier(ligne.brut.round()),
                      style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    _Pastille(texte, couleur, fond),
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

/// Le bulletin d'un employé : part fixe ligne par ligne, prime de rendement
/// (plancher, mérite, radar, tableau des critères), et la barre de validation.
class _Bulletin extends ConsumerWidget {
  const _Bulletin({super.key, required this.paie, required this.ligne, required this.large});
  final PaieMois paie;
  final PaieEmploye ligne;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ligne.employe;
    final marge = large ? 28.0 : 16.0;
    final j = ligne.jours;
    final sousTitre = [
      e.poste ?? 'Poste à renseigner',
      if (e.dateEntree != null) 'entrée le ${date(e.dateEntree!)}',
      '${j.presence} jours présents',
      if (j.absences > 0) '${j.absences} absence${j.absences > 1 ? 's' : ''}',
    ].join(' · ');
    final brut = Column(
      crossAxisAlignment: large ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          dinars(ligne.brut),
          key: const ValueKey('brut'),
          style: const TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700),
        ),
        Text('brut de ${moisFrancais[paie.mois - 1]}', style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
      ],
    );
    final titre = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e.nomComplet,
          style: const TextStyle(fontFamily: 'Sora', fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(sousTitre, style: TextStyle(fontSize: 13, color: context.couleurs.encre3)),
      ],
    );
    final partFixe = _PartFixe(paie: paie, ligne: ligne);
    final prime = _Prime(ligne: ligne);
    final colonnes = MediaQuery.sizeOf(context).width >= 1280 && large;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(marge, large ? 22 : 12, marge, 14),
          child: large
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: titre),
                    brut,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titre, const SizedBox(height: 10), brut],
                ),
        ),
        Divider(height: 1, color: context.couleurs.bord),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (ligne.aVerifier.isNotEmpty)
                Container(
                  key: const ValueKey('a-verifier'),
                  margin: EdgeInsets.fromLTRB(marge, 14, marge, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: context.etats.alerteDoux, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final a in ligne.aVerifier)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $a', style: TextStyle(fontSize: 13, color: context.couleurs.encre2)),
                        ),
                    ],
                  ),
                ),
              if (colonnes)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 9,
                        child: Padding(padding: EdgeInsets.all(marge - 8), child: partFixe),
                      ),
                      VerticalDivider(width: 1, color: context.couleurs.bord),
                      Expanded(
                        flex: 11,
                        child: Padding(padding: EdgeInsets.all(marge - 8), child: prime),
                      ),
                    ],
                  ),
                )
              else ...[
                Padding(padding: EdgeInsets.fromLTRB(marge, 16, marge, 16), child: partFixe),
                Divider(height: 1, color: context.couleurs.bord),
                Padding(padding: EdgeInsets.fromLTRB(marge, 16, marge, 16), child: prime),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: context.couleurs.bord),
        _BarreValidation(paie: paie, ligne: ligne, marge: marge),
      ],
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
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

class _Ligne extends StatelessWidget {
  const _Ligne({required this.libelle, required this.montant, this.detail, this.action, this.total = false, this.cle});
  final String libelle;
  final double montant;
  final String? detail;
  final Widget? action;
  final bool total;
  final String? cle;

  @override
  Widget build(BuildContext context) => Container(
    key: cle == null ? null : ValueKey(cle),
    padding: EdgeInsets.symmetric(vertical: total ? 12 : 8),
    decoration: BoxDecoration(
      border: total ? null : Border(bottom: BorderSide(color: context.couleurs.bord.withValues(alpha: 0.7))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle, style: TextStyle(fontSize: 13, fontWeight: total ? FontWeight.w700 : FontWeight.w400)),
              if ((detail ?? '').isNotEmpty || action != null)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if ((detail ?? '').isNotEmpty)
                      Text(detail!, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                    ?action,
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          montant == 0 ? '0,00' : dinars(montant).replaceAll(' DA', ''),
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: total ? 16 : 13,
            color: montant < 0 ? context.etats.critique : null,
          ),
        ),
      ],
    ),
  );
}

class _PartFixe extends ConsumerWidget {
  const _PartFixe({required this.paie, required this.ligne});
  final PaieMois paie;
  final PaieEmploye ligne;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('part-fixe'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titre('Part fixe'),
        for (final l in ligne.lignes)
          _Ligne(
            cle: 'ligne-${l.code}',
            libelle: l.libelle,
            montant: l.montant,
            detail: detailLigne(ligne, l.code, paie.regles),
            action: l.code == 'heures_sup'
                ? TextButton(
                    key: const ValueKey('modifier-heures-sup'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    onPressed: () => _heuresSup(context, ref),
                    child: const Text('modifier', style: TextStyle(fontSize: 12)),
                  )
                : null,
          ),
        _Ligne(libelle: 'Part fixe', montant: ligne.partFixe, total: true, cle: 'total-part-fixe'),
      ],
    );
  }

  Future<void> _heuresSup(BuildContext context, WidgetRef ref) async {
    final champ = TextEditingController(text: ligne.heuresSup == 0 ? '' : decimal(ligne.heuresSup, chiffres: 2));
    final heures = await showDialog<double>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Heures supplémentaires · ${ligne.employe.nomComplet}'),
        content: TextField(
          key: const ValueKey('saisie-heures-sup'),
          controller: champ,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(
            labelText: 'Heures du mois',
            helperText: 'Arrondies au quart d\'heure ; 0 pour aucune.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Annuler')),
          FilledButton(
            key: const ValueKey('heures-sup-ok'),
            onPressed: () => Navigator.pop(
              d,
              double.tryParse(champ.text.replaceAll(',', '.').trim().isEmpty ? '0' : champ.text.replaceAll(',', '.')),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (heures == null) return;
    try {
      await ref.read(paieProvider.notifier).heuresSup(ligne.employe.id, heures);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
      }
    }
  }
}

class _Prime extends StatelessWidget {
  const _Prime({required this.ligne});
  final PaieEmploye ligne;

  @override
  Widget build(BuildContext context) {
    final p = ligne.prime;
    if (p == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Titre('Prime de rendement'),
          Text(
            'Pas encore calculée pour ce mois. « Recalculer les primes » la calcule pour toute l\'équipe.',
            style: TextStyle(fontSize: 13, color: context.couleurs.encre2),
          ),
        ],
      );
    }
    final criteres = p.criteres;
    return Column(
      key: const ValueKey('prime'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Titre('Prime de rendement · ${dinars(ligne.partVariable).replaceAll(' DA', '')}'),
        _Ligne(libelle: 'Plancher', detail: '50 % de la part égalitaire', montant: p.plancher, cle: 'plancher'),
        _Ligne(libelle: 'Mérite', detail: 'selon les critères ci-dessous', montant: p.merite, cle: 'merite'),
        const SizedBox(height: 10),
        if (criteres.length >= 3) RadarCriteres(criteres: criteres, nom: ligne.employe.nomComplet),
        const SizedBox(height: 10),
        _TableCriteres(criteres: criteres),
      ],
    );
  }
}

class _TableCriteres extends StatelessWidget {
  const _TableCriteres({required this.criteres});
  final List<Critere> criteres;

  @override
  Widget build(BuildContext context) {
    final entete = TextStyle(
      fontFamily: 'Sora',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: context.couleurs.encre3,
    );
    Widget ligne(List<Widget> cellules, {Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.couleurs.bord.withValues(alpha: 0.7))),
      ),
      child: Row(
        children: [
          Expanded(child: cellules[0]),
          SizedBox(
            width: 96,
            child: Align(alignment: Alignment.centerRight, child: cellules[1]),
          ),
          SizedBox(
            width: 82,
            child: Align(alignment: Alignment.centerRight, child: cellules[2]),
          ),
          SizedBox(
            width: 44,
            child: Align(alignment: Alignment.centerRight, child: cellules[3]),
          ),
        ],
      ),
    );
    return Column(
      key: const ValueKey('table-criteres'),
      children: [
        ligne([
          Text('CRITÈRE', style: entete),
          Text('VALEUR', style: entete),
          Text('VS MOYENNE', style: entete),
          Text('POIDS', style: entete),
        ]),
        for (final c in criteres)
          ligne(key: ValueKey('critere-${c.code}'), [
            Text(c.libelle, style: const TextStyle(fontSize: 12)),
            Text(
              c.valeurLisible,
              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(
              c.ecart ?? '—',
              style: TextStyle(
                fontSize: 12,
                color: c.indice == null
                    ? context.couleurs.encre3
                    : (c.indice! >= 100 ? context.etats.bon : context.etats.critique),
              ),
            ),
            Text(entier(c.poids), style: const TextStyle(fontSize: 12)),
          ]),
      ],
    );
  }
}

class _BarreValidation extends ConsumerStatefulWidget {
  const _BarreValidation({required this.paie, required this.ligne, required this.marge});
  final PaieMois paie;
  final PaieEmploye ligne;
  final double marge;

  @override
  ConsumerState<_BarreValidation> createState() => _EtatBarre();
}

class _EtatBarre extends ConsumerState<_BarreValidation> {
  bool _occupe = false;

  Future<void> _faire(Future<void> Function() geste, String reussi) async {
    final messager = ScaffoldMessenger.of(context);
    setState(() => _occupe = true);
    try {
      await geste();
      messager.showSnackBar(SnackBar(content: Text(reussi)));
    } catch (e) {
      messager.showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paie;
    final b = widget.ligne.bulletin;
    final mois = moisFrancais[p.mois - 1];
    // Sur portable, libellés courts : les deux boutons tiennent sur une ligne.
    final court = MediaQuery.sizeOf(context).width < 600;
    final etat = b == null
        ? '${mois[0].toUpperCase()}${mois.substring(1)} pas encore validé'
        : (b.aJour
              ? 'Bulletin validé (version ${b.version})${b.validePar != null ? ' par ${b.validePar}' : ''}'
              : 'Validé, mais modifié depuis : à revalider');
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.marge, 12, widget.marge, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            etat,
            key: const ValueKey('etat-bulletin'),
            style: TextStyle(
              fontSize: 13,
              color: b != null && !b.aJour ? context.etats.alerte : context.couleurs.encre2,
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const ValueKey('recalculer-primes'),
                onPressed: _occupe
                    ? null
                    : () => _faire(
                        () => ref.read(paieProvider.notifier).recalculerPrimes(),
                        'Primes de $mois recalculées.',
                      ),
                child: Text(court ? 'Recalculer' : 'Recalculer les primes'),
              ),
              FilledButton(
                key: const ValueKey('valider-paie'),
                onPressed: _occupe ? null : () => _valider(mois),
                child: Text(court ? 'Valider $mois' : 'Valider la paie de $mois'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _valider(String mois) async {
    final p = widget.paie;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Valider la paie de $mois ?'),
        content: Text(
          '${p.employes.length} bulletins bruts, ${dinars(p.totaux.brut.round())} au total.'
          '${p.aVerifier > 0 ? '\n${p.aVerifier} employé${p.aVerifier > 1 ? 's' : ''} encore à vérifier.' : ''}'
          '\nUne nouvelle version est gardée ; les précédentes ne sont pas effacées.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annuler')),
          FilledButton(
            key: const ValueKey('confirmer-validation'),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _faire(() => ref.read(paieProvider.notifier).valider(), 'Paie de $mois validée.');
  }
}
