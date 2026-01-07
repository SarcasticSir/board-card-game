class TurnManager {
  int currentPlayer = 0;
  final int totalPlayers;

  TurnManager({required this.totalPlayers});

  void next() {
    currentPlayer = (currentPlayer + 1) % totalPlayers;
  }

  // ======================
  // State restore (used by multiplayer)
  // ======================
  void forceSet(int player) {
    currentPlayer = player % totalPlayers;
  }
}
