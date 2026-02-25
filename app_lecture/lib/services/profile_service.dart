import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile.dart';
import '../models/word.dart';
import '../models/word_progress.dart';
import 'map_config.dart';

/// Gestion du profil courant et des progressions par profil.
class ProfileService {
  static final ProfileService _instance = ProfileService._();
  static ProfileService get instance => _instance;

  ProfileService._();

  static const String _profilesBoxName = 'profiles';
  static const String _progressBoxName = 'word_progress';
  static const String _settingsBoxName = 'app_settings';
  static const String _currentProfileKey = 'current_profile_key';

  /// Ordre de déblocage des sons en PS : a → e/eu → i/y → o → u → consonnes doubles.
  static const List<String> psSoundOrder = [
    'niveau_1_cv_son_a',
    'niveau_1_cv_son_e_eu',
    'niveau_1_cv_son_i_y',
    'niveau_1_cv_son_o',
    'niveau_1_cv_son_u',
    'niveau_1_consonnes_doubles',
  ];

  static const int _psWordsToUnlockNext = 5;

  Box<Profile>? _profilesBox;
  Box<WordProgress>? _progressBox;
  Box<dynamic>? _settingsBox;

  Future<void> ensureOpen() async {
    _profilesBox ??= await Hive.openBox<Profile>(_profilesBoxName);
    _progressBox ??= await Hive.openBox<WordProgress>(_progressBoxName);
    _settingsBox ??= await Hive.openBox(_settingsBoxName);
  }

  Box<Profile> get profilesBox {
    if (_profilesBox == null) throw StateError('ProfileService not initialized. Call ensureOpen() first.');
    return _profilesBox!;
  }

  Box<WordProgress> get progressBox {
    if (_progressBox == null) throw StateError('ProfileService not initialized. Call ensureOpen() first.');
    return _progressBox!;
  }

  Box<dynamic> get settingsBox {
    if (_settingsBox == null) throw StateError('ProfileService not initialized. Call ensureOpen() first.');
    return _settingsBox!;
  }

  /// Profil actuellement sélectionné (null si aucun).
  Profile? getCurrentProfile() {
    final key = settingsBox.get(_currentProfileKey) as int?;
    if (key == null) return null;
    return profilesBox.get(key);
  }

  /// Définit le profil courant par sa clé Hive.
  Future<void> setCurrentProfile(int profileKey) async {
    await settingsBox.put(_currentProfileKey, profileKey);
  }

  /// Index du son PS débloqué (0 = seulement "a", 5 = tous les sons).
  int getUnlockedPsSoundIndex(int profileKey) {
    final v = settingsBox.get('ps_sound_$profileKey');
    if (v == null) return 0;
    final i = v is int ? v : int.tryParse(v.toString());
    if (i == null || i < 0 || i >= psSoundOrder.length) return 0;
    return i;
  }

  Future<void> setUnlockedPsSoundIndex(int profileKey, int index) async {
    await settingsBox.put('ps_sound_$profileKey', index.clamp(0, psSoundOrder.length - 1));
  }

  /// Thèmes PS autorisés pour ce profil (progression par sons).
  List<String> getAllowedPsThemes(int profileKey) {
    final idx = getUnlockedPsSoundIndex(profileKey);
    return psSoundOrder.sublist(0, idx + 1);
  }

  /// Si le profil a réussi assez de mots du groupe actuel, débloque le son suivant.
  Future<void> tryUnlockNextPsSound(int profileKey, List<Word> wordsInCurrentGroup) async {
    if (wordsInCurrentGroup.isEmpty) return;
    int succeeded = 0;
    for (final w in wordsInCurrentGroup) {
      final key = w.key;
      if (key == null) continue;
      final wp = getWordProgress(profileKey, key as int);
      if (wp != null && wp.successCount >= 1) succeeded++;
    }
    if (succeeded >= _psWordsToUnlockNext) {
      final current = getUnlockedPsSoundIndex(profileKey);
      if (current < psSoundOrder.length - 1) {
        await setUnlockedPsSoundIndex(profileKey, current + 1);
      }
    }
  }

  /// Liste tous les profils.
  List<Profile> getProfiles() => profilesBox.values.toList();

  /// Crée un nouveau profil.
  Future<Profile> addProfile({required String name, int avatarId = 0}) async {
    final p = Profile(name: name.trim(), avatarId: avatarId);
    await profilesBox.add(p);
    return p;
  }

  /// Met à jour un profil existant.
  Future<void> updateProfile(Profile profile) async {
    await profile.save();
  }

  /// Supprime un profil et toute sa progression.
  Future<void> deleteProfile(Profile profile) async {
    final key = profile.key as int;
    final toRemove = progressBox.values.where((wp) => wp.profileKey == key).toList();
    for (final wp in toRemove) await wp.delete();
    await profile.delete();
    if (getCurrentProfile()?.key == key) {
      await settingsBox.delete(_currentProfileKey);
    }
  }

  /// Récupère ou crée la progression d'un mot pour le profil courant.
  WordProgress getOrCreateWordProgress(int profileKey, int wordKey) {
    for (final wp in progressBox.values) {
      if (wp.profileKey == profileKey && wp.wordKey == wordKey) return wp;
    }
    final wp = WordProgress(profileKey: profileKey, wordKey: wordKey);
    progressBox.add(wp);
    return wp;
  }

