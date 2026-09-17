import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/card_model.dart';
import '../logic/rules_engine.dart';
import '../providers/chkoba_provider.dart';
import 'card_widget.dart';
import 'score_dialog.dart';

class GameTableScreen extends ConsumerStatefulWidget {
  const GameTableScreen({super.key});

  @override
  ConsumerState<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends ConsumerState<GameTableScreen> {
  bool _scoreDialogShown = false;

  Future<void> _onPlayCard(GameCard card) async {
    final state = ref.read(chkobaStateProvider)!;
    final options = ChkobaEngine.possibleCaptures(card, state.tableCards);

    if (options.length <= 1) {
      ref.read(gameManagerProvider).playCard(
            card,
            chosenCaptureCardIds: options.isEmpty ? null : options.first.cards.map((c) => c.id).toList(),
          );
      return;
    }

    final chosen = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF123D26),
        title: const Text('Choose a capture', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: options.map((opt) {
              return ListTile(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: opt.cards.map((c) => CardWidget(card: c, width: 40)).toList(),
                ),
                onTap: () => Navigator.pop(context, opt.cards.map((c) => c.id).toList()),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (chosen != null) {
      ref.read(gameManagerProvider).playCard(card, chosenCaptureCardIds: chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chkobaStateProvider);
    final manager = ref.read(gameManagerProvider);

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myId = manager.myPlayerId;
    final myHand = state.hands[myId] ?? [];
    final isMyTurn = state.currentPlayerId == myId;
    final opponents = state.playerIds.where((id) => id != myId).toList();

    if (state.gameOver && !_scoreDialogShown) {
      _scoreDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => ScoreDialog(
            state: state,
            onClose: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isMyTurn ? 'Your turn' : "${state.playerNames[state.currentPlayerId]}'s turn"),
      ),
      body: Column(
        children: [
          // opponents row
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 16,
              children: opponents.map((id) {
                final count = state.hands[id]?.length ?? 0;
                final isTurn = state.currentPlayerId == id;
                return Column(
                  children: [
                    Text(
                      state.playerNames[id] ?? id,
                      style: TextStyle(
                        color: isTurn ? AppTheme.gold : Colors.white70,
                        fontWeight: isTurn ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        count,
                        (_) => const CardWidget(card: GameCard(suit: Suit.spades, rank: 1), faceDown: true, width: 30),
                      ),
                    ),
                    Text('Captured: ${state.capturedPiles[id]?.length ?? 0}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ),

          if (state.statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(state.statusMessage!, style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
            ),

          // table cards
          Expanded(
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: state.tableCards.map((c) => CardWidget(card: c, width: 55)).toList(),
              ),
            ),
          ),

          // my hand
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  isMyTurn ? 'Tap a card to play' : 'Waiting...',
                  style: TextStyle(color: isMyTurn ? AppTheme.gold : Colors.white38),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: myHand
                      .map((c) => CardWidget(
                            card: c,
                            width: 60,
                            onTap: isMyTurn ? () => _onPlayCard(c) : null,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
