import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/aurora.dart';

/// Animierter Start-Screen.
///
/// Ablauf (~3 s): Neon-Aurora blendet ein, das Logo poppt mit Glow auf und
/// bekommt einen Glanz-Schimmer, danach erscheint der Titel Buchstabe fuer
/// Buchstabe. Im Hintergrund steigen Bierblasen auf. Sobald die Animation
/// durch ist **und** [ready] (Profil geladen) gilt, blendet der Screen aus und
/// ruft [onFinished] auf.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.ready,
    required this.onFinished,
    this.introDuration = const Duration(milliseconds: 3000),
  });

  final bool ready;
  final VoidCallback onFinished;
  final Duration introDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _outro;
  late final AnimationController _loop;

  bool _introDone = false;
  bool _finished = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: widget.introDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _introDone = true;
          _maybeFinish();
        }
      });
    _outro =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 450),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed && !_finished) {
            _finished = true;
            widget.onFinished();
          }
        });
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_intro.isAnimating && !_introDone && _intro.value == 0) {
      _reduceMotion = reduce;
      if (reduce) _intro.duration = const Duration(milliseconds: 500);
      _intro.forward();
    }
  }

  @override
  void didUpdateWidget(SplashScreen old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready) _maybeFinish();
  }

  void _maybeFinish() {
    if (_introDone && widget.ready && !_outro.isAnimating && !_finished) {
      _outro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _outro.dispose();
    _loop.dispose();
    super.dispose();
  }

  static const _title = 'ALCOHOLTRACKER';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final logoSize = math.min(media.size.width * 0.42, 190.0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _outro, _loop]),
        builder: (context, _) {
          final t = _intro.value;
          final out = Curves.easeInCubic.transform(_outro.value);

          double seg(double a, double b, [Curve curve = Curves.linear]) =>
              curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

          final auroraIn = seg(0, 0.5, Curves.easeOut);
          final logoScale = 0.55 + 0.45 * seg(0.02, 0.34, Curves.easeOutBack);
          final logoOpacity = seg(0, 0.14);
          final glowIn = seg(0.08, 0.45, Curves.easeOut);
          final breathe = 0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi * 6);
          final shine = seg(0.38, 0.66, Curves.easeInOut);
          final tagline = seg(0.72, 0.92, Curves.easeOut);
          final hint = seg(0.8, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Aurora-Lichtatmosphaere
              Opacity(
                opacity: 1 - out,
                child: AuroraBackground(
                  style: AuroraStyle.splash,
                  intensity: auroraIn,
                ),
              ),

              // Aufsteigende Bierblasen
              Opacity(
                opacity: (seg(0.05, 0.4) * (1 - out)).clamp(0.0, 1.0),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _BubblesPainter(_loop.value, reduce: _reduceMotion),
                ),
              ),

              // Inhalt (Logo + Titel)
              Opacity(
                opacity: 1 - out,
                child: Transform.scale(
                  scale: 1 + 0.08 * out,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: logoSize * 1.9,
                        height: logoSize * 1.9,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsierender Neon-Glow hinter dem Logo
                            Container(
                              width: logoSize * (1.05 + 0.1 * breathe),
                              height: logoSize * (1.05 + 0.1 * breathe),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  logoSize * 0.28,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.lime.o(
                                      (0.30 + 0.20 * breathe) * glowIn,
                                    ),
                                    blurRadius: 70,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: AppColors.pink.o(0.16 * glowIn),
                                    blurRadius: 90,
                                    spreadRadius: -4,
                                    offset: const Offset(24, 18),
                                  ),
                                ],
                              ),
                            ),
                            Opacity(
                              opacity: logoOpacity,
                              child: Transform.scale(
                                scale: logoScale,
                                child: _ShinyLogo(size: logoSize, shine: shine),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _AnimatedTitle(progress: t),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: tagline,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - tagline)),
                          child: Text(
                            'GEMEINSAM TRINKEN · FAIR VERGLEICHEN',
                            textAlign: TextAlign.center,
                            style: AppText.body(
                              11,
                              color: AppColors.dim,
                              weight: FontWeight.w700,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Opacity(
                        opacity: hint,
                        child: _LoadingDots(phase: _loop.value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Logo mit einmaligem diagonalem Glanz-Schimmer.
class _ShinyLogo extends StatelessWidget {
  const _ShinyLogo({required this.size, required this.shine});

  final double size;
  final double shine;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
    );
    if (shine <= 0 || shine >= 1) return image;

    // Heller Streifen, der von links unten nach rechts oben ueber das Logo wandert.
    final pos = -0.4 + 1.8 * shine;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        begin: const Alignment(-1, 1),
        end: const Alignment(1, -1),
        colors: [Colors.white.o(0), Colors.white.o(0.55), Colors.white.o(0)],
        stops: [
          (pos - 0.12).clamp(0.0, 1.0),
          pos.clamp(0.0, 1.0),
          (pos + 0.12).clamp(0.0, 1.0),
        ],
      ).createShader(rect),
      child: image,
    );
  }
}

