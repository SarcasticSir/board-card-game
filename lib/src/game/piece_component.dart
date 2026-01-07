import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'game_engine.dart';

enum PieceZone { nest, track, goal }

class PieceState {
  final int owner;
  final int index;
  PieceZone zone;
  int trackIndex;
  int goalIndex;
  bool immuneLocked;

  PieceState({
    required this.owner,
    required this.index,
    this.zone = PieceZone.nest,
    this.trackIndex = -1,
    this.goalIndex = -1,
    this.immuneLocked = false,
  });

  // ======================
  // Serialization
  // ======================
  Map<String, dynamic> toJson() => {
        'owner': owner,
        'index': index,
        'zone': zone.name,
        'trackIndex': trackIndex,
        'goalIndex': goalIndex,
        'immuneLocked': immuneLocked,
      };

  factory PieceState.fromJson(Map<String, dynamic> json) {
    return PieceState(
      owner: json['owner'],
      index: json['index'],
    )
      ..zone =
          PieceZone.values.firstWhere((e) => e.name == json['zone'])
      ..trackIndex = json['trackIndex']
      ..goalIndex = json['goalIndex']
      ..immuneLocked = json['immuneLocked'];
  }

  void copyFrom(PieceState other) {
    zone = other.zone;
    trackIndex = other.trackIndex;
    goalIndex = other.goalIndex;
    immuneLocked = other.immuneLocked;
  }
}

class PieceComponent extends PositionComponent
    with TapCallbacks, HasGameRef<BoardGame> {
  final PieceState state;
  final void Function(PieceComponent) onTapped;
  final Color color;

  PieceComponent({
    required this.state,
    required this.onTapped,
    required this.color,
  });

  @override
  Future<void> onLoad() async {
    size = Vector2.all(22);
    anchor = Anchor.center;
  }

  // ======================
  // Visual sync (SAFE)
  // ======================
  void syncVisual() {
    switch (state.zone) {
      case PieceZone.nest:
        position =
            gameRef.nestPositions[state.owner][state.index];
        break;

      case PieceZone.track:
        if (state.trackIndex >= 0 &&
            state.trackIndex < gameRef.trackPositions.length) {
          position = gameRef.trackPositions[state.trackIndex];
        }
        break;

      case PieceZone.goal:
        if (state.goalIndex >= 0 &&
            state.goalIndex < gameRef.goalPositions[state.owner].length) {
          position =
              gameRef.goalPositions[state.owner][state.goalIndex];
        }
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );

    if (state.immuneLocked) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFFD54F),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapped(this);
  }
}
