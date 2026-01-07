class RoundManager {
  int _cards = 6;

  int get cardsPerPlayer => _cards;

  void nextRound() {
    _cards--;
    if (_cards < 2) {
      _cards = 6;
    }
  }

  void reset() {
    _cards = 6;
  }

  // ======================
  // State restore (used by multiplayer)
  // ======================
  void forceSet(int cardsPerPlayer) {
    _cards = cardsPerPlayer;
  }
}
