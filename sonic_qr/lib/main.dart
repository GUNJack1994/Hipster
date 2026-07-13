import 'package:flutter/material.dart';
import 'main_menu_screen.dart';

void main() {
  runApp(const SonicQrApp());
}

class SonicQrApp extends StatelessWidget {
  const SonicQrApp({super.key});

@override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Music Player',
      theme: ThemeData.dark(),
      home: const MainMenuScreen(), // <--- Ustaw menu jako ekran startowy
    );
  }
}