import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/format.dart';
import '../../../domain/paie.dart';
import '../application/paie_providers.dart';

/// Ouvre la fiche paie de [employe] : poste, dates d'entrée et de sortie,
/// heure de début, présence dans la paie.
Future<void> ouvrirFicheEmploye(BuildContext context, EmployePaie employe) =>
    showDialog<void>(context: context, builder: (_) => _FicheEmploye(employe));

String _iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _FicheEmploye extends ConsumerStatefulWidget {
  const _FicheEmploye(this.employe);
  final EmployePaie employe;

  @override
  ConsumerState<_FicheEmploye> createState() => _EtatFiche();
}

class _EtatFiche extends ConsumerState<_FicheEmploye> {
  late String? _poste = widget.employe.posteCode;
  late DateTime? _entree = widget.employe.dateEntree;
  late DateTime? _sortie = widget.employe.dateSortie;
  late TimeOfDay? _heure = _lireHeure(widget.employe.heureDebutCourte);
  bool _dansLaPaie = true;
  bool _occupe = false;
  String? _erreur;

  static TimeOfDay? _lireHeure(String? h) {
    if (h == null) return null;
    final p = h.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _heureTexte(TimeOfDay h) =>
      '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';

  /// Seuls les champs changés partent au serveur.
  Map<String, Object?> _changements() {
    final e = widget.employe;
    String? j(DateTime? d) => d == null ? null : _iso(d);
    return {
      if (_poste != e.posteCode) 'poste_code': _poste,
      if (j(_entree) != j(e.dateEntree)) 'date_entree': j(_entree),
      if (j(_sortie) != j(e.dateSortie)) 'date_sortie': j(_sortie),
      if (_heure?.let(_heureTexte) != e.heureDebutCourte) 'heure_debut': _heure?.let(_heureTexte),
      if (!_dansLaPaie) 'eligible_prime': false,
    };
  }

  Future<void> _enregistrer() async {
    final champs = _changements();
    if (champs.isEmpty) return Navigator.pop(context);
    final messager = ScaffoldMessenger.of(context);
    final routeur = GoRouter.of(context);
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      await ref.read(paieProvider.notifier).modifierEmploye(widget.employe.id, champs);
      if (!mounted) return;
      Navigator.pop(context);
      if (!_dansLaPaie) {
        routeur.go('/paie');
        messager.showSnackBar(SnackBar(content: Text('${widget.employe.nomComplet} n\'est plus dans la paie.')));
      }
    } catch (e) {
      if (mounted) setState(() => _erreur = ErreurApi.depuis(e).message);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  Future<DateTime?> _choisirDate(DateTime? depart) => showDatePicker(
    context: context,
    initialDate: depart ?? DateTime.now(),
    firstDate: DateTime(1980),
    lastDate: DateTime(DateTime.now().year + 2),
  );

  @override
  Widget build(BuildContext context) {
    final postes = ref.watch(postesTravailProvider);
    final encre3 = context.couleurs.encre3;
    Widget champ({
      required String cle,
      required String titre,
      required String valeur,
      required VoidCallback choisir,
      VoidCallback? effacer,
    }) => ListTile(
      key: ValueKey(cle),
      contentPadding: EdgeInsets.zero,
      title: Text(titre, style: TextStyle(fontSize: 12, color: encre3)),
      subtitle: Text(valeur, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: choisir,
      trailing: effacer == null
          ? const Icon(Icons.edit_calendar_outlined, size: 18)
          : IconButton(tooltip: 'Effacer', icon: const Icon(Icons.close, size: 18), onPressed: effacer),
    );
    return AlertDialog(
      title: Text(widget.employe.nomComplet),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              postes.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(ErreurApi.depuis(e).message, style: TextStyle(color: context.etats.alerte)),
                data: (liste) => DropdownButtonFormField<String>(
                  key: const ValueKey('choix-poste'),
                  initialValue: liste.any((p) => p.code == _poste) ? _poste : null,
                  decoration: const InputDecoration(labelText: 'Poste'),
                  hint: const Text('À choisir'),
                  items: [
                    for (final p in liste)
                      DropdownMenuItem(value: p.code, child: Text('${p.libelle} · ${dinars(p.salaireBase.round())}')),
                  ],
                  onChanged: (v) => setState(() => _poste = v),
                ),
              ),
              const SizedBox(height: 8),
              champ(
                cle: 'date-entree',
                titre: 'Date d\'entrée (ancienneté, prorata)',
                valeur: _entree == null ? 'À renseigner' : date(_entree!),
                choisir: () async {
                  final d = await _choisirDate(_entree);
                  if (d != null) setState(() => _entree = d);
                },
              ),
              champ(
                cle: 'date-sortie',
                titre: 'Date de sortie',
                valeur: _sortie == null ? 'Toujours en poste' : date(_sortie!),
                choisir: () async {
                  final d = await _choisirDate(_sortie);
                  if (d != null) setState(() => _sortie = d);
                },
                effacer: _sortie == null ? null : () => setState(() => _sortie = null),
              ),
              champ(
                cle: 'heure-debut',
                titre: 'Heure de début (retard au-delà de 45 min)',
                valeur: _heure == null ? 'Heure générale des réglages' : _heureTexte(_heure!),
                choisir: () async {
                  final h = await showTimePicker(
                    context: context,
                    initialTime: _heure ?? const TimeOfDay(hour: 8, minute: 30),
                  );
                  if (h != null) setState(() => _heure = h);
                },
                effacer: _heure == null ? null : () => setState(() => _heure = null),
              ),
              SwitchListTile(
                key: const ValueKey('dans-la-paie'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Dans la paie et les primes'),
                subtitle: Text(
                  'À retirer pour un compte non nominatif (poste de caisse partagé).',
                  style: TextStyle(fontSize: 12, color: encre3),
                ),
                value: _dansLaPaie,
                onChanged: (v) => setState(() => _dansLaPaie = v),
              ),
              if (_erreur != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_erreur!, style: TextStyle(color: context.etats.alerte)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _occupe ? null : () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          key: const ValueKey('enregistrer-fiche'),
          onPressed: _occupe ? null : _enregistrer,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

extension<T extends Object> on T {
  R let<R>(R Function(T) f) => f(this);
}
