import 'package:hive/hive.dart';

part 'word_progress.g.dart';

/// Progression d'un mot pour un profil donné (SRS par enfant).
@HiveType(typeId: 2)
class WordProgress extends HiveObject {
  @HiveField(0)
  int profileKey;

  @HiveField(1)
  int wordKey;

  @HiveField(2)
  int successCount;

  @HiveField(3)
  int failCount;

  @HiveField(4)
  DateTime lastSeen;

  @HiveField(5)
  DateTime nextReview;

  WordProgress({
    required this.profileKey,
    required this.wordKey,
    this.successCount = 0,
    this.failCount = 0,
    DateTime? lastSeen,
    DateTime? nextReview,
  })  : lastSeen = lastSeen ?? DateTime.now(),
        nextReview = nextReview ?? DateTime.now();
}
