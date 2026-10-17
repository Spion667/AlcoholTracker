import 'package:alcohol_tracker/models/drink.dart';
import 'package:alcohol_tracker/models/profile.dart';
import 'package:alcohol_tracker/services/demo_api.dart';
import 'package:alcohol_tracker/state/party_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoApi api;
  late Profile lukas;

  setUp(() async {
    api = DemoApi();
    lukas = (await api.getProfile('demo-lukas'))!;
  });

  Future<PartyController> open(String id, Profile me) async {
    final c = PartyController(partyId: id, me: me, api: api);
    await c.init();
    addTearDown(c.dispose);
    return c;
  }

  test('loads party, members and ranks them by pure alcohol', () async {
    final c = await open('demo-wg', lukas);

    expect(c.loading, isFalse);
    expect(c.party?.name, 'WG-Abend');
    expect(c.members, hasLength(4));
    expect(c.isMember, isTrue);
    expect(c.isHost, isTrue);

    final board = c.leaderboard;
    expect(board.map((e) => e.rank), [1, 2, 3, 4]);
    for (var i = 1; i < board.length; i++) {
      expect(
        board[i - 1].totalAlcoholGrams,
        greaterThanOrEqualTo(board[i].totalAlcoholGrams),
      );
    }
    expect(c.totalPartyAlcoholGrams, greaterThan(0));
    expect(c.lastDrinkOfUser?.profileId, 'demo-lukas');
  });

  test(
    'logging a round creates one drink per person with a shared round id',
    () async {
      final c = await open('demo-wg', lukas);
      final before = c.totalPartyDrinks;

      final logged = await c.logDrink(
        profileIds: ['demo-lukas', 'demo-hannes', 'demo-sarah'],
        drink: const DrinkInput(
          key: 'beer_500',
          name: 'Bier 0,5L',
          category: 'beer',
          volume: 500,
          abv: 5,
          beerFactor: 1,
        ),
      );

      expect(logged, hasLength(3));
      expect(logged.map((d) => d.roundId).toSet(), hasLength(1));
      expect(logged.first.roundId, isNotNull);
      expect(logged.every((d) => d.loggedBy == 'demo-lukas'), isTrue);
      expect(logged.first.alcoholG, 19.7);
      expect(c.totalPartyDrinks, before + 3);
    },
  );

  test('undo removes the drinks again', () async {
    final c = await open('demo-wg', lukas);
    final logged = await c.logDrink(
      drink: const DrinkInput(
        key: 'custom',
        name: 'Test',
        volume: 100,
        abv: 10,
      ),
    );
    final count = c.totalPartyDrinks;
    await c.deleteDrink(logged.single.id);
    expect(c.totalPartyDrinks, count - 1);
  });

  test(
    'realtime: drinks logged by someone else show up without a manual refresh',
    () async {
      final c = await open('demo-wg', lukas);
      final before = c.totalPartyDrinks;

      await api.logDrinksBatch(
        partyId: 'demo-wg',
        profileIds: ['demo-hannes'],
        loggedBy: 'demo-hannes',
        drink: const DrinkInput(
          key: 'custom',
          name: 'Shot',
          volume: 40,
          abv: 40,
        ),
      );
      // Der Realtime-Handler laedt asynchron nach.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(c.totalPartyDrinks, before + 1);
    },
  );

  test(
    'only the host can end the party; the update arrives via realtime',
    () async {
      final hannes = (await api.getProfile('demo-hannes'))!;
      final guestView = await open('demo-wg', hannes);
      expect(guestView.isHost, isFalse);
      await guestView.endParty(); // kein Host -> Backend verweigert
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final hostView = await open('demo-wg', lukas);
      expect(hostView.isEnded, isFalse);
      await hostView.endParty();
      expect(hostView.isEnded, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(guestView.isEnded, isTrue);
    },
  );

  test('toggling a reaction adds and removes it', () async {
    final c = await open('demo-wg', lukas);
    final drinkId = c.drinks.last.id;
    final before = c.reactions.length;

    await c.toggleReaction(drinkId, '🔥');
    expect(c.reactions.length, before + 1);
    expect(
      c.reactions.any((r) => r.drinkId == drinkId && r.profileId == lukas.id),
      isTrue,
    );

    await c.toggleReaction(drinkId, '🔥');
    expect(c.reactions.length, before);
  });

  test('unknown party ends in an error state without crashing', () async {
    final c = await open('does-not-exist', lukas);
    expect(c.loading, isFalse);
    expect(c.party, isNull);
    expect(c.error, isNotNull);
  });
}
