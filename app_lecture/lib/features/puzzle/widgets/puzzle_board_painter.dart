import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/puzzle_cut_data.dart';
import 'puzzle_piece_painter.dart';

/// Painter pour le plateau de jeu (board).
/// Dessine l'image fantôme (opacité faible) globale et les contours 
/// des emplacements vides, ainsi que les pièces déjà placées.
class PuzzleBoardPainter extends CustomPainter {
  final ui.Image image;
  final int totalPieces;
  final List<PuzzleCutData> cuts; // taille: totalPieces - 1
  final List<bool> placedPieces;  // taille: totalPieces
  final List<String> syllables;

  PuzzleBoardPainter({
    required this.image,
    required this.totalPieces,
    required this.cuts,
    required this.placedPieces,
    required this.syllables,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseWidth = size.width / totalPieces;
    final height = size.height;
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Fond : Image globale (fantôme) très claire 
    canvas.saveLayer(dstRect, Paint()..color = Colors.white.withValues(alpha: 0.3));
    canvas.drawImageRect(image, srcRect, dstRect, Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();

    // 2. Dessiner les pièces (vides = contour / pleines = image parfaitement découpée)
    for (int i = 0; i < totalPieces; i++) {
      final leftCut = i > 0 ? cuts[i - 1] : null;
      final rightCut = i < totalPieces - 1 ? cuts[i] : null;
      final isPlaced = placedPieces[i];

      canvas.save();
      canvas.translate(i * baseWidth, 0);

      final piecePainter = PuzzlePiecePainter(
        image: image,
        boardSize: size,
        pieceIndex: i,
        totalPieces: totalPieces,
        text: syllables[i],
        leftCut: leftCut,
        rightCut: rightCut,
        isPlaced: isPlaced,
        isDragging: false,
      );

      if (!isPlaced) {
        // Juste le contour vide (stroke)
        final path = piecePainter.getPiecePath(baseWidth, height);
        final strokePaint = Paint()
           ..color = Colors.black.withValues(alpha: 0.2)
           ..style = PaintingStyle.stroke
           ..strokeWidth = 2.0;
        canvas.drawPath(path, strokePaint);
      } else {
        // On délègue au painter de pièce pour dessiner la pièce placée (image recadrée + stroke vert)
        piecePainter.paint(canvas, Size(baseWidth, height));
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(PuzzleBoardPainter oldDelegate) {
    bool piecesChanged = false;
    for (int i = 0; i < totalPieces; i++) {
      if (oldDelegate.placedPieces[i] != placedPieces[i]) {
        piecesChanged = true;
        break;
      }
    }
    return piecesChanged || oldDelegate.image != image;
  }
}
