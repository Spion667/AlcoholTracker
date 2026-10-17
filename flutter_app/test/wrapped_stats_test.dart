import 'package:alcohol_tracker/models/profile.dart';
import 'package:alcohol_tracker/utils/wrapped_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  const lukas = Profile(id: 'u1', name: 'Lukas');
  const hannes = Profile(id: 'u2', name: 'Hannes');
  const sarah = Profile(id: 'u3', name: 'Sarah');
  const members = [lukas, hannes, sarah];

  // Lokale Zeit, damit die Peak-Hour-Auswertung unabhaengig von der Zeitzone ist.
  final t0 = DateTime(2026, 10, 10, 21, 10);

  test('ranking, totals and beer equivalent', () {
    final stats = WrappedStats.compute(
      members: members,
      drinks: [
        testDrink(
          id: 'a',
          profileId: 'u1',
          alcoholG: 19.7,
          name: 'Bier',
          createdAt: t0,
        ),
        testDrink(
          id: 'b',
          profileId: 'u1',
          alcoholG: 19.7,
          name: 'Bier',
          createdAt: t0,
        ),
        testDrink(
          id: 'c',
          profileId: 'u2',
          alcoholG: 15.8,
          name: 'Wodka Shot',
          createdAt: t0,
        ),
      ],
      myProfileId: 'u2',
    );

    expect(stats.ranking.map((r) => r.profile.id), ['u1', 'u2', 'u3']);
    expect(stats.totalAlcohol, closeTo(55.2, 0.001));
    expect(stats.beerEquivalent, 3); // 55.2 / 19.7 = 2.8
    expect(stats.drinkCount, 3);
    expect(stats.memberCount, 3);
    expect(stats.mostPopularDrink, 'Bier');
    expect(stats.mostPopularCount, 2);
    expect(stats.myRank, 2);
    expect(stats.me?.drinksCount, 1);
  });

  test('peak hour uses the local hour with the most drinks', () {
    final stats = WrappedStats.compute(
      members: members,
      drinks: [
        testDrink(id: 'a', createdAt: DateTime(2026, 10, 10, 21, 5)),
        testDrink(id: 'b', createdAt: DateTime(2026, 10, 10, 22, 5)),
        testDrink(id: 'c', createdAt: DateTime(2026, 10, 10, 22, 40)),
      ],
    );
    expect(stats.peakHour, 22);
    expect(stats.peakHourCount, 2);
    expect(stats.peakHourLabel, '22:00 – 23:00 Uhr');
  });

  test('spendierhose counts only drinks of rounds logged for others', () {
    final stats = WrappedStats.compute(
      members: members,
      drinks: [
        testDrink(
          id: 'a',
          profileId: 'u1',
          loggedBy: 'u2',
          roundId: 'r1',
          createdAt: t0,
        ),
        testDrink(
          id: 'b',
          profileId: 'u3',
          loggedBy: 'u2',
          roundId: 'r1',
          createdAt: t0,
        ),
        // Einzel-Drink fuer andere (ohne round_id) zaehlt hier nicht.
        testDrink(id: 'c', profileId: 'u3', loggedBy: 'u1', createdAt: t0),
      ],
    );
    expect(stats.topGenerous?.profile.id, 'u2');
    expect(stats.topGenerous?.roundsGiven, 2);
  });

  test('empty party yields no popular drink, no peak hour and zero totals', () {
    final stats = WrappedStats.compute(members: members, drinks: const []);
    expect(stats.mostPopularDrink, isNull);
    expect(stats.peakHour, isNull);
    expect(stats.totalAlcohol, 0);
    expect(stats.beerEquivalent, 0);
    expect(stats.me, isNull);
    expect(stats.myRank, 0);
  });
}
