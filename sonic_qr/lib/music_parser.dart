enum MusicProvider { youtube, unknown }

class ParsedTrack {
  final MusicProvider provider;
  final String id;

  ParsedTrack({required this.provider, required this.id});
}

class MusicParser {
  static ParsedTrack parse(String data) {
    // 1. Obsługa formatu skróconego, np. yt:dQw4w9WgXcQ
    if (data.startsWith('yt:')) {
      return ParsedTrack(provider: MusicProvider.youtube, id: data.replaceFirst('yt:', ''));
    }

    // 2. Obsługa standardowych oraz mobilnych linków YouTube
    if (data.contains('youtube.com') || data.contains('youtu.be')) {
      RegExp regExp = RegExp(
        r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      );
      final match = regExp.firstMatch(data);
      if (match != null && match.group(1) != null) {
        return ParsedTrack(provider: MusicProvider.youtube, id: match.group(1)!);
      }
    }

    return ParsedTrack(provider: MusicProvider.unknown, id: '');
  }
}