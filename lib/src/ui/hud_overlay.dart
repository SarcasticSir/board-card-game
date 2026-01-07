import 'package:flutter/material.dart';
import '../game/game_engine.dart';

class HudOverlay extends StatelessWidget {
  static const overlayId = 'hud';
  final BoardGame game;

  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final p = game.turnManager.currentPlayer;
    final hand = game.hands[p] ?? const [];
    final selected = game.selectedCard;
    final isWide = MediaQuery.of(context).size.width >= 900;

    Widget sevenStatus() {
      if (!game.inSevenMode) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              '7 steps left: ${game.sevenRemainingSteps}',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            if (game.canUndoSeven)
              IconButton(
                tooltip: 'Undo',
                icon: const Icon(Icons.undo),
                onPressed: game.undoSevenStep,
              ),
            IconButton(
              tooltip: 'Abort',
              icon: const Icon(Icons.close),
              onPressed: game.abortSeven,
            ),
          ],
        ),
      );
    }

    Widget handStrip() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Text(
                game.inSwapPhaseActive
                    ? 'Swap a card with teammate'
                    : game.inSevenMode
                        ? '7 active: tap pieces to move'
                        : 'Player ${p + 1} hand',
              ),
              const Spacer(),
              if (selected != null && !game.inSevenMode)
                Text('Selected: ${selected.display()}'),
              const SizedBox(width: 12),
            ],
          ),
          sevenStatus(),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hand.length,
              itemBuilder: (_, i) {
                final c = hand[i];
                final isSel = identical(c, selected);

                return GestureDetector(
                  onTap: () {
                    if (game.inSevenMode) return;

                    if (game.inSwapPhaseActive) {
                      game.submitSwapCard(c);
                    } else {
                      game.selectCard(c);
                    }
                  },
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.amber : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.display(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Text(
                  'Turn: P${p + 1} | Cards: ${game.roundManager.cardsPerPlayer}',
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: game.forceNextTurnForTesting,
                  child: const Text('Next Turn'),
                ),
              ],
            ),
          ),
          if (!isWide)
            Positioned(left: 0, right: 0, bottom: 0, child: handStrip())
          else
            Positioned(
              right: 0,
              top: 90,
              bottom: 0,
              width: 320,
              child: handStrip(),
            ),
        ],
      ),
    );
  }
}
