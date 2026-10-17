import 'dart:async';

import '../models/drink.dart';
import '../models/party.dart';
import '../models/profile.dart';
import '../utils/drinks.dart';
import 'api.dart';

/// In-Memory-Backend ohne Netzwerk.
///
/// Wird fuer den Demo-Modus (`--dart-define=DEMO_MODE=true`), Screenshots und
/// Widget-Tests verwendet. Simuliert auch die Realtime-Events von Supabase.
class DemoApi implements Api {
  DemoApi({bool seed = true, DateTime? now}) {
    if (seed) _seed(now ?? DateTime.now());
  }

  final _profiles = <String, Profile>{};
  final _parties = <String, Party>{};
  final _members = <String, Map<String, ({DateTime joinedAt, double? bac})>>{};
  final _drinks = <Drink>[];
  final _reactions = <Reaction>[];
  final _changes = StreamController<_Change>.broadcast();
  var _idCounter = 0;

  String _id(String prefix) => '$prefix-${++_idCounter}';

  // --- Seed ---

  void _seed(DateTime now) {
    const lukas = Profile(
      id: 'demo-lukas',
      name: 'Lukas',
      emoji: '🦊',
      color: '#FF2E93',
    );
    const hannes = Profile(
      id: 'demo-hannes',
      name: 'Hannes',
      emoji: '🐻',
      color: '#00F0FF',
    );
    const sarah = Profile(
      id: 'demo-sarah',
      name: 'Sarah',
      emoji: '🐼',
      color: '#8B5CF6',
    );
    const jonas = Profile(
      id: 'demo-jonas',
      name: 'Jonas',
      emoji: '🤠',
      color: '#FFB800',
      isGuest: true,
    );
    for (final p in [lukas, hannes, sarah, jonas]) {
      _profiles[p.id] = p;
    }

    void party(
      String id,
      String name,
      String emoji,
      String host,
      Duration age,
      Duration remaining,
      List<Profile> members, {
      String? code,
      bool ended = false,
    }) {
      final created = now.subtract(age);
      _parties[id] = Party(
        id: id,
        name: name,
        emoji: emoji,
        hostId: host,
        createdAt: created,
        endsAt: now.add(remaining),
        endedAt: ended ? now.subtract(const Duration(hours: 3)) : null,
        symbolCode: code,
      );
      _members[id] = {
        for (final m in members) m.id: (joinedAt: created, bac: null),
      };
    }

    party(
      'demo-wg',
      'WG-Abend',
      '🍻',
      lukas.id,
      const Duration(hours: 3),
      const Duration(hours: 6),
      [lukas, hannes, sarah, jonas],
    );
    party(
      'demo-geburtstag',
      'Geburtstagsfeier',
      '🎉',
      hannes.id,
      const Duration(hours: 1),
      const Duration(hours: 8),
      [hannes],
      code: 'spade,heart,club,diamond',
    );
    party(
      'demo-silvester',
      'Silvester',
      '🍾',
      lukas.id,
      const Duration(days: 9),
      const Duration(days: -8, hours: -14),
      [lukas, hannes, sarah, jonas],
      ended: true,
    );

    void drink(
      String party,
      Profile who,
      DrinkDef def,
      int minutesAgo, {
      String? loggedBy,
      String? roundId,
    }) {
      _drinks.add(
        Drink(
          id: _id('drink'),
          partyId: party,
          profileId: who.id,
          loggedBy: loggedBy ?? who.id,
          roundId: roundId,
          drinkKey: def.key,
          name: def.name,
          icon: def.icon,
          category: def.category,
          volumeMl: def.volume,
          abv: def.defaultAbv,
          alcoholG: calculateAlcoholGrams(def.volume, def.defaultAbv),
          beerLiters: calculateBeerLiters(def.volume, def.beerFactor),
          createdAt: now.subtract(Duration(minutes: minutesAgo)),
        ),
      );
    }

    final beer = drinksDb['beer_500']!;
    final shot = drinksDb['vodka_shot']!;
    final wine = drinksDb['wine']!;
    for (final p in [lukas, hannes, sarah, jonas]) {
      drink('demo-wg', p, beer, 170, loggedBy: lukas.id, roundId: 'round-1');
    }
    drink('demo-wg', lukas, shot, 130);
    drink('demo-wg', lukas, shot, 100);
    drink('demo-wg', lukas, beer, 75);
    drink('demo-wg', hannes, beer, 120);
    drink('demo-wg', hannes, beer, 60);
    drink('demo-wg', sarah, wine, 90);
    drink('demo-wg', sarah, wine, 40);
    drink('demo-wg', jonas, beer, 20, loggedBy: lukas.id);
    drink('demo-geburtstag', hannes, beer, 30);

    final past = [lukas, hannes, sarah, jonas];
    for (var i = 0; i < past.length; i++) {
      for (var k = 0; k <= i; k++) {
        drink(
          'demo-silvester',
          past[i],
          k.isEven ? beer : shot,
          60 * 24 * 9 - 60 * (i + k),
        );
      }
    }

    final first = _drinks.first;
    _reactions
      ..add(Reaction(drinkId: first.id, profileId: hannes.id, emoji: '🍻'))
      ..add(Reaction(drinkId: first.id, profileId: sarah.id, emoji: '🔥'));
  }

