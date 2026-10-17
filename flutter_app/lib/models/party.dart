import 'profile.dart';

num? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

class PartyMember {
  const PartyMember({required this.profile, this.joinedAt, this.currentBac});

  final Profile profile;
  final DateTime? joinedAt;

  /// Freiwillig geteilter Promillewert (`party_members.current_bac`).
  final double? currentBac;

  String get id => profile.id;
}

class Party {
  const Party({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
    required this.endsAt,
    this.hostId,
    this.endedAt,
    this.symbolCode,
    this.members = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final String? hostId;
  final DateTime createdAt;
  final DateTime endsAt;
  final DateTime? endedAt;

  /// Optionaler 4-Symbol-Code, z. B. `spade,heart,club,spade`.
  final String? symbolCode;
  final List<PartyMember> members;

  bool get isProtected => symbolCode != null && symbolCode!.isNotEmpty;

  bool isEndedAt(DateTime now) => endedAt != null || !endsAt.isAfter(now);

  bool get isEnded => isEndedAt(DateTime.now());

  Party copyWith({
    String? name,
    String? emoji,
    String? hostId,
    DateTime? endsAt,
    DateTime? endedAt,
    String? symbolCode,
    List<PartyMember>? members,
  }) => Party(
    id: id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    hostId: hostId ?? this.hostId,
    createdAt: createdAt,
    endsAt: endsAt ?? this.endsAt,
    endedAt: endedAt ?? this.endedAt,
    symbolCode: symbolCode ?? this.symbolCode,
    members: members ?? this.members,
  );

  /// Uebernimmt eine Realtime-Zeile der `parties`-Tabelle (`payload.new`).
  Party mergeRecord(Map<String, dynamic> record) => Party(
    id: id,
    name: (record['name'] as String?) ?? name,
    emoji: (record['emoji'] as String?) ?? emoji,
    hostId: record.containsKey('host_id')
        ? record['host_id'] as String?
        : hostId,
    createdAt: _date(record['created_at']) ?? createdAt,
    endsAt: _date(record['ends_at']) ?? endsAt,
    endedAt: record.containsKey('ended_at')
        ? _date(record['ended_at'])
        : endedAt,
    symbolCode: record.containsKey('symbol_code')
        ? record['symbol_code'] as String?
        : symbolCode,
    members: members,
  );

  factory Party.fromJson(Map<String, dynamic> json) {
    final rawMembers = (json['party_members'] as List?) ?? const [];
    final members = <PartyMember>[];
    for (final raw in rawMembers) {
      final m = raw as Map<String, dynamic>;
      final p = m['profiles'];
      if (p is! Map<String, dynamic>) continue;
      members.add(
        PartyMember(
          profile: Profile.fromJson(p),
          joinedAt: _date(m['joined_at']),
          currentBac: _num(m['current_bac'])?.toDouble(),
        ),
      );
    }

    return Party(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '🎉',
      hostId: json['host_id'] as String?,
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      endsAt: _date(json['ends_at']) ?? DateTime.now(),
      endedAt: _date(json['ended_at']),
      symbolCode: json['symbol_code'] as String?,
      members: members,
    );
  }
}
