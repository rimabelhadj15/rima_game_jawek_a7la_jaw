import '../models/chkoba_state.dart';

class Scoring {
  /// Classic Chkoba/Chkobba scoring:
  /// +1 most cards captured, +1 most diamonds captured,
  /// +1 for holding the seven of diamonds, +1 most sevens captured,
  /// plus 1 point per "chkoba" (table clear) already tracked in chkobaCounts.
  /// Ties on a category award no point to anyone.
  static Map<String, int> computeFinalScores(ChkobaState state) {
    final scores = {for (final id in state.playerIds) id: 0};

    void awardMax(Map<String, int> tally) {
      if (tally.isEmpty) return;
      final maxVal = tally.values.reduce((a, b) => a > b ? a : b);
      if (maxVal <= 0) return;
      final winners = tally.entries.where((e) => e.value == maxVal).toList();
      if (winners.length == 1) {
        scores[winners.first.key] = (scores[winners.first.key] ?? 0) + 1;
      }
    }

    final cardCounts = {for (final id in state.playerIds) id: state.capturedPiles[id]!.length};
    awardMax(cardCounts);

    final diamondCounts = {
      for (final id in state.playerIds) id: state.capturedPiles[id]!.where((c) => c.isDiamond).length
    };
    awardMax(diamondCounts);

    final sevenCounts = {
      for (final id in state.playerIds) id: state.capturedPiles[id]!.where((c) => c.isSeven).length
    };
    awardMax(sevenCounts);

    for (final id in state.playerIds) {
      if (state.capturedPiles[id]!.any((c) => c.isSevenOfDiamonds)) {
        scores[id] = (scores[id] ?? 0) + 1;
      }
    }

    for (final id in state.playerIds) {
      scores[id] = (scores[id] ?? 0) + (state.chkobaCounts[id] ?? 0);
    }

    return scores;
  }
}
