import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/drink.dart';
import '../models/party.dart';
import '../models/profile.dart';
import '../utils/drinks.dart';
import 'api.dart';

/// Supabase-Zugriffsschicht, Spiegel von `src/lib/api.js`.
class SupabaseApi implements Api {
  SupabaseApi(this.client);

  final SupabaseClient client;

  static const _uuid = Uuid();

  // --- Profiles ---

  @override
  Future<Profile?> getProfile(String? id) async {
    if (id == null || id.isEmpty) return null;
    final data = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data == null ? null : Profile.fromJson(data);
  }

  @override
  Future<Profile> createProfile({
    required String name,
    String emoji = '😎',
    String color = '#C6FF3D',
    bool isGuest = false,
  }) async {
    final data = await client
        .from('profiles')
        .insert({
          'name': name.trim(),
          'emoji': emoji,
          'color': color,
          'is_guest': isGuest,
        })
        .select()
        .single();
    return Profile.fromJson(data);
  }

  @override
  Future<Profile> updateProfile(String id, Map<String, dynamic> updates) async {
    final data = await client
        .from('profiles')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Profile.fromJson(data);
  }

  // --- Parties ---

  @override
  Future<List<Party>> listActiveParties() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final data = await client
        .from('parties')
        .select('''
          id, name, emoji, host_id, created_at, ends_at, ended_at, symbol_code,
          party_members ( profile_id, profiles ( id, name, emoji, color ) )
        ''')
        .isFilter('ended_at', null)
        .gt('ends_at', nowIso)
        .order('created_at', ascending: false);
    return data.map(Party.fromJson).toList();
  }

  @override
  Future<List<Party>> listPastParties(String? profileId) async {
    if (profileId == null || profileId.isEmpty) return [];
    final data = await client
        .from('party_members')
        .select('''
          party_id, joined_at,
          parties ( id, name, emoji, created_at, ends_at, ended_at, host_id, symbol_code )
        ''')
        .eq('profile_id', profileId)
        .order('joined_at', ascending: false);

    return [
      for (final row in data)
        if (row['parties'] is Map<String, dynamic>)
          Party.fromJson(row['parties'] as Map<String, dynamic>),
    ];
  }

  @override
  Future<Party> getParty(String id) async {
    final data = await client
        .from('parties')
        .select('''
          id, name, emoji, host_id, created_at, ends_at, ended_at, symbol_code,
          party_members ( *, profiles ( id, name, emoji, color, is_guest ) )
        ''')
        .eq('id', id)
        .single();
    return Party.fromJson(data);
  }

  /// Speichert den freiwillig geteilten Promillewert (`null` = nicht teilen).
  /// Schlaegt still fehl, falls Migration 004 noch nicht eingespielt wurde.
  @override
  Future<void> updateMemberBac(
    String? partyId,
    String? profileId,
    double? currentBac,
  ) async {
    if (partyId == null || profileId == null) return;
    try {
      await client
          .from('party_members')
          .update({'current_bac': currentBac})
          .eq('party_id', partyId)
          .eq('profile_id', profileId);
    } catch (_) {
      // BAC-Sync ist optional (Migration 004 evtl. noch nicht ausgefuehrt).
    }
  }

  @override
  Future<Party> createParty({
    required String name,
    String emoji = '🎉',
    String? hostId,
    String? symbolCode,
  }) async {
    final data = await client
        .from('parties')
        .insert({
          'name': name.trim(),
          'emoji': emoji,
          'host_id': hostId,
          'symbol_code': (symbolCode == null || symbolCode.isEmpty)
              ? null
              : symbolCode,
        })
        .select()
        .single();

    final party = Party.fromJson(data);

    // Host tritt der Party automatisch bei.
    if (hostId != null) {
      await client.from('party_members').insert({
        'party_id': party.id,
        'profile_id': hostId,
      });
    }
    return party;
  }

  @override
  Future<void> joinParty(String partyId, String profileId) async {
    await client.from('party_members').upsert({
      'party_id': partyId,
      'profile_id': profileId,
    }).select();
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
    final data = await client.rpc(
      'end_party',
      params: {'p_party_id': partyId, 'p_requester_id': requesterId},
    );
    return data == true;
  }

  // --- Drinks ---

  @override
  Future<List<Drink>> getPartyDrinks(String partyId) async {
    final data = await client
        .from('drinks')
        .select()
        .eq('party_id', partyId)
        .order('created_at', ascending: false);
    return data.map(Drink.fromJson).toList();
  }

  @override
  Future<List<Drink>> logDrinksBatch({
    required String partyId,
    required List<String> profileIds,
    required String loggedBy,
    required DrinkInput drink,
    DateTime? createdAt,
  }) async {
    final isRound = profileIds.length > 1;
    final roundId = isRound ? _uuid.v4() : null;
    final alcoholG = calculateAlcoholGrams(drink.volume, drink.abv);
    final beerLiters = calculateBeerLiters(drink.volume, drink.beerFactor);

    final rows = [
      for (final profileId in profileIds)
        {
          'party_id': partyId,
          'profile_id': profileId,
          'logged_by': loggedBy,
          'round_id': roundId,
          'drink_key': drink.key,
          'name': drink.name,
          'icon': drink.icon,
          'category': drink.category,
          'volume_ml': drink.volume,
          'abv': drink.abv,
          'alcohol_g': alcoholG,
          'beer_liters': beerLiters,
          if (createdAt != null)
            'created_at': createdAt.toUtc().toIso8601String(),
        },
    ];

    final data = await client.from('drinks').insert(rows).select();
    return data.map(Drink.fromJson).toList();
  }

  @override
  Future<void> deleteDrink(String drinkId) async {
    await client.from('drinks').delete().eq('id', drinkId);
  }

  // --- Reactions ---

  @override
  Future<List<Reaction>> getPartyReactions(String partyId) async {
    final data = await client
        .from('reactions')
        .select('drink_id, profile_id, emoji, drinks!inner(party_id)')
        .eq('drinks.party_id', partyId);
    return data.map(Reaction.fromJson).toList();
  }

  /// Schaltet eine Reaktion um. Gibt `true` zurueck, wenn sie hinzugefuegt wurde.
  @override
  Future<bool> toggleReaction({
    required String drinkId,
    required String profileId,
    required String emoji,
  }) async {
    final existing = await client
        .from('reactions')
        .select()
        .eq('drink_id', drinkId)
        .eq('profile_id', profileId)
        .eq('emoji', emoji)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('reactions')
          .delete()
          .eq('drink_id', drinkId)
          .eq('profile_id', profileId)
          .eq('emoji', emoji);
      return false;
    }
    await client.from('reactions').insert({
      'drink_id': drinkId,
      'profile_id': profileId,
      'emoji': emoji,
    });
    return true;
  }

  // --- Full Party (Wrapped) ---

  @override
  Future<PartyFull> getPartyFull(String partyId) async {
    final party = await getParty(partyId);
    final drinks = await getPartyDrinks(partyId);
    final reactions = await getPartyReactions(partyId);
    return PartyFull(party: party, drinks: drinks, reactions: reactions);
  }

  @override
  Unsubscribe subscribeToParty(
    String partyId, {
    required void Function() onDrinks,
    required void Function() onMembers,
    required void Function() onReactions,
    required void Function(Map<String, dynamic> record) onParty,
  }) {
    PostgresChangeFilter eq(String column) => PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: column,
      value: partyId,
    );

    final channel = client
        .channel('party-realtime-$partyId')
        // Neue / geloeschte Getraenke
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'drinks',
          filter: eq('party_id'),
          callback: (_) => onDrinks(),
        )
        // Neue Mitglieder
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'party_members',
          filter: eq('party_id'),
          callback: (_) => onMembers(),
        )
        // Party-Statusaenderung (z. B. ended_at)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'parties',
          filter: eq('id'),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) onParty(payload.newRecord);
          },
        )
        // Reaktionen (kein party_id-Filter moeglich, siehe Web-App)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reactions',
          callback: (_) => onReactions(),
        )
        .subscribe();

    return () => client.removeChannel(channel);
  }
}
