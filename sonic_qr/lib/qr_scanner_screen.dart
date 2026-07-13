import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'music_parser.dart';
import 'music_player_screen.dart';

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

      // Natychmiast zatrzymujemy skaner, żeby nie czytał kodu wielokrotnie
      await controller.pauseCamera();

      final parsed = MusicParser.parse(scanData.code!);

      // Sprawdzamy czy to YouTube, ale NIE pokazujemy już żadnego panelu
      // z informacjami, żeby utrzymać 100% tajemnicy przed odtworzeniem!
      if (parsed.provider == MusicProvider.youtube) {
        if (!mounted) return;

        // Przechodzimy bezpośrednio do odtwarzacza
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicPlayerScreen(track: parsed),
          ),
        ).then((_) {
          // Po powrocie z ekranu odtwarzacza (np. kliknięcie strzałki wstecz)
          // resetujemy stan i włączamy aparat ponownie
          setState(() {
            isProcessing = false;
          });
          controller.resumeCamera();
        });
      } else {
        // Obsługa błędnego kodu QR
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zeskanowany kod nie zawiera linku YouTube!'),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        await controller.resumeCamera();
        setState(() {
          isProcessing = false;
        });
      }
    });
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
                  color: Colors.black.withOpacity(
                    0.5,
                  ), // Półprzezroczyste tło dla lepszej widoczności na podglądzie z kamery
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
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              'Skieruj aparat na kod QR',
              textAlign: TextAlign.center,
              style: TextStyle(
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
