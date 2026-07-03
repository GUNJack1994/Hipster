import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'music_parser.dart';

class MusicPlayerScreen extends StatefulWidget {
  final ParsedTrack track;

  const MusicPlayerScreen({super.key, required this.track});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

// ZMIANA: Dodano SingleTickerProviderStateMixin do obsługi zegara animacji (vsync)
class _MusicPlayerScreenState extends State<MusicPlayerScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  final YoutubeExplode _ytExplode = YoutubeExplode();
  
  // ZMIANA: Deklaracja kontrolera animacji obrotu płyty
  AnimationController? _animationController;
  
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // ZMIANA: Inicjalizacja kontrolera (pełen obrót trwający 4 sekundy)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      var manifest = await _ytExplode.videos.streams.getManifest(widget.track.id);
      var muxedStreams = manifest.muxed;

      if (muxedStreams.isNotEmpty) {
        var streamInfo = muxedStreams.sortByBitrate().first;

        _videoController = VideoPlayerController.networkUrl(streamInfo.url);
        
        await _videoController!.initialize();
        await _videoController!.setLooping(true);
        await _videoController!.play();

        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isLoading = false;
            
            // ZMIANA: Uruchomienie kręcenia płyty po pomyślnym załadowaniu
            _animationController?.repeat();
          });
        }

        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _videoController!.value.isPlaying;
              
              // ZMIANA: Synchronizacja obrotów płyty z rzeczywistym stanem odtwarzacza
              if (_isPlaying && !_isLoading) {
                _animationController?.repeat();
              } else {
                _animationController?.stop();
              }
            });
          }
        });
      } else {
        throw Exception('Brak dostępnych strumieni typu Muxed');
      }
    } catch (e) {
      print("Błąd odtwarzacza wideo: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          // ZMIANA: Zatrzymanie animacji w przypadku błędu
          _animationController?.stop();
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  @override
  void dispose() {
    // ZMIANA: Czyszczenie kontrolera animacji z pamięci
    _animationController?.dispose();
    _videoController?.dispose();
    _ytExplode.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ZMIANA: Podmiana statycznego kontenera na animowaną płytę winylową
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  shape: BoxShape.circle, // Zmiana kształtu na koło
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0000).withOpacity(0.15),
                      blurRadius: 40,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.all(60.0),
                        child: CircularProgressIndicator(color: Color(0xFFFF0000)),
                      )
                    : RotationTransition(
                        turns: _animationController!,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Główny korpus płyty (rowki winylu)
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[900]!, width: 2),
                                color: const Color(0xFF0D0D0D),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(35),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[900]!, width: 1),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(65),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[900]!, width: 1),
                              ),
                            ),
                            // Środek płyty (czerwona naklejka)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF0000),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.music_note, size: 24, color: Colors.white),
                            ),
                            // Centralny otwór płyty
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF181818),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Odtwarzam z kodu QR',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              if (_hasError)
                const Text(
                  'Nie udało się odtworzyć tego utworu. Spróbuj innego kodu.',
                  style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                
              const SizedBox(height: 30),
              
              if (!_isLoading)
                IconButton(
                  iconSize: 80,
                  icon: Icon(
                    _hasError 
                        ? Icons.refresh
                        : (_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
            ],
          ),
        ),
      ),
    );
  }
}