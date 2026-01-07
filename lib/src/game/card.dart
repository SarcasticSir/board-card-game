enum CardType { ace, number, four, seven, jack, queen, king, joker }

class GameCard {
  final CardType type;
  final int value;

  const GameCard({
    required this.type,
    this.value = 0,
  });

  // ======================
  // Serialization
  // ======================
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'value': value,
      };

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      type: CardType.values.firstWhere((e) => e.name == json['type']),
      value: json['value'] as int,
    );
  }

  // ======================
  // UI helper
  // ======================
  String display() {
    switch (type) {
      case CardType.ace:
        return 'A';
      case CardType.four:
        return '4';
      case CardType.seven:
        return '7';
      case CardType.jack:
        return 'J';
      case CardType.queen:
        return 'Q';
      case CardType.king:
        return 'K';
      case CardType.joker:
        return '🃏';
      case CardType.number:
        return value.toString();
    }
  }
}
