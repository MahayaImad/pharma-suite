import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/pastille_etat.dart';
import '../../../data/api/client_api.dart';
import '../../../data/api/stock_api.dart';
import '../../reglages/application/reglages_providers.dart' show peutModifierProvider;
import '../../../domain/format.dart';
import '../../../domain/stock.dart';
import '../application/stock_providers.dart';
import 'ecran_stock.dart' show bientotCommandes, nomLisible;
import 'elements_stock.dart';

/// Fiche d'un produit : ce qu'il faut faire, la projection du stock, les
/// lots, le réapprovisionnement et les prix.
///
/// [enPanneau] : affichée à côté de la liste (grand écran), avec un bouton
/// « fermer » au lieu du retour.
class FicheProduit extends ConsumerWidget {
  const FicheProduit({super.key, required this.id, this.enPanneau = false});

  final int id;
  final bool enPanneau;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fiche = ref.watch(ficheProduitProvider(id));
    void fermer() => context.go('/stock');

    return Scaffold(
      backgroundColor: enPanneau ? context.schema.surface : null,
      appBar: AppBar(
        backgroundColor: enPanneau ? context.schema.surface : null,
        automaticallyImplyLeading: false,
        toolbarHeight: 52,
        leading: enPanneau
            ? null
            : IconButton(tooltip: 'Retour', icon: const Icon(Icons.arrow_back_rounded), onPressed: fermer),
        title: Text(enPanneau ? 'Fiche produit' : '', style: const TextStyle(fontSize: 15)),
        actions: [
          if (enPanneau) IconButton(tooltip: 'Fermer', icon: const Icon(Icons.close_rounded), onPressed: fermer),
          const SizedBox(width: 4),
        ],
      ),
      body: fiche.when(
        data: (p) => _Contenu(produit: p),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: MessageErreur(erreur: e, reessayer: () => ref.invalidate(ficheProduitProvider(id))),
        ),
      ),
    );
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p0 = produit;
    final i = ref.watch(indicateursProduitProvider(p0.id)).value;
    // La fiche donne le produit ; les indicateurs complètent la jauge.
    final p = i == null
        ? p0
        : p0.copyWith(
            cmm: i.cmm,
            stockSecurite: i.stockSecurite,
            stockMaximum: i.stockMaximum,
            couverture: i.couverture,
            qteARisque: i.qteARisque,
            valeurARisque: i.valeurARisque,
            qteSurstock: math.max(0, p0.stock.round() - i.stockMaximum),
          );
    final enTete = [
      if (p.famille != null && p.famille!.isNotEmpty) libelle(p.famille!),
      if (p.labo != null && p.labo!.isNotEmpty) libelleProduit(p.labo!),
    ].join(' · ');
    final forme = [
      if (p.dci != null && p.dci!.isNotEmpty) libelleProduit(p.dci!),
      if (p.formeAbr != null && p.formeAbr!.isNotEmpty) p.formeAbr!.toLowerCase(),
      if (p.conditionnement != null && p.conditionnement!.isNotEmpty) p.conditionnement!,
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconeFamille(p.idFamille, taille: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (enTete.isNotEmpty) Text(enTete, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                  const SizedBox(height: 2),
                  Text(
                    nomLisible(p),
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  if (forme.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(forme, style: TextStyle(fontSize: 13, color: context.couleurs.encre2)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            PastilleSignal(p.signal),
            EtiquetteClasse(p),
            if (p.psychotrope == 1) const Etiquette('Psychotrope', icone: Icons.gpp_maybe_outlined),
            if (p.remboursable == 1) const Etiquette('Remboursable', icone: Icons.verified_outlined),
            if (p.categorie != null && p.categorie!.isNotEmpty) Etiquette(libelle(p.categorie!)),
            if (p.consommable) const Etiquette('Consommable', icone: Icons.volunteer_activism_outlined),
          ],
        ),
        const SizedBox(height: 16),
        if (p.consommablePropose) ...[_PropositionConsommable(produit: p), const SizedBox(height: 16)],
        _Bande(produit: p, indicateurs: i),
        const SizedBox(height: 16),
        _JaugeFiche(produit: p, pret: i != null),
        const SizedBox(height: 16),
        if (i != null) _Conseil(produit: p, indicateurs: i),
        const SizedBox(height: 22),
        const _Titre('Projection du stock'),
        if (i == null)
          const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)))
        else
          _Projection(produit: p, indicateurs: i),
        const SizedBox(height: 22),
        _Lots(id: p.id),
        const SizedBox(height: 22),
        const _Titre('Réapprovisionnement'),
        _Reappro(produit: p),
        const SizedBox(height: 22),
        _CaseConsommable(produit: p),
        const SizedBox(height: 22),
        const _Titre('Prix'),
        _Prix(produit: p),
        if (p.codeBarre != null && p.codeBarre!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 18, color: context.couleurs.encre3),
              const SizedBox(width: 6),
              SelectableText(p.codeBarre!, style: TextStyle(color: context.couleurs.encre2, fontSize: 13)),
            ],
          ),
        ],
      ],
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte, {this.fin});
  final String texte;
  final Widget? fin;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            texte,
            style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        ?fin,
      ],
    ),
  );
}

