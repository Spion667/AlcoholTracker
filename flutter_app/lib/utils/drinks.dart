import 'dart:ui';

import '../models/drink.dart';
import '../models/profile.dart';

/// Getraenkedatenbank & Rechner, Spiegel von `src/utils/drinks.js`.

const ethanolDensity = 0.789; // g/ml

class DrinkDef {
  const DrinkDef({
    required this.key,
    required this.name,
    required this.category,
    required this.defaultAbv,
    required this.icon,
    required this.volume,
    this.beerFactor = 0,
    this.isCustomMix = false,
  });

  final String key;
  final String name;
  final String category;
  final double defaultAbv;
  final String icon;
  final double volume;
  final double beerFactor;
  final bool isCustomMix;
}

class DrinkSection {
  const DrinkSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.drinks,
  });

  final String id;
  final String title;
  final String icon;
  final List<DrinkDef> drinks;
}

const drinksSections = <DrinkSection>[
  DrinkSection(
    id: 'beer',
    title: 'Bier & Radler',
    icon: '🍺',
    drinks: [
      DrinkDef(
        key: 'beer_500',
        name: 'Bier 0,5L',
        category: 'beer',
        defaultAbv: 5.0,
        icon: '🍺',
        volume: 500,
        beerFactor: 1.0,
      ),
      DrinkDef(
        key: 'beer_330',
        name: 'Bier 0,33L',
        category: 'beer',
        defaultAbv: 5.0,
        icon: '🍺',
        volume: 330,
        beerFactor: 0.66,
      ),
      DrinkDef(
        key: 'radler_500',
        name: 'Radler 0,5L',
        category: 'beer',
        defaultAbv: 2.5,
        icon: '🍺',
        volume: 500,
        beerFactor: 0.5,
      ),
      DrinkDef(
        key: 'radler_330',
        name: 'Radler 0,33L',
        category: 'beer',
        defaultAbv: 2.5,
        icon: '🍺',
        volume: 330,
        beerFactor: 0.33,
      ),
    ],
  ),
  DrinkSection(
    id: 'mix',
    title: 'Mischen',
    icon: '🥤',
    drinks: [
      DrinkDef(
        key: 'mischen',
        name: 'Mischen',
        category: 'mix',
        defaultAbv: 0,
        icon: '🥤',
        volume: 250,
        isCustomMix: true,
      ),
    ],
  ),
  DrinkSection(
    id: 'shots',
    title: 'Kurze & Shots',
    icon: '🥃',
    drinks: [
      DrinkDef(
        key: 'klopfer',
        name: 'Klopfer',
        category: 'shot',
        defaultAbv: 16.0,
        icon: '🌰',
        volume: 50,
      ),
      DrinkDef(
        key: 'hubertus',
        name: 'Hubertus Tropfen',
        category: 'shot',
        defaultAbv: 16.0,
        icon: '🌿',
        volume: 20,
      ),
      DrinkDef(
        key: 'berentzen',
        name: 'Berentzen',
        category: 'shot',
        defaultAbv: 16.0,
        icon: '🍏',
        volume: 20,
      ),
      DrinkDef(
        key: 'vodka_shot',
        name: 'Wodka Shot',
        category: 'shot',
        defaultAbv: 40.0,
        icon: '🥃',
        volume: 40,
      ),
    ],
  ),
  DrinkSection(
    id: 'wine',
    title: 'Wein & Prickelndes',
    icon: '🍾',
    drinks: [
      DrinkDef(
        key: 'prosecco',
        name: 'Prosecco',
        category: 'sparkling',
        defaultAbv: 11.0,
        icon: '🍾',
        volume: 150,
      ),
      DrinkDef(
        key: 'champagne',
        name: 'Champagner',
        category: 'sparkling',
        defaultAbv: 12.0,
        icon: '🍾',
        volume: 150,
      ),
      DrinkDef(
        key: 'wine',
        name: 'Wein',
        category: 'wine',
        defaultAbv: 12.0,
        icon: '🍷',
        volume: 150,
      ),
    ],
  ),
];

/// Flache Lookup-Map ueber alle Getraenke.
final Map<String, DrinkDef> drinksDb = {
  for (final s in drinksSections)
    for (final d in s.drinks) d.key: d,
};

