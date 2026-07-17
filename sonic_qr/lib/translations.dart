import 'main.dart'; // importujemy localeNotifier

class S {
  static bool get isEn => localeNotifier.value.languageCode == 'en';

  // Tłumaczenia menu głównego
  static String get scanQr => isEn ? 'Scan QR Code' : 'Skanuj kod QR';
  static String get settings => isEn ? 'Settings' : 'Ustawienia';
  static String get language => isEn ? 'Language' : 'Język';
  static String get theme => isEn ? 'Theme' : 'Motyw';
  static String get polish => isEn ? 'Polish' : 'Polski';
  static String get english => isEn ? 'English' : 'Angielski';
  static String get lightTheme => isEn ? 'Light' : 'Jasny';
  static String get darkTheme => isEn ? 'Dark' : 'Ciemny';
  static String get back => isEn ? 'Back' : 'Wstecz';
  
  // Tłumaczenia skanera
  static String get scanInstruction => isEn ? 'Point your camera at the QR code' : 'Skieruj aparat na kod QR';
  static String get invalidQr => isEn ? 'Scanned code is invalid or unsafe!' : 'Zeskanowany kod jest nieprawidłowy lub niebezpieczny!';
  static String get scanError => isEn ? 'An error occurred while processing QR.' : 'Wystąpił błąd podczas przetwarzania kodu QR.';
  
  // Tłumaczenia odtwarzacza
  static String get secretTrack => isEn ? 'Secret Track' : 'Tajemniczy Utwór';
  static String get tapToReveal => isEn ? 'Press to see video on YouTube' : 'Naciśnij, aby zobaczyć wideo na YouTube';
}