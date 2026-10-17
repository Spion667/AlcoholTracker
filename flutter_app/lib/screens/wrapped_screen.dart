import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/env.dart';
import '../services/api.dart';
import '../state/profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/drinks.dart';
import '../utils/wrapped_stats.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';

const _slideDuration = Duration(seconds: 6);

class _Slide {
  const _Slide(this.id, this.colors, this.content);

  final String id;
  final List<Color> colors;
  final Widget content;
}

/// Spotify-Wrapped-artiger Story-Player (6 s pro Slide, Tippen zum Navigieren,
/// Halten zum Pausieren).
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({
    super.key,
    required this.partyId,
    this.fromParty = false,
  });

  final String partyId;

  /// `true`, wenn der Nutzer direkt aus der Party kommt (Schliessen = zurueck).
  final bool fromParty;

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  PartyFull? _data;
  WrappedStats? _stats;
  List<_Slide> _slides = const [];
  bool _loading = true;
  bool _failed = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _slideDuration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && _index < _slides.length - 1) {
          _goTo(_index + 1);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profiles = context.read<ProfileController>();
    final me = profiles.profile;
    try {
      final full = await context.read<Api>().getPartyFull(widget.partyId);
      final stats = WrappedStats.compute(
        members: full.members,
        drinks: full.drinks,
        myProfileId: me?.id,
      );
      profiles.markWrappedSeen(widget.partyId);
      if (!mounted) return;
      setState(() {
        _data = full;
        _stats = stats;
        _slides = _buildSlides(full, stats);
        _loading = false;
      });
      _progress.forward(from: 0);
    } catch (e) {
      debugPrint('Wrapped laden fehlgeschlagen: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _goTo(int i) {
    if (i < 0 || i >= _slides.length) return;
    setState(() => _index = i);
    _progress.forward(from: 0);
    if (_slides[i].id == 'podium') {
      Confetti.burst(
        context,
        particleCount: 50,
        spread: 80,
        originY: 0.6,
        colors: const [Color(0xFFFFD700), AppColors.lime, AppColors.pink],
      );
    }
  }

  void _leave() {
    if (widget.fromParty && context.canPop()) {
      context.pop();
    } else {
      context.pushReplacement('/p/${widget.partyId}');
    }
  }

  Future<void> _share() async {
    final data = _data;
    final stats = _stats;
    if (data == null || stats == null) return;
    final link = Env.partyLink(widget.partyId, wrapped: true);
    final text = StringBuffer(
      'Wir haben bei ${data.party.name} zusammen ${formatGrams(stats.totalAlcohol)}g Alkohol getrunken! 🍻',
    );
    if (link != null) text.write('\n$link');
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text.toString(),
          subject: 'AlcoholTracker: ${data.party.name}',
        ),
      );
    } catch (e) {
      if (mounted) showToast(context, 'Teilen nicht möglich: $e', error: true);
    }
  }

  // ---------------------------------------------------------------------------

  List<_Slide> _buildSlides(PartyFull data, WrappedStats s) {
    final party = data.party;
    final me = context.read<ProfileController>().profile;
    final slides = <_Slide>[];

    // 1. Intro
    slides.add(
      _Slide(
        'intro',
        const [Color(0xFF0A051B), Color(0xFF1E0836), AppColors.bg],
        _Centered(
          spacing: 16,
          children: [
            BouncingEmoji(party.emoji, size: 72),
            _Eyebrow('Euer Abend im Rückblick', AppColors.pink),
            Text(
              party.name,
              textAlign: TextAlign.center,
              style: AppText.display(48).copyWith(height: 1.1),
            ),
            _InfoBox(
              Text(
                '${s.memberCount} Freunde · ${s.drinkCount} Drinks getrunken',
                style: AppText.mono(12, color: AppColors.dim),
              ),
            ),
          ],
        ),
      ),
    );

    // 2. Gesamtalkohol
    slides.add(
      _Slide(
        'total_alcohol',
        const [Color(0xFF17052E), Color(0xFF2A0845), AppColors.bg],
        _Centered(
          spacing: 16,
          children: [
            _Eyebrow('Die Runde zusammen', AppColors.lime),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: s.totalAlcohol),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: formatGrams(v)),
                    TextSpan(
                      text: 'g',
                      style: AppText.body(
                        30,
                        color: AppColors.lime,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                style: AppText.display(
                  96,
                  color: AppColors.lime,
                ).copyWith(height: 1),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'reiner Alkohol wurde vernichtet! 💥',
                textAlign: TextAlign.center,
                style: AppText.body(18, weight: FontWeight.w700),
              ),
            ),
            _InfoBox(
              Text.rich(
                TextSpan(
                  style: AppText.mono(12, color: AppColors.dim, height: 1.5),
                  children: [
                    const TextSpan(text: '🍺 Das entspricht ca. '),
                    TextSpan(
                      text: '${s.beerEquivalent} Halben Bier',
                      style: AppText.mono(
                        12,
                        weight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const TextSpan(text: ' (0,5L)!'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              maxWidth: 320,
              padding: 16,
            ),
          ],
        ),
      ),
    );

    // 3. Beliebtestes Getraenk
    if (s.mostPopularDrink != null) {
      slides.add(
        _Slide(
          'popular_drink',
          const [Color(0xFF071E26), Color(0xFF083040), AppColors.bg],
          _Centered(
            spacing: 16,
            children: [
              _Eyebrow('Der Liebling des Abends', AppColors.cyan),
              PopIn(
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.o(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cyan.o(0.4)),
                    boxShadow: glow(AppColors.lime),
                  ),
                  child: const Text('🍸', style: TextStyle(fontSize: 48)),
                ),
              ),
              Text(
                s.mostPopularDrink!,
                textAlign: TextAlign.center,
                style: AppText.display(48),
              ),
              Text.rich(
                TextSpan(
                  style: AppText.body(12, color: AppColors.dim),
                  children: [
                    const TextSpan(text: 'Ganze '),
                    TextSpan(
                      text: '${s.mostPopularCount}x',
                      style: AppText.body(16, weight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' bestellt und getrunken.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Peak Hour
    if (s.peakHour != null) {
      slides.add(
        _Slide(
          'peak_hour',
          const [Color(0xFF2A0512), Color(0xFF3D0A1C), AppColors.bg],
          _Centered(
            spacing: 16,
            children: [
              _Eyebrow('Die wildeste Stunde', AppColors.pink),
              Text(
                s.peakHourLabel!,
                textAlign: TextAlign.center,
                style: AppText.display(
                  60,
                  color: AppColors.pink,
                ).copyWith(height: 1.05),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  'Um diese Uhrzeit ging es richtig rund: ${s.peakHourCount} Drinks in nur 60 Minuten! ⏱️',
                  textAlign: TextAlign.center,
                  style: AppText.body(14, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4b. Spendierhose
    final generous = s.topGenerous;
    if (generous != null && generous.roundsGiven > 0) {
      const yellow = Color(0xFFFACC15);
      slides.add(
        _Slide(
          'top_generous',
          const [Color(0xFF1A1803), Color(0xFF2E2805), AppColors.bg],
          _Centered(
            spacing: 16,
            children: [
              _Eyebrow('Die Spendierhose des Abends 💸', yellow),
              PopIn(
                child: EmojiTile(
                  emoji: generous.profile.emoji,
                  size: 80,
                  radius: 24,
                  fontSize: 40,
                  background: yellow.o(0.2),
                  borderColor: yellow,
                ),
              ),
              Text(
                generous.profile.name,
                textAlign: TextAlign.center,
                style: AppText.body(30, weight: FontWeight.w700),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text.rich(
                  TextSpan(
                    style: AppText.body(14, weight: FontWeight.w700),
                    children: [
                      const TextSpan(text: 'Hat ganze '),
                      TextSpan(
                        text: '${generous.roundsGiven}',
                        style: AppText.body(
                          18,
                          color: yellow,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: ' Runden für Freunde spendiert! Ehrenperson! 🫡',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 5. Dein Abend
    if (s.me != null) {
      slides.add(
        _Slide(
          'my_stats',
          const [Color(0xFF0F1E05), Color(0xFF1B3308), AppColors.bg],
          _Centered(
            spacing: 16,
            children: [
              _Eyebrow('Dein persönlicher Abend', AppColors.lime),
              PopIn(
                child: EmojiTile(
                  emoji: me?.emoji ?? '😎',
                  size: 80,
                  radius: 24,
                  fontSize: 40,
                  background: AppColors.lime.o(0.2),
                  borderColor: AppColors.lime,
                ),
              ),
              Text(
                me?.name ?? '',
                style: AppText.body(24, weight: FontWeight.w700),
              ),
              Text(
                'Platz #${s.myRank}',
                style: AppText.display(60, color: AppColors.lime),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: _StatBox(
                        'Alkohol',
                        '${formatGrams(s.me!.alcoholGrams)}g',
                      ),
                    ),
                    Expanded(child: _StatBox('Drinks', '${s.me!.drinksCount}')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 6. Podium
    final top3 = s.ranking.take(3).toList();
    slides.add(
      _Slide(
        'podium',
        const [Color(0xFF2B1B05), Color(0xFF422507), AppColors.bg],
        _Centered(
          spacing: 20,
          children: [
            const _Bounce(
              child: Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: Color(0xFFFACC15),
              ),
            ),
            Text(
              'Das Siegertreppchen',
              textAlign: TextAlign.center,
              style: AppText.display(48),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                spacing: 10,
                children: [
                  for (final (idx, entry) in top3.indexed)
                    PopIn(
                      delay: Duration(milliseconds: 150 * idx),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: idx == 0
                              ? const Color(0xFFEAB308).o(0.2)
                              : white(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: idx == 0
                                ? const Color(0xFFFACC15)
                                : white(0.10),
                          ),
                          boxShadow: idx == 0 ? glow(AppColors.lime) : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              const ['🥇', '🥈', '🥉'][idx],
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              entry.profile.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.profile.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${formatGrams(entry.alcoholGrams)}g',
                              style: AppText.mono(
                                16,
                                color: AppColors.lime,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // 7. Outro (Buttons liegen in der obersten Ebene, siehe build)
    slides.add(
      _Slide(
        'outro',
        const [Color(0xFF141424), Color(0xFF0E0E18), AppColors.bg],
        _Centered(
          spacing: 20,
          children: [
            const Text('🍻', style: TextStyle(fontSize: 60)),
            Text(
              'Was für ein Abend!',
              textAlign: TextAlign.center,
              style: AppText.display(48),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Teile euer Wrapped mit Freunden oder schau es dir später in deinem Profil an.',
                textAlign: TextAlign.center,
                style: AppText.body(12, color: AppColors.dim, height: 1.5),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );

    return slides;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView(label: 'Berechne Wrapped...');
    if (_failed || _slides.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  const Text('🤷', style: TextStyle(fontSize: 48)),
                  Text('Wrapped nicht verfügbar', style: AppText.display(30)),
                  Text(
                    'Der Rückblick konnte nicht geladen werden.',
                    style: AppText.body(12, color: AppColors.dim),
                  ),
                  const SizedBox(height: 8),
                  NeonButton(
                    onPressed: () => popOrHome(context),
                    child: const Text('Zurück'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final slide = _slides[_index];
    final isLast = _index == _slides.length - 1;
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hintergrund-Verlauf mit weichem Wechsel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: DecoratedBox(
              key: ValueKey('bg-${slide.id}'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: slide.colors,
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // Tipp-Zonen: links = zurueck, rechts = weiter, halten = pausieren
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _TapZone(
                  onTap: () => _goTo(_index - 1),
                  onHold: _progress.stop,
                  onRelease: () => _progress.forward(),
                ),
              ),
              Expanded(
                flex: 2,
                child: _TapZone(
                  onTap: () => isLast ? null : _goTo(_index + 1),
                  onHold: _progress.stop,
                  onRelease: () => _progress.forward(),
                ),
              ),
            ],
          ),

          // Slide-Inhalt (nicht klickbar, Taps gehen an die Zonen)
          IgnorePointer(
            child: Padding(
              padding: EdgeInsets.only(
                top: media.padding.top + 64,
                bottom: media.padding.bottom,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                child: KeyedSubtree(
                  key: ValueKey(slide.id),
                  child: slide.content,
                ),
              ),
            ),
          ),

          // Buttons des letzten Slides
          if (isLast)
            Positioned(
              left: 24,
              right: 24,
              bottom: media.padding.bottom + 32,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      NeonButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _share,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            const Icon(Icons.share_rounded, size: 16),
                            Text(
                              'Wrapped teilen',
                              style: AppText.body(
                                12,
                                color: Colors.black,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SecondaryButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _leave,
                        child: Text(
                          'Zurück zur Party',
                          style: AppText.body(12, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Fortschrittsbalken + Schliessen
          Positioned(
            top: media.padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => Row(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: white(0.2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: i < _index
                                  ? 1
                                  : (i == _index ? _progress.value : 0),
                              child: const ColoredBox(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Pressable(
                      onTap: _leave,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: black(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TapZone extends StatelessWidget {
  const _TapZone({
    required this.onTap,
    required this.onHold,
    required this.onRelease,
  });

  final VoidCallback onTap;
  final VoidCallback onHold;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    onLongPressStart: (_) => onHold(),
    onLongPressEnd: (_) => onRelease(),
    onLongPressCancel: onRelease,
    child: const SizedBox.expand(),
  );
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children, this.spacing = 16});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: children,
      ),
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    textAlign: TextAlign.center,
    style: AppText.body(
      12,
      color: color,
      weight: FontWeight.w800,
      letterSpacing: 2,
    ),
  );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.child, {this.maxWidth, this.padding = 12});

  final Widget child;
  final double? maxWidth;
  final double padding;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
    child: Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: white(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: white(0.10)),
      ),
      child: child,
    ),
  );
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: white(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: white(0.10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.body(
            10,
            color: AppColors.faint,
            weight: FontWeight.w700,
          ),
        ),
        Text(value, style: AppText.body(18, weight: FontWeight.w700)),
      ],
    ),
  );
}

/// Huepfende Animation (`animate-bounce`) fuer beliebige Widgets.
class _Bounce extends StatefulWidget {
  const _Bounce({required this.child});

  final Widget child;

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, -20 * Curves.easeInOut.transform(_c.value)),
      child: child,
    ),
    child: widget.child,
  );
}
