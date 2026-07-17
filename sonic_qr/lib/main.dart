import 'package:flutter/material.dart';
import 'main_menu_screen.dart'; // Upewnij się, że nazwa pliku się zgadza

// Globalne powiadomienia o stanie (dla uproszczenia bez zewnętrznych bibliotek)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('pl'));

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentThemeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (_, currentLocale, _) {
            return MaterialApp(
              title: 'QR Music Player',
              debugShowCheckedModeBanner: false,
              locale: currentLocale,
              themeMode: currentThemeMode,
              // Motyw Jasny
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: Colors.white,
                colorScheme: const ColorScheme.light(
                  primary: Colors.red,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              // Motyw Ciemny
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.black,
                colorScheme: const ColorScheme.dark(
                  primary: Colors.red,
                  surface: Colors.black,
                  onSurface: Colors.white,
                ),
              ),
              home: const MainMenuScreen(),
            );
          },
        );
      },
    );
  }
}