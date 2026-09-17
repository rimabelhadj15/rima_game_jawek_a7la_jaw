import 'dart:math';
import '../models/card_model.dart';

class Deck {
  static List<GameCard> buildShuffled({int? seed}) {
    final cards = <GameCard>[];
    for (final suit in Suit.values) {
      for (var rank = 1; rank <= 10; rank++) {
        cards.add(GameCard(suit: suit, rank: rank));
      }
    }
    cards.shuffle(seed != null ? Random(seed) : Random());
    return cards;
  }
}
