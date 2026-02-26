
import 'package:hive/hive.dart';

part 'word.g.dart'; // Hive generator file

@HiveType(typeId: 0)
class Word extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final List<String> syllables;

  @HiveField(2)
  final String theme;

  @HiveField(3)
  final String imagePath;

  // SRS Fields
  @HiveField(4)
  int level; // 1 to 5

  @HiveField(5)
  DateTime lastSeen;

  @HiveField(6)
  DateTime nextReview;

  @HiveField(7)
  int successCount;

  @HiveField(8)
  List<String> failedPhonemes;

  Word({
    required this.text,
    required this.syllables,
    required this.theme,
    required this.imagePath,
    this.level = 1,
    required this.lastSeen,
    required this.nextReview,
    this.successCount = 0,
    this.failedPhonemes = const [],
  });

  // Factory to create from JSON
  factory Word.fromJson(Map<String, dynamic> json) {
    final mot = json['mot'] ?? "Sans nom";
    final theme = json['theme'] ?? "divers";
    
    // Syllables list
    final List<String> syllables = json['syllabes'] != null 
          ? List<String>.from(json['syllabes']) 
          : [mot];

    // Fallback for image path (scripts Pixabay/Pexels enregistrent en .jpg)
    String img = json['image_path'] ?? "";
    if (img.isEmpty) {
        String fileMot = mot.toLowerCase().replaceAll(' ', '_');
        fileMot = fileMot
            .replaceAll(RegExp(r'[éèêë]'), 'e')
            .replaceAll(RegExp(r'[àâä]'), 'a')
            .replaceAll(RegExp(r'[îï]'), 'i')
            .replaceAll(RegExp(r'[ôö]'), 'o')
            .replaceAll(RegExp(r'[ùûü]'), 'u')
            .replaceAll(RegExp(r'[ç]'), 'c');
        img = "assets/images/$theme/$fileMot.jpg";
    }
    // Normalisation : slash Unix, sans antislash ni slash initial (compatibilité bundle Flutter)
    img = img.replaceAll(r'\', '/').trim();
    if (img.startsWith('/')) img = img.substring(1);

    // Niveau 1 (PS) : uniquement les thèmes "sons" (niveau_1_cv_son_*, consonnes_doubles).
    // Niveaux 2–4 : pour les autres thèmes (aliments, animaux, etc.), niveau basé sur les syllabes
    // (les JSON ont souvent "level":1 par défaut, on l'ignore pour ces thèmes).
    int level;
    if (theme.startsWith('niveau_1_cv_son') || theme.startsWith('niveau_1_consonnes_doubles')) {
      level = 1; // Petite section — sons uniquement
    } else {
      // Heuristique par nombre de syllabes pour aliments, animaux, etc.
      if (syllables.length <= 1 && mot.length <= 4) {
        level = 1; // PS
      } else if (syllables.length <= 2) {
        level = 2; // MS
      } else if (syllables.length == 3) {
        level = 3; // GS
      } else {
        level = 4; // CP
      }
    }

    return Word(
      text: mot,
      syllables: syllables,
      theme: theme,
      imagePath: img,
      level: level,
      lastSeen: DateTime.now(),
      nextReview: DateTime.now(),
      successCount: json['success_count'] ?? 0,
      failedPhonemes: json['failed_phonemes'] != null 
          ? List<String>.from(json['failed_phonemes']) 
          : const [],
    );
  }
}