  /// Intervalles SRS après succès : 1 j → 2 j → 4 j → 7 j (plafond).
  static int _intervalDaysAfterSuccess(WordProgress wp) {
    final n = wp.successCount;
    if (n <= 0) return 1;
    if (n == 1) return 2;
    if (n == 2) return 4;
    return 7;
  }

  /// Sauvegarde la progression (succès/échec) et met à jour nextReview (SRS).
  /// Si [attempts] est fourni et succès, enregistre les étoiles (1 essai=3★, 2=2★, 3+=1★).
  Future<void> saveWordProgress(int profileKey, int wordKey, {required bool success, int? attempts}) async {
    final wp = getOrCreateWordProgress(profileKey, wordKey);
    final now = DateTime.now();
    wp.lastSeen = now;
    if (success) {
      wp.successCount += 1;
      wp.nextReview = now.add(Duration(days: _intervalDaysAfterSuccess(wp)));
      if (attempts != null && attempts >= 1) {
        final stars = attempts <= 1 ? 3 : (attempts <= 2 ? 2 : 1);
        final current = getStars(profileKey, wordKey);
        if (stars > current) await setStars(profileKey, wordKey, stars);
      }
    } else {
      wp.failCount += 1;
      wp.nextReview = now; // à revoir tout de suite
    }
    await wp.save();
  }

  /// Étoiles (1–3) pour un mot, stockées en settings.
  int getStars(int profileKey, int wordKey) {
    final v = settingsBox.get('stars_${profileKey}_$wordKey');
    if (v == null) return 0;
    final i = v is int ? v : int.tryParse(v.toString());
    return (i ?? 0).clamp(0, 3);
  }

  Future<void> setStars(int profileKey, int wordKey, int stars) async {
    await settingsBox.put('stars_${profileKey}_$wordKey', stars.clamp(0, 3));
  }

  /// Index de l'étape de carte débloquée (0 = première, 6 = dernière).
  int getUnlockedMapStepIndex(int profileKey) {
    final v = settingsBox.get('map_step_$profileKey');
    if (v == null) return 0;
    final i = v is int ? v : int.tryParse(v.toString());
    return (i ?? 0).clamp(0, MapConfig.steps.length - 1);
  }

  Future<void> setUnlockedMapStepIndex(int profileKey, int index) async {
    await settingsBox.put('map_step_$profileKey', index.clamp(0, MapConfig.steps.length - 1));
  }

  /// Mots de l'étape [stepIndex] (depuis la box words).
  List<Word> getWordsForStep(int stepIndex, List<Word> allWords) {
    if (stepIndex < 0 || stepIndex >= MapConfig.steps.length) return [];
    final themes = MapConfig.steps[stepIndex].themes;
    return allWords.where((w) => themes.contains(w.theme)).toList();
  }

  /// Débloque l'étape suivante si assez de mots réussis dans l'étape [stepIndex].
  Future<void> tryUnlockNextMapStep(int profileKey, int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= MapConfig.steps.length - 1) return;
    final step = MapConfig.steps[stepIndex];
    int succeeded = 0;
    for (final wp in progressBox.values) {
      if (wp.profileKey != profileKey) continue;
      final word = Hive.box<Word>('words').get(wp.wordKey);
      if (word != null && step.themes.contains(word.theme) && wp.successCount >= 1) {
        succeeded++;
      }
    }
    if (succeeded >= MapConfig.wordsToUnlockNext) {
      final current = getUnlockedMapStepIndex(profileKey);
      if (stepIndex == current && current < MapConfig.steps.length - 1) {
        await setUnlockedMapStepIndex(profileKey, current + 1);
      }
    }
  }

  /// Total étoiles pour un profil sur une étape (pour affichage carte).
  int getStarsForStep(int profileKey, int stepIndex, List<Word> stepWords) {
    int total = 0;
    for (final w in stepWords) {
      final key = w.key;
      if (key != null) total += getStars(profileKey, key as int);
    }
    return total;
  }

  /// Progression d'un mot pour ce profil (null si jamais vu).
  WordProgress? getWordProgress(int profileKey, int wordKey) {
    for (final wp in progressBox.values) {
      if (wp.profileKey == profileKey && wp.wordKey == wordKey) return wp;
    }
    return null;
  }

  /// Toute la progression pour un profil (pour le dashboard).
  List<WordProgress> getAllProgressForProfile(int profileKey) {
    return progressBox.values
        .where((wp) => wp.profileKey == profileKey)
        .toList();
  }

  /// Choisit le prochain mot : ~70 % parmi les mots à revoir (SRS), ~30 % aléatoire.
  Word? pickNextWord(int profileKey, List<Word> levelWords, {Random? random}) {
    if (levelWords.isEmpty) return null;
    final rnd = random ?? Random();
    final now = DateTime.now();
    final due = <Word>[];
    for (final w in levelWords) {
      final key = w.key;
      if (key == null) continue;
      final wp = getWordProgress(profileKey, key as int);
      if (wp == null || wp.nextReview.isBefore(now) || wp.nextReview.isAtSameMomentAs(now)) {
        due.add(w);
      }
    }
    final pool = due.isEmpty ? levelWords : due;
    if (rnd.nextDouble() < 0.7 || due.isEmpty) {
      return pool[rnd.nextInt(pool.length)];
    }
    return levelWords[rnd.nextInt(levelWords.length)];
  }
}
