enum MusicProvider { youtube, unknown }

class ParsedTrack {
  final String id;
  final String title;
  final MusicProvider provider;

  ParsedTrack({
    required this.id,
    required this.title,
    this.provider = MusicProvider.unknown,
  });
}

class MusicParser {
  // Regex 1: Bezpieczne wyodrębnianie ID z różnych formatów URL YouTube (watch?v=, youtu.be, embed/)
  static final RegExp _ytUrlRegExp = RegExp(
    r'^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
    multiLine: false,
  );

  // Regex 2: Ścisła walidacja samego ID (musi mieć dokładnie 11 znaków ze specyficznego zestawu)
  static final RegExp _ytIdStrictRegExp = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  /// Główna metoda parsowania i sanityzacji danych z kodu QR
  static ParsedTrack parse(String input) {
    // Usunięcie zbędnych spacji z początku i końca (częsty błąd przy generowaniu QR)
    final trimmedInput = input.trim();

    // Zabezpieczenie przed przepełnieniem bufora (bardzo długi ciąg znaków w QR)
    if (trimmedInput.length > 500) {
      return _unknownTrack();
    }

    String? extractedId;

    // KROK 1: Próba dopasowania do pełnego URL YouTube
    final match = _ytUrlRegExp.firstMatch(trimmedInput);
    if (match != null && match.groupCount >= 1) {
      extractedId = match.group(1);
    } 
    // KROK 2: Jeśli wejście nie jest adresem URL, sprawdź czy to sam, poprawny 11-znakowy identyfikator wideo
    else if (_ytIdStrictRegExp.hasMatch(trimmedInput)) {
      extractedId = trimmedInput;
    }

    // KROK 3: Ostateczna walidacja wyodrębnionego ID pod kątem bezpieczeństwa
    if (extractedId != null && _isValidYouTubeId(extractedId)) {
      return ParsedTrack(
        id: extractedId,
        title: 'Utwór QR ($extractedId)',
        provider: MusicProvider.youtube,
      );
    }

    // Jeśli dane nie przeszły walidacji, zwracamy bezpieczny, nieznany obiekt
    return _unknownTrack();
  }

  /// Pomocnicza metoda sprawdzająca zgodność struktury ID z wymogami YouTube
  static bool _isValidYouTubeId(String id) {
    return _ytIdStrictRegExp.hasMatch(id);
  }

  static ParsedTrack _unknownTrack() {
    return ParsedTrack(
      id: '',
      title: 'Nieznane źródło',
      provider: MusicProvider.unknown,
    );
  }
}