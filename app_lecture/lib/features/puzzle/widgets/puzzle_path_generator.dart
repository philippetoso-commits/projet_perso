import 'package:flutter/material.dart';
import '../models/puzzle_cut_data.dart';

/// Générateur de Paths pour les pièces de puzzle.
class PuzzlePathGenerator {
  /// Dessine le chemin (Path) complet pour une pièce spécifique d'une grille 1xN.
  /// [width] et [height] sont les dimensions de la pièce (hors tenons).
  /// [leftCut] est la coupe avec la pièce précédente (si index > 0).
  /// [rightCut] est la coupe avec la pièce suivante (si index < N-1).
  static Path getPiecePath({
    required double width,
    required double height,
    PuzzleCutData? leftCut,
    PuzzleCutData? rightCut,
  }) {
    final path = Path();
    
    // Top-Left corner
    path.moveTo(0, 0);

    // Ligne du Haut
    path.lineTo(width, 0);

    // Bord Droit (avec tenon sortant ou entrant si rightCut défini)
    if (rightCut != null) {
      _drawVerticalEdge(
        path: path,
        startX: width,
        startY: 0,
        endY: height,
        cut: rightCut,
        isRightEdge: true,
        pieceWidth: width,
      );
    } else {
      path.lineTo(width, height);
    }

    // Ligne du Bas
    path.lineTo(0, height);

    // Bord Gauche (avec tenon sortant ou entrant inversé si leftCut défini)
    if (leftCut != null) {
      _drawVerticalEdge(
        path: path,
        startX: 0,
        startY: height,
        endY: 0, // on remonte
        cut: leftCut,
        isRightEdge: false,
        pieceWidth: width,
      );
    } else {
      path.lineTo(0, 0);
    }

    path.close();
    return path;
  }

  /// Dessine un bord vertical bosselé (tenon/mortaise).
  /// [isRightEdge] = true si c'est le bord droit de la pièce courante (on descend).
  /// [isRightEdge] = false si c'est le bord gauche de la pièce courante (on remonte).
  static void _drawVerticalEdge({
    required Path path,
    required double startX,
    required double startY,
    required double endY,
    required PuzzleCutData cut,
    required bool isRightEdge,
    required double pieceWidth,
  }) {
    final height = (endY - startY).abs();
    final directionY = endY > startY ? 1 : -1;
    
    // Position et taille du tenon
    final tabCenterY = startY + (cut.tabHeight * height * directionY);
    // Largeur absolue du tenon
    final tabDepthAbs = cut.tabWidth * pieceWidth;
    
    // Si isRightEdge, direction 1 = vers la droite (+), -1 = vers la gauche (-)
    // Si gauche, direction 1 = tenon appartient à GAUCHE (donc on le dessine vers la droite, creusant la pièce : +X), etc.
    // L'astuce c'est que la pièce gauche P1 dessine le bord droit (+1 sort), la pièce droite P2 dessine le bord gauche (+1 entre en elle).
    final signX = isRightEdge ? cut.direction : cut.direction;
    
    // Déclaration des points de la courbe de bezier
    // On dessine de haut en bas (ou bas en haut) avec 4 paires cubiques.
    final p1 = tabCenterY - (height * 0.15 * directionY); // début courbe
    final p2 = tabCenterY - (height * 0.08 * directionY); // base tab
    final p3 = tabCenterY + (height * 0.08 * directionY); // fin tab
    final p4 = tabCenterY + (height * 0.15 * directionY); // fin courbe

    path.lineTo(startX, p1); // Ligne droite jusqu'au début du tenon

    // Cou de la base vers le bout (courbe rentrante puis sortante)
    path.cubicTo(
      startX, p2, 
      startX + (tabDepthAbs * signX), p2 - (height * 0.05 * directionY), 
      startX + (tabDepthAbs * signX), tabCenterY
    );

    // Bout du tenon vers l'autre cou
    path.cubicTo(
      startX + (tabDepthAbs * signX), p3 + (height * 0.05 * directionY), 
      startX, p3, 
      startX, p4
    );

    path.lineTo(startX, endY); // Fin de la ligne droite
  }
}
