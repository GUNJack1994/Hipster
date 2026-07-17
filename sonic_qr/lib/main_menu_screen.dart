import 'package:flutter/material.dart';
import 'package:sonic_qr/qr_scanner_screen.dart';
import 'main.dart'; // importujemy localeNotifier i themeNotifier
import 'translations.dart'; // plik z tłumaczeniami S.

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NAGŁÓWEK
              Row(
                children: [
                  const Icon(Icons.library_music_rounded, color: Color(0xFFFF0000), size: 36),
                  const SizedBox(width: 12),
                  Text(
                    'SZLAGIER',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                S.isEn ? 'Welcome, music lover!' : 'Witaj amatorze muzyki wszelakiej!',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 60),

              // PRZYCISKI MENU
              _buildMenuButton(
                context,
                icon: Icons.qr_code_scanner_rounded,
                title: S.scanQr,
                subtitle: S.isEn ? 'Launch the music player via QR' : 'Uruchom odtwarzacz muzyki z QR',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QrScannerScreen(),
                    ),
                  ).then((_) {
                    // Odświeżenie stanu po powrocie ze skanera
                    setState(() {});
                  });
                },
              ),
              const SizedBox(height: 20),
              
              _buildMenuButton(
                context,
                icon: Icons.settings_rounded,
                title: S.settings,
                subtitle: S.isEn ? 'App configuration and preferences' : 'Konfiguracja i preferencje aplikacji',
                onTap: () {
                  _showSettingsBottomSheet(context);
                },
              ),
              const SizedBox(height: 20),

              _buildMenuButton(
                context,
                icon: Icons.person_rounded,
                title: S.isEn ? 'About Author' : 'O autorze',
                subtitle: S.isEn ? 'Who I am and what I do' : 'Kim jestem i czym się zajmuję',
                onTap: () {
                  _showAboutMeDialog(context);
                },
              ),
              
              const Spacer(),
              Center(
                child: Text(
                  'v1.0.0 Stable',
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.3), fontSize: 12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF141414), const Color(0xFF1D1D1D)]
              : [const Color(0xFFF5F5F5), const Color(0xFFEFEFEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
          splashColor: const Color(0xFFFF0000).withValues(alpha: 0.1),
          highlightColor: const Color(0xFFFF0000).withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? null : Border.all(color: Colors.grey[300]!),
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
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600], 
                          fontSize: 13
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[600], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Panel dolny z ustawieniami Języka i Motywu
  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Górna kreseczka do zamykania
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    S.settings,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 10),

                  // Opcja 1: Język
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: Color(0xFFFF0000)),
                    title: Text(
                      S.language, 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black)
                    ),
                    trailing: DropdownButton<String>(
                      value: localeNotifier.value.languageCode,
                      underline: const SizedBox(),
                      dropdownColor: isDark ? const Color(0xFF1D1D1D) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      items: [
                        DropdownMenuItem(value: 'pl', child: Text(S.polish)),
                        DropdownMenuItem(value: 'en', child: Text(S.english)),
                      ],
                      onChanged: (langCode) {
                        if (langCode != null) {
                          localeNotifier.value = Locale(langCode);
                          // Odświeża modal oraz ekran pod spodem
                          setModalState(() {});
                          setState(() {}); 
                        }
                      },
                    ),
                  ),

                  // Opcja 2: Motyw
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 
                      color: const Color(0xFFFF0000)
                    ),
                    title: Text(
                      S.theme, 
                      style: TextStyle(color: isDark ? Colors.white : Colors.black)
                    ),
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: const Color(0xFFFF0000),
                      onChanged: (value) {
                        themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                        // Odświeża modal oraz ekran pod spodem
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Okienko "O autorze" wspierające język angielski
  void _showAboutMeDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.code_rounded, color: Color(0xFFFF0000)),
              const SizedBox(width: 10),
              Text(
                S.isEn ? 'About Author' : 'O Autorze', 
                style: TextStyle(color: isDark ? Colors.white : Colors.black)
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.isEn
                    ? 'The app creator is a Test Automation Engineer specializing in building advanced and stable test architectures.'
                    : 'Twórca aplikacji to inżynier automatyzacji testów (Test Automation Engineer), specjalizujący się w budowaniu zaawansowanych i stabilnych architektur testowych.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87, 
                  fontSize: 14, 
                  height: 1.4
                ),
              ),
              const SizedBox(height: 16),
              Text(
                S.isEn ? 'Main technologies:' : 'Główne technologie:',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700], 
                  fontSize: 13, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTechChip(context, 'C#'),
                  _buildTechChip(context, '.NET'),
                  _buildTechChip(context, 'TypeScript'),
                  _buildTechChip(context, 'Playwright'),
                  _buildTechChip(context, 'xUnit / SpecFlow'),
                  _buildTechChip(context, 'Flutter'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                S.isEn ? 'Close' : 'Zamknij', 
                style: const TextStyle(color: Color(0xFFFF0000))
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTechChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey[900]! : Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(color: isDark ? Colors.grey : Colors.grey[700], fontSize: 12),
      ),
    );
  }
}