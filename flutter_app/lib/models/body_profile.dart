/// Auswahl fuer das biologische Geschlecht: (id, Label, Emoji).
const genderOptions = <(String, String, String)>[
  ('male', 'Männlich', '👨'),
  ('female', 'Weiblich', '👩'),
  ('other', 'Divers', '🧑'),
];

/// Lokale Koerperdaten fuer den Promille-Radar. Verlassen nie das Geraet.
class BodyProfile {
  const BodyProfile({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    this.shareInParty = false,
    this.updatedAt,
  });

  /// `male` | `female` | `other`
  final String gender;
  final int age;
  final int heightCm;
  final int weightKg;
  final bool shareInParty;
  final DateTime? updatedAt;

  /// Begrenzt alle Werte wie `saveBodyProfile` der Web-App.
  factory BodyProfile.sanitized({
    String? gender,
    num? age,
    num? heightCm,
    num? weightKg,
    bool shareInParty = false,
  }) {
    int clamp(num? v, int fallback, int min, int max) {
      final n = (v == null || v == 0) ? fallback : v.round();
      return n.clamp(min, max);
    }

    return BodyProfile(
      gender: (gender == null || gender.isEmpty) ? 'male' : gender,
      age: clamp(age, 25, 16, 99),
      heightCm: clamp(heightCm, 175, 100, 240),
      weightKg: clamp(weightKg, 75, 35, 250),
      shareInParty: shareInParty,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'shareInParty': shareInParty,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static BodyProfile? fromJson(Map<String, dynamic> json) {
    final weight = json['weightKg'];
    if (weight is! num || weight == 0) return null;
    return BodyProfile(
      gender: (json['gender'] as String?) ?? 'male',
      age: (json['age'] as num?)?.round() ?? 25,
      heightCm: (json['heightCm'] as num?)?.round() ?? 175,
      weightKg: weight.round(),
      shareInParty: json['shareInParty'] == true,
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
    );
  }
}
