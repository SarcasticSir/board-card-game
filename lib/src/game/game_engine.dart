import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'game_mode.dart';
import 'game_snapshot.dart';

import 'board_math.dart';
import 'card.dart';
import 'deck.dart';
import 'round_manager.dart';
import 'turn_manager.dart';
import 'piece_component.dart';
import 'rules.dart';
import 'playable_moves.dart';
import 'swap_manager.dart';

class BoardGame extends FlameGame {
  final VoidCallback onHudChanged;
  final void Function(String msg) onToast;
  final GameMode mode;

  BoardGame({
    required this.onHudChanged,
    required this.onToast,
    required this.mode,
  });

  bool get isHost => mode == GameMode.host;

  // ======================
  // Board geometry
  // ======================
  late Vector2 boardTopLeft;
  late double boardSize;
  late List<Vector2> trackPositions;
  late List<List<Vector2>> nestPositions;
  late List<List<Vector2>> goalPositions;

  // ======================
  // Game state
  // ======================
  final Deck deck = Deck();
  final RoundManager roundManager = RoundManager();
  final TurnManager turnManager = TurnManager(totalPlayers: 4);

  // Avoid late-init issues by constructing immediately.
  final SwapManager swapManager = SwapManager(totalPlayers: 4);

  late RulesEngine rules;
  late PlayableMoves playableMoves;

  final Map<int, List<GameCard>> hands = {};
  final Set<int> passedPlayers = {};
  final List<PieceComponent> pieces = [];

  GameCard? selectedCard;

  bool inSwapPhase = false;
  bool get inSwapPhaseActive => inSwapPhase;

  // ======================
  // Seven mode (mobile-first)
  // ======================
  bool _inSevenMode = false;
  int _sevenRemaining = 0;

  // Snapshots allow perfect undo/abort.
  final List<GameSnapshot> _sevenHistory = [];

  // HUD expects these names:
  bool get inSevenMode => _inSevenMode;
  int get sevenRemainingSteps => _sevenRemaining;
  bool get canUndoSeven => _inSevenMode && _sevenHistory.length > 1;

  void undoSevenStep() => _sevenUndo();
  void abortSeven() => _sevenAbort();

  // ======================
  // Lifecycle safety flags
  // ======================
  bool _logicReady = false;
  bool _geometryReady = false;
  bool _piecesReady = false;
  bool _roundStarted = false;

  // ======================
  // Lifecycle
  // ======================
  @override
  Future<void> onLoad() async {
    // Prepare basic objects; geometry & pieces will be created in onGameResize.
    rules = RulesEngine(const []);
    playableMoves = PlayableMoves(rules);

    _logicReady = true;
    _maybeStartGame();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    // Geometry depends on `size` being set.
    _layoutBoard();

    if (!_piecesReady) {
      _initPieces();
      _piecesReady = true;

      rules = RulesEngine(pieces.map((p) => p.state).toList());
      playableMoves = PlayableMoves(rules);
    } else {
      for (final p in pieces) {
        p.syncVisual();
      }
    }

    _geometryReady = true;
    _maybeStartGame();
    _notifyHud();
  }

  void _maybeStartGame() {
    if (_roundStarted) return;
    if (!isHost) return;

    if (_logicReady && _geometryReady && _piecesReady) {
      _roundStarted = true;
      _startRound();
    }
  }

  // ======================
  // Serialization
  // ======================
  GameSnapshot exportState() {
    return GameSnapshot(
      round: 0,
      cardsPerPlayer: roundManager.cardsPerPlayer,
      currentPlayer: turnManager.currentPlayer,
      inSwapPhase: inSwapPhase,
      hands: hands.map((k, v) => MapEntry(k, List<GameCard>.from(v))),
      deck: deck.exportDeck(),
      discard: deck.exportDiscard(),
      pieces: pieces.map((p) => p.state).toList(),
    );
  }

  void importState(GameSnapshot snap) {
    hands
      ..clear()
      ..addAll(
        snap.hands.map((k, v) => MapEntry(k, List<GameCard>.from(v))),
      );

    deck.importDeck(snap.deck, snap.discard);

    turnManager.forceSet(snap.currentPlayer);
    roundManager.forceSet(snap.cardsPerPlayer);

    inSwapPhase = snap.inSwapPhase;

    for (final saved in snap.pieces) {
      final live = pieces.firstWhere(
        (p) => p.state.owner == saved.owner && p.state.index == saved.index,
      );
      live.state.copyFrom(saved);
      live.syncVisual();
    }

    _notifyHud();
  }

