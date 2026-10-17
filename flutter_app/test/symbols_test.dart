import 'dart:math';

import 'package:alcohol_tracker/utils/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Symbol Password Utilities', () {
    test('contains the 4 required card symbols', () {
      expect(cardSymbols.length, 4);
      for (final id in ['spade', 'heart', 'diamond', 'club']) {
        expect(cardSymbolsMap[id], isNotNull);
      }
    });

    test('generates a random 4-symbol code', () {
      final code = generateRandomSymbolCode(Random(1));
      final parts = code.split(',');
      expect(parts.length, 4);
      for (final p in parts) {
        expect(['spade', 'heart', 'diamond', 'club'], contains(p));
      }
    });

    test('parses a symbol code string into objects', () {
      final parsed = parseSymbolCode('spade,heart,diamond,club');
      expect(parsed.map((s) => s.symbol).toList(), ['♠', '♥', '♦', '♣']);
    });

    test('handles invalid or empty symbol code strings gracefully', () {
      expect(parseSymbolCode(null), isEmpty);
      expect(parseSymbolCode(''), isEmpty);
      expect(parseSymbolCode('invalid'), isEmpty);
    });

    test('verifies correct symbol code', () {
      const target = 'spade,heart,club,diamond';
      expect(
        verifySymbolCode(['spade', 'heart', 'club', 'diamond'], target),
        isTrue,
      );
      expect(
        verifySymbolCode(['heart', 'spade', 'club', 'diamond'], target),
        isFalse,
      );
      expect(verifySymbolCode(['spade', 'heart', 'club'], target), isFalse);
    });

    test('open party (no target code) always verifies', () {
      expect(verifySymbolCode([], null), isTrue);
      expect(verifySymbolCode([], ''), isTrue);
    });
  });
}