class Spirit {
  const Spirit(this.key, this.name, this.abv, this.icon);
  final String key;
  final String name;
  final double abv;
  final String icon;
}

const spiritsDb = <String, Spirit>{
  'vodka': Spirit('vodka', 'Wodka', 40, '🥃'),
  'korn': Spirit('korn', 'Korn', 38, '🌾'),
  'springer': Spirit('springer', 'Springer', 33, '🍺'),
};

class MixRatio {
  const MixRatio(this.label, this.value, this.ratio);
  final String label;
  final String value;
  final double ratio;
}

const mixRatios = <MixRatio>[
  MixRatio('10% Spirituose', '10-90', 0.10),
  MixRatio('20% Spirituose', '20-80', 0.20),
  MixRatio('30% Spirituose', '30-70', 0.30),
  MixRatio('40% Spirituose', '40-60', 0.40),
  MixRatio('50% Spirituose (Halbe-Halbe)', '50-50', 0.50),
];

const mixSizes = <int>[100, 150, 200, 250, 300, 500];

/// `Number(x.toFixed(digits))` wie in JavaScript.
double _round(double x, int digits) => double.parse(x.toStringAsFixed(digits));

/// Reiner Alkohol in Gramm.
double calculateAlcoholGrams(double? volumeMl, double? abvPercent) {
  if (volumeMl == null || abvPercent == null) return 0;
  if (volumeMl == 0 || abvPercent == 0) return 0;
  return _round(volumeMl * (abvPercent / 100) * ethanolDensity, 1);
}

/// Reiner Alkohol in Litern.
double calculateAlcoholLiters(double? volumeMl, double? abvPercent) {
  if (volumeMl == null || abvPercent == null) return 0;
  if (volumeMl == 0 || abvPercent == 0) return 0;
  return _round(volumeMl * (abvPercent / 100) / 1000, 4);
}

/// Bier-Aequivalent in Litern.
double calculateBeerLiters(double? volumeMl, [double beerFactor = 0]) {
  if (volumeMl == null || volumeMl == 0 || beerFactor == 0) return 0;
  return _round(volumeMl * beerFactor / 1000, 2);
}

/// Gramm Alkohol ohne Nachkommastelle (fuer das Ranking).
String formatGrams(num? grams) => (grams ?? 0).round().toString();

/// Restzeit bis zum Party-Ende, z. B. `2h 14m`.
String formatTimeRemaining(DateTime? endsAt, {DateTime? now}) {
  if (endsAt == null) return '';
  final diff = endsAt.difference(now ?? DateTime.now());
  if (diff.inMilliseconds <= 0) return 'Endet jetzt';
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}

// ==============================================
// Gruppen-Meilensteine
// ==============================================

class Milestone {
  const Milestone(this.target, this.title, this.icon, this.desc);
  final int target;
  final String title;
  final String icon;
  final String desc;
}

const partyMilestones = <Milestone>[
  Milestone(25, 'Warm-Up geschafft!', '🍻', 'Die ersten Runden laufen'),
  Milestone(50, '50g Club geknackt!', '🔥', 'Die Stimmung nimmt Fahrt auf'),
  Milestone(
    100,
    '100g Reinalkohol Legenden!',
    '🚀',
    'Party-Modus auf Anschlag',
  ),
  Milestone(200, '200g Party-Monster!', '⚡', 'Absolute Abriss-Stimmung'),
  Milestone(350, '350g Olymp der Trinker!', '👑', 'Geschichtsträchtiger Abend'),
  Milestone(500, '500g Halbe-Kilo-Club!', '💥', 'Legendärer Kater garantiert'),
];

class MilestoneInfo {
  const MilestoneInfo({
    required this.currentTotal,
    required this.nextMilestone,
    required this.prevMilestone,
    required this.percent,
    required this.gramsRemaining,
    required this.achievedCount,
  });

  final double currentTotal;
  final Milestone nextMilestone;
  final Milestone? prevMilestone;
  final int percent;
  final int gramsRemaining;
  final int achievedCount;
}

