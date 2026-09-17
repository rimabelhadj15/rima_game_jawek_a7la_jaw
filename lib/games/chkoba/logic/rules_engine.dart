import '../models/card_model.dart';
import '../models/chkoba_state.dart';
import 'deck.dart';
import 'scoring.dart';

class CaptureOption {
  final List<GameCard> cards; // table cards being captured (not including the played card)
  const CaptureOption(this.cards);
}

class MoveResult {
  final ChkobaState state;
  final String? error;
  const MoveResult(this.state, {this.error});
}

class ChkobaEngine {
  /// Start a brand new game: shuffle deck, deal 4 to table, 3 to each player.
  static ChkobaState newGame(List<String> playerIds, Map<String, String> playerNames) {
    final deck = Deck.buildShuffled();
    final table = <GameCard>[];
    for (var i = 0; i < 4; i++) {
      table.add(deck.removeLast());
    }
    final hands = <String, List<GameCard>>{};
    for (final id in playerIds) {
      hands[id] = List.generate(3, (_) => deck.removeLast());
    }
    return ChkobaState(
      playerIds: playerIds,
      playerNames: playerNames,
      hands: hands,
      tableCards: table,
      deck: deck,
      capturedPiles: {for (final id in playerIds) id: <GameCard>[]},
      chkobaCounts: {for (final id in playerIds) id: 0},
      currentPlayerIndex: 0,
      statusMessage: 'Game started',
    );
  }

  /// All valid ways `played` could capture from `table`.
  /// Rule: if any single card on the table matches the played rank exactly,
  /// only single-card captures are allowed (must pick one of them).
  /// Otherwise, any subset of table cards summing to the played rank is valid.
  static List<CaptureOption> possibleCaptures(GameCard played, List<GameCard> table) {
    final singleMatches = table.where((c) => c.rank == played.rank).toList();
    if (singleMatches.isNotEmpty) {
      return singleMatches.map((c) => CaptureOption([c])).toList();
    }

    final options = <CaptureOption>[];
    final n = table.length;
    // brute-force subsets (table is small, max ~13 cards in practice)
    for (var mask = 1; mask < (1 << n); mask++) {
      var sum = 0;
      final combo = <GameCard>[];
      for (var i = 0; i < n; i++) {
        if ((mask & (1 << i)) != 0) {
          sum += table[i].rank;
          combo.add(table[i]);
        }
      }
      if (sum == played.rank && combo.length > 1) {
        options.add(CaptureOption(combo));
      }
    }
    return options;
  }

  /// Apply a move: [playerId] plays [card] from their hand.
  /// If there are multiple valid capture options, [chosenCaptureCardIds]
  /// must specify which table cards (by id) to capture. If null and exactly
  /// one option (or zero) exists, it's resolved automatically.
  static MoveResult playCard(
    ChkobaState state,
    String playerId,
    GameCard card, {
    List<String>? chosenCaptureCardIds,
  }) {
    if (state.gameOver) return MoveResult(state, error: 'Game already over');
    if (state.currentPlayerId != playerId) return MoveResult(state, error: 'Not your turn');

    final hand = state.hands[playerId];
    if (hand == null || !hand.any((c) => c.id == card.id)) {
      return MoveResult(state, error: 'Card not in hand');
    }

    final newState = state.copy();
    final newHand = newState.hands[playerId]!;
    newHand.removeWhere((c) => c.id == card.id);

    final options = possibleCaptures(card, newState.tableCards);
    List<GameCard>? chosen;

    if (options.isEmpty) {
      // no capture -> card joins the table
      newState.tableCards.add(card);
    } else if (options.length == 1) {
      chosen = options.first.cards;
    } else {
      if (chosenCaptureCardIds == null) {
        return MoveResult(state, error: 'Multiple capture options - must choose one');
      }
      final match = options.firstWhere(
        (o) => o.cards.map((c) => c.id).toSet().containsAll(chosenCaptureCardIds) &&
            chosenCaptureCardIds.length == o.cards.length,
        orElse: () => const CaptureOption([]),
      );
      if (match.cards.isEmpty) {
        return MoveResult(state, error: 'Invalid capture choice');
      }
      chosen = match.cards;
    }

    if (chosen != null) {
      final pile = newState.capturedPiles[playerId]!;
      pile.add(card);
      pile.addAll(chosen);
      final capturedIds = chosen.map((c) => c.id).toSet();
      newState.tableCards.removeWhere((c) => capturedIds.contains(c.id));
      newState.lastCapturerId = playerId;
      if (newState.tableCards.isEmpty && newState.deck.isNotEmpty) {
        // clearing the table mid-deck is a "chkoba" bonus
        newState.chkobaCounts[playerId] = (newState.chkobaCounts[playerId] ?? 0) + 1;
        newState.statusMessage = '${newState.playerNames[playerId]} scored a CHKOBA!';
      } else {
        newState.statusMessage = '${newState.playerNames[playerId]} captured ${chosen.length + 1} card(s)';
      }
    } else {
      newState.statusMessage = '${newState.playerNames[playerId]} played ${card.displayRank}${card.suitSymbol}';
    }

    _advanceTurnAndRedeal(newState);
    return MoveResult(newState);
  }

  static void _advanceTurnAndRedeal(ChkobaState state) {
    final allHandsEmpty = state.hands.values.every((h) => h.isEmpty);

    if (allHandsEmpty) {
      if (state.deck.isNotEmpty) {
        for (final id in state.playerIds) {
          final n = state.deck.length >= 3 ? 3 : state.deck.length;
          for (var i = 0; i < n; i++) {
            state.hands[id]!.add(state.deck.removeLast());
          }
        }
      } else {
        // game over: remaining table cards go to whoever captured last
        if (state.tableCards.isNotEmpty && state.lastCapturerId != null) {
          state.capturedPiles[state.lastCapturerId]!.addAll(state.tableCards);
          state.tableCards = [];
        }
        state.gameOver = true;
        state.finalScores = Scoring.computeFinalScores(state);
        state.statusMessage = 'Game over!';
        return;
      }
    }

    state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.playerIds.length;
  }
}
