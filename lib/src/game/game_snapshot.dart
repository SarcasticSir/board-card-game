import 'card.dart';
import 'piece_component.dart';

class GameSnapshot {
  final int round;
  final int cardsPerPlayer;
  final int currentPlayer;
  final bool inSwapPhase;

  final Map<int, List<GameCard>> hands;
  final List<GameCard> deck;
  final List<GameCard> discard;
  final List<PieceState> pieces;

  GameSnapshot({
    required this.round,
    required this.cardsPerPlayer,
    required this.currentPlayer,
    required this.inSwapPhase,
    required Map<int, List<GameCard>> hands,
    required List<GameCard> deck,
    required List<GameCard> discard,
    required List<PieceState> pieces,
  })  : hands = hands.map(
          (k, v) => MapEntry(k, List<GameCard>.from(v)),
        ),
        deck = List<GameCard>.from(deck),
        discard = List<GameCard>.from(discard),
        pieces = pieces.map((p) => PieceState.fromJson(p.toJson())).toList();

  // ======================
  // Serialization
  // ======================
  Map<String, dynamic> toJson() => {
        'round': round,
        'cardsPerPlayer': cardsPerPlayer,
        'currentPlayer': currentPlayer,
        'inSwapPhase': inSwapPhase,
        'hands': hands.map(
          (k, v) =>
              MapEntry(k.toString(), v.map((c) => c.toJson()).toList()),
        ),
        'deck': deck.map((c) => c.toJson()).toList(),
        'discard': discard.map((c) => c.toJson()).toList(),
        'pieces': pieces.map((p) => p.toJson()).toList(),
      };

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      round: json['round'] as int,
      cardsPerPlayer: json['cardsPerPlayer'] as int,
      currentPlayer: json['currentPlayer'] as int,
      inSwapPhase: json['inSwapPhase'] as bool,
      hands: (json['hands'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          int.parse(k),
          (v as List)
              .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      deck: (json['deck'] as List)
          .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      discard: (json['discard'] as List)
          .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      pieces: (json['pieces'] as List)
          .map((e) => PieceState.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ======================
  // Utility
  // ======================
  GameSnapshot copy() => GameSnapshot(
        round: round,
        cardsPerPlayer: cardsPerPlayer,
        currentPlayer: currentPlayer,
        inSwapPhase: inSwapPhase,
        hands: hands,
        deck: deck,
        discard: discard,
        pieces: pieces,
      );
}
