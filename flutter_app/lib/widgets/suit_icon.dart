import 'package:flutter/material.dart';

/// Kartensymbole (Pik, Herz, Karo, Kreuz) als Vektor.
///
/// Die Unicode-Zeichen ♠ ♥ ♦ ♣ werden je nach Plattform als farbige Emojis
/// gerendert und ignorieren dann die gewuenschte Farbe. Gezeichnete Pfade sehen
/// auf Android, iOS und Web identisch aus.
class SuitIcon extends StatelessWidget {
  const SuitIcon({
    super.key,
    required this.id,
    required this.color,
    this.size = 32,
  });

  /// `spade` | `heart` | `diamond` | `club`
  final String id;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _SuitPainter(id, color)),
  );
}

class _SuitPainter extends CustomPainter {
  const _SuitPainter(this.id, this.color);

  final String id;
  final Color color;

  /// Herz im Einheitsquadrat.
  static Path _heart() => Path()
    ..moveTo(0.5, 0.92)
    ..cubicTo(0.12, 0.64, 0.0, 0.38, 0.17, 0.20)
    ..cubicTo(0.31, 0.05, 0.49, 0.13, 0.5, 0.31)
    ..cubicTo(0.51, 0.13, 0.69, 0.05, 0.83, 0.20)
    ..cubicTo(1.0, 0.38, 0.88, 0.64, 0.5, 0.92)
    ..close();

  static Path _path(String id) {
    switch (id) {
      case 'heart':
        return _heart();
      case 'diamond':
        return Path()
          ..moveTo(0.5, 0.04)
          ..lineTo(0.86, 0.5)
          ..lineTo(0.5, 0.96)
          ..lineTo(0.14, 0.5)
          ..close();
      case 'spade':
        // Herz auf den Kopf gestellt + Stiel.
        final body = _heart().transform(
          (Matrix4.identity()
                ..translateByDouble(0, 0.82, 0, 1)
                ..scaleByDouble(1, -0.78, 1, 1))
              .storage,
        );
        final stem = Path()
          ..moveTo(0.46, 0.55)
          ..quadraticBezierTo(0.47, 0.82, 0.34, 0.94)
          ..lineTo(0.66, 0.94)
          ..quadraticBezierTo(0.53, 0.82, 0.54, 0.55)
          ..close();
        return Path.combine(PathOperation.union, body, stem);
      case 'club':
      default:
        final leaves = Path()
          ..addOval(
            Rect.fromCircle(center: const Offset(0.5, 0.29), radius: 0.2),
          )
          ..addOval(
            Rect.fromCircle(center: const Offset(0.27, 0.58), radius: 0.2),
          )
          ..addOval(
            Rect.fromCircle(center: const Offset(0.73, 0.58), radius: 0.2),
          );
        final stem = Path()
          ..moveTo(0.46, 0.5)
          ..quadraticBezierTo(0.47, 0.82, 0.33, 0.95)
          ..lineTo(0.67, 0.95)
          ..quadraticBezierTo(0.53, 0.82, 0.54, 0.5)
          ..close();
        return Path.combine(PathOperation.union, leaves, stem);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _path(id).transform(
      (Matrix4.identity()..scaleByDouble(size.width, size.height, 1, 1))
          .storage,
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SuitPainter old) => old.id != id || old.color != color;
}