  // --- Profiles ---

  @override
  Future<Profile?> getProfile(String? id) async => _profiles[id];

  @override
  Future<Profile> createProfile({
    required String name,
    String emoji = '😎',
    String color = '#C6FF3D',
    bool isGuest = false,
  }) async {
    final p = Profile(
      id: _id('profile'),
      name: name.trim(),
      emoji: emoji,
      color: color,
      isGuest: isGuest,
    );
    _profiles[p.id] = p;
    _seedHistory(p);
    return p;
  }

  /// Neue Demo-Nutzer waren (scheinbar) bei der beendeten Party dabei, damit
  /// Historie und Wrapped sofort etwas anzeigen.
  void _seedHistory(Profile p) {
    final party = _parties['demo-silvester'];
    if (party == null || p.isGuest) return;
    _members[party.id]![p.id] = (joinedAt: party.createdAt, bac: null);
    final beer = drinksDb['beer_500']!;
    final shot = drinksDb['vodka_shot']!;
    for (var i = 0; i < 4; i++) {
      final def = i.isEven ? beer : shot;
      _drinks.add(
        Drink(
          id: _id('drink'),
          partyId: party.id,
          profileId: p.id,
          loggedBy: p.id,
          drinkKey: def.key,
          name: def.name,
          icon: def.icon,
          category: def.category,
          volumeMl: def.volume,
          abv: def.defaultAbv,
          alcoholG: calculateAlcoholGrams(def.volume, def.defaultAbv),
          beerLiters: calculateBeerLiters(def.volume, def.beerFactor),
          createdAt: party.createdAt.add(Duration(minutes: 90 + 25 * i)),
        ),
      );
    }
  }

  @override
  Future<Profile> updateProfile(String id, Map<String, dynamic> updates) async {
    final old = _profiles[id]!;
    final p = Profile(
      id: id,
      name: (updates['name'] as String?) ?? old.name,
      emoji: (updates['emoji'] as String?) ?? old.emoji,
      color: (updates['color'] as String?) ?? old.color,
      isGuest: old.isGuest,
    );
    _profiles[id] = p;
    return p;
  }

  // --- Parties ---

  Party _withMembers(Party p) => p.copyWith(
    members: [
      for (final e in (_members[p.id] ?? {}).entries)
        if (_profiles[e.key] != null)
          PartyMember(
            profile: _profiles[e.key]!,
            joinedAt: e.value.joinedAt,
            currentBac: e.value.bac,
          ),
    ],
  );

