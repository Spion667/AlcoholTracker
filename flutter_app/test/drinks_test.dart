import 'package:alcohol_tracker/models/profile.dart';
import 'package:alcohol_tracker/utils/drinks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('Alcohol Calculations', () {
    test('0.5L beer at 5%', () {
      // 500ml * 0.05 * 0.789 = 19.725 -> 19.7
      expect(calculateAlcoholGrams(500, 5), 19.7);
    });

    test('50ml vodka shot at 40%', () {
      // 50ml * 0.40 * 0.789 = 15.78 -> 15.8
      expect(calculateAlcoholGrams(50, 40), 15.8);
    });

    test('edge cases with zero volume or abv', () {
      expect(calculateAlcoholGrams(0, 5), 0);
      expect(calculateAlcoholGrams(500, 0), 0);
      expect(calculateAlcoholGrams(null, null), 0);
    });

    test('beer liters equivalent', () {
      expect(calculateBeerLiters(500, 1), 0.5);
      expect(calculateBeerLiters(500, 0.5), 0.25);
      expect(calculateBeerLiters(50, 0), 0);
    });

    test('formats grams rounded for the ranking UI', () {
      expect(formatGrams(19.7), '20');
      expect(formatGrams(15.2), '15');
      expect(formatGrams(0), '0');
    });

    test('contains all required drinks in the database', () {
      for (final key in [
        'beer_500',
        'beer_330',
        'radler_500',
        'radler_330',
        'mischen',
        'klopfer',
        'hubertus',
        'berentzen',
        'vodka_shot',
        'prosecco',
        'champagne',
        'wine',
      ]) {
        expect(drinksDb[key], isNotNull, reason: key);
      }
      expect(drinksDb['whiskey'], isNull);
      expect(drinksDb['rum'], isNull);
      expect(drinksDb['gin'], isNull);
    });
  });

  group('Countdown formatting', () {
    test('past date -> ending now', () {
      final past = DateTime.now().subtract(const Duration(seconds: 10));
      expect(formatTimeRemaining(past), 'Endet jetzt');
    });

    test('future date with hours and minutes', () {
      final future = DateTime.now().add(const Duration(hours: 2, minutes: 15));
      expect(formatTimeRemaining(future), matches(RegExp(r'^2h 1[45]m$')));
    });

    test('under one hour only shows minutes', () {
      final now = DateTime(2026, 10, 11, 20);
      expect(
        formatTimeRemaining(
          now.add(const Duration(minutes: 42, seconds: 30)),
          now: now,
        ),
        '42m',
      );
    });
  });

  group('Group Milestones', () {
    test('initial milestone for 0g', () {
      final info = getGroupMilestoneInfo(0);
      expect(info.nextMilestone.target, 25);
      expect(info.percent, 0);
      expect(info.gramsRemaining, 25);
      expect(info.achievedCount, 0);
    });

    test('progress between milestones', () {
      // 35g liegt zwischen 25g und 50g -> (35-25)/25 = 40 %
      final info = getGroupMilestoneInfo(35);
      expect(info.nextMilestone.target, 50);
      expect(info.percent, 40);
      expect(info.gramsRemaining, 15);
      expect(info.achievedCount, 1);
    });

    test('high tier milestones', () {
      final info = getGroupMilestoneInfo(220);
      expect(info.nextMilestone.target, 350);
      expect(info.achievedCount, 4);
    });

    test('beyond the last milestone generates a dynamic one', () {
      final info = getGroupMilestoneInfo(520);
      expect(info.nextMilestone.target, 600);
      expect(info.nextMilestone.title, 'Party-Überflieger!');
      expect(info.achievedCount, 6);
    });
  });

  group('Dynamic Badges', () {
    const members = [
      Profile(id: 'u1', name: 'Lukas'),
      Profile(id: 'u2', name: 'Hannes'),
      Profile(id: 'u3', name: 'Sarah'),
    ];
    final t0 = DateTime.utc(2026, 10, 10, 20);

    test('early bird goes to the very first drink', () {
      final badges = computeBadges([
        testDrink(
          id: 'd1',
          profileId: 'u2',
          createdAt: t0,
          category: 'beer',
          beerLiters: 0.5,
        ),
        testDrink(
          id: 'd2',
          profileId: 'u1',
          createdAt: t0.add(const Duration(minutes: 15)),
          category: 'shot',
        ),
      ], members);
      expect(badges['u2']!.any((b) => b.id == 'early_bird'), isTrue);
    });

    test('bierkönig for highest beer consumer', () {
      final badges = computeBadges([
        testDrink(
          id: 'd1',
          profileId: 'u1',
          createdAt: t0,
          category: 'beer',
          beerLiters: 1.0,
        ),
        testDrink(
          id: 'd2',
          profileId: 'u2',
          createdAt: t0.add(const Duration(minutes: 5)),
          category: 'beer',
          beerLiters: 0.5,
        ),
      ], members);
      expect(badges['u1']!.any((b) => b.id == 'beer_king'), isTrue);
    });

    test('shot-maschine needs at least 2 shots', () {
      final badges = computeBadges([
        testDrink(id: 'd1', profileId: 'u3', createdAt: t0, category: 'shot'),
        testDrink(
          id: 'd2',
          profileId: 'u3',
          createdAt: t0.add(const Duration(minutes: 10)),
          category: 'shot',
        ),
      ], members);
      expect(badges['u3']!.any((b) => b.id == 'shot_machine'), isTrue);

      final single = computeBadges([
        testDrink(id: 'd1', profileId: 'u3', createdAt: t0, category: 'shot'),
      ], members);
      expect(single['u3']!.any((b) => b.id == 'shot_machine'), isFalse);
    });

    test('spendierhose when user logs drinks for others', () {
      final badges = computeBadges([
        testDrink(id: 'd1', profileId: 'u1', loggedBy: 'u2', createdAt: t0),
        testDrink(id: 'd2', profileId: 'u3', loggedBy: 'u2', createdAt: t0),
      ], members);
      expect(badges['u2']!.any((b) => b.id == 'spendierhose'), isTrue);
    });

    test('no members or no drinks yields empty badge lists', () {
      expect(computeBadges([], []), isEmpty);
      final empty = computeBadges([], members);
      expect(empty['u1'], isEmpty);
    });
  });
}
