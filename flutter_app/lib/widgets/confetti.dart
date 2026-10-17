import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Konfetti-Burst (Ersatz fuer `canvas-confetti`).
///
/// ```dart
/// Confetti.burst(context, particleCount: 75, spread: 90, originY: 0.55,
///     colors: [...]);
/// ```
class Confetti {
  const Confetti._();

  /// [spread] in Grad, [originX]/[originY] als Anteil der Bildschirmgroesse.
  static void burst(
    BuildContext context, {
    int particleCount = 50,
    double spread = 70,
    double angle = 90,
    double startVelocity = 45,
    double originX = 0.5,
    double originY = 0.6,
    List<Color> colors = const [
      Color(0xFFC6FF3D),
      Color(0xFFFF2E93),
      Color(0xFF8B5CF6),
      Color(0xFF00F0FF),
      Color(0xFFFFB800),
    ],
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiLayer(
        config: _Config(
          count: particleCount,
          spread: spread,
          angle: angle,
          startVelocity: startVelocity,
          origin: Offset(originX, originY),
          colors: colors,
        ),
        onDone: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _Config {
  const _Config({
    required this.count,
    required this.spread,
    required this.angle,
    required this.startVelocity,
    required this.origin,
    required this.colors,
  });

  final int count;
  final double spread, angle, startVelocity;
  final Offset origin;
  final List<Color> colors;
}

class _Particle {
  _Particle(
    this.x,
    this.y,
    this.angle,
    this.velocity,
    this.color,
    this.size,
    this.tilt,
    this.wobbleSpeed,
    this.round,
  );

  double x, y;
  double angle; // Bogenmass
  double velocity;
  final Color color;
  final double size;
  double tilt;
  final double wobbleSpeed;
  final bool round;
  double wobble = 0;
  int tick = 0;
}

const _totalTicks = 200;
const _decay = 0.9;
const _gravity = 1.0;

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({required this.config, required this.onDone});

  final _Config config;
  final VoidCallback onDone;

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rng = math.Random();
  final _particles = <_Particle>[];
  final _repaint = ValueNotifier<int>(0);
  Size _size = Size.zero;
  Duration _last = Duration.zero;
  double _acc = 0;
  bool _spawned = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _spawn(Size size) {
    final c = widget.config;
    final radSpread = c.spread * math.pi / 180;
    final radAngle = c.angle * math.pi / 180;
    for (var i = 0; i < c.count; i++) {
      _particles.add(
        _Particle(
          c.origin.dx * size.width,
          c.origin.dy * size.height,
          -radAngle + (0.5 * radSpread) - (_rng.nextDouble() * radSpread),
          c.startVelocity * 0.5 + _rng.nextDouble() * c.startVelocity,
          c.colors[_rng.nextInt(c.colors.length)],
          5 + _rng.nextDouble() * 5,
          _rng.nextDouble() * 10,
          0.1 + _rng.nextDouble() * 0.1,
          _rng.nextBool(),
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    if (_size.isEmpty) return;
    if (!_spawned) {
      _spawned = true;
      _spawn(_size);
    }
    // Physik in 60-fps-Schritten, unabhaengig von der Bildrate.
    _acc += (elapsed - _last).inMicroseconds / 16667;
    _last = elapsed;
    var steps = _acc.floor();
    _acc -= steps;
    steps = steps.clamp(0, 4);
    for (var s = 0; s < steps; s++) {
      for (final p in _particles) {
        p.x += math.cos(p.angle) * p.velocity;
        p.y += math.sin(p.angle) * p.velocity + _gravity * 3;
        p.velocity *= _decay;
        p.wobble += p.wobbleSpeed;
        p.tilt += 0.1;
        p.tick++;
      }
    }
    _particles.removeWhere((p) => p.tick >= _totalTicks);
    _repaint.value++;
    if (_particles.isEmpty && _spawned) {
      _ticker.stop();
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_particles, _repaint),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, Listenable repaint)
    : super(repaint: repaint);

  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final fade = 1 - p.tick / _totalTicks;
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.x + math.sin(p.wobble) * 4, p.y);
      canvas.rotate(p.tilt);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * (0.4 + 0.6 * math.cos(p.wobble).abs()),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