  @override
  Future<List<Party>> listActiveParties() async {
    final now = DateTime.now();
    final list =
        _parties.values
            .where((p) => p.endedAt == null && p.endsAt.isAfter(now))
            .map(_withMembers)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Party>> listPastParties(String? profileId) async {
    if (profileId == null) return [];
    return [
      for (final p in _parties.values)
        if (_members[p.id]?.containsKey(profileId) ?? false) p,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Party> getParty(String id) async {
    final p = _parties[id];
    if (p == null) throw StateError('Party nicht gefunden');
    return _withMembers(p);
  }

  @override
  Future<void> updateMemberBac(
    String? partyId,
    String? profileId,
    double? currentBac,
  ) async {
    final m = _members[partyId]?[profileId];
    if (m == null) return;
    _members[partyId]![profileId!] = (joinedAt: m.joinedAt, bac: currentBac);
  }

  @override
  Future<Party> createParty({
    required String name,
    String emoji = '🎉',
    String? hostId,
    String? symbolCode,
  }) async {
    final now = DateTime.now();
    final p = Party(
      id: _id('party'),
      name: name.trim(),
      emoji: emoji,
      hostId: hostId,
      createdAt: now,
      endsAt: now.add(const Duration(hours: 10)),
      symbolCode: symbolCode,
    );
    _parties[p.id] = p;
    _members[p.id] = {?hostId: (joinedAt: now, bac: null)};
    return p;
  }

  @override
  Future<void> joinParty(String partyId, String profileId) async {
    _members[partyId]?.putIfAbsent(
      profileId,
      () => (joinedAt: DateTime.now(), bac: null),
    );
    _changes.add(_Change(partyId, _Kind.members));
  }

  @override
  Future<Profile> addGuestToParty({
    required String partyId,
    required String name,
    String emoji = '👤',
    String color = '#8B5CF6',
  }) async {
    final guest = await createProfile(
      name: name,
      emoji: emoji,
      color: color,
      isGuest: true,
    );
    await joinParty(partyId, guest.id);
    return guest;
  }

  @override
  Future<bool> endParty(String partyId, String requesterId) async {
    final p = _parties[partyId];
    if (p == null) return false;
    if (p.hostId != null && p.hostId != requesterId) return false;
    final ended = DateTime.now();
    _parties[partyId] = p.copyWith(endedAt: ended);
    _changes.add(
      _Change(partyId, _Kind.party, {
        'ended_at': ended.toUtc().toIso8601String(),
      }),
    );
    return true;
  }

  // --- Drinks ---

  @override
  Future<List<Drink>> getPartyDrinks(String partyId) async => [
    for (final d in _drinks)
      if (d.partyId == partyId) d,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<Drink>> logDrinksBatch({
    required String partyId,
    required List<String> profileIds,
    required String loggedBy,
    required DrinkInput drink,
    DateTime? createdAt,
  }) async {
    final roundId = profileIds.length > 1 ? _id('round') : null;
    final logged = [
      for (final pid in profileIds)
        Drink(
          id: _id('drink'),
          partyId: partyId,
          profileId: pid,
          loggedBy: loggedBy,
          roundId: roundId,
          drinkKey: drink.key,
          name: drink.name,
          icon: drink.icon,
          category: drink.category,
          volumeMl: drink.volume,
          abv: drink.abv,
          alcoholG: calculateAlcoholGrams(drink.volume, drink.abv),
          beerLiters: calculateBeerLiters(drink.volume, drink.beerFactor),
          createdAt: createdAt ?? DateTime.now(),
        ),
    ];
    _drinks.addAll(logged);
    _changes.add(_Change(partyId, _Kind.drinks));
    return logged;
  }

  @override
  Future<void> deleteDrink(String drinkId) async {
    final idx = _drinks.indexWhere((d) => d.id == drinkId);
    if (idx < 0) return;
    final partyId = _drinks[idx].partyId;
    _drinks.removeAt(idx);
    _reactions.removeWhere((r) => r.drinkId == drinkId);
    _changes.add(_Change(partyId, _Kind.drinks));
  }

  // --- Reactions ---

  @override
  Future<List<Reaction>> getPartyReactions(String partyId) async {
    final ids = {
      for (final d in _drinks)
        if (d.partyId == partyId) d.id,
    };
    return [
      for (final r in _reactions)
        if (ids.contains(r.drinkId)) r,
    ];
  }

  @override
  Future<bool> toggleReaction({
    required String drinkId,
    required String profileId,
    required String emoji,
  }) async {
    final idx = _reactions.indexWhere(
      (r) =>
          r.drinkId == drinkId && r.profileId == profileId && r.emoji == emoji,
    );
    final partyId = _drinks.firstWhere((d) => d.id == drinkId).partyId;
    final added = idx < 0;
    if (added) {
      _reactions.add(
        Reaction(drinkId: drinkId, profileId: profileId, emoji: emoji),
      );
    } else {
      _reactions.removeAt(idx);
    }
    _changes.add(_Change(partyId, _Kind.reactions));
    return added;
  }

  @override
  Future<PartyFull> getPartyFull(String partyId) async {
    final party = await getParty(partyId);
    return PartyFull(
      party: party,
      drinks: await getPartyDrinks(partyId),
      reactions: await getPartyReactions(partyId),
    );
  }

  // --- Realtime ---

  @override
  Unsubscribe subscribeToParty(
    String partyId, {
    required void Function() onDrinks,
    required void Function() onMembers,
    required void Function() onReactions,
    required void Function(Map<String, dynamic> record) onParty,
  }) {
    final sub = _changes.stream.where((c) => c.partyId == partyId).listen((c) {
      switch (c.kind) {
        case _Kind.drinks:
          onDrinks();
        case _Kind.members:
          onMembers();
        case _Kind.reactions:
          onReactions();
        case _Kind.party:
          onParty(c.record ?? const {});
      }
    });
    return sub.cancel;
  }
}

enum _Kind { drinks, members, reactions, party }

class _Change {
  _Change(this.partyId, this.kind, [this.record]);
  final String partyId;
  final _Kind kind;
  final Map<String, dynamic>? record;
}
