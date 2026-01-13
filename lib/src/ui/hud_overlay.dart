import 'package:flutter/material.dart';

import '../game/card.dart';
import '../game/game_engine.dart';
import '../ui/ui_mode.dart';

class HudOverlay extends StatelessWidget {
  static const overlayId = 'hud';
  final BoardGame game;

  const HudOverlay({super.key, required this.game});

  bool get _showSevenUx {
    return game.selectedCard?.type == CardType.seven || game.inSevenMode;
  }

  bool get _showFourUx {
    return game.selectedCard?.type == CardType.four && !game.inSevenMode;
  }

  @override
  Widget build(BuildContext context) {
    final p = game.turnManager.currentPlayer;
    final hand = game.hands[p] ?? const [];
    final selected = game.selectedCard;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isMobile = game.uiMode == UiMode.mobile;

    // ======================
    // Seven controls
    // ======================
    Widget sevenControlsInline() {
      if (!_showSevenUx) return const SizedBox.shrink();

      final stepsLeft = game.inSevenMode ? game.sevenRemainingSteps : 7;

      if (isMobile) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Seven — $stepsLeft step(s)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (game.inSevenMode && game.canUndoSeven)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.undo),
                        label: const Text('UNDO'),
                        onPressed: game.undoSevenStep,
                      ),
                    ),
                  if (game.inSevenMode && game.canUndoSeven)
                    const SizedBox(width: 12),
                  if (game.inSevenMode)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('ABORT'),
                        onPressed: game.abortSeven,
                      ),
                    ),
                ],
              ),
              if (!game.inSevenMode)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Tap one of your track pieces to begin.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        );
      }

      // Desktop
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              game.inSevenMode
                  ? '7 steps left: ${game.sevenRemainingSteps}'
                  : '7 selected',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            if (game.inSevenMode && game.canUndoSeven)
              IconButton(
                tooltip: 'Undo',
                icon: const Icon(Icons.undo, color: Colors.white),
                onPressed: game.undoSevenStep,
              ),
            if (game.inSevenMode)
              IconButton(
                tooltip: 'Abort',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: game.abortSeven,
              ),
          ],
        ),
      );
    }

    // ======================
    // Card 4 controls
    // ======================
    Widget fourControlsInline() {
      if (!_showFourUx) return const SizedBox.shrink();

      if (isMobile) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Four — choose direction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            game.fourDirection == FourDirection.backward
                                ? Colors.amber
                                : Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () =>
                          game.setFourDirection(FourDirection.backward),
                      child: const Text('← BACK'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            game.fourDirection == FourDirection.forward
                                ? Colors.amber
                                : Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () =>
                          game.setFourDirection(FourDirection.forward),
                      child: const Text('FORWARD →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      // Desktop
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Text(
              '4 direction:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Back'),
              selected:
                  game.fourDirection == FourDirection.backward,
              onSelected: (_) =>
                  game.setFourDirection(FourDirection.backward),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Forward'),
              selected:
                  game.fourDirection == FourDirection.forward,
              onSelected: (_) =>
                  game.setFourDirection(FourDirection.forward),
            ),
          ],
        ),
      );
    }

    // ======================
    // Hand strip
    // ======================
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
                    : _showSevenUx
                        ? 'Seven'
                        : _showFourUx
                            ? 'Four'
                            : 'Player ${p + 1} hand',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (selected != null && !game.inSevenMode)
                Text(
                  'Selected: ${selected.display()}',
                  style: const TextStyle(color: Colors.white),
                ),
              const SizedBox(width: 12),
            ],
          ),
          sevenControlsInline(),
          fourControlsInline(),
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
                    width: isMobile ? 84 : 76,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.amber : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      c.display(),
                      style: TextStyle(
                        fontSize: isMobile ? 30 : 28,
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

    // ======================
    // Layout
    // ======================
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
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: game.forceNextTurnForTesting,
                  child: const Text('Next Turn'),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<DebugHandPreset>(
                  tooltip: 'Debug hand presets',
                  onSelected: game.debugApplyPreset,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: DebugHandPreset.sevenTest,
                      child: Text('Seven test'),
                    ),
                    PopupMenuItem(
                      value: DebugHandPreset.jackTest,
                      child: Text('Jack test'),
                    ),
                    PopupMenuItem(
                      value: DebugHandPreset.jokerTest,
                      child: Text('Joker test'),
                    ),
                    PopupMenuItem(
                      value: DebugHandPreset.mixed,
                      child: Text('Mixed'),
                    ),
                  ],
                  child:
                      const Icon(Icons.bug_report, color: Colors.white),
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
