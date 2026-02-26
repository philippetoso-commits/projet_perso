import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:app_lecture/models/audiobook.dart';

class AudiobookScreen extends StatefulWidget {
  final Audiobook audiobook;

  const AudiobookScreen({Key? key, required this.audiobook}) : super(key: key);

  @override
  _AudiobookScreenState createState() => _AudiobookScreenState();
}

class _AudiobookScreenState extends State<AudiobookScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentPageIndex = 0;
  
  // To handle the state
  late StreamSubscription _playerCompleteSubscription;
  late StreamSubscription _playerStateChangeSubscription;
  late StreamSubscription _onDurationChangedSubscription;
  late StreamSubscription _onPositionChangedSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerStateChangeSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _onDurationChangedSubscription = _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _onPositionChangedSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
          _updateCurrentPage(newPosition);
        });
      }
    });
    
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _currentPageIndex = 0;
          _audioPlayer.seek(Duration.zero);
        });
      }
    });

    // We don't auto-play, but we set the source. AssetSource expects path without 'assets/' prefix.
    _audioPlayer.setSource(AssetSource(widget.audiobook.audioPath));
  }

  void _updateCurrentPage(Duration position) {
    int newIndex = 0;
    for (int i = 0; i < widget.audiobook.pages.length; i++) {
      if (position.inSeconds >= widget.audiobook.pages[i].startTimeSeconds) {
        newIndex = i;
      } else {
        break;
      }
    }
    if (_currentPageIndex != newIndex) {
      _currentPageIndex = newIndex;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _playerCompleteSubscription.cancel();
    _playerStateChangeSubscription.cancel();
    _onDurationChangedSubscription.cancel();
    _onPositionChangedSubscription.cancel();
    super.dispose();
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  void _seekTo(double value) {
    final position = Duration(seconds: value.toInt());
    _audioPlayer.seek(position);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.audiobook.pages[_currentPageIndex].imagePath;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.audiobook.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedSwitcher(
                  duration: const Duration(seconds: 1),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey<String>(currentImage),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(currentImage),
                        fit: BoxFit.contain, // Maintain aspect ratio to show the whole image
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.indigo,
                      inactiveTrackColor: Colors.indigo.shade100,
                      thumbColor: Colors.indigo,
                      overlayColor: Colors.indigo.withOpacity(0.2),
                      trackHeight: 6.0,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                      value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
                      onChanged: _seekTo,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                        Text(_formatDuration(_duration), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        color: Colors.indigo.shade300,
                        icon: const Icon(Icons.replay_10),
                        onPressed: () {
                          final newPosition = _position - const Duration(seconds: 10);
                          _audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                        },
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: _playPause,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              )
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      IconButton(
                        iconSize: 40,
                        color: Colors.indigo.shade300,
                        icon: const Icon(Icons.forward_10),
                        onPressed: () {
                          final newPosition = _position + const Duration(seconds: 10);
                          _audioPlayer.seek(newPosition > _duration ? _duration : newPosition);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
