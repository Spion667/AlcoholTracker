import 'package:alcohol_tracker/models/body_profile.dart';
import 'package:alcohol_tracker/utils/bac.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('Watson TBW Calculations', () {
    test('average male (25yo, 180cm, 75kg)', () {
      // 2.447 - 0.09516*25 + 0.1074*180 + 0.3362*75 = 44.615
      final tbw = calculateTbw(
        gender: 'male',
        age: 25,
        heightCm: 180,
        weightKg: 75,
      );
      expect(tbw, closeTo(44.615, 0.01));
    });

    test('average female (25yo, 165cm, 60kg)', () {
      // -2.097 + 0.1069*165 + 0.2466*60 = 30.3375
      final tbw = calculateTbw(
        gender: 'female',
        age: 25,
        heightCm: 165,
        weightKg: 60,
      );
      expect(tbw, closeTo(30.3375, 0.01));
    });

    test('diverse is the average of male and female', () {
      double tbw(String g) =>
          calculateTbw(gender: g, age: 25, heightCm: 175, weightKg: 70);
      expect(tbw('other'), closeTo((tbw('male') + tbw('female')) / 2, 0.01));
    });
  });

  group('BAC Time Kinetics and Metabolism', () {
    const profile = BodyProfile(
      gender: 'male',
      age: 25,
      heightCm: 180,
      weightKg: 75,
    );
    final now = DateTime.utc(2026, 10, 11, 23, 30);

    test('zero for empty drinks or missing profile', () {
      final r1 = calculateBacFromDrinks([], profile, currentTime: now);
      expect(r1.currentBac, 0);
      expect(r1.isZero, isTrue);

      final r2 = calculateBacFromDrinks(
        [testDrink(alcoholG: 20, createdAt: now)],
        null,
        currentTime: now,
      );
      expect(r2.currentBac, 0);
    });

    test('1 drink 30 minutes ago (full absorption)', () {
      final drinks = [
        testDrink(
          alcoholG: 19.7,
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
      ];
      final r = calculateBacFromDrinks(drinks, profile, currentTime: now);
      // 19.7 * 0.8 / 44.615 = 0.353 minus ~0.06 Abbau -> ca. 0.29
      expect(r.currentBac, greaterThan(0.20));
      expect(r.currentBac, lessThan(0.35));
      expect(r.isZero, isFalse);
      expect(r.soberTimeString, contains(':'));
    });

    test('lower BAC during early absorption (5 minutes after drinking)', () {
      final drinks = [
        testDrink(
          alcoholG: 19.7,
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
      ];
      final r = calculateBacFromDrinks(drinks, profile, currentTime: now);
      expect(r.currentBac, greaterThan(0.02));
      expect(r.currentBac, lessThan(0.12));
    });

    test('completely eliminated after 8 hours (1 beer)', () {
      final drinks = [
        testDrink(
          alcoholG: 19.7,
          createdAt: now.subtract(const Duration(hours: 8)),
        ),
      ];
      final r = calculateBacFromDrinks(drinks, profile, currentTime: now);
      expect(r.currentBac, 0);
      expect(r.isZero, isTrue);
      expect(r.soberTime, isNull);
    });

    test('accumulates multiple drinks and finds the peak', () {
      final drinks = [
        testDrink(
          id: 'a',
          alcoholG: 19.7,
          createdAt: now.subtract(const Duration(minutes: 120)),
        ),
        testDrink(
          id: 'b',
          alcoholG: 19.7,
          createdAt: now.subtract(const Duration(minutes: 60)),
        ),
        testDrink(
          id: 'c',
          alcoholG: 15.8,
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
      ];
      final r = calculateBacFromDrinks(drinks, profile, currentTime: now);
      expect(r.currentBac, greaterThan(0.4));
      expect(r.peakBac, greaterThanOrEqualTo(r.currentBac));
      expect(r.formattedBac, matches(RegExp(r'^~\d+,\d{2} ‰$')));
    });

    test('drinks in the future are ignored', () {
      final drinks = [
        testDrink(alcoholG: 19.7, createdAt: now.add(const Duration(hours: 1))),
      ];
      expect(
        calculateBacFromDrinks(drinks, profile, currentTime: now).isZero,
        isTrue,
      );
    });
  });

  group('BodyProfile sanitising', () {
    test('clamps values like the web app', () {
      final p = BodyProfile.sanitized(
        gender: 'female',
        age: 5,
        heightCm: 999,
        weightKg: 10,
      );
      expect(p.age, 16);
      expect(p.heightCm, 240);
      expect(p.weightKg, 35);
    });

    test('falls back to defaults for missing values', () {
      final p = BodyProfile.sanitized();
      expect(p.gender, 'male');
      expect(p.age, 25);
      expect(p.heightCm, 175);
      expect(p.weightKg, 75);
      expect(p.shareInParty, isFalse);
    });

    test('json roundtrip', () {
      final p = BodyProfile.sanitized(
        gender: 'female',
        age: 26,
        heightCm: 168,
        weightKg: 62,
        shareInParty: true,
      );
      final back = BodyProfile.fromJson(p.toJson())!;
      expect(back.gender, 'female');
      expect(back.age, 26);
      expect(back.heightCm, 168);
      expect(back.weightKg, 62);
      expect(back.shareInParty, isTrue);
    });
  });
}
