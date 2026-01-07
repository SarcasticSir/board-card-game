import 'card.dart';

class Deck {
  final List<GameCard> _drawPile = [];
  final List<GameCard> _discardPile = [];

  Deck() {
    // Two decks
    for (int d = 0; d < 2; d++) {
      // Non-number cards (4 of each)
      for (int i = 0; i < 4; i++) {
        _drawPile.add(const GameCard(type: CardType.ace));
        _drawPile.add(const GameCard(type: CardType.king));
        _drawPile.add(const GameCard(type: CardType.queen));
        _drawPile.add(const GameCard(type: CardType.jack));
        _drawPile.add(const GameCard(type: CardType.four));
        _drawPile.add(const GameCard(type: CardType.seven));
      }

      // Number cards
      for (final v in [2, 3, 5, 6, 8, 9, 10]) {
        for (int i = 0; i < 4; i++) {
          _drawPile.add(GameCard(type: CardType.number, value: v));
        }
      }

      // Jokers
      _drawPile.add(const GameCard(type: CardType.joker));
      _drawPile.add(const GameCard(type: CardType.joker));
    }

    _drawPile.shuffle();
  }

  // ======================
  // Core operations
  // ======================
  GameCard draw() {
    if (_drawPile.isEmpty) {
      _reshuffle();
    }
    return _drawPile.removeLast();
  }

  void discard(GameCard card) {
    _discardPile.add(card);
  }

  void _reshuffle() {
    _drawPile.addAll(_discardPile);
    _discardPile.clear();
    _drawPile.shuffle();
  }

  // ======================
  // Serialization
  // ======================
  List<GameCard> exportDeck() => List<GameCard>.from(_drawPile);

  List<GameCard> exportDiscard() =>
      List<GameCard>.from(_discardPile);

  void importDeck(
    List<GameCard> deck,
    List<GameCard> discard,
  ) {
    _drawPile
      ..clear()
      ..addAll(deck);

    _discardPile
      ..clear()
      ..addAll(discard);
  }
}
