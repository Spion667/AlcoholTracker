import 'package:flutter/services.dart';

/// Haptik & Klick-Sound (ersetzt `navigator.vibrate` / Web-Audio der Web-App).
class Haptics {
  const Haptics._();

  static void tap() => HapticFeedback.lightImpact();

  static void select() => HapticFeedback.selectionClick();

  static void success() => HapticFeedback.mediumImpact();

  static void error() => HapticFeedback.heavyImpact();

  static void click() => SystemSound.play(SystemSoundType.click);
}