MilestoneInfo getGroupMilestoneInfo([double totalAlcoholGrams = 0]) {
  final current = totalAlcoholGrams;

  final next = partyMilestones.firstWhere(
    (m) => m.target > current,
    orElse: () => Milestone(
      (((current + 50) / 50).ceil()) * 50,
      'Party-Überflieger!',
      '✨',
      'Unaufhaltsame Truppe',
    ),
  );

  Milestone? prev;
  for (final m in partyMilestones.reversed) {
    if (m.target <= current) {
      prev = m;
      break;
    }
  }

  final prevTarget = prev?.target ?? 0;
  final range = (next.target - prevTarget).clamp(1, 1 << 30);
  final progressInRange = (current - prevTarget).clamp(0, double.infinity);
  final percent = ((progressInRange / range) * 100).round().clamp(0, 100);
  final remaining = (next.target - current).round().clamp(0, 1 << 30);

  return MilestoneInfo(
    currentTotal: current,
    nextMilestone: next,
    prevMilestone: prev,
    percent: percent,
    gramsRemaining: remaining,
    achievedCount: partyMilestones.where((m) => current >= m.target).length,
  );
}

// ==============================================
// Dynamische Live-Titel (Badges)
// ==============================================

class DrinkBadge {
  const DrinkBadge(this.id, this.icon, this.label, this.color);
  final String id;
  final String icon;
  final String label;
  final Color color;
}

class _BadgeStat {
  double beerLiters = 0;
  int shotsCount = 0;
  int roundsGiven = 0;
}

Map<String, List<DrinkBadge>> computeBadges(
  List<Drink> drinks,
  List<Profile> members,
) {
  final badgeMap = <String, List<DrinkBadge>>{};
  if (members.isEmpty) return badgeMap;

  for (final m in members) {
    badgeMap[m.id] = [];
  }
  if (drinks.isEmpty) return badgeMap;

  // 1. Fruehstarter (aeltester Drink)
  final chronological = [...drinks]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  badgeMap[chronological.first.profileId]?.add(
    const DrinkBadge('early_bird', '🚀', 'Frühstarter', Color(0xFF00F0FF)),
  );

  // Aggregierte Statistiken
  final stats = <String, _BadgeStat>{
    for (final m in members) m.id: _BadgeStat(),
  };
  final countedRounds = <String>{};

  for (final d in drinks) {
    final userStat = stats[d.profileId];
    if (userStat != null) {
      if (d.category == 'beer') {
        userStat.beerLiters += d.beerLiters != 0
            ? d.beerLiters
            : d.volumeMl / 1000;
      } else if (d.category == 'shot') {
        userStat.shotsCount += 1;
      }
    }

    // Spendierhose
    if (d.loggedBy != null && d.loggedBy != d.profileId) {
      stats[d.loggedBy]?.roundsGiven += 1;
    } else if (d.roundId != null && countedRounds.add(d.roundId!)) {
      if (d.loggedBy != null) stats[d.loggedBy]?.roundsGiven += 1;
    }
  }

  // Bierkoenig (mind. 0.5 Liter)
  var maxBeer = 0.5;
  String? beerKingId;
  stats.forEach((pid, s) {
    if (s.beerLiters >= maxBeer) {
      maxBeer = s.beerLiters;
      beerKingId = pid;
    }
  });
  if (beerKingId != null) {
    badgeMap[beerKingId]?.add(
      const DrinkBadge('beer_king', '👑', 'Bierkönig', Color(0xFFFFB800)),
    );
  }

  // Shot-Maschine (mind. 2 Shots)
  var maxShots = 2;
  String? shotMachineId;
  stats.forEach((pid, s) {
    if (s.shotsCount >= maxShots) {
      maxShots = s.shotsCount;
      shotMachineId = pid;
    }
  });
  if (shotMachineId != null) {
    badgeMap[shotMachineId]?.add(
      const DrinkBadge('shot_machine', '⚡', 'Shot-Maschine', Color(0xFFFF2E93)),
    );
  }

  // Spendierhose (mind. 1 Runde oder Spendier-Drink)
  var maxRounds = 1;
  String? spendierhoseId;
  stats.forEach((pid, s) {
    if (s.roundsGiven >= maxRounds) {
      maxRounds = s.roundsGiven;
      spendierhoseId = pid;
    }
  });
  if (spendierhoseId != null) {
    badgeMap[spendierhoseId]?.add(
      const DrinkBadge('spendierhose', '🤝', 'Spendierhose', Color(0xFFC6FF3D)),
    );
  }

  return badgeMap;
}
