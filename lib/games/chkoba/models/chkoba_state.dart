import 'card_model.dart';

class ChkobaState {
  List<String> playerIds;
  Map<String, String> playerNames;
  Map<String, List<GameCard>> hands;
  List<GameCard> tableCards;
  List<GameCard> deck;
  Map<String, List<GameCard>> capturedPiles;
  Map<String, int> chkobaCounts;
  int currentPlayerIndex;
  String? lastCapturerId;
  bool gameOver;
  Map<String, int>? finalScores;
  String? statusMessage;

  ChkobaState({
    required this.playerIds,
    required this.playerNames,
    required this.hands,
    required this.tableCards,
    required this.deck,
    required this.capturedPiles,
    required this.chkobaCounts,
    required this.currentPlayerIndex,
    this.lastCapturerId,
    this.gameOver = false,
    this.finalScores,
    this.statusMessage,
  });

  String get currentPlayerId => playerIds[currentPlayerIndex];

  ChkobaState copy() => ChkobaState.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'playerIds': playerIds,
        'playerNames': playerNames,
        'hands': hands.map((k, v) => MapEntry(k, v.map((c) => c.toJson()).toList())),
        'tableCards': tableCards.map((c) => c.toJson()).toList(),
        'deck': deck.map((c) => c.toJson()).toList(),
        'capturedPiles': capturedPiles.map((k, v) => MapEntry(k, v.map((c) => c.toJson()).toList())),
        'chkobaCounts': chkobaCounts,
        'currentPlayerIndex': currentPlayerIndex,
        'lastCapturerId': lastCapturerId,
        'gameOver': gameOver,
        'finalScores': finalScores,
        'statusMessage': statusMessage,
      };

  factory ChkobaState.fromJson(Map<String, dynamic> json) {
    List<GameCard> cardList(dynamic raw) =>
        (raw as List).map((c) => GameCard.fromJson(Map<String, dynamic>.from(c))).toList();

    Map<String, List<GameCard>> cardMap(dynamic raw) => (raw as Map).map(
          (k, v) => MapEntry(k as String, cardList(v)),
        );

    return ChkobaState(
      playerIds: List<String>.from(json['playerIds']),
      playerNames: Map<String, String>.from(json['playerNames']),
      hands: cardMap(json['hands']),
      tableCards: cardList(json['tableCards']),
      deck: cardList(json['deck']),
      capturedPiles: cardMap(json['capturedPiles']),
      chkobaCounts: Map<String, int>.from(json['chkobaCounts']),
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      lastCapturerId: json['lastCapturerId'] as String?,
      gameOver: json['gameOver'] as bool? ?? false,
      finalScores: json['finalScores'] != null ? Map<String, int>.from(json['finalScores']) : null,
      statusMessage: json['statusMessage'] as String?,
    );
  }
}
