import 'dart:math';

/// Définit la forme géométrique d'une coupe entre deux pièces de puzzle.
/// Une coupe est un bord vertical avec un tenon (tab) ou une mortaise.
class PuzzleCutData {
  /// Direction du tenon : 1 (vers la droite / pièce suivante), -1 (vers la gauche / pièce précédente)
  final int direction;

  /// Hauteur (en % de 0.0 à 1.0) où se trouve le centre du tenon (typiquement entre 0.3 et 0.7)
  final double tabHeight;

  /// Largeur/Amplitude du tenon (en % de la largeur de la pièce, ex: 0.25)
  final double tabWidth;

  PuzzleCutData({
    required this.direction,
    required this.tabHeight,
    required this.tabWidth,
  });

  /// Crée un bord de puzzle aléatoire
  factory PuzzleCutData.random(Random rng) {
    return PuzzleCutData(
      direction: rng.nextBool() ? 1 : -1,
      // Centre entre 35% et 65% de la hauteur
      tabHeight: 0.35 + rng.nextDouble() * 0.3,
      // Amplitude entre 22% et 32% (pour être visible mais pas trop grand)
      tabWidth: 0.22 + rng.nextDouble() * 0.1,
    );
  }
}
