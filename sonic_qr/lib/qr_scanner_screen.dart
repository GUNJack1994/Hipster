import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'music_parser.dart';
import 'music_player_screen.dart';
import 'translations.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  // Reset kamery przy wznowieniu aplikacji (wymagane na Androidzie)
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
      controller?.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing || scanData.code == null) return;

      setState(() {
        isProcessing = true;
      });

      try {
        // Natychmiast zatrzymujemy skaner, żeby zapobiec pętli wielokrotnego odczytu
        await controller.pauseCamera();

        // Bezpieczne parsowanie z użyciem nowej logiki sanityzacji
        final parsed = MusicParser.parse(scanData.code!);

        if (parsed.provider == MusicProvider.youtube && parsed.id.isNotEmpty) {
          if (!mounted) return;

          // Przechodzimy bezpośrednio do odtwarzacza
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicPlayerScreen(track: parsed),
            ),
          );

          // Po powrocie z odtwarzacza przywracamy aparat do życia
          _resetScanner();
        } else {
          // Kod nie przeszedł weryfikacji bezpieczeństwa (np. to nie był YouTube)
          _showErrorSnackbar(S.invalidQr);
          await Future.delayed(const Duration(seconds: 2));
          _resetScanner();
        }
      } catch (e) {
        // Globalny "bezpiecznik" – w razie jakiegokolwiek błędu aplikacja nie crashuje
        debugPrint("Krytyczny błąd skanera: $e");
        _showErrorSnackbar(S.scanError);
        await Future.delayed(const Duration(seconds: 2));
        _resetScanner();
      }
    });
  }

  // Pomocnicza metoda do bezpiecznego resetowania stanu skanera
  void _resetScanner() {
    if (!mounted) return;
    setState(() {
      isProcessing = false;
    });
    controller?.resumeCamera();
  }

  // Bezpieczne wyświetlanie powiadomienia o błędzie
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F), // Czerwony kolor błędu
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Widok z aparatu skanera
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: const Color(
                0xFFFF0000,
              ), // Czerwony pasujący do motywu
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 260,
            ),
          ),

          // STRZAŁKA COFANIA DO MENU GŁÓWNEGO
          Positioned(
            top: 50,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.5,
                  ), // Półprzezroczyste tło
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Powrót do MainMenuScreen
                  },
                ),
              ),
            ),
          ),

          // Tekst pomocniczy na górze ekranu
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              S.scanInstruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
