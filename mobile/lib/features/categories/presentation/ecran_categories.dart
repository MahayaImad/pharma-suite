import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../../data/api/client_api.dart';
import '../../../domain/categories.dart';
import '../../../domain/format.dart';
import '../../../domain/paie.dart' show moisFrancais;
import '../../stock/presentation/elements_stock.dart' show MessageErreur, MessageVide;
import '../application/categories_providers.dart';

/// Couleur d'une catégorie (null : sans catégorie).
Color couleurCategorie(BuildContext context, String? code) => switch (code) {
  'princeps' => context.schema.primary,
  'generique' => const Color(0xFF1FA855),
  'generique++' => const Color(0xFF6B3FC4),
  _ => const Color(0xFFE79A00),
};

/// Catégories de prime — design « tout sur une page » retenu le 2026-11-18.
/// L'enveloppe du mois et sa répartition, les laboratoires génériques, le
/// classement automatique et les produits à classer à la main. Titulaire.
class EcranCategories extends ConsumerWidget {
  const EcranCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prime = ref.watch(primeCategoriesProvider);
    return Scaffold(
      body: SafeArea(
        child: prime.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: MessageErreur(erreur: e, reessayer: () => ref.invalidate(primeCategoriesProvider)),
          ),
          data: (p) => LayoutBuilder(
            builder: (context, c) {
              final large = c.maxWidth >= 900;
              final marge = large ? 28.0 : 16.0;
              final gauche = const _Laboratoires();
              final droite = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Classer(prime: p),
                  const SizedBox(height: 18),
                  const _Produits(),
                ],
              );
              return ListView(
                padding: EdgeInsets.fromLTRB(marge, large ? 24 : 12, marge, 40),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _EnTete(prime: p),
                          const SizedBox(height: 16),
                          _Enveloppe(prime: p),
                          const SizedBox(height: 12),
                          _Tuiles(prime: p, colonnes: large ? 4 : 2),
                          const SizedBox(height: 18),
                          if (large)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 23, child: gauche),
                                const SizedBox(width: 16),
                                Expanded(flex: 20, child: droite),
                              ],
                            )
                          else ...[
                            gauche,
                            const SizedBox(height: 18),
                            droite,
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String _taux(double t) => pourcent(t);

class _EnTete extends StatelessWidget {
  const _EnTete({required this.prime});
  final PrimeCategories prime;

  @override
  Widget build(BuildContext context) {
    final sous = [for (final c in categoriesPrime) '${libelleCategorie(c).toLowerCase()} ${_taux(prime.taux(c))}'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.go('/preferences'),
                child: Text('Préférences ›', style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Catégories de prime',
                style: TextStyle(fontFamily: 'Sora', fontSize: 24, fontWeight: FontWeight.w700),
              ),
              Text('${sous.join(' · ')} du CA du mois', style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
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
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.fond, this.bord});
  final Widget child;
  final EdgeInsets padding;
  final Color? fond, bord;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: fond ?? context.schema.surface,
      border: Border.all(color: bord ?? context.couleurs.bord),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _Enveloppe extends ConsumerWidget {
  const _Enveloppe({required this.prime});
  final PrimeCategories prime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = prime;
    Widget fleche(IconData icone, int pas, String cle) => SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        key: ValueKey(cle),
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
        onPressed: () => ref.read(moisCategoriesProvider.notifier).decaler(pas),
        child: Icon(icone, size: 18),
      ),
    );
    final nomMois = moisFrancais[p.mois - 1];
    final parts = [
      for (final c in [...categoriesPrime, null]) (c, p.categorie(c).ca),
    ];
    return _Carte(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enveloppe de $nomMois ${p.annee}',
                    style: TextStyle(fontSize: 13, color: context.couleurs.encre3),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 10,
                    children: [
                      Text(
                        dinars(p.enveloppe.round()),
                        key: const ValueKey('enveloppe'),
                        style: const TextStyle(fontFamily: 'Sora', fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          'sur ${dinars(p.ca.round())} de CA',
                          style: TextStyle(fontSize: 13, color: context.couleurs.encre3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  fleche(Icons.chevron_left, -1, 'mois-precedent'),
                  const SizedBox(width: 10),
                  Text(
                    nomMois[0].toUpperCase() + nomMois.substring(1),
                    key: const ValueKey('mois-categories'),
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  fleche(Icons.chevron_right, 1, 'mois-suivant'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              key: const ValueKey('barre-categories'),
              height: 10,
              width: double.infinity,
              child: p.ca <= 0
                  ? ColoredBox(color: context.couleurs.neutreDoux)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (c, ca) in parts)
                          if (ca > 0)
                            Expanded(
                              flex: (ca / p.ca * 1000).round().clamp(1, 1000),
                              child: ColoredBox(color: couleurCategorie(context, c)),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final (c, _) in parts)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: couleurCategorie(context, c),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        c == null ? 'Sans catégorie (comptée princeps)' : libelleCategorie(c),
                        style: TextStyle(fontSize: 12, color: context.couleurs.encre2),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tuiles extends StatelessWidget {
  const _Tuiles({required this.prime, required this.colonnes});
  final PrimeCategories prime;
  final int colonnes;

  @override
  Widget build(BuildContext context) {
    Widget tuile(String? code) {
      final c = prime.categorie(code);
      final sans = code == null;
      return _Carte(
        key: ValueKey('tuile-${code ?? 'sans'}'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        fond: sans && c.ca > 0 ? context.etats.alerteDoux : null,
        bord: sans && c.ca > 0 ? context.etats.alerte.withValues(alpha: .35) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sans ? 'Sans catégorie' : '${libelleCategorie(code)} · ${_taux(c.tauxPct)}',
              style: TextStyle(
                fontSize: 12,
                color: sans ? context.etats.alerte : context.couleurs.encre2,
                fontWeight: sans ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            FittedBox(
              child: Text(
                entier(c.ca),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sans
                  ? '→ ${dinars(c.montant.round())} au taux princeps · ${c.produits} produit${c.produits > 1 ? 's' : ''}'
                  : '→ ${dinars(c.montant.round())}',
              style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
            ),
          ],
        ),
      );
    }

    final codes = [...categoriesPrime, null];
    final lignes = <Widget>[];
    for (var i = 0; i < codes.length; i += colonnes) {
      lignes.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + colonnes; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(child: j < codes.length ? tuile(codes[j]) : const SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + colonnes < codes.length) lignes.add(const SizedBox(height: 10));
    }
    return Column(children: lignes);
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      texte.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Sora',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: .6,
        color: context.couleurs.encre3,
      ),
    ),
  );
}

void _erreur(BuildContext context, Object e) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));

class _Laboratoires extends ConsumerWidget {
  const _Laboratoires();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labos = ref.watch(laboratoiresPrimeProvider);
    final filtre = ref.watch(filtreLaboratoiresProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TitreSection('Laboratoires génériques'),
        TextField(
          key: const ValueKey('recherche-labo'),
          decoration: InputDecoration(
            hintText: 'Chercher un laboratoire',
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
            filled: true,
            fillColor: context.schema.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.couleurs.bord),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.couleurs.bord),
            ),
          ),
          onChanged: ref.read(filtreLaboratoiresProvider.notifier).chercher,
        ),
        const SizedBox(height: 10),
        labos.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(laboratoiresPrimeProvider)),
          data: (page) {
            if (page.laboratoires.isEmpty) {
              return MessageVide(
                titre: 'Aucun laboratoire',
                texte: filtre.recherche.isEmpty
                    ? 'La synchronisation d\'EASYPHARM n\'a pas encore envoyé de laboratoires.'
                    : 'Aucun laboratoire ne correspond à « ${filtre.recherche} ».',
              );
            }
            final reste = page.total - page.laboratoires.length;
            return _Carte(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, l) in page.laboratoires.indexed) ...[
                    if (i > 0) Divider(height: 1, color: context.couleurs.bord),
                    _LigneLabo(labo: l),
                  ],
                  if (reste > 0) ...[
                    Divider(height: 1, color: context.couleurs.bord),
                    TextButton(
                      key: const ValueKey('voir-tous-labos'),
                      onPressed: ref.read(filtreLaboratoiresProvider.notifier).toutVoir,
                      child: Text('Voir les $reste autres laboratoires'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LigneLabo extends ConsumerStatefulWidget {
  const _LigneLabo({required this.labo});
  final LaboratoirePrime labo;

  @override
  ConsumerState<_LigneLabo> createState() => _EtatLigneLabo();
}

class _EtatLigneLabo extends ConsumerState<_LigneLabo> {
  bool? _choix; // affiché tout de suite, avant la relecture

  @override
  Widget build(BuildContext context) {
    final l = widget.labo;
    final generique = _choix ?? l.generique;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.labo, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${l.produits} produit${l.produits > 1 ? 's' : ''} · ${pourcent(l.partCa)} du CA',
                  style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entier(l.ca),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text('DA ce mois', style: TextStyle(fontSize: 11, color: context.couleurs.encre3)),
            ],
          ),
          const SizedBox(width: 6),
          Switch(
            key: ValueKey('labo-${l.id}'),
            value: generique,
            onChanged: (v) async {
              setState(() => _choix = v);
              try {
                await ref.read(gestesCategoriesProvider).marquerLaboratoire(l.id, v);
              } catch (e) {
                if (!context.mounted) return;
                setState(() => _choix = null);
                _erreur(context, e);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Classer extends ConsumerStatefulWidget {
  const _Classer({required this.prime});
  final PrimeCategories prime;

  @override
  ConsumerState<_Classer> createState() => _EtatClasser();
}

class _EtatClasser extends ConsumerState<_Classer> {
  late double _seuil = widget.prime.seuilMarge;
  bool _occupe = false;

  Future<void> _changerSeuil() async {
    final saisie = TextEditingController(text: entier(_seuil));
    final v = await showDialog<double>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Seuil de marge générique++'),
        content: TextField(
          key: const ValueKey('saisie-seuil'),
          controller: saisie,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            suffixText: '%',
            helperText: 'Marge moyenne des lots, en % du prix d\'achat',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Annuler')),
          FilledButton(
            key: const ValueKey('seuil-ok'),
            onPressed: () => Navigator.pop(d, double.tryParse(saisie.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (v != null && v >= 0) setState(() => _seuil = v);
  }

  Future<void> _classer({required bool tout}) async {
    final messager = ScaffoldMessenger.of(context);
    if (tout) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('Tout reclasser ?'),
          content: const Text(
            'Chaque produit reçoit à nouveau la catégorie que donnent les laboratoires et le seuil de marge. '
            'Les catégories choisies à la main ne changent pas. L\'enveloppe du mois en dépend.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Annuler')),
            FilledButton(
              key: const ValueKey('confirmer-reclasser'),
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Tout reclasser'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _occupe = true);
    try {
      final r = await ref.read(gestesCategoriesProvider).classer(_seuil, tout: tout);
      messager.showSnackBar(
        SnackBar(
          content: Text(
            r.total == 0
                ? 'Aucun produit à classer.'
                : '${entier(r.total)} produits classés : ${entier(r.princeps)} princeps, '
                      '${entier(r.generique)} génériques, ${entier(r.generiquePlus)} génériques++.',
          ),
        ),
      );
    } catch (e) {
      messager.showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prime;
    final d = p.dernierClassement;
    final note = TextStyle(fontSize: 12, color: context.couleurs.encre3, height: 1.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TitreSection('Classer les produits'),
        _Carte(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Générique++ au-delà d\'une marge de')),
                  OutlinedButton(
                    key: const ValueKey('seuil-marge'),
                    onPressed: _occupe ? null : _changerSeuil,
                    child: Text(
                      pourcent(_seuil),
                      style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Générique++ : marge moyenne des lots au-dessus du seuil. Générique : laboratoire marqué '
                'générique. Princeps : le reste. Une catégorie choisie à la main n\'est jamais touchée.',
                style: note,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const ValueKey('classer'),
                    onPressed: _occupe || p.sansCategorieTotal == 0 ? null : () => _classer(tout: false),
                    child: Text(
                      p.sansCategorieTotal == 0
                          ? 'Tous les produits sont classés'
                          : 'Classer les ${entier(p.sansCategorieTotal)} produits sans catégorie',
                    ),
                  ),
                  OutlinedButton(
                    key: const ValueKey('tout-reclasser'),
                    onPressed: _occupe ? null : () => _classer(tout: true),
                    child: const Text('Tout reclasser'),
                  ),
                ],
              ),
              if (_occupe) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
              const SizedBox(height: 10),
              Text(
                d == null
                    ? 'Aucun classement lancé pour l\'instant.'
                    : 'Dernier classement : ${date(d.le.toLocal())}${d.par != null ? ' par ${d.par}' : ''} · '
                          '${entier(d.produits)} produits',
                key: const ValueKey('dernier-classement'),
                style: note,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Produits extends ConsumerWidget {
  const _Produits();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produits = ref.watch(produitsCategorieProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TitreSection('Sans catégorie, les plus vendus'),
        produits.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(produitsCategorieProvider)),
          data: (liste) => liste.isEmpty
              ? _Carte(
                  child: Text(
                    'Tous les produits vendus ce mois-ci ont une catégorie.',
                    style: TextStyle(color: context.couleurs.encre2),
                  ),
                )
              : _Carte(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, p) in liste.indexed) ...[
                        if (i > 0) Divider(height: 1, color: context.couleurs.bord),
                        _LigneProduit(produit: p),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LigneProduit extends ConsumerWidget {
  const _LigneProduit({required this.produit});
  final ProduitCategorie produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = produit;
    final choisie = p.manuelle && p.categorie != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelleProduit(p.nom ?? 'Produit ${p.id}'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${p.labo ?? 'sans laboratoire'} · ${dinars(p.ca.round())}',
                  style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            key: ValueKey('choisir-${p.id}'),
            tooltip: 'Choisir la catégorie',
            onSelected: (v) async {
              try {
                await ref.read(gestesCategoriesProvider).choisir(p.id, v == 'auto' ? null : v);
              } catch (e) {
                if (context.mounted) _erreur(context, e);
              }
            },
            itemBuilder: (_) => [
              for (final c in categoriesPrime) PopupMenuItem(value: c, child: Text(libelleCategorie(c))),
              if (choisie) const PopupMenuItem(value: 'auto', child: Text('Classement automatique')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: choisie ? context.schema.primaryContainer : context.schema.surface,
                border: Border.all(color: choisie ? Colors.transparent : context.couleurs.bord),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                choisie ? '${libelleCategorie(p.categorie)} · à la main' : 'Choisir ▾',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: choisie ? context.schema.onPrimaryContainer : context.couleurs.encre2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
