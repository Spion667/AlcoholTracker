import 'package:flutter/foundation.dart';

import '../models/drink.dart';
import '../models/party.dart';
import '../models/profile.dart';
import '../services/api.dart';

/// Eine Zeile im Live-Ranking.
class LeaderboardEntry {
  LeaderboardEntry(this.member);

  final PartyMember member;
  int rank = 0;
  double totalAlcoholGrams = 0;
  int totalDrinksCount = 0;
  double totalBeerLiters = 0;

  Profile get profile => member.profile;
}

/// Zustand einer Party inkl. Realtime-Updates (Spiegel von `useParty.js`).
class PartyController extends ChangeNotifier {
  PartyController({required this.partyId, required this.me, required this.api});

  final String partyId;
  final Profile me;
  final Api api;

  Party? _party;
  List<Drink> _drinks = const [];
  List<Reaction> _reactions = const [];
  bool _loading = true;
  String? _error;
  Unsubscribe? _unsubscribe;
  bool _disposed = false;

  Party? get party => _party;
  List<PartyMember> get members => _party?.members ?? const [];
  List<Drink> get drinks => _drinks;
  List<Reaction> get reactions => _reactions;
  bool get loading => _loading;
  String? get error => _error;

  bool get isMember => members.any((m) => m.id == me.id);
  bool get isHost => _party?.hostId == me.id;
  bool get isEnded => _party?.isEnded ?? false;

  int get totalPartyDrinks => _drinks.length;

  double get totalPartyAlcoholGrams =>
      _drinks.fold<double>(0, (sum, d) => sum + d.alcoholG);

  /// Letztes Getraenk des aktuellen Nutzers (fuer "Nochmal ...").
  Drink? get lastDrinkOfUser {
    for (final d in _drinks) {
      if (d.profileId == me.id) return d;
    }
    return null;
  }

  /// Live-Ranking nach Gramm reinem Alkohol (absteigend).
  List<LeaderboardEntry> get leaderboard {
    final stats = <String, LeaderboardEntry>{
      for (final m in members) m.id: LeaderboardEntry(m),
    };
    for (final d in _drinks) {
      final entry = stats[d.profileId];
      if (entry != null) {
        entry.totalAlcoholGrams += d.alcoholG;
        entry.totalDrinksCount += 1;
        entry.totalBeerLiters += d.beerLiters;
      }
    }
    final list = stats.values.toList();
    // List.sort ist nicht stabil -> Index als Tiebreaker (wie Array.sort in JS).
    final indexed = list.asMap().entries.toList()
      ..sort((a, b) {
        final c = b.value.totalAlcoholGrams.compareTo(
          a.value.totalAlcoholGrams,
        );
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    final sorted = indexed.map((e) => e.value).toList();
    for (var i = 0; i < sorted.length; i++) {
      sorted[i].rank = i + 1;
    }
    return sorted;
  }

  // --- Laden & Realtime ---

  Future<void> init() async {
    await refresh();
    _subscribe();
  }

  /// Laedt Party, Drinks und Reaktionen neu.
  Future<void> refresh() async {
    try {
      _party = await api.getParty(partyId);
      final results = await Future.wait([
        api.getPartyDrinks(partyId),
        api.getPartyReactions(partyId),
      ]);
      _drinks = results[0] as List<Drink>;
      _reactions = results[1] as List<Reaction>;
      _error = null;
    } catch (e) {
      debugPrint('Fehler beim Laden der Party: $e');
      _error = e.toString();
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> _refreshDrinks() async {
    try {
      _drinks = await api.getPartyDrinks(partyId);
      _notify();
    } catch (e) {
      debugPrint('Drinks-Refresh fehlgeschlagen: $e');
    }
  }

  Future<void> _refreshReactions() async {
    try {
      _reactions = await api.getPartyReactions(partyId);
      _notify();
    } catch (e) {
      debugPrint('Reaktionen-Refresh fehlgeschlagen: $e');
    }
  }

  void _subscribe() {
    _unsubscribe = api.subscribeToParty(
      partyId,
      onDrinks: _refreshDrinks,
      onMembers: refresh,
      onReactions: _refreshReactions,
      onParty: (record) {
        if (_party != null) {
          _party = _party!.mergeRecord(record);
          _notify();
        }
      },
    );
  }

  // --- Aktionen ---

  Future<void> join() async {
    await api.joinParty(partyId, me.id);
    await refresh();
  }

  Future<List<Drink>> logDrink({
    List<String>? profileIds,
    required DrinkInput drink,
    DateTime? createdAt,
  }) async {
    final targets = (profileIds == null || profileIds.isEmpty)
        ? [me.id]
        : profileIds;
    final logged = await api.logDrinksBatch(
      partyId: partyId,
      profileIds: targets,
      loggedBy: me.id,
      drink: drink,
      createdAt: createdAt,
    );
    _drinks = [...logged, ..._drinks];
    _notify();
    return logged;
  }

  Future<void> deleteDrink(String drinkId) async {
    await api.deleteDrink(drinkId);
    _drinks = _drinks.where((d) => d.id != drinkId).toList();
    _notify();
  }

  Future<void> toggleReaction(String drinkId, String emoji) async {
    await api.toggleReaction(drinkId: drinkId, profileId: me.id, emoji: emoji);
    // Realtime liefert das ebenfalls; lokales Nachladen haelt die UI auch bei
    // verzoegertem Event aktuell.
    await _refreshReactions();
  }

  Future<void> addGuest({
    required String name,
    required String emoji,
    required String color,
  }) async {
    await api.addGuestToParty(
      partyId: partyId,
      name: name,
      emoji: emoji,
      color: color,
    );
    await refresh();
  }

  Future<void> endParty() async {
    await api.endParty(partyId, me.id);
    if (_party != null) {
      _party = _party!.copyWith(endedAt: DateTime.now());
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _unsubscribe?.call();
    super.dispose();
  }
}
