import 'dart:math';
import 'package:flutter/material.dart';

/// Célébration thématique Puzzle : pluie de pièces de puzzle colorées.
/// Remplace la pluie d'étoiles du module Mot Mystère.
class PuzzlePieceRainCelebration extends StatefulWidget {
  final VoidCallback onComplete;

  const PuzzlePieceRainCelebration({super.key, required this.onComplete});

  @override
  State<PuzzlePieceRainCelebration> createState() =>
      _PuzzlePieceRainCelebrationState();
}

class _PuzzlePieceRainCelebrationState
    extends State<PuzzlePieceRainCelebration>
    with TickerProviderStateMixin {
  static const int _pieceCount = 20;
  static const int _durationMs = 5500;

  late AnimationController _controller;
  List<_PuzzlePieceData> _pieces = [];
  bool _initialized = false;

  static const _colors = [
    Color(0xFF7C4DFF),
    Color(0xFFFF6D00),
    Color(0xFF2E7D32),
    Color(0xFFD81B60),
    Color(0xFF0288D1),
    Color(0xFFF9A825),
    Color(0xFF00838F),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _durationMs),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final rng = Random();
    final w = MediaQuery.of(context).size.width;
    _pieces = List.generate(_pieceCount, (i) {
      return _PuzzlePieceData(
        x: 20 + rng.nextDouble() * (w - 40),
        delay: rng.nextDouble() * 0.3,
        speed: 0.5 + rng.nextDouble() * 0.5,
        size: 28 + rng.nextDouble() * 22,
        rotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextBool() ? 1 : -1) * (0.5 + rng.nextDouble()),
        color: _colors[i % _colors.length],
        sway: (rng.nextBool() ? 1 : -1) * (8 + rng.nextDouble() * 12),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final overlayOpacity =
                (_controller.value / 0.15).clamp(0.0, 1.0) * 0.45;
            return Container(
              color: Colors.black.withValues(alpha: overlayOpacity),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Pièces de puzzle tombantes
                  ..._pieces.map((piece) {
                    final t =
                        ((_controller.value - piece.delay) / (1.0 - piece.delay))
                            .clamp(0.0, 1.0);
                    final y =
                        -piece.size + t * (h + piece.size * 2);
                    final sway = piece.sway * sin(t * pi * 2);
                    final x = (piece.x + sway)
                        .clamp(0.0, w - piece.size)
                        .toDouble();
                    final rotation =
                        piece.rotation + t * pi * 2 * piece.rotationSpeed;
                    final opacity = t < 0.08
                        ? t / 0.08
                        : (t > 0.9 ? (1 - t) / 0.1 : 1.0);

                    return Positioned(
                      left: x,
                      top: y,
                      width: piece.size,
                      height: piece.size,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: rotation,
                          child: CustomPaint(
                            painter: _PuzzlePiecePainter(color: piece.color),
                            size: Size(piece.size, piece.size),
                          ),
                        ),
                      ),
                    );
                  }),

                  // "Bravo !"
                  Positioned(
                    top: h * 0.08,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 450),
                        builder: (_, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Column(
                          children: [
                            Text(
                              'Bravo ! 🧩',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Puzzle complété !',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(color: Colors.black45, blurRadius: 6),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Données d'une pièce individuelle.
class _PuzzlePieceData {
  final double x, delay, speed, size, rotation, rotationSpeed, sway;
  final Color color;

  const _PuzzlePieceData({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.sway,
  });
}

/// Dessinateur de pièce de puzzle : rectangle + tenon haut + mortaise bas.
class _PuzzlePiecePainter extends CustomPainter {
  final Color color;

  const _PuzzlePiecePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final r = w * 0.18; // rayon des tenons/mortaises

    final path = Path();
    // Coin haut-gauche
    path.moveTo(w * 0.25, 0);
    // Haut avec tenon au centre
    path.lineTo(w * 0.38, 0);
    path.arcToPoint(Offset(w * 0.62, 0),
        radius: Radius.circular(r), clockwise: true);
    path.lineTo(w * 0.75, 0);
    // Côté droit avec mortaise
    path.lineTo(w * 0.75, h * 0.38);
    path.arcToPoint(Offset(w * 0.75, h * 0.62),
        radius: Radius.circular(r), clockwise: false);
    path.lineTo(w * 0.75, h);
    // Bas sans tenon (simple)
    path.lineTo(w * 0.25, h);
    // Côté gauche avec tenon
    path.lineTo(w * 0.25, h * 0.62);
    path.arcToPoint(Offset(w * 0.25, h * 0.38),
        radius: Radius.circular(r), clockwise: false);
    path.lineTo(w * 0.25, 0);
    path.close();

    // Ombre
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, paint);

    // Reflet blanc
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(_PuzzlePiecePainter old) => old.color != color;
}
