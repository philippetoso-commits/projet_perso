import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/puzzle_cut_data.dart';
/// Painter pour dessiner une pièce de puzzle spécifique extraite de l'image source.
class PuzzlePiecePainter extends CustomPainter {
  final ui.Image image;
  final Size boardSize;
  final int pieceIndex;
  final int totalPieces;
  final String text; // La syllabe
  final PuzzleCutData? leftCut;
  final PuzzleCutData? rightCut;
  final bool isPlaced;
  final bool isDragging;

  PuzzlePiecePainter({
    required this.image,
    required this.boardSize,
    required this.pieceIndex,
    required this.totalPieces,
    required this.text,
    this.leftCut,
    this.rightCut,
    this.isPlaced = false,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // On utilise la taille absolue d'une pièce calée sur le plateau complet.
    final baseWidth = boardSize.width / totalPieces;
    final height = boardSize.height;

    // Le path géométrique de la pièce
    final path = getPiecePath(baseWidth, height);

    // Ombre : uniquement si pas placé pour que les pièces validées s'emboîtent sans démarcation
    if (isDragging) {
      canvas.drawShadow(path, Colors.black87, 10.0, false);
    } else if (!isPlaced) {
      canvas.drawShadow(path, Colors.black45, 4.0, false);
    }

    // On clip le canvas avec la forme de la pièce
    canvas.save();
    canvas.clipPath(path);

    // L'image source complète
    final srcWidth = image.width.toDouble();
    final srcHeight = image.height.toDouble();
    
    // Rect destination : on décale l'image vers la gauche de (pieceIndex * baseWidth)
    final destRect = Rect.fromLTWH(
      -pieceIndex * baseWidth,
      0,
      totalPieces * baseWidth,
      height,
    );

    // Dessin de l'image
    paintImage(
      canvas: canvas,
      rect: destRect,
      image: image,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );

    // Même placé, l'enfant peut vouloir re-lire la syllabe (translucidité sur fond sombre)
    // On dessine un calque d'assombrissement léger pour faire ressortir le texte
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: isPlaced ? 0.35 : 0.45),
    );

    // Trouvons le centre X optique pour le texte
    double centerX = baseWidth / 2;
    if (leftCut != null) centerX += leftCut!.direction * leftCut!.tabWidth * baseWidth * 0.15;
    if (rightCut != null) centerX += rightCut!.direction * rightCut!.tabWidth * baseWidth * 0.15;

    // Dessin de la syllabe au format gros et visible
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          shadows: [
            const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
            Shadow(color: const Color(0xFF7C4DFF).withValues(alpha: 0.8), blurRadius: 10, offset: const Offset(0, 0)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: baseWidth * 1.5);
    final textX = centerX - textPainter.width / 2;
    final textY = (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));

    canvas.restore();

    // Bordure
    if (!isPlaced) {
      // Bordure blanche pour délimiter les pièces hors plateau
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, borderPaint);
    }
    // Si la pièce est placée, AUCUNE bordure ! Pour qu'elles s'emboîtent parfaitement.
  }

  Path getPiecePath(double width, double height) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(width, 0);

    // Bord droit
    if (rightCut != null) {
      _drawVerticalEdge(path, width, 0, height, rightCut!, 1, width);
    } else {
      path.lineTo(width, height);
    }

    path.lineTo(0, height);

    // Bord gauche (on remonte)
    if (leftCut != null) {
      _drawVerticalEdge(path, 0, height, 0, leftCut!, -1, width);
    } else {
      path.lineTo(0, 0);
    }

    path.close();
    return path;
  }

  void _drawVerticalEdge(
    Path path, double startX, double startY, double endY,
    PuzzleCutData cut, double xSign, double pieceWidth
  ) {
    // Pour garantir un emboîtement PARFAIT au pixel près, on doit toujours calculer
    // la courbe de Bézier dans le même sens (de haut en bas), puis l'ajouter au Path
    // soit dans le sens normal (bord droit, on descend), soit en la renversant (bord gauche, on monte).
    
    // xSign: 1 pour bord droit (la pièce courante fournit le tab à droite)
    // xSign: -1 pour bord gauche (la pièce courante subit le tab venant de gauche)
    
    // On travaille toujours en absolu Top -> Bottom
    final double topY = min(startY, endY);
    final double bottomY = max(startY, endY);
    final double h = bottomY - topY;
    
    // Le centre du tab est toujours proportionnel à la hauteur depuis le haut
    final cy = topY + cut.tabHeight * h;
    
    // La largeur absolue du tab. 
    // cut.direction = 1 (vers la droite globale), cut.direction = -1 (vers la gauche globale)
    // On veut le décalage X absolu sur l'écran :
    final tabW = cut.tabWidth * pieceWidth * cut.direction;

    // Mesures du "Ω" classique
    final halfNeck = h * 0.055;
    final radius = h * 0.12;

    // On crée un sous-path qui va STRICTEMENT de haut en bas
    final edgePath = Path();
    edgePath.moveTo(startX, topY);
    edgePath.lineTo(startX, cy - halfNeck);
    
    // 1ère courbe
    edgePath.cubicTo(
      startX - (tabW * 0.25), cy - radius, 
      startX + tabW, cy - radius * 1.8, 
      startX + tabW, cy
    );
    
    // 2ème courbe
    edgePath.cubicTo(
      startX + tabW, cy + radius * 1.8, 
      startX - (tabW * 0.25), cy + radius, 
      startX, cy + halfNeck
    );
    
    edgePath.lineTo(startX, bottomY);

    // Si on dessine de bas en haut (startY > endY, donc le bord gauche), 
    // on doit ajouter ce tracé "à l'envers" au path principal.
    // Malheureusement Flutter path.addPath ne permet pas de renverser le sens de tracé.
    // On doit donc extraire les points ou utiliser une astuce avec addPath et matrix,
    // mais la façon la plus sûre pour un CustomPainter est d'utiliser les métriques de path
    // OU de réécrire les cubics de bas en haut mathématiquement.
    
    if (startY < endY) {
      // Sens normal (bord droit, de haut en bas)
      // Le path principal est à currentPoint = (startX, topY), on a juste à dessiner les courbes en descendant.
      path.lineTo(startX, cy - halfNeck);
      path.cubicTo(
        startX - (tabW * 0.25), cy - radius, 
        startX + tabW, cy - radius * 1.8, 
        startX + tabW, cy
      );
      path.cubicTo(
        startX + tabW, cy + radius * 1.8, 
        startX - (tabW * 0.25), cy + radius, 
        startX, cy + halfNeck
      );
      path.lineTo(startX, bottomY);
    } else {
      // Sens inverse (bord gauche, de bas en haut)
      // Le path principal est à currentPoint = (startX, bottomY), on dessine en montant.
      // On inverse l'ordre et les Y des points de contrôle !
      path.lineTo(startX, cy + halfNeck);
      path.cubicTo(
        startX - (tabW * 0.25), cy + radius, 
        startX + tabW, cy + radius * 1.8, 
        startX + tabW, cy
      );
      path.cubicTo(
        startX + tabW, cy - radius * 1.8, 
        startX - (tabW * 0.25), cy - radius, 
        startX, cy - halfNeck
      );
      path.lineTo(startX, topY);
    }
  }

  @override
  bool shouldRepaint(PuzzlePiecePainter oldDelegate) {
    return oldDelegate.isDragging != isDragging ||
           oldDelegate.isPlaced != isPlaced ||
           oldDelegate.pieceIndex != pieceIndex ||
           oldDelegate.image != image;
  }
}
