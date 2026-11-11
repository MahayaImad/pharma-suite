import 'package:flutter/material.dart';

/// Le logo PharmaSuite : une tête et deux bras en arc qui se répondent.
/// Dessiné en vectoriel, net à toutes les tailles.
class LogoPharmaSuite extends StatelessWidget {
  const LogoPharmaSuite({super.key, this.taille = 40, this.blanc = false});

  final double taille;

  /// Version blanche, pour les surfaces bleues.
  final bool blanc;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: taille,
    child: CustomPaint(painter: _PeintreLogo(blanc)),
  );
}

class _PeintreLogo extends CustomPainter {
  const _PeintreLogo(this.blanc);
  final bool blanc;

  @override
  void paint(Canvas canvas, Size taille) {
    final e = taille.width / 100; // le dessin est pensé dans un carré de 100
    Offset p(double x, double y) => Offset(x * e, y * e);

    Paint trait(List<Color> couleurs, Offset de, Offset a) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17 * e
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: couleurs).createShader(Rect.fromPoints(de, a));

    final gauche = Path()
      ..moveTo(26 * e, 33 * e)
      ..cubicTo(46 * e, 44 * e, 52 * e, 56 * e, 34 * e, 82 * e);
    final droite = Path()
      ..moveTo(75 * e, 33 * e)
      ..cubicTo(55 * e, 44 * e, 49 * e, 56 * e, 67 * e, 82 * e);

    if (blanc) {
      final plein = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17 * e
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(droite, plein..color = Colors.white.withValues(alpha: .72));
      canvas.drawPath(gauche, plein..color = Colors.white);
      canvas.drawCircle(p(51, 17), 10 * e, Paint()..color = Colors.white);
      return;
    }
    canvas.drawPath(droite, trait(const [Color(0xFF5FA8FF), Color(0xFF2E74D8)], p(75, 30), p(55, 85)));
    canvas.drawPath(gauche, trait(const [Color(0xFF123F86), Color(0xFF1F5FBF)], p(30, 85), p(50, 30)));
    canvas.drawCircle(
      p(51, 17),
      10 * e,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF2E74D8), Color(0xFF1F5FBF)])
            .createShader(Rect.fromCircle(center: p(51, 17), radius: 10 * e)),
    );
  }

  @override
  bool shouldRepaint(_PeintreLogo ancien) => ancien.blanc != blanc;
}
