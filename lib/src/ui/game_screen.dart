import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/game_engine.dart';
import '../game/game_mode.dart';
import 'hud_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BoardGame game;

  @override
  void initState() {
    super.initState();

    game = BoardGame(
      mode: GameMode.host, // 🔴 later dynamic
      onHudChanged: () {
        if (!mounted) return;
        setState(() {});
      },
      onToast: (msg) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(milliseconds: 900)),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          HudOverlay.overlayId: (_, g) =>
              HudOverlay(game: g as BoardGame),
        },
        initialActiveOverlays: const [HudOverlay.overlayId],
      ),
    );
  }
}
