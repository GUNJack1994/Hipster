import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'music_parser.dart';

class MusicPlayerScreen extends StatefulWidget {
  final ParsedTrack track;

  const MusicPlayerScreen({super.key, required this.track});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _ytController;
  AnimationController? _animationController;
  StreamSubscription? _streamSubscription;

  bool _showVideo = false;
  bool _isPlaying = false;
  double _currentPositionInSeconds = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: widget.track.id,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        mute: false,
      ),
    );

    _streamSubscription = _ytController.videoStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _currentPositionInSeconds = state.position.inSeconds.toDouble();
        _isPlaying = _ytController.value.playerState == PlayerState.playing;

        if (_isPlaying) {
          _animationController?.repeat();
        } else {
          _animationController?.stop();
        }
      });
    });
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
        _animationController?.stop();
      });
      await _ytController.pauseVideo();
    } else {
      setState(() {
        _isPlaying = true;
        _animationController?.repeat();
      });
      await _ytController.playVideo();
    }
  }

  void _seekBackward() async {
    try {
      final double newTime = _currentPositionInSeconds - 10;
      final double targetTime = newTime < 0 ? 0 : newTime;

      await _ytController.seekTo(
        seconds: targetTime,
        allowSeekAhead: true,
      );

      setState(() {
        _currentPositionInSeconds = targetTime;
      });
    } catch (e) {
      print("Błąd przewijania wstecz: $e");
    }
  }

  void _seekForward() async {
    try {
      final double targetTime = _currentPositionInSeconds + 10;

      await _ytController.seekTo(
        seconds: targetTime,
        allowSeekAhead: true,
      );

      setState(() {
        _currentPositionInSeconds = targetTime;
      });
    } catch (e) {
      print("Błąd przewijania w przód: $e");
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _animationController?.dispose();
    _ytController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _ytController,
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            // UPROSZCZONE I NAPRAWIONE: Nowoczesna strzałka powrotu do menu głównego
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // SEKRETNA ZASŁONKA (Z ikoną YouTube i nowym tekstem)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 12.0,
                ),
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF141414),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: GestureDetector(
                    onLongPress: () {
                      setState(() {
                        _showVideo = !_showVideo;
                      });
                      Feedback.forLongPress(context);
                    },
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _showVideo
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,

                      // STAN 1: Oficjalny wygląd z customową ikoną YouTube i napisem
                      firstChild: Container(
                        width: double.infinity,
                        height: 110,
                        color: const Color(0xFF151515),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dokładne odwzorowanie logotypu ze zdjęcia
                            Container(
                              width: 38,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000), // Żywy czerwony kolor YT
                                borderRadius: BorderRadius.circular(8), // Zaokrąglone rogi "telewizorka"
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Press to see video on YouTube',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // STAN 2: Odtwarzacz wideo pod spodem
                      secondChild: SizedBox(
                        width: double.infinity,
                        height: 110,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: 220,
                            height: 110,
                            child: player,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Kręcąca się płyta winylowa
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: const Color(0xFF181818),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF0000).withOpacity(0.15),
                                  blurRadius: 35,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: RotationTransition(
                              turns: _animationController!,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey[900]!,
                                        width: 2,
                                      ),
                                      color: const Color(0xFF0D0D0D),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(30),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey[900]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF0000),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                          const Text(
                            'Odtwarzam z kodu QR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Panel sterowania
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                ),
                                onPressed: _seekBackward,
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                iconSize: 70,
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                iconSize: 40,
                                icon: const Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                ),
                                onPressed: _seekForward,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}