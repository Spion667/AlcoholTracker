num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

/// Ein geloggtes Getraenk (Zeile der Tabelle `drinks`).
class Drink {
  const Drink({
    required this.id,
    required this.partyId,
    required this.profileId,
    required this.name,
    required this.createdAt,
    this.loggedBy,
    this.roundId,
    this.drinkKey = 'custom',
    this.icon = '🍹',
    this.category = 'other',
    this.volumeMl = 0,
    this.abv = 0,
    this.alcoholG = 0,
    this.beerLiters = 0,
  });

  final String id;
  final String partyId;
  final String profileId;
  final String? loggedBy;
  final String? roundId;
  final String drinkKey;
  final String name;
  final String icon;
  final String category;
  final double volumeMl;
  final double abv;
  final double alcoholG;
  final double beerLiters;
  final DateTime createdAt;

  factory Drink.fromJson(Map<String, dynamic> json) => Drink(
    id: json['id'] as String,
    partyId: json['party_id'] as String,
    profileId: json['profile_id'] as String,
    loggedBy: json['logged_by'] as String?,
    roundId: json['round_id'] as String?,
    drinkKey: (json['drink_key'] as String?) ?? 'custom',
    name: (json['name'] as String?) ?? '',
    icon: (json['icon'] as String?) ?? '🍹',
    category: (json['category'] as String?) ?? 'other',
    volumeMl: _num(json['volume_ml']).toDouble(),
    abv: _num(json['abv']).toDouble(),
    alcoholG: _num(json['alcohol_g']).toDouble(),
    beerLiters: _num(json['beer_liters']).toDouble(),
    createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
  );
}

/// Beschreibung eines Getraenks, das eingetragen werden soll.
class DrinkInput {
  const DrinkInput({
    required this.key,
    required this.name,
    required this.volume,
    required this.abv,
    this.icon = '🍹',
    this.category = 'other',
    this.beerFactor = 0,
  });

  final String key;
  final String name;
  final String icon;
  final String category;
  final double volume;
  final double abv;
  final double beerFactor;
}

class Reaction {
  const Reaction({
    required this.drinkId,
    required this.profileId,
    required this.emoji,
  });

  final String drinkId;
  final String profileId;
  final String emoji;

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
    drinkId: json['drink_id'] as String,
    profileId: json['profile_id'] as String,
    emoji: json['emoji'] as String,
  );
}
