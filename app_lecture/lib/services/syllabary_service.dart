import 'package:flutter/services.dart';

/// Résultat de recherche dans le lexique V4 (découpe + orthographe avec accents).
class SyllabaryEntry {
  final String displayWord;
  final List<String> syllables;

  SyllabaryEntry({required this.displayWord, required this.syllables});
}

/// Charge mots_decoupesV4.txt et fournit la découpe syllabique avec accents.
class SyllabaryService {
  static final SyllabaryService _instance = SyllabaryService._();
  static SyllabaryService get instance => _instance;

  SyllabaryService._();

  static const String _assetPath = 'assets/mots_decoupesV4.txt';

  Map<String, SyllabaryEntry> _map = {};
  Map<String, String> _normalizedToKey = {};
  bool _loaded = false;

  static String _normalize(String s) {
    const accents = 'àâäéèêëïîôùûüçæœ';
    const sans = 'aaaeeeeiioouucao';
    String r = s.toLowerCase();
    for (int i = 0; i < accents.length; i++) {
      r = r.replaceAll(accents[i], sans[i]);
    }
    return r;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final String data = await rootBundle.loadString(_assetPath);
      final lines = data.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('Liste') || trimmed.startsWith('=')) continue;
        final tab = trimmed.indexOf('\t');
        if (tab <= 0) continue;
        final word = trimmed.substring(0, tab).trim();
        final decoupe = trimmed.substring(tab + 1).trim();
        final syllables = decoupe.split('-').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (word.isEmpty || syllables.isEmpty) continue;
        _map[word] = SyllabaryEntry(displayWord: word, syllables: syllables);
        _normalizedToKey[_normalize(word)] = word;
      }
      _loaded = true;
    } catch (e) {
      // Fichier absent ou erreur : on garde _loaded false, getEntry retournera null
    }
  }

  /// Retourne l'entrée V4 pour ce mot (orthographe avec accents + syllabes), ou null.
  SyllabaryEntry? getEntry(String word) {
    if (word.isEmpty) return null;
    final w = word.trim();
    if (_map.containsKey(w)) return _map[w];
    final n = _normalize(w);
    final key = _normalizedToKey[n];
    if (key != null) return _map[key];
    return null;
  }

  /// Syllabes pour l'affichage (avec accents). Fallback sur [fallbackSyllables] si pas dans V4.
  List<String> getSyllablesForDisplay(String word, List<String> fallbackSyllables) {
    final entry = getEntry(word);
    if (entry != null) return entry.syllables;
    return fallbackSyllables;
  }

  /// Mot avec accents pour l'affichage. Retourne [word] si pas trouvé dans V4.
  String getDisplayWord(String word) {
    final entry = getEntry(word);
    if (entry != null) return entry.displayWord;
    return word;
  }
}
