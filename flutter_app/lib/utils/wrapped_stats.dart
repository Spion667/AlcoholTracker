import '../models/drink.dart';
import '../models/profile.dart';

/// Pro-Person-Auswertung fuer den Wrapped-Rueckblick.
class DrinkerStats {
  DrinkerStats(this.profile);

  final Profile profile;
  double alcoholGrams = 0;
  int drinksCount = 0;
  int roundsGiven = 0;
  final Map<String, int> drinkCounts = {};
}

/// Alle Kennzahlen, aus denen die Wrapped-Slides gebaut werden
/// (Logik 1:1 aus `src/pages/Wrapped.jsx`).
class WrappedStats {
  const WrappedStats({
    required this.ranking,
    required this.totalAlcohol,
    required this.beerEquivalent,
    required this.drinkCount,
    required this.memberCount,
    this.mostPopularDrink,
    this.mostPopularCount = 0,
    this.peakHour,
    this.peakHourCount = 0,
    this.topGenerous,
    this.me,
    this.myRank = 0,
  });

  final List<DrinkerStats> ranking;
  final double totalAlcohol;

  /// 1 Halbe Bier (0,5 L) ~ 19,7 g Alkohol.
  final int beerEquivalent;
  final int drinkCount;
  final int memberCount;
  final String? mostPopularDrink;
  final int mostPopularCount;

  /// Lokale Stunde (0-23) mit den meisten Drinks.
  final int? peakHour;
  final int peakHourCount;
  final DrinkerStats? topGenerous;
  final DrinkerStats? me;

  /// 1-basiert; 0 = nicht Teil der Party.
  final int myRank;

  String? get peakHourLabel =>
      peakHour == null ? null : '$peakHour:00 – ${peakHour! + 1}:00 Uhr';

  factory WrappedStats.compute({
    required List<Profile> members,
    required List<Drink> drinks,
    String? myProfileId,
  }) {
    final statsMap = <String, DrinkerStats>{
      for (final m in members) m.id: DrinkerStats(m),
    };

    for (final d in drinks) {
      final entry = statsMap[d.profileId];
      if (entry != null) {
        entry.alcoholGrams += d.alcoholG;
        entry.drinksCount += 1;
        entry.drinkCounts[d.name] = (entry.drinkCounts[d.name] ?? 0) + 1;
      }

      if (d.roundId != null &&
          d.loggedBy != null &&
          d.loggedBy != d.profileId) {
        statsMap[d.loggedBy]?.roundsGiven += 1;
      }
    }

    // Stabil sortieren (wie Array.sort in JS): bei Gleichstand bleibt die Reihenfolge.
    final ranking = statsMap.values.toList();
    final indexed = ranking.asMap().entries.toList()
      ..sort((a, b) {
        final c = b.value.alcoholGrams.compareTo(a.value.alcoholGrams);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    final sortedRanking = indexed.map((e) => e.value).toList();

    final totalAlcohol = drinks.fold<double>(0, (s, d) => s + d.alcoholG);

    // Beliebtestes Getraenk (erstes bei Gleichstand, wie Object.entries + sort).
    final nameCounts = <String, int>{};
    for (final d in drinks) {
      nameCounts[d.name] = (nameCounts[d.name] ?? 0) + 1;
    }
    MapEntry<String, int>? popular;
    for (final e in nameCounts.entries) {
      if (popular == null || e.value > popular.value) popular = e;
    }

    // Peak-Hour (lokale Stunde mit den meisten Drinks).
    final hourCounts = <int, int>{};
    for (final d in drinks) {
      final h = d.createdAt.toLocal().hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    MapEntry<int, int>? peak;
    // JS-Object-Keys sind ganzzahlig aufsteigend sortiert.
    final hours = hourCounts.keys.toList()..sort();
    for (final h in hours) {
      final c = hourCounts[h]!;
      if (peak == null || c > peak.value) peak = MapEntry(h, c);
    }

    DrinkerStats? me;
    var myRank = 0;
    if (myProfileId != null) {
      me = statsMap[myProfileId];
      myRank = sortedRanking.indexWhere((r) => r.profile.id == myProfileId) + 1;
    }

    // Spendierhose: wer die meisten Runden ausgegeben hat.
    DrinkerStats? topGenerous;
    if (sortedRanking.isNotEmpty) {
      topGenerous = sortedRanking.first;
      for (final r in sortedRanking) {
        if (r.roundsGiven > topGenerous!.roundsGiven) topGenerous = r;
      }
    }

    return WrappedStats(
      ranking: sortedRanking,
      totalAlcohol: totalAlcohol,
      beerEquivalent: (totalAlcohol / 19.7).round(),
      drinkCount: drinks.length,
      memberCount: members.length,
      mostPopularDrink: popular?.key,
      mostPopularCount: popular?.value ?? 0,
      peakHour: peak?.key,
      peakHourCount: peak?.value ?? 0,
      topGenerous: topGenerous,
      me: me,
      myRank: myRank,
    );
  }
}
