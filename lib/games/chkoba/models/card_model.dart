enum Suit { diamonds, hearts, clubs, spades }

/// A single Chkoba card. Rank goes 1-7, then 8=Jack, 9=Queen, 10=King
/// (the 8, 9, 10 pip cards are removed from a standard deck, 40 cards total).
class GameCard {
  final Suit suit;
  final int rank; // 1-10, capture/value is always == rank

  const GameCard({required this.suit, required this.rank});

  String get id => '${suit.name}_$rank';

  int get value => rank;

  bool get isDiamond => suit == Suit.diamonds;

  bool get isSeven => rank == 7;

  bool get isSevenOfDiamonds => isSeven && isDiamond;

  String get displayRank {
    switch (rank) {
      case 8:
        return 'J';
      case 9:
        return 'Q';
      case 10:
        return 'K';
      default:
        return rank.toString();
    }
  }

  String get suitSymbol {
    switch (suit) {
      case Suit.diamonds:
        return '♦';
      case Suit.hearts:
        return '♥';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  bool get isRed => suit == Suit.diamonds || suit == Suit.hearts;

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank};

  factory GameCard.fromJson(Map<String, dynamic> json) => GameCard(
        suit: Suit.values.firstWhere((s) => s.name == json['suit']),
        rank: json['rank'] as int,
      );

  @override
  bool operator ==(Object other) => other is GameCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
