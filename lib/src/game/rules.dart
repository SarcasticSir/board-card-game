import 'board_math.dart';
import 'piece_component.dart';

class MoveResult {
  final bool ok;
  final String? error;
  final List<PieceState> captured;

  const MoveResult.ok(this.captured) : ok = true, error = null;
  const MoveResult.err(this.error)
      : ok = false,
        captured = const [];
}

class RulesEngine {
  final List<PieceState> allPieces;

  RulesEngine(this.allPieces);

  PieceState? pieceAtTrack(int idx) {
    for (final p in allPieces) {
      if (p.zone == PieceZone.track && p.trackIndex == idx) return p;
    }
    return null;
  }

  bool blocksPassing(int moverOwner, int idx) {
    final p = pieceAtTrack(idx);
    if (p == null) return false;
    if (!p.immuneLocked) return false;
    return p.owner != moverOwner;
  }

  List<int> forwardPath(int start, int steps) =>
      List.generate(steps, (i) => (start + i + 1) % kTrackLen);

  List<int> backwardPath(int start, int steps) =>
      List.generate(steps, (i) => (start - i - 1) % kTrackLen);

  MoveResult moveOutToImmune(PieceState piece) {
    final immune = immuneIndexForPlayer(piece.owner);
    final occupying = pieceAtTrack(immune);
    final captured = <PieceState>[];

    if (occupying != null) {
      _sendToNest(occupying);
      captured.add(occupying);
    }

    piece.zone = PieceZone.track;
    piece.trackIndex = immune;
    piece.goalIndex = -1;
    piece.immuneLocked = true;

    return MoveResult.ok(captured);
  }

  MoveResult moveOnTrack(
    PieceState piece, {
    required int steps,
    required bool forward,
    bool bypassCaptures = false,
  }) {
    if (piece.zone != PieceZone.track) {
      return const MoveResult.err('Piece not on track');
    }

    final start = piece.trackIndex;
    final path = forward ? forwardPath(start, steps) : backwardPath(start, steps);

    if (path.length > 1) {
      for (final idx in path.sublist(0, path.length - 1)) {
        if (blocksPassing(piece.owner, idx)) {
          return const MoveResult.err('Blocked by immune piece');
        }
      }
    }

    final landing = path.last;
    final captured = <PieceState>[];

    // Seven rule: any piece bypassed gets sent back to nest.
    if (bypassCaptures && path.length > 1) {
      for (final idx in path.sublist(0, path.length - 1)) {
        final p = pieceAtTrack(idx);
        if (p != null) {
          _sendToNest(p);
          captured.add(p);
        }
      }
    }

    final target = pieceAtTrack(landing);
    if (target != null && target != piece) {
      _sendToNest(target);
      captured.add(target);
    }

    // Goal entry rule (simple version you currently have)
    final goalEntrance = goalEntranceForPlayer(piece.owner);
    if (forward && start == goalEntrance) {
      if (steps < 1 || steps > 4) {
        return const MoveResult.err('Invalid goal move');
      }

      for (final other in allPieces) {
        if (other.owner == piece.owner &&
            other.zone == PieceZone.goal &&
            other.goalIndex == steps - 1) {
          return const MoveResult.err('Goal slot occupied');
        }
      }

      piece.zone = PieceZone.goal;
      piece.goalIndex = steps - 1;
      piece.trackIndex = -1;
      piece.immuneLocked = false;
      return MoveResult.ok(captured);
    }

    piece.trackIndex = landing;
    piece.immuneLocked = false;
    return MoveResult.ok(captured);
  }

  MoveResult swapWithJack(PieceState a, PieceState b) {
    if (a.zone != PieceZone.track || b.zone != PieceZone.track) {
      return const MoveResult.err('Jack requires track pieces');
    }
    if (a.owner == b.owner) {
      return const MoveResult.err('Cannot swap own piece');
    }
    if (b.immuneLocked) {
      return const MoveResult.err('Target is immune-locked');
    }

    final tmp = a.trackIndex;
    a.trackIndex = b.trackIndex;
    b.trackIndex = tmp;
    a.immuneLocked = false;

    return const MoveResult.ok([]);
  }

  bool canMoveSteps(
    PieceState piece,
    int steps, {
    required bool forward,
    bool bypassCaptures = false,
  }) {
    if (piece.zone != PieceZone.track) return false;

    final start = piece.trackIndex;
    final path = forward ? forwardPath(start, steps) : backwardPath(start, steps);

    if (path.length > 1) {
      for (final idx in path.sublist(0, path.length - 1)) {
        if (blocksPassing(piece.owner, idx)) return false;
      }
    }

    final goalEntrance = goalEntranceForPlayer(piece.owner);
    if (forward && start == goalEntrance) {
      if (steps < 1 || steps > 4) return false;
      for (final other in allPieces) {
        if (other.owner == piece.owner &&
            other.zone == PieceZone.goal &&
            other.goalIndex == steps - 1) {
          return false;
        }
      }
    }

    return true;
  }

  void _sendToNest(PieceState p) {
    p.zone = PieceZone.nest;
    p.trackIndex = -1;
    p.goalIndex = -1;
    p.immuneLocked = false;
  }
}
