import 'card.dart';
import 'piece_component.dart';
import 'rules.dart';

class PlayableMoves {
  final RulesEngine rules;
  PlayableMoves(this.rules);

  bool hasAnyPlayableMove(
    int player,
    List<GameCard> hand,
    List<PieceState> pieces,
  ) {
    for (final card in hand) {
      if (_cardPlayable(player, card, pieces)) return true;
    }
    return false;
  }

  bool _cardPlayable(
    int player,
    GameCard card,
    List<PieceState> pieces,
  ) {
    final own = pieces.where((p) => p.owner == player).toList();

    switch (card.type) {
      case CardType.ace:
      case CardType.king:
        for (final p in own) {
          if (p.zone == PieceZone.nest) return true;
          if (p.zone == PieceZone.track &&
              rules.canMoveSteps(
                p,
                card.type == CardType.king ? 13 : 1,
                forward: true,
              )) {
            return true;
          }
          // Ace can also be 11
          if (card.type == CardType.ace &&
              p.zone == PieceZone.track &&
              rules.canMoveSteps(p, 11, forward: true)) {
            return true;
          }
        }
        return false;

      case CardType.number:
      case CardType.queen:
        final steps = card.type == CardType.queen ? 12 : card.value;
        return own.any(
          (p) => p.zone == PieceZone.track &&
              rules.canMoveSteps(p, steps, forward: true),
        );

      case CardType.four:
        return own.any(
          (p) =>
              p.zone == PieceZone.track &&
              (rules.canMoveSteps(p, 4, forward: true) ||
                  rules.canMoveSteps(p, 4, forward: false)),
        );

      case CardType.seven:
        // Seven is only playable if you can spend ALL 7 steps forward.
        return _sevenHasFullSpend(player, pieces);

      case CardType.jack:
        return own.any((p) => p.zone == PieceZone.track) &&
            rules.allPieces.any(
              (o) =>
                  o.owner != player &&
                  o.zone == PieceZone.track &&
                  !o.immuneLocked,
            );

      case CardType.joker:
        return _jokerOptions()
            .any((fake) => _cardPlayable(player, fake, pieces));
    }
  }

  /// DFS over 7 single-step moves.
  /// Steps are small (7) and pieces per player are small (4) -> safe.
  bool _sevenHasFullSpend(int player, List<PieceState> pieces) {
    // Must use only own pieces that are on track.
    final ownTrack = pieces
        .where((p) => p.owner == player && p.zone == PieceZone.track)
        .toList();
    if (ownTrack.isEmpty) return false;

    bool dfs(List<PieceState> state, int remaining) {
      if (remaining == 0) return true;

      // Build a rules engine for this branch
      final branchRules = RulesEngine(state);

      // Try moving any own track piece by 1 (forward), applying captures.
      for (final mover in state) {
        if (mover.owner != player) continue;
        if (mover.zone != PieceZone.track) continue;

        if (!branchRules.canMoveSteps(
          mover,
          1,
          forward: true,
          bypassCaptures: true,
        )) {
          continue;
        }

        // Clone state for next branch (deep enough for our fields)
        final next = state.map((p) {
          final c = PieceState(owner: p.owner, index: p.index)
            ..zone = p.zone
            ..trackIndex = p.trackIndex
            ..goalIndex = p.goalIndex
            ..immuneLocked = p.immuneLocked;
          return c;
        }).toList();

        // Find the cloned mover
        final nextMover = next.firstWhere(
          (p) => p.owner == mover.owner && p.index == mover.index,
        );

        // Apply move of 1
        final res = RulesEngine(next).moveOnTrack(
          nextMover,
          steps: 1,
          forward: true,
          bypassCaptures: true,
        );
        if (!res.ok) continue;

        if (dfs(next, remaining - 1)) return true;
      }

      return false;
    }

    // Start from a cloned baseline
    final baseline = pieces.map((p) {
      final c = PieceState(owner: p.owner, index: p.index)
        ..zone = p.zone
        ..trackIndex = p.trackIndex
        ..goalIndex = p.goalIndex
        ..immuneLocked = p.immuneLocked;
      return c;
    }).toList();

    return dfs(baseline, 7);
  }

  List<GameCard> _jokerOptions() => const [
        GameCard(type: CardType.ace),
        GameCard(type: CardType.king),
        GameCard(type: CardType.queen),
        GameCard(type: CardType.four),
        GameCard(type: CardType.seven),
        GameCard(type: CardType.jack),
        GameCard(type: CardType.number, value: 2),
        GameCard(type: CardType.number, value: 3),
        GameCard(type: CardType.number, value: 5),
        GameCard(type: CardType.number, value: 6),
        GameCard(type: CardType.number, value: 8),
        GameCard(type: CardType.number, value: 9),
        GameCard(type: CardType.number, value: 10),
      ];
}
