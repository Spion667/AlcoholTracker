import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AuroraStyle {
  /// Lichtwellen am oberen Rand (Party-Header, "Fluid Club Aurora").
  header,

  /// Weiche Lichtatmosphaere hinter dem Logo (Start-Animation).
  splash,
}

class _Blob {
  const _Blob({
    required this.fx,
    required this.dx,
    required this.fy,
    required this.dy,
    required this.w,
    required this.h,
    required this.inner,
    required this.outer,
    required this.opacity,
    required this.period,
    required this.drift,
    this.reverse = false,
  });

  /// Mittelpunkt = Breite * fx + dx, Hoehe * fy + dy.
  final double fx, dx, fy, dy;
  final double w, h;
  final Color inner, outer;
  final double opacity;

  /// Dauer eines Hin-und-Her-Zyklus in Sekunden.
  final double period;
  final int drift;
  final bool reverse;
}

const _lime = AppColors.lime;
const _cyan = AppColors.cyan;
const _pink = AppColors.pink;
const _purple = AppColors.purple;
const _amber = AppColors.amber;

final _headerBlobs = [
  _Blob(
    fx: 0,
    dx: 128,
    fy: 0,
    dy: 40,
    w: 384,
    h: 240,
    inner: _cyan.o(0.8),
    outer: _lime.o(0.5),
    opacity: 0.8,
    period: 8.5,
    drift: 1,
  ),
  _Blob(
    fx: 1,
    dx: -144,
    fy: 0,
    dy: 48,
    w: 416,
    h: 256,
    inner: _pink.o(0.8),
    outer: _purple.o(0.55),
    opacity: 0.75,
    period: 10.5,
    drift: 2,
  ),
  _Blob(
    fx: 0.25,
    dx: 168,
    fy: 0,
    dy: 16,
    w: 336,
    h: 224,
    inner: _lime.o(0.75),
    outer: _amber.o(0.45),
    opacity: 0.7,
    period: 9,
    drift: 3,
  ),
  _Blob(
    fx: 0.5,
    dx: 0,
    fy: 0,
    dy: 16,
    w: 320,
    h: 192,
    inner: _purple.o(0.8),
    outer: _cyan.o(0.45),
    opacity: 0.8,
    period: 11,
    drift: 1,
    reverse: true,
  ),
];

final _splashBlobs = [
  _Blob(
    fx: 0.5,
    dx: -90,
    fy: 0.42,
    dy: -40,
    w: 380,
    h: 320,
    inner: _cyan.o(0.7),
    outer: _purple.o(0.3),
    opacity: 0.5,
    period: 6.5,
    drift: 1,
  ),
  _Blob(
    fx: 0.5,
    dx: 100,
    fy: 0.42,
    dy: 30,
    w: 400,
    h: 340,
    inner: _pink.o(0.7),
    outer: _purple.o(0.45),
    opacity: 0.5,
    period: 7.5,
    drift: 2,
  ),
  _Blob(
    fx: 0.5,
    dx: 0,
    fy: 0.42,
    dy: -120,
    w: 320,
    h: 260,
    inner: _lime.o(0.4),
    outer: _amber.o(0.25),
    opacity: 0.3,
    period: 7,
    drift: 3,
  ),
  _Blob(
    fx: 0.5,
    dx: 10,
    fy: 0.42,
    dy: 110,
    w: 360,
    h: 280,
    inner: _purple.o(0.65),
    outer: _cyan.o(0.35),
    opacity: 0.45,
    period: 8,
    drift: 1,
    reverse: true,
  ),
];

/// Animierte, weich fliessende Neon-Lichtatmosphaere (Port von `PartyHeaderFx`).
///
/// Die vier Farbwolken driften wie die CSS-Keyframes `auroraDrift1..3`; der
/// Verlauf der Radial-Gradienten ersetzt den CSS-`blur`.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({
    super.key,
    this.style = AuroraStyle.header,
    this.intensity = 1,
  });

  final AuroraStyle style;

  /// 0..1, blendet die Lichtwolken ein/aus.
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  // Lange Laufzeit, damit der Wrap-Around (alle 1000 s) nicht auffaellt.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AuroraPainter(
            repaint: _c,
            seconds: () => _c.value * 1000,
            style: widget.style,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required Listenable repaint,
    required this.seconds,
    required this.style,
    required this.intensity,
  }) : super(repaint: repaint);

  final double Function() seconds;
  final AuroraStyle style;
  final double intensity;

  // Sanfte Ease-in-out-Phase 0..1..0.
  double _phase(double t, double period, {bool reverse = false}) {
    final p = 0.5 - 0.5 * math.cos(2 * math.pi * t / period);
    return reverse ? 1 - p : p;
  }

  // (translateX%, translateY%, scale, rotateDeg, opacity) fuer Phase 0 und 1.
  static const _drift = {
    1: [-0.10, -0.08, 1.0, 0.0, 0.6, 0.18, 0.12, 1.22, 10.0, 0.85],
    2: [0.20, 0.08, 1.15, 0.0, 0.55, -0.15, -0.12, 0.92, -12.0, 0.82],
    3: [-0.08, 0.15, 0.95, 0.0, 0.5, 0.12, -0.08, 1.18, 0.0, 0.78],
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (style == AuroraStyle.header) {
      // 1. Voller oberer Ambient-Glow (reicht ueber den oberen Rand hinaus).
      final ambient = Rect.fromLTWH(0, -80, size.width, 256);
      canvas.drawRect(
        ambient,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _purple.o(0.40 * 0.85 * intensity),
              _cyan.o(0.25 * 0.85 * intensity),
              _cyan.o(0),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(ambient),
      );
    }

    final t = seconds();
    final blobs = style == AuroraStyle.header ? _headerBlobs : _splashBlobs;
    for (final b in blobs) {
      final k = _phase(t, b.period, reverse: b.reverse);
      final d = _drift[b.drift]!;
      double mix(int i) => d[i] + (d[i + 5] - d[i]) * k;
      final tx = mix(0), ty = mix(1), scale = mix(2), rot = mix(3), op = mix(4);

      final cx = size.width * b.fx + b.dx + tx * b.w;
      final cy = size.height * b.fy + b.dy + ty * b.h;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: b.w,
        height: b.h,
      );

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot * math.pi / 180);
      canvas.scale(scale);
      final alpha = (b.opacity * op * intensity).clamp(0.0, 1.0);
      canvas.drawOval(
        rect,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(
            colors: [
              b.inner.o(b.inner.a * alpha),
              b.outer.o(b.outer.a * alpha),
              b.outer.o(0),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(rect),
      );
      canvas.restore();
    }

    if (style == AuroraStyle.header) {
      // Subtile Vignette nach unten fuer perfekte Textlesbarkeit.
      final full = Offset.zero & size;
      canvas.drawRect(
        full,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bg.o(0),
              AppColors.bg.o(0.15),
              AppColors.bg.o(0.75),
            ],
          ).createShader(full),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.style != style || old.intensity != intensity;
}