/// "ALCOHOL" (weiss) + "TRACKER" (lime), Buchstabe fuer Buchstabe eingeblendet.
class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    const start = 0.36;
    const step = 0.017;
    const dur = 0.2;
    final letters = _SplashScreenState._title.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < letters.length; i++)
          Builder(
            builder: (context) {
              final a = start + i * step;
              final p = Curves.easeOutCubic.transform(
                ((progress - a) / dur).clamp(0.0, 1.0),
              );
              return Opacity(
                opacity: p,
                child: Transform.translate(
                  offset: Offset(0, 26 * (1 - p)),
                  child: Text(
                    letters[i],
                    style:
                        AppText.display(
                          52,
                          color: i < 7 ? Colors.white : AppColors.lime,
                        ).copyWith(
                          shadows: i < 7
                              ? null
                              : [
                                  Shadow(
                                    color: AppColors.lime.o(0.55),
                                    blurRadius: 18,
                                  ),
                                ],
                        ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Drei pulsierende Punkte als dezenter Lade-Hinweis.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.lime, AppColors.cyan, AppColors.pink];
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              final k =
                  0.5 + 0.5 * math.sin(phase * 2 * math.pi * 14 - i * 0.9);
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors[i].o(0.35 + 0.65 * k),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: colors[i].o(0.4 * k), blurRadius: 8),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Aufsteigende Bierblasen ueber den ganzen Bildschirm.
class _BubblesPainter extends CustomPainter {
  _BubblesPainter(this.t, {this.reduce = false});

  /// 0..1 ueber 14 s.
  final double t;
  final bool reduce;

  static final _bubbles = () {
    final rng = math.Random(7);
    return List.generate(
      30,
      (_) => (
        x: rng.nextDouble(),
        radius: 2.0 + rng.nextDouble() * 6,
        speed: 1 + rng.nextInt(3), // ganze Zyklen pro 14 s -> nahtloser Loop
        phase: rng.nextDouble(),
        sway: 6 + rng.nextDouble() * 14,
        swaySpeed: 2 + rng.nextInt(3),
        color: [
          AppColors.lime,
          AppColors.cyan,
          AppColors.pink,
          AppColors.amber,
        ][rng.nextInt(4)],
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (reduce) return;
    for (final b in _bubbles) {
      final p = (t * b.speed + b.phase) % 1.0;
      final y = size.height * (1.06 - 1.12 * p);
      final x =
          size.width * b.x +
          math.sin((t * b.swaySpeed + b.phase) * 2 * math.pi) * b.sway;
      // Weich ein- und ausblenden
      final fade = math.sin(p * math.pi).clamp(0.0, 1.0);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = b.color.o(0.45 * fade);
      final fill = Paint()..color = b.color.o(0.08 * fade);
      canvas.drawCircle(Offset(x, y), b.radius, fill);
      canvas.drawCircle(Offset(x, y), b.radius, stroke);
      // Glanzpunkt
      canvas.drawCircle(
        Offset(x - b.radius * 0.35, y - b.radius * 0.35),
        math.max(0.8, b.radius * 0.18),
        Paint()..color = Colors.white.o(0.5 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblesPainter old) => old.t != t;
}
