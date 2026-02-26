import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../services/tts_service.dart'; // Used to say "cui cui"

class AnimatedBackgroundWidget extends StatefulWidget {
  final TtsService ttsService;

  const AnimatedBackgroundWidget({Key? key, required this.ttsService}) : super(key: key);

  @override
  _AnimatedBackgroundWidgetState createState() => _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget> with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _birdController;
  final Random _random = Random();

  // Clouds positions
  List<_Cloud> _clouds = [];
  // Birds positions
  List<_Bird> _birds = [];

  @override
  void initState() {
    super.initState();

    _cloudController = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _birdController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();

    // Initialize random clouds
    for (int i = 0; i < 5; i++) {
       _clouds.add(_Cloud(
          xOffset: _random.nextDouble(),
          yFactor: _random.nextDouble() * 0.4, // top 40% of screen
          speed: _random.nextDouble() * 0.5 + 0.5,
          scale: _random.nextDouble() * 0.5 + 0.8,
       ));
    }

    // Initialize random birds
    for (int i = 0; i < 3; i++) {
       _birds.add(_Bird(
          xOffset: _random.nextDouble(),
          yFactor: _random.nextDouble() * 0.6, // top 60% of screen
          speed: _random.nextDouble() * 0.8 + 0.8,
          isFlyingRight: _random.nextBool(),
       ));
    }
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _birdController.dispose();
    super.dispose();
  }

  void _onBirdTapped() {
      // Small "cui cui" TTS action
      widget.ttsService.speak("cui-cui");
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        return Stack(
          children: [
            // Animated Clouds
            AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                 return Stack(
                    children: _clouds.map((cloud) {
                        // Calculate moving position based on time
                        double dx = (cloud.xOffset + (_cloudController.value * cloud.speed)) % 1.0;
                        // Move slightly outside bounds so it wraps smoothly
                        double actualX = (dx * (width + 200)) - 100;

                        return Positioned(
                           left: actualX,
                           top: height * cloud.yFactor,
                           child: Opacity(
                               opacity: 0.3, // "Nuages en transparence"
                               child: Icon(Icons.cloud, color: Colors.white, size: 80 * cloud.scale),
                           ),
                        );
                    }).toList(),
                 );
              }
            ),

            // Animated Birds
            AnimatedBuilder(
              animation: _birdController,
              builder: (context, child) {
                 return Stack(
                    children: _birds.map((bird) {
                        double progress = _birdController.value * bird.speed;
                        double dx = (bird.xOffset + progress) % 1.0;
                        
                        double actualX;
                        if (bird.isFlyingRight) {
                            actualX = (dx * (width + 100)) - 50;
                        } else {
                            actualX = width - ((dx * (width + 100)) - 50);
                        }

                        // Bobbing up and down motion using sine wave
                        double bobbingY = sin(progress * pi * 8) * 15;

                        return Positioned(
                           left: actualX,
                           top: height * bird.yFactor + bobbingY,
                           child: GestureDetector(
                               onTap: _onBirdTapped,
                               child: Transform(
                                 alignment: Alignment.center,
                                 transform: Matrix4.rotationY(bird.isFlyingRight ? 0 : pi), // Flip if flying left
                                 child: const Icon(Icons.flutter_dash, color: Colors.black54, size: 40),
                               ),
                           ),
                        );
                    }).toList(),
                 );
              }
            ),
          ],
        );
      }
    );
  }
}

class _Cloud {
  final double xOffset;
  final double yFactor;
  final double speed;
  final double scale;
  _Cloud({required this.xOffset, required this.yFactor, required this.speed, required this.scale});
}

class _Bird {
  final double xOffset;
  final double yFactor;
  final double speed;
  final bool isFlyingRight;
  _Bird({required this.xOffset, required this.yFactor, required this.speed, required this.isFlyingRight});
}
