import 'package:flutter/material.dart';
import '../models/chkoba_state.dart';

class ScoreDialog extends StatelessWidget {
  final ChkobaState state;
  final VoidCallback onClose;

  const ScoreDialog({super.key, required this.state, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scores = state.finalScores ?? {};
    final sorted = state.playerIds.toList()
      ..sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));

    return AlertDialog(
      backgroundColor: const Color(0xFF123D26),
      title: const Text('Final Score', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: sorted.map((id) {
          final name = state.playerNames[id] ?? id;
          final score = scores[id] ?? 0;
          final cards = state.capturedPiles[id]?.length ?? 0;
          final chkobas = state.chkobaCounts[id] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  '$score pts  ($cards cards, $chkobas chkoba)',
                  style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(onPressed: onClose, child: const Text('Close')),
      ],
    );
  }
}
