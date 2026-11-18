import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/themes.dart';
import '../../../domain/paie.dart';

/// Radar des critères d'un employé : un axe par critère, la valeur est son
/// indice face à la moyenne de l'équipe (100 = moyenne, cercle pointillé).
/// Plafonné à 200 pour qu'un seul critère n'écrase pas le dessin ; le
/// tableau sous le radar donne le chiffre exact.
class RadarCriteres extends StatelessWidget {
  const RadarCriteres({super.key, required this.criteres, required this.nom});

  final List<Critere> criteres;
  final String nom;

  @override
  Widget build(BuildContext context) {
    final couleur = context.schema.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Critères de $nom comparés à la moyenne de l\'équipe',
          child: AspectRatio(
            aspectRatio: 1.3,
            child: CustomPaint(
              key: const ValueKey('radar'),
              painter: _Radar(
                criteres: criteres,
                serie: couleur,
                grille: context.couleurs.bord,
                moyenne: context.couleurs.encre3,
                texte: context.couleurs.encre2,
                surface: context.schema.surface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _Legende(
              marque: Container(
                width: 14,
                height: 10,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.18),
                  border: Border.all(color: couleur, width: 2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              texte: nom,
            ),
            _Legende(
              marque: SizedBox(
                width: 16,
                child: CustomPaint(painter: _Tirets(context.couleurs.encre3), size: const Size(16, 2)),
              ),
              texte: 'Moyenne de l\'équipe = 100',
            ),
          ],
        ),
      ],
    );
  }
}

class _Legende extends StatelessWidget {
  const _Legende({required this.marque, required this.texte});
  final Widget marque;
  final String texte;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      marque,
      const SizedBox(width: 6),
      Text(texte, style: TextStyle(fontSize: 12, color: context.couleurs.encre2)),
    ],
  );
}

class _Tirets extends CustomPainter {
  _Tirets(this.couleur);
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = couleur
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(math.min(x + 4, size.width), size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(_Tirets old) => old.couleur != couleur;
}

class _Radar extends CustomPainter {
  _Radar({
    required this.criteres,
    required this.serie,
    required this.grille,
    required this.moyenne,
    required this.texte,
    required this.surface,
  });

  final List<Critere> criteres;
  final Color serie, grille, moyenne, texte, surface;
  static const _max = 200.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = criteres.length;
    if (n < 3) return;
    final centre = Offset(size.width / 2, size.height / 2 + 4);
    final rayon = math.min(size.width / 2 - 70, size.height / 2 - 22);
    Offset point(int i, double v) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final r = rayon * (v.clamp(0, _max) / _max);
      return centre + Offset(r * math.cos(a), r * math.sin(a));
    }

    Path polygone(double Function(int i) valeur) {
      final p = Path()..moveTo(point(0, valeur(0)).dx, point(0, valeur(0)).dy);
      for (var i = 1; i < n; i++) {
        p.lineTo(point(i, valeur(i)).dx, point(i, valeur(i)).dy);
      }
      return p..close();
    }

    final trait = Paint()
      ..style = PaintingStyle.stroke
      ..color = grille
      ..strokeWidth = 1;
    for (final v in [50.0, 150.0, 200.0]) {
      canvas.drawPath(polygone((_) => v), trait);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(centre, point(i, _max), trait);
    }
    // Moyenne de l'équipe : le polygone 100, en pointillés.
    final pm = Paint()
      ..color = moyenne
      ..strokeWidth = 1.5;
    for (var i = 0; i < n; i++) {
      final a = point(i, 100), b = point((i + 1) % n, 100);
      final l = (b - a).distance;
      for (var t = 0.0; t < l; t += 8) {
        canvas.drawLine(a + (b - a) * (t / l), a + (b - a) * (math.min(t + 4, l) / l), pm);
      }
    }
    // L'employé.
    double valeur(int i) => (criteres[i].indice ?? 0).toDouble();
    final forme = polygone(valeur);
    canvas.drawPath(forme, Paint()..color = serie.withValues(alpha: 0.16));
    canvas.drawPath(
      forme,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = serie
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < n; i++) {
      final p = point(i, valeur(i));
      canvas.drawCircle(p, 6, Paint()..color = surface);
      canvas.drawCircle(p, 4, Paint()..color = serie);
    }
    // Libellés des axes.
    for (var i = 0; i < n; i++) {
      final p = point(i, _max + 22);
      final tp = TextPainter(
        text: TextSpan(
          text: criteres[i].libelle,
          style: TextStyle(fontSize: 11, color: texte),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 96);
      final dx = (p.dx - centre.dx).abs() < 8 ? -tp.width / 2 : (p.dx > centre.dx ? 0.0 : -tp.width);
      tp.paint(canvas, Offset(p.dx + dx, p.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_Radar old) => old.criteres != criteres || old.serie != serie;
}