  // ======================
  // SAFE UI notifications
  // ======================
  void _notifyHud() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onHudChanged();
    });
  }

  void _notifyToast(String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onToast(msg);
    });
  }

  // ======================
  // Board setup
  // ======================
  void _layoutBoard() {
    if (size.x == 0 || size.y == 0) return;

    final minDim = size.x < size.y ? size.x : size.y;
    boardSize = minDim * 0.82;

    boardTopLeft = Vector2(
      (size.x - boardSize) / 2,
      (size.y - boardSize) / 2,
    );

    trackPositions = buildTrackPositions(boardTopLeft, boardSize);
    nestPositions = List.generate(4, (p) => nestSlots(boardTopLeft, boardSize, p));
    goalPositions = List.generate(4, (p) => goalSlots(boardTopLeft, boardSize, p));
  }

  void _initPieces() {
    removeAll(children.toList());
    pieces.clear();

    const colors = [
      Color(0xFF42A5F5),
      Color(0xFFEF5350),
      Color(0xFF66BB6A),
      Color(0xFFFFA726),
    ];

    for (int p = 0; p < 4; p++) {
      for (int i = 0; i < 4; i++) {
        final state = PieceState(owner: p, index: i);
        final piece = PieceComponent(
          state: state,
          color: colors[p],
          onTapped: _onPieceTapped,
        );
        piece.position = nestPositions[p][i];
        add(piece);
        pieces.add(piece);
      }
    }
  }

  // ======================
  // Round & swap
  // ======================
  void _startRound() {
    hands.clear();
    passedPlayers.clear();
    swapManager.reset();

    for (int p = 0; p < 4; p++) {
      hands[p] = List.generate(roundManager.cardsPerPlayer, (_) => deck.draw());
    }

    selectedCard = null;
    inSwapPhase = true;

    _notifyHud();
    _notifyToast('Round start: swap one card with your teammate.');
  }

  void submitSwapCard(GameCard card) {
    if (!isHost) return;
    if (!inSwapPhase) return;

    final p = turnManager.currentPlayer;
    if (!(hands[p]?.contains(card) ?? false)) return;

    swapManager.submit(p, card);

    if (swapManager.isComplete) {
      swapManager.execute(hands);
      inSwapPhase = false;
      _notifyToast('Swap complete. Game begins.');
      _checkForcedPass();
    } else {
      turnManager.next();
    }

    _notifyHud();
  }

  // ======================
  // Turn enforcement
  // ======================
  void _checkForcedPass() {
    final p = turnManager.currentPlayer;

    if (passedPlayers.contains(p)) {
      turnManager.next();
      _checkForcedPass();
      return;
    }

    final canPlay = playableMoves.hasAnyPlayableMove(
      p,
      hands[p] ?? const [],
      pieces.map((e) => e.state).toList(),
    );

    if (!canPlay) {
      passedPlayers.add(p);
      _notifyToast('Player ${p + 1} must pass.');
      turnManager.next();
      _checkForcedPass();
      return;
    }

    _notifyHud();
  }

  // ======================
  // Seven mode (mobile-first)
  // ======================
  void _enterSevenMode() {
    _inSevenMode = true;
    _sevenRemaining = 7;
    _sevenHistory
      ..clear()
      ..add(exportState());

    _notifyHud();
    _notifyToast('7: Tap your pieces to move 1 step each. Undo/Abort available.');
  }

  void _applySevenOneStep(PieceComponent piece) {
    if (!_inSevenMode) return;
    if (_sevenRemaining <= 0) return;

    // Must be your piece, and must be on track.
    if (piece.state.owner != turnManager.currentPlayer) {
      _notifyToast('Not your piece.');
      return;
    }
    if (piece.state.zone != PieceZone.track) {
      _notifyToast('7 can only move track pieces.');
      return;
    }

    // 7 captures bypassed pieces: we implement it as 1 step at a time,
    // so bypass-capture behavior is effectively "capture on the step".
    final res = rules.moveOnTrack(
      piece.state,
      steps: 1,
      forward: true,
      bypassCaptures: true,
    );

    if (!res.ok) {
      _notifyToast(res.error ?? 'Illegal 7 step');
      return;
    }

    // Sync moved + any captured.
    piece.syncVisual();
    for (final cap in res.captured) {
      final capturedPc = pieces.firstWhere(
        (pc) => pc.state.owner == cap.owner && pc.state.index == cap.index,
      );
      capturedPc.syncVisual();
    }

    _sevenRemaining -= 1;
    _sevenHistory.add(exportState());
    _notifyHud();

    if (_sevenRemaining == 0) {
      _commitSevenAuto();
    }
  }

  void _sevenUndo() {
    if (!canUndoSeven) return;

    // Remove current snapshot, revert to previous.
    _sevenHistory.removeLast();
    importState(_sevenHistory.last);

    _sevenRemaining += 1;
    _notifyHud();
  }

  void _sevenAbort() {
    if (!_inSevenMode) return;
    if (_sevenHistory.isEmpty) return;

    // Revert to baseline snapshot. Keep the 7 card in hand (not discarded).
    importState(_sevenHistory.first);

    _inSevenMode = false;
    _sevenRemaining = 0;
    _sevenHistory.clear();

    _notifyHud();
    _notifyToast('7 aborted.');
  }

  void _commitSevenAuto() {
    // Discard the selected 7 now.
    final card = selectedCard;
    final p = turnManager.currentPlayer;

    if (card != null && card.type == CardType.seven) {
      hands[p]?.remove(card);
      deck.discard(card);
    }

    _inSevenMode = false;
    _sevenRemaining = 0;
    _sevenHistory.clear();
    selectedCard = null;

    turnManager.next();
    _checkForcedPass();
    _notifyHud();
    _notifyToast('7 completed.');
  }

  // ======================
  // Piece interaction
  // ======================
  void _onPieceTapped(PieceComponent piece) {
    if (!isHost) return;

    if (_inSevenMode) {
      _applySevenOneStep(piece);
      return;
    }

    if (inSwapPhase) {
      _notifyToast('Finish swapping first.');
      return;
    }

    if (selectedCard == null) {
      _notifyToast('Select a card first.');
      return;
    }

    if (piece.state.owner != turnManager.currentPlayer) {
      _notifyToast('Not your piece.');
      return;
    }

    final card = selectedCard!;

    // Selecting 7 enters mode; the actual moves happen by tapping pieces.
    if (card.type == CardType.seven) {
      _enterSevenMode();
      return;
    }

    final res = _applyCard(card, piece);
    if (!res.ok) {
      _notifyToast(res.error!);
      return;
    }

    hands[turnManager.currentPlayer]!.remove(card);
    deck.discard(card);

    piece.syncVisual();
    for (final cap in res.captured) {
      final capturedPc = pieces.firstWhere(
        (pc) => pc.state.owner == cap.owner && pc.state.index == cap.index,
      );
      capturedPc.syncVisual();
    }

    selectedCard = null;
    turnManager.next();
    _checkForcedPass();
  }

  MoveResult _applyCard(GameCard card, PieceComponent piece) {
    switch (card.type) {
      case CardType.ace:
        if (piece.state.zone == PieceZone.nest) {
          return rules.moveOutToImmune(piece.state);
        }
        return rules.moveOnTrack(piece.state, steps: 1, forward: true);

      case CardType.king:
        if (piece.state.zone == PieceZone.nest) {
          return rules.moveOutToImmune(piece.state);
        }
        return rules.moveOnTrack(piece.state, steps: 13, forward: true);

      case CardType.number:
        return rules.moveOnTrack(piece.state, steps: card.value, forward: true);

      case CardType.queen:
        return rules.moveOnTrack(piece.state, steps: 12, forward: true);

      case CardType.four:
        // We'll add forward/back choice next.
        return rules.moveOnTrack(piece.state, steps: 4, forward: true);

      case CardType.seven:
        return const MoveResult.err('Seven handled via seven-mode');

      case CardType.jack:
        return const MoveResult.err('Jack swap handled later');

      case CardType.joker:
        return const MoveResult.err('Resolve joker first');
    }
  }

  // ======================
  // UI hooks
  // ======================
  void selectCard(GameCard card) {
    if (!isHost) return;
    if (inSwapPhase) return;
    if (_inSevenMode) {
      _notifyToast('Finish 7 (undo/abort) first.');
      return;
    }

    selectedCard = card;
    _notifyHud();
  }

  void forceNextTurnForTesting() {
    if (!isHost) return;
    if (_inSevenMode) {
      _notifyToast('Finish 7 first.');
      return;
    }
    selectedCard = null;
    turnManager.next();
    _checkForcedPass();
  }

  // ======================
  // Rendering (board first, then pieces)
  // ======================
  @override
  void render(Canvas canvas) {
    _renderBoard(canvas);
    super.render(canvas);
  }

  void _renderBoard(Canvas canvas) {
    if (!_geometryReady) return;

    final rect = Rect.fromLTWH(
      boardTopLeft.x,
      boardTopLeft.y,
      boardSize,
      boardSize,
    );

    // Board background
    canvas.drawRect(rect, Paint()..color = const Color(0xFF1E1E1E));

    // Track dots
    final dotPaint = Paint()..color = const Color(0xFFBDBDBD);
    for (final pos in trackPositions) {
      canvas.drawCircle(Offset(pos.x, pos.y), 6, dotPaint);
    }

    // Immune markers (bigger colored dots on immune indices)
    const immuneColors = [
      Color(0xFF42A5F5),
      Color(0xFFEF5350),
      Color(0xFF66BB6A),
      Color(0xFFFFA726),
    ];
    for (int p = 0; p < 4; p++) {
      final idx = immuneIndexForPlayer(p);
      final pos = trackPositions[idx];
      canvas.drawCircle(
        Offset(pos.x, pos.y),
        10,
        Paint()..color = immuneColors[p],
      );
      canvas.drawCircle(
        Offset(pos.x, pos.y),
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFFFFF),
      );
    }

    // Nest rings
    final nestStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF9E9E9E);

    for (int p = 0; p < 4; p++) {
      for (final pos in nestPositions[p]) {
        canvas.drawCircle(Offset(pos.x, pos.y), 12, nestStroke);
      }
    }

    // Goal squares
    final goalStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFEEEEEE);

    for (int p = 0; p < 4; p++) {
      for (final pos in goalPositions[p]) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(pos.x, pos.y), width: 20, height: 20),
          goalStroke,
        );
      }
    }
  }
}
