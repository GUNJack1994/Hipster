import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'music_parser.dart';

class MusicPlayerScreen extends StatefulWidget {
  final ParsedTrack track;

  const MusicPlayerScreen({super.key, required this.track});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  final YoutubeExplode _ytExplode = YoutubeExplode();
  
  AnimationController? _animationController;
  
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
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
            _animationController?.repeat();
            WakelockPlus.enable();
          });
        }

        _videoController!.addListener(() {
          if (mounted) {
            setState(() {
              _isPlaying = _videoController!.value.isPlaying;
              
              if (_isPlaying && !_isLoading) {
                _animationController?.repeat();
                WakelockPlus.enable();
              } else {
                _animationController?.stop();
                WakelockPlus.disable();
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
          _animationController?.stop();
          WakelockPlus.disable();
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

  // DODANO: Funkcja cofania o 10 sekund
  void _seekBackward() async {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final currentPosition = _videoController!.value.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      
      // Zabezpieczenie, żeby nie cofnąć poniżej zera
      await _videoController!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    }
  }

  // DODANO: Funkcja przewijania w przód o 10 sekund
  void _seekForward() async {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final currentPosition = _videoController!.value.position;
      final totalDuration = _videoController!.value.duration;
      final newPosition = currentPosition + const Duration(seconds: 10);
      
      // Zabezpieczenie, żeby nie przewinąć poza długość utworu
      await _videoController!.seekTo(newPosition > totalDuration ? totalDuration : newPosition);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
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
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  shape: BoxShape.circle,
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
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF0000),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.music_note, size: 24, color: Colors.white),
                            ),
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
              
              // ZMIANA: Przycisk Play/Pause otoczony kontrolkami do przewijania o 10s
              if (!_isLoading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Przycisk: Tył 10s
                    IconButton(
                      iconSize: 48,
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: _hasError ? null : _seekBackward,
                    ),
                    const SizedBox(width: 20),
                    // Główny przycisk: Play / Pause / Odśwież
                    IconButton(
                      iconSize: 80,
                      icon: Icon(
                        _hasError 
                            ? Icons.refresh
                            : (_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                        color: Colors.white,
                      ),
                      onPressed: _hasError ? _initializePlayer : _togglePlayPause,
                    ),
                    const SizedBox(width: 20),
                    // Przycisk: Przód 10s
                    IconButton(
                      iconSize: 48,
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: _hasError ? null : _seekForward,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}