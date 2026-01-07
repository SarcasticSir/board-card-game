import 'card.dart';

class SwapManager {
  final int totalPlayers;

  /// playerId -> selected card
  final Map<int, GameCard> _pending = {};

  SwapManager({required this.totalPlayers}) {
    assert(
      totalPlayers == 4,
      'SwapManager currently supports 2v2 (4 players) only',
    );
  }

  bool get isComplete =>
      _pending.length == totalPlayers &&
      List.generate(totalPlayers, (i) => i)
          .every((p) => _pending.containsKey(p));

  /// Submit a card for swapping.
  /// A player may only submit once per swap phase.
  bool submit(int player, GameCard card) {
    if (_pending.containsKey(player)) {
      return false; // already submitted
    }
    _pending[player] = card;
    return true;
  }

  /// Execute swaps between teammates.
  /// Teams: (0 ↔ 2) and (1 ↔ 3)
  void execute(Map<int, List<GameCard>> hands) {
    if (!isComplete) {
      throw StateError('Swap not complete');
    }

    _swapPair(0, 2, hands);
    _swapPair(1, 3, hands);

    _pending.clear();
  }

  void _swapPair(
    int a,
    int b,
    Map<int, List<GameCard>> hands,
  ) {
    final ca = _pending[a]!;
    final cb = _pending[b]!;

    hands[a]!.remove(ca);
    hands[b]!.remove(cb);

    hands[a]!.add(cb);
    hands[b]!.add(ca);
  }

  void reset() {
    _pending.clear();
  }
}
