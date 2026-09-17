import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardWidget extends StatelessWidget {
  final GameCard card;
  final bool selected;
  final bool faceDown;
  final double width;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    this.selected = false,
    this.faceDown = false,
    this.width = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = width * 1.45;
    if (faceDown) {
      return Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2A6F97),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white70, width: 1.5),
        ),
        child: const Center(
          child: Icon(Icons.diamond, color: Colors.white24, size: 20),
        ),
      );
    }

    final color = card.isRed ? Colors.red.shade600 : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        transform: selected ? (Matrix4.identity()..translate(0.0, -12.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFFD4AF37) : Colors.black26, width: selected ? 2.5 : 1),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 2))],
        ),
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 2,
              child: Text(
                card.displayRank,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: width * 0.24),
              ),
            ),
            Center(
              child: Text(
                card.suitSymbol,
                style: TextStyle(color: color, fontSize: width * 0.4),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 2,
              child: Transform.rotate(
                angle: 3.14159,
                child: Text(
                  card.displayRank,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: width * 0.24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
