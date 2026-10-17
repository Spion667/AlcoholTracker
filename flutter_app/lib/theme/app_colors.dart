import 'package:flutter/painting.dart';

/// Farbpalette "Neon Night" (aus `tailwind.config.js`).
class AppColors {
  const AppColors._();

  static const bg = Color(0xFF07070B);
  static const surface = Color(0xFF12121A);
  static const surfaceLight = Color(0xFF1C1C28);
  static const surfaceHover = Color(0xFF262636);
  static const sheet = Color(0xFF101018);

  static const lime = Color(0xFFC6FF3D);
  static const pink = Color(0xFFFF2E93);
  static const purple = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF00F0FF);
  static const amber = Color(0xFFFFB800);

  static const dim = Color(0xFF9494A8);
  static const faint = Color(0xFF5E5E72);
  static const line = Color(0x14FFFFFF); // white @ 8%
}

/// `Colors.white` mit Deckkraft, z. B. `white(.08)` entspricht `border-white/[0.08]`.
Color white(double opacity) => Color.fromRGBO(255, 255, 255, opacity);

Color black(double opacity) => Color.fromRGBO(0, 0, 0, opacity);

/// Parst `#RRGGBB` (oder `RRGGBB`) in eine [Color].
Color hexToColor(String hex, {Color fallback = AppColors.lime}) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}

extension ColorOpacity on Color {
  /// Kurzform fuer `withValues(alpha: ...)`.
  Color o(double opacity) => withValues(alpha: opacity);
}

/// Neon-Leuchtschatten (`shadow-glow-*`).
List<BoxShadow> glow(Color color, {double opacity = 0.45}) => [
  BoxShadow(color: color.o(opacity), blurRadius: 25, spreadRadius: -4),
];
