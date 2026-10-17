import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Skaliert beim Druecken leicht ein (`active:scale-95`).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// `.glass-card`: halbtransparente Karte mit feinem Rand.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.color,
    this.radius = 16,
    this.shadows,
    this.onTap,
    this.dashed = false,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? color;
  final double radius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool dashed;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface.o(0.9)) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? white(0.08)),
        boxShadow: shadows,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, scale: 0.99, child: box);
  }
}

/// Primaerer Neon-Button (`.btn-lime`).
class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.expand = true,
    this.color = AppColors.lime,
    this.foreground = Colors.black,
    this.glowing = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final bool expand;
  final Color color;
  final Color foreground;
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = AnimatedOpacity(
      opacity: enabled ? 1 : 0.5,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: glowing ? glow(color) : null,
        ),
        child: DefaultTextStyle(
          style: AppText.body(14, color: foreground, weight: FontWeight.w800),
          child: IconTheme(
            data: IconThemeData(color: foreground, size: 18),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [Flexible(child: child)],
            ),
          ),
        ),
      ),
    );
    return Pressable(onTap: onPressed, child: button);
  }
}

/// Sekundaerer Button (`.btn-secondary`).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      child: Container(
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: white(0.08)),
        ),
        child: DefaultTextStyle(
          style: AppText.body(14, weight: FontWeight.w700),
          textAlign: TextAlign.center,
          child: child,
        ),
      ),
    );
  }
}

/// Kleiner quadratischer Icon-Button (`w-9 h-9 rounded-xl bg-surface-light`).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Pressable(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: white(0.05)),
        ),
        child: Icon(icon, size: 20, color: AppColors.dim),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Runder Schliessen-Button in Sheets.
class CloseCircleButton extends StatelessWidget {
  const CloseCircleButton({super.key, required this.onTap, this.size = 32});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: white(0.05), shape: BoxShape.circle),
        child: Icon(
          Icons.close_rounded,
          size: size * 0.5,
          color: AppColors.dim,
        ),
      ),
    );
  }
}

/// Grosses Emoji in einer getoenten Kachel (Avatar).
class EmojiTile extends StatelessWidget {
  const EmojiTile({
    super.key,
    required this.emoji,
    required this.size,
    this.color,
    this.radius,
    this.borderColor,
    this.borderWidth = 1,
    this.fontSize,
    this.shadows,
    this.background,
  });

  final String emoji;
  final double size;
  final Color? color;
  final double? radius;
  final Color? borderColor;
  final double borderWidth;
  final double? fontSize;
  final List<BoxShadow>? shadows;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? color?.o(0.14),
        borderRadius: BorderRadius.circular(radius ?? size * 0.3),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Text(emoji, style: TextStyle(fontSize: fontSize ?? size * 0.5)),
    );
  }
}

/// Kleines Label ueber Formularfeldern.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.size = 11, this.bottom = 6});

  final String text;
  final double size;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottom),
    child: Text(text.toUpperCase(), style: AppText.label(size: size)),
  );
}

/// Dunkles Eingabefeld im App-Look.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLength,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.focusColor = AppColors.lime,
    this.fontSize = 16,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.suffixText,
    this.autofocus = false,
    this.onChanged,
    this.fillColor = AppColors.surfaceLight,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final Color focusColor;
  final double fontSize;
  final EdgeInsets padding;
  final double radius;
  final String? suffixText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final Color fillColor;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: c),
    );
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textAlign: textAlign,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      cursorColor: focusColor,
      style: AppText.body(fontSize, weight: FontWeight.w700),
      decoration: InputDecoration(
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: fillColor,
        hintText: hint,
        hintStyle: AppText.body(
          fontSize,
          color: AppColors.dim,
          weight: FontWeight.w600,
        ),
        suffixText: suffixText,
        suffixStyle: AppText.body(10, color: AppColors.faint),
        contentPadding: padding,
        enabledBorder: border(white(0.10)),
        focusedBorder: border(focusColor),
        border: border(white(0.10)),
      ),
    );
  }
}

/// Toggle-Schalter im Neon-Look.
class NeonSwitch extends StatelessWidget {
  const NeonSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.cyan,
    this.knobColor = Colors.white,
    this.width = 48,
    this.height = 24,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color knobColor;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const pad = 2.0;
    final knob = height - pad * 2;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: height,
        padding: const EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: value ? activeColor : white(0.10),
          borderRadius: BorderRadius.circular(height),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knob,
            height: knob,
            decoration: BoxDecoration(color: knobColor, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// Kleine abgerundete Pille (z. B. "Du", "Gast", Badges).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.child,
    this.background,
    this.borderColor,
    this.radius = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  final Widget child;
  final Color? background;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor == null ? null : Border.all(color: borderColor!),
    ),
    child: child,
  );
}

/// Dezente Trennlinie (`border-white/[0.08]`).
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.opacity = 0.08});

  final double opacity;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: white(opacity));
}

/// Zentriert Inhalte auf Handy-Breite (`max-w-md`) und liefert den App-Hintergrund.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bg,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: child,
        ),
      ),
    );
  }
}

/// Einblenden + leichtes Hochgleiten (fuer Listen-Eintraege, `animate-pop`).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280) + delay,
      curve: Interval(
        delay.inMilliseconds / (280 + delay.inMilliseconds),
        1,
        curve: Curves.easeOutBack,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      ),
      child: child,
    );
  }
}

/// Pulsierende Deckkraft (`animate-pulse`).
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.min = 0.5});

  final Widget child;
  final double min;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: 1,
      end: widget.min,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_c),
    child: widget.child,
  );
}

/// Zeigt ein Ladeindikator-Emoji (`animate-bounce`).
class BouncingEmoji extends StatefulWidget {
  const BouncingEmoji(this.emoji, {super.key, this.size = 36});

  final String emoji;
  final double size;

  @override
  State<BouncingEmoji> createState() => _BouncingEmojiState();
}

class _BouncingEmojiState extends State<BouncingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Tailwind "bounce": 0%/100% unten, 50% oben mit Ease.
        final t = _c.value;
        final y = t < 0.5
            ? -25 * Curves.easeOut.transform(t * 2)
            : -25 * (1 - Curves.easeIn.transform((t - 0.5) * 2));
        return Transform.translate(
          offset: Offset(0, y * widget.size / 36),
          child: child,
        );
      },
      child: Text(widget.emoji, style: TextStyle(fontSize: widget.size)),
    );
  }
}

/// Vollflaechiger Lade-Zustand.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            const BouncingEmoji('🍺'),
            Text(
              label.toUpperCase(),
              style: AppText.body(
                12,
                color: AppColors.dim,
                weight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kurze Meldung am unteren Rand (Ersatz fuer `alert()` der Web-App).
void showToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: error ? AppColors.pink.o(0.5) : white(0.12)),
        ),
        content: Text(
          message,
          style: AppText.body(
            13,
            color: error ? AppColors.pink : Colors.white,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
}

/// Zurueck, falls es eine vorherige Seite gibt; sonst zur Startseite.
void popOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/');
  }
}
