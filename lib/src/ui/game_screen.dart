import 'package:flutter/material.dart';
import 'src/ui/game_screen.dart';
import 'src/ui/ui_mode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Board Card Game',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ModeSelectScreen(),
    );
  }
}

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select UI Mode',
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const GameScreen(
                      uiMode: UiMode.desktop,
                    ),
                  ),
                );
              },
              child: const Text('Desktop'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const GameScreen(
                      uiMode: UiMode.mobile,
                    ),
                  ),
                );
              },
              child: const Text('Mobile'),
            ),
          ],
        ),
      ),
    );
  }
}
