import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typografie: Bebas Neue (Display), Inter (Text), Space Mono (Zahlen/Mono).
class AppText {
  const AppText._();

  static const _displayFamily = 'Bebas Neue';
  static const _bodyFamily = 'Inter';
  static const _monoFamily = 'Space Mono';

  static TextStyle display(double size, {Color color = Colors.white}) =>
      TextStyle(
        fontFamily: _displayFamily,
        fontSize: size,
        color: color,
        letterSpacing: size * 0.03,
        height: 1.0,
      );

  static TextStyle body(
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: _bodyFamily,
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    // Inter liegt als Variable-Font vor: Gewicht explizit auf die wght-Achse legen.
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
  );

  static TextStyle mono(
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => TextStyle(
    fontFamily: _monoFamily,
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
  );

  /// `text-[11px] font-bold uppercase tracking-wider text-faint`
  static TextStyle label({double size = 11, Color color = AppColors.faint}) =>
      body(size, color: color, weight: FontWeight.w700, letterSpacing: 0.9);
}

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lime,
        onPrimary: Colors.black,
        secondary: AppColors.pink,
        surface: AppColors.surface,
        onSurface: Colors.white,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.lime,
        selectionColor: AppColors.lime.o(0.3),
        selectionHandleColor: AppColors.lime,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Inter',
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
