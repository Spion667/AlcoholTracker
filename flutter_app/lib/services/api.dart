import '../models/drink.dart';
import '../models/party.dart';
import '../models/profile.dart';

/// Abbestellen eines Realtime-Abos.
typedef Unsubscribe = void Function();

/// Backend-Schnittstelle der App (Spiegel von `src/lib/api.js`).
///
/// Produktiv implementiert durch `SupabaseApi`; `DemoApi` ist eine In-Memory-
/// Variante fuer Demo-Modus und Tests.
abstract class Api {
  // --- Profiles ---
  Future<Profile?> getProfile(String? id);

  Future<Profile> createProfile({
    required String name,
    String emoji = '😎',
    String color = '#C6FF3D',
    bool isGuest = false,
  });

  Future<Profile> updateProfile(String id, Map<String, dynamic> updates);

  // --- Parties ---
  Future<List<Party>> listActiveParties();

  Future<List<Party>> listPastParties(String? profileId);

  Future<Party> getParty(String id);

  /// Speichert den freiwillig geteilten Promillewert (`null` = nicht teilen).
  Future<void> updateMemberBac(
    String? partyId,
    String? profileId,
    double? currentBac,
  );

  Future<Party> createParty({
    required String name,
    String emoji = '🎉',
    String? hostId,
    String? symbolCode,
  });

  Future<void> joinParty(String partyId, String profileId);

  Future<Profile> addGuestToParty({
    required String partyId,
    required String name,
    String emoji = '👤',
    String color = '#8B5CF6',
  });

  Future<bool> endParty(String partyId, String requesterId);

  // --- Drinks ---
  Future<List<Drink>> getPartyDrinks(String partyId);

  Future<List<Drink>> logDrinksBatch({
    required String partyId,
    required List<String> profileIds,
    required String loggedBy,
    required DrinkInput drink,
    DateTime? createdAt,
  });

  Future<void> deleteDrink(String drinkId);

  // --- Reactions ---
  Future<List<Reaction>> getPartyReactions(String partyId);

  /// Schaltet eine Reaktion um. `true` = hinzugefuegt, `false` = entfernt.
  Future<bool> toggleReaction({
    required String drinkId,
    required String profileId,
    required String emoji,
  });

  // --- Full Party (Wrapped) ---
  Future<PartyFull> getPartyFull(String partyId) async {
    final party = await getParty(partyId);
    final drinks = await getPartyDrinks(partyId);
    final reactions = await getPartyReactions(partyId);
    return PartyFull(party: party, drinks: drinks, reactions: reactions);
  }

  // --- Realtime ---
  Unsubscribe subscribeToParty(
    String partyId, {
    required void Function() onDrinks,
    required void Function() onMembers,
    required void Function() onReactions,
    required void Function(Map<String, dynamic> record) onParty,
  });
}

class PartyFull {
  const PartyFull({
    required this.party,
    required this.drinks,
    required this.reactions,
  });

  final Party party;
  final List<Drink> drinks;
  final List<Reaction> reactions;

  List<Profile> get members => party.members.map((m) => m.profile).toList();
}
