import 'package:alcohol_tracker/models/drink.dart';

Drink testDrink({
  String id = 'd',
  String profileId = 'u1',
  String? loggedBy,
  String? roundId,
  String category = 'other',
  double alcoholG = 0,
  double beerLiters = 0,
  double volumeMl = 0,
  String name = 'Test',
  required DateTime createdAt,
}) => Drink(
  id: id,
  partyId: 'p',
  profileId: profileId,
  loggedBy: loggedBy,
  roundId: roundId,
  name: name,
  category: category,
  alcoholG: alcoholG,
  beerLiters: beerLiters,
  volumeMl: volumeMl,
  createdAt: createdAt,
);