/// En stock, vendu par mois, couverture, prix : une bande de quatre cases.
class _Bande extends StatelessWidget {
  const _Bande({required this.produit, required this.indicateurs});
  final Produit produit;
  final IndicateursProduit? indicateurs;

  @override
  Widget build(BuildContext context) {
    final i = indicateurs;
    final c = i?.couverture;
    final cases = [
      ('En stock', entier(produit.stock), null),
      ('Vendu / mois', i == null ? '…' : decimal(i.cmm), null),
      (
        'Couverture',
        i == null ? '…' : (c == null ? '—' : duree(c)),
        i != null && i.couvertureTropLongue ? couleursSignal(context, Signal.risque).texte : null,
      ),
      ('Prix', produit.prixVente > 0 ? entier(produit.prixVente) : '—', null),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.schema.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.couleurs.bord),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (n, (titre, valeur, couleur)) in cases.indexed) ...[
              if (n > 0) VerticalDivider(width: 1, color: context.couleurs.bord),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: context.couleurs.encre3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        valeur,
                        key: ValueKey('bande-$titre'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700, color: couleur),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Règle du stock : zone sous le stock de sécurité, zone normale jusqu'au
/// maximum, zone de surstock ; un curseur marque le stock actuel.
class _JaugeFiche extends StatelessWidget {
  const _JaugeFiche({required this.produit, required this.pret});
  final Produit produit;
  final bool pret;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    if (!pret) return const SizedBox(height: 40);
    final ss = p.stockSecurite.toDouble();
    final max = math.max(p.stockMaximum.toDouble(), ss + 1);
    final fin = math.max(max * 1.25, p.stock * 1.08);
    final e = context.etats;
    return Column(
      key: const ValueKey('jauge-fiche'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 22,
          child: LayoutBuilder(
            builder: (context, c) {
              double x(double v) => c.maxWidth * (v / fin).clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 6,
                    height: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: x(ss),
                            child: ColoredBox(color: e.critiqueDoux),
                          ),
                          SizedBox(
                            width: x(max) - x(ss),
                            child: ColoredBox(color: e.bonDoux),
                          ),
                          Expanded(child: ColoredBox(color: e.alerteDoux)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (x(p.stock) - 2).clamp(0, c.maxWidth - 4),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: context.schema.onSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.schema.surface, width: 1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, c) {
            final style = TextStyle(fontSize: 11, color: context.couleurs.encre3);
            double x(double v) => c.maxWidth * (v / fin).clamp(0.0, 1.0);
            return SizedBox(
              height: 14,
              child: Stack(
                children: [
                  Positioned(left: 0, child: Text('0', style: style)),
                  if (ss > 0)
                    Positioned(
                      left: (x(ss) - 30).clamp(14, c.maxWidth - 120),
                      child: Text('sécurité ${entier(ss)}', style: style),
                    ),
                  Positioned(
                    left: (x(max) - 24).clamp(90, c.maxWidth - 60),
                    child: Text('max ${entier(p.stockMaximum)}', style: style),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Que faire, en une phrase, avec l'action qui va avec.
class _Conseil extends StatelessWidget {
  const _Conseil({required this.produit, required this.indicateurs});
  final Produit produit;
  final IndicateursProduit indicateurs;

  @override
  Widget build(BuildContext context) {
    final c = conseil(produit, indicateurs);
    final e = context.etats;
    final violet = couleursSignal(context, Signal.risque);
    final (couleur, fond, icone) = switch (c.niveau) {
      NiveauConseil.urgent => (e.critique, e.critiqueDoux, Icons.remove_circle_outline),
      NiveauConseil.attention => (e.alerte, e.alerteDoux, Icons.trending_down),
      NiveauConseil.risque => (violet.texte, violet.fond, Icons.hourglass_bottom_rounded),
      NiveauConseil.info => (context.couleurs.encre2, context.couleurs.neutreDoux, Icons.info_outline),
      NiveauConseil.bon => (e.bon, e.bonDoux, Icons.check_circle_outline),
    };
    final actions = switch (c.niveau) {
      NiveauConseil.risque => ['Retour fournisseur', 'Échange', 'Mise en avant'],
      NiveauConseil.urgent || NiveauConseil.attention => ['Commander'],
      _ => <String>[],
    };
    final risque = c.niveau == NiveauConseil.risque;
    return Container(
      key: const ValueKey('conseil'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (risque)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${entier(indicateurs.qteARisque)} unité${indicateurs.qteARisque > 1 ? 's' : ''} à risque · '
                      '${dinars(indicateurs.valeurARisque)}',
                      style: TextStyle(color: couleur, fontWeight: FontWeight.w700),
                    ),
                  ),
                Text(c.texte, style: TextStyle(color: context.schema.onSurface, fontSize: 13, height: 1.4)),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final a in actions)
                        ActionChip(
                          label: Text(a),
                          labelStyle: TextStyle(color: couleur, fontWeight: FontWeight.w700, fontSize: 12),
                          backgroundColor: context.schema.surface,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => bientotCommandes(context),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _moisCourts = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// Courbe du stock dans le temps, sans nouvelle commande, en FEFO.
class _Projection extends StatelessWidget {
  const _Projection({required this.produit, required this.indicateurs});
  final Produit produit;
  final IndicateursProduit indicateurs;

  @override
  Widget build(BuildContext context) {
    final i = indicateurs;
    // Lots bloqués (dans le calcul : ni écoulable ni date manquante) exclus.
    final lots = [
      for (final l in i.lots)
        if (l.ecoulable != null || l.dvr == null) (stock: l.stock, dvr: l.dvr),
    ];
    final points = projectionStock(lots, i.cmj);
    final legende = i.cmj > 0
        ? 'Au rythme de ${decimal(i.cmj, chiffres: 2)} par jour, sans nouvelle commande, '
              'en vendant d\'abord le lot qui périme le plus tôt.'
        : 'Aucune vente sur 12 mois : le stock ne baisse qu\'à la péremption des lots.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(legende, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
        const SizedBox(height: 8),
        SizedBox(
          key: const ValueKey('projection'),
          height: 170,
          child: CustomPaint(
            painter: _PeintreProjection(
              points: points,
              stockSecurite: i.stockSecurite.toDouble(),
              aujourdhui: DateTime.now(),
              couleur: context.schema.primary,
              couleurPerte: couleursSignal(context, Signal.risque).texte,
              couleurSecurite: context.etats.alerteIcone,
              couleurAxe: context.couleurs.bord,
              couleurTexte: context.couleurs.encre3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PeintreProjection extends CustomPainter {
  _PeintreProjection({
    required this.points,
    required this.stockSecurite,
    required this.aujourdhui,
    required this.couleur,
    required this.couleurPerte,
    required this.couleurSecurite,
    required this.couleurAxe,
    required this.couleurTexte,
  });

  final List<PointStock> points;
  final double stockSecurite;
  final DateTime aujourdhui;
  final Color couleur, couleurPerte, couleurSecurite, couleurAxe, couleurTexte;

  void _texte(Canvas c, String t, Offset o, {Color? couleur, bool gras = false, bool droite = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontSize: 10.5,
          color: couleur ?? couleurTexte,
          fontWeight: gras ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, droite ? o.translate(-tp.width, 0) : o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const bas = 20.0, haut = 16.0, gauche = 4.0;
    final dernier = points.last.jour;
    final horizon = (dernier * 1.15).clamp(60.0, 400.0);
    final maxStock = math.max(points.first.stock, stockSecurite) * 1.15 + 1;
    final largeur = size.width - gauche - 4;
    double x(double j) => gauche + largeur * (j / horizon).clamp(0.0, 1.0);
    double y(double s) => haut + (size.height - bas - haut) * (1 - s / maxStock);

    // Axe et mois
    final axe = Paint()..color = couleurAxe;
    canvas.drawLine(Offset(gauche, y(0)), Offset(size.width, y(0)), axe);
    for (var m = 1; m * 30 < horizon; m++) {
      final date = DateTime(aujourdhui.year, aujourdhui.month + m, 1);
      final j = date.difference(DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day)).inDays.toDouble();
      if (j >= horizon) break;
      if (largeur / horizon * 30 < 34 && m.isOdd) continue; // pas de chevauchement
      canvas.drawLine(Offset(x(j), y(0)), Offset(x(j), y(0) + 4), axe);
      _texte(canvas, _moisCourts[date.month - 1], Offset(x(j) - 8, y(0) + 5));
    }

    // Stock de sécurité
    if (stockSecurite > 0) {
      final p = Paint()
        ..color = couleurSecurite
        ..strokeWidth = 1.2;
      for (var d = gauche; d < size.width; d += 8) {
        canvas.drawLine(Offset(d, y(stockSecurite)), Offset(math.min(d + 4, size.width), y(stockSecurite)), p);
      }
      _texte(
        canvas,
        'stock de sécurité',
        Offset(size.width - 2, y(stockSecurite) - 14),
        couleur: couleurSecurite,
        droite: true,
      );
    }

    // Courbe, prolongée à plat jusqu'à l'horizon
    final chemin = Path()..moveTo(x(points.first.jour), y(points.first.stock));
    for (final p in points.skip(1)) {
      chemin.lineTo(x(p.jour), y(p.stock));
    }
    chemin.lineTo(x(horizon), y(points.last.stock));
    final aire = Path.from(chemin)
      ..lineTo(x(horizon), y(0))
      ..lineTo(x(0), y(0))
      ..close();
    canvas.drawPath(aire, Paint()..color = couleur.withValues(alpha: .08));
    canvas.drawPath(
      chemin,
      Paint()
        ..color = couleur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );

    // Pertes à la péremption : deux points au même jour, le second plus bas.
    for (var n = 1; n < points.length; n++) {
      final a = points[n - 1], b = points[n];
      if (a.jour == b.jour && b.stock < a.stock) {
        canvas.drawCircle(Offset(x(a.jour), y(a.stock)), 4.5, Paint()..color = couleurPerte);
        _texte(
          canvas,
          '−${entier(a.stock - b.stock)} périmées',
          Offset(x(a.jour) + 7, y(a.stock) - 6),
          couleur: couleurPerte,
          gras: true,
        );
      }
    }
    canvas.drawCircle(Offset(x(0), y(points.first.stock)), 4.5, Paint()..color = couleur);
    _texte(
      canvas,
      '${entier(points.first.stock)} aujourd\'hui',
      Offset(x(0) + 7, y(points.first.stock) - 15),
      couleur: couleur,
      gras: true,
    );
  }

  @override
  bool shouldRepaint(_PeintreProjection ancien) =>
      ancien.points != points || ancien.stockSecurite != stockSecurite || ancien.couleur != couleur;
}

/// Une ligne « libellé · valeur », avec une explication discrète.
class _Ligne extends StatelessWidget {
  const _Ligne(this.titre, this.valeur, {this.detail, this.cle});
  final String titre, valeur;
  final String? detail;
  final String? cle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: TextStyle(color: context.couleurs.encre2)),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(detail!, style: TextStyle(fontSize: 12, color: context.couleurs.encre3)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valeur,
          key: cle == null ? null : ValueKey<String>(cle!),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// Carte blanche à lignes séparées.
class _Carte extends StatelessWidget {
  const _Carte(this.lignes);
  final List<Widget> lignes;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.schema.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.couleurs.bord),
    ),
    child: Column(
      children: [
        for (final (i, l) in lignes.indexed) ...[if (i > 0) const Divider(indent: 14, endIndent: 14), l],
      ],
    ),
  );
}

/// CMJ, délai de livraison, stock de sécurité, stock maximum.
class _Reappro extends ConsumerWidget {
  const _Reappro({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicateurs = ref.watch(indicateursProduitProvider(produit.id));
    return indicateurs.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (e, _) =>
          MessageErreur(erreur: e, reessayer: () => ref.invalidate(indicateursProduitProvider(produit.id))),
      data: (i) {
        final f = i.fournisseur;
        final livraison = i.dateLivraison;
        final jours = '${i.delaiLivraison} jour${i.delaiLivraison > 1 ? 's' : ''}';
        final classe = produit.classeAbc;
        final service = switch (classe) {
          'A' => '95 %',
          'C' => '85 %',
          _ => '90 %',
        };
        final seuil = produit.seuil;
        return _Carte([
          _Ligne(
            'Consommation journalière (CMJ)',
            '${decimal(i.cmj, chiffres: 2)} / jour',
            detail: i.moisHistorique < 12
                ? 'CMM ÷ 30, sur ${i.moisHistorique} mois de ventes'
                : 'CMM ÷ 30, ventes des 12 derniers mois',
            cle: 'cmj',
          ),
          _Ligne(
            'Délai de livraison',
            jours,
            detail: [
              f?.nom ?? 'Fournisseur inconnu',
              if (livraison != null) 'commande du jour livrée ${jourEtDate(livraison)}',
              if (f != null && !f.delaiSaisi) 'délai par défaut',
            ].join(' · '),
            cle: 'delai',
          ),
          _Ligne(
            'Stock de sécurité',
            entier(i.stockSecurite),
            detail:
                'Z × σ × √L, ${classe == null ? 'non classé' : 'classe $classe'}, $service de service'
                ' · simple (CMJ × ${decimal(i.delaiSecurite)} j) : ${entier(i.stockSecuriteSimple)}',
            cle: 'ss',
          ),
          _Ligne(
            'Stock maximum',
            entier(i.stockMaximum),
            detail: 'SS + CMM × ${decimal(i.periodeCommande)} jours entre deux commandes',
          ),
          _Ligne(
            "Seuil d'alerte EASYPHARM",
            seuil == null || seuil == 0 ? '—' : entier(seuil),
            detail: seuil == null || seuil == 0 ? 'non défini dans EASYPHARM' : null,
          ),
          _Ligne('Vendu sur 12 mois', entier(i.ventes12Mois), detail: 'quantité nette, retours déduits'),
        ]);
      },
    );
  }
}

class _Prix extends StatelessWidget {
  const _Prix({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context) {
    final p = produit;
    final taux = tauxMarge(p.prixVente, p.prixAchat);
    String ou(double v, String Function(double) f) => v > 0 ? f(v) : '—';
    final lignes = [
      ('Prix de vente', ou(p.prixVente, dinars)),
      ("Prix d'achat moyen", ou(p.prixAchat, dinars)),
      ('Marge', taux == null ? '—' : '${dinars(p.prixVente - p.prixAchat)}  ·  ${pourcent(taux)}'),
      ('Valeur du stock (achat)', dinars(p.valeurAchat)),
      ('Valeur du stock (vente)', dinars(p.valeurVente)),
    ];
    return _Carte([for (final (i, (titre, valeur)) in lignes.indexed) _Ligne(titre, valeur, cle: 'prix-$i')]);
  }
}

/// Lots, du plus proche de la péremption au plus lointain.
class _Lots extends ConsumerStatefulWidget {
  const _Lots({required this.id});
  final int id;

  @override
  ConsumerState<_Lots> createState() => _LotsState();
}

class _LotsState extends ConsumerState<_Lots> {
  bool _epuises = false;

  @override
  Widget build(BuildContext context) {
    final cle = (id: widget.id, epuises: _epuises);
    final lots = ref.watch(lotsProduitProvider(cle));
    final indicateurs = ref.watch(indicateursProduitProvider(widget.id)).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Titre(
          'Lots',
          fin: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lots épuisés', style: TextStyle(fontSize: 13, color: context.couleurs.encre2)),
              Switch(
                key: const ValueKey('lots-epuises'),
                value: _epuises,
                onChanged: (v) => setState(() => _epuises = v),
              ),
            ],
          ),
        ),
        lots.when(
          data: (liste) => liste.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _epuises ? 'Aucun lot enregistré.' : 'Aucun lot en stock.',
                    style: TextStyle(color: context.couleurs.encre2),
                  ),
                )
              : Column(
                  children: [
                    for (final l in liste)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LigneLot(l, risque: indicateurs?.risque(l.id)),
                      ),
                  ],
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
          error: (e, _) => MessageErreur(erreur: e, reessayer: () => ref.invalidate(lotsProduitProvider(cle))),
        ),
      ],
    );
  }
}

class _LigneLot extends StatelessWidget {
  const _LigneLot(this.lot, {this.risque});
  final Lot lot;
  final RisqueLot? risque;

  @override
  Widget build(BuildContext context) {
    final etat = etatPeremption(lot.peremptionDate, DateTime.now());
    final (niveau, texte) = switch (etat) {
      EtatPeremption.perime => (NiveauEtat.critique, 'Périmé'),
      EtatPeremption.proche => (NiveauEtat.alerte, 'Moins de 3 mois'),
      EtatPeremption.bonne => (NiveauEtat.bon, 'Bonne'),
      EtatPeremption.inconnue => (NiveauEtat.alerte, 'Sans date'),
    };
    final details = [
      if (lot.fournisseur != null && lot.fournisseur!.isNotEmpty) lot.fournisseur!,
      if (lot.dateEntree != null) 'entré le ${date(lot.dateEntree!)}',
      if (lot.numBl != null && lot.numBl!.isNotEmpty) 'BL ${lot.numBl}',
    ].join(' · ');
    final epuise = lot.stock <= 0;

    return Opacity(
      opacity: epuise ? .6 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: context.schema.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.couleurs.bord),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.peremption?.isNotEmpty == true ? lot.peremption! : '—',
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  Text('péremption', style: TextStyle(fontSize: 11, color: context.couleurs.encre3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Lot ${lot.lot?.isNotEmpty == true ? lot.lot : '—'}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (lot.bloque) ...[const SizedBox(width: 6), const Etiquette('Bloqué', icone: Icons.block)],
                    ],
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.couleurs.encre2),
                    ),
                  const SizedBox(height: 6),
                  if (!epuise) PastilleEtat(niveau: niveau, libelle: texte),
                  if (!epuise && risque?.ecoulable != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      (risque!.aRisque ?? 0) > 0
                          ? '${entier(risque!.aRisque!)} à risque · ${entier(risque!.ecoulable!)} écoulables '
                                'en ${entier(risque!.dvr ?? 0)} j'
                          : 'Écoulé avant péremption (${entier(risque!.dvr ?? 0)} j restants)',
                      key: ValueKey('risque-lot-${lot.id}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (risque!.aRisque ?? 0) > 0 ? context.etats.critique : context.couleurs.encre2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entier(lot.stock),
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(epuise ? 'épuisé' : 'unités', style: TextStyle(fontSize: 11, color: context.couleurs.encre3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enregistre la décision du titulaire et rafraîchit la fiche et les listes.
Future<void> _deciderConsommable(BuildContext context, WidgetRef ref, Produit p, bool oui) async {
  final messager = ScaffoldMessenger.of(context);
  try {
    await ref.read(stockApiProvider).deciderConsommable(p.id, oui);
    ref.invalidate(ficheProduitProvider(p.id));
    ref.invalidate(aTraiterProvider);
    ref.invalidate(listeProduitsProvider);
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(oui ? 'Marqué consommable : écarté du surstock et des pertes.' : 'Non consommable.')),
      );
  } catch (e) {
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
  }
}

/// Produit jamais vendu mais ajusté à la baisse : la détection le propose
/// comme consommable, le titulaire tranche.
class _PropositionConsommable extends ConsumerWidget {
  const _PropositionConsommable({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return Container(
      key: const ValueKey('proposition-consommable'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.etats.alerteDoux, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.volunteer_activism_outlined, color: context.etats.alerte),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consommable donné ?',
                  style: TextStyle(color: context.etats.alerte, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jamais vendu, mais sorti du stock par ajustements d\'inventaire. Un consommable '
                  'n\'est compté ni comme une perte ni comme un surstock.',
                  style: TextStyle(color: context.schema.onSurface, fontSize: 13, height: 1.4),
                ),
                if (modifiable) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        key: const ValueKey('consommable-oui'),
                        onPressed: () => _deciderConsommable(context, ref, produit, true),
                        child: const Text('Oui, consommable'),
                      ),
                      TextButton(
                        key: const ValueKey('consommable-non'),
                        onPressed: () => _deciderConsommable(context, ref, produit, false),
                        child: const Text('Non'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Case « consommable » : cochée par le titulaire seul.
class _CaseConsommable extends ConsumerWidget {
  const _CaseConsommable({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiable = ref.watch(peutModifierProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.schema.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.couleurs.bord),
      ),
      child: SwitchListTile(
        key: const ValueKey('case-consommable'),
        value: produit.consommable,
        onChanged: modifiable ? (v) => _deciderConsommable(context, ref, produit, v) : null,
        title: const Text('Consommable', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          modifiable
              ? 'Donné, jamais vendu (aiguilles, sachets, lecteurs…) : ni perte ni surstock.'
              : 'Donné, jamais vendu. Seul le titulaire modifie cette case.',
          style: TextStyle(fontSize: 12.5, color: context.couleurs.encre3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
