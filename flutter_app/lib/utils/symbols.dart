import 'dart:math';
import 'dart:ui';

/// Symbol-Passwort-System (Wii-U-Style), Spiegel von `src/utils/symbols.js`.
class CardSymbol {
  const CardSymbol({
    required this.id,
    required this.symbol,
    required this.label,
    required this.color,
  });

  final String id;
  final String symbol;
  final String label;
  final Color color;
}

const cardSymbols = <CardSymbol>[
  CardSymbol(id: 'spade', symbol: '♠', label: 'Pik', color: Color(0xFF00F0FF)),
  CardSymbol(id: 'heart', symbol: '♥', label: 'Herz', color: Color(0xFFFF2E93)),
  CardSymbol(
    id: 'diamond',
    symbol: '♦',
    label: 'Karo',
    color: Color(0xFFFFB800),
  ),
  CardSymbol(id: 'club', symbol: '♣', label: 'Kreuz', color: Color(0xFFC6FF3D)),
];

final cardSymbolsMap = {for (final s in cardSymbols) s.id: s};

/// Zufaelliger 4-Symbol-Code als String (z. B. `spade,heart,club,spade`).
String generateRandomSymbolCode([Random? rng]) {
  final random = rng ?? Random.secure();
  return List.generate(
    4,
    (_) => cardSymbols[random.nextInt(cardSymbols.length)].id,
  ).join(',');
}

/// Parst einen Code-String in Symbol-Objekte; unbekannte IDs werden verworfen.
List<CardSymbol> parseSymbolCode(String? codeString) {
  if (codeString == null || codeString.isEmpty) return const [];
  return codeString
      .split(',')
      .map((p) => cardSymbolsMap[p.trim()])
      .whereType<CardSymbol>()
      .toList();
}

/// Vergleicht eingegebene Symbol-IDs mit dem Ziel-Code. Ohne Ziel-Code (offene Party) immer `true`.
bool verifySymbolCode(List<String> enteredIds, String? targetCodeString) {
  if (targetCodeString == null || targetCodeString.isEmpty) return true;
  if (enteredIds.length != 4) return false;
  final targetIds = targetCodeString.split(',').map((p) => p.trim()).toList();
  if (targetIds.length != 4) return false;
  for (var i = 0; i < 4; i++) {
    if (enteredIds[i] != targetIds[i]) return false;
  }
  return true;
}
