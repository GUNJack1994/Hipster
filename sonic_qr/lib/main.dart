import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart';

void main() {
  runApp(const SonicQrApp());
}

class SonicQrApp extends StatelessWidget {
  const SonicQrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hipster_v2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const QrScannerScreen(),
    );
  }
}