import 'package:flutter/material.dart';
import 'package:sonic_qr/qr_scanner_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NAGŁÓWEK
              const Row(
                children: [
                  Icon(Icons.library_music_rounded, color: Color(0xFFFF0000), size: 36),
                  SizedBox(width: 12),
                  Text(
                    'SZLAGIER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Witaj amatorze muzyki wszelakiej!',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 60),

              // PRZYCISKI MENU
              _buildMenuButton(
                context,
                icon: Icons.qr_code_scanner_rounded,
                title: 'Skanuj kod',
                subtitle: 'Uruchom odtwarzacz muzyki z QR',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrScannerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                icon: Icons.settings_rounded,
                title: 'Opcje',
                subtitle: 'Konfiguracja i preferencje aplikacji',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Dostępne wkrótce...'),
                      backgroundColor: Colors.grey[900],
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildMenuButton(
                context,
                icon: Icons.person_rounded,
                title: 'O autorze',
                subtitle: 'Kim jestem i czym się zajmuję',
                onTap: () {
                  _showAboutMeDialog(context);
                },
              ),
              
              const Spacer(),
              Center(
                child: Text(
                  'v1.0.0 Stable',
                  style: TextStyle(color: Colors.grey.withOpacity(0.3), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Budowanie animowanego, klikalnego kafelka menu
  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [const Color(0xFF141414), const Color(0xFF1D1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFFFF0000).withOpacity(0.1),
          highlightColor: const Color(0xFFFF0000).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF0000), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[700], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Okienko "O autorze" wyciągające informacje z Twojego profilu
  void _showAboutMeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.code_rounded, color: Color(0xFFFF0000)),
              SizedBox(width: 10),
              Text('O Autorze', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Twórca aplikacji to inżynier automatyzacji testów (Test Automation Engineer), specjalizujący się w budowaniu zaawansowanych i stabilnych architektur testowych.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Główne technologie:',
                style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTechChip('C#'),
                  _buildTechChip('.NET'),
                  _buildTechChip('TypeScript'),
                  _buildTechChip('Playwright'),
                  _buildTechChip('xUnit / SpecFlow'),
                  _buildTechChip('Flutter'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zamknij', style: TextStyle(color: Color(0xFFFF0000))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}