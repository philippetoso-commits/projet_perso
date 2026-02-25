import 'package:flutter/material.dart';
import 'levenshtein.dart';

class PedagogicUtils {
  // Digraphes à colorier (Priorité aux plus longs)
  static const Map<String, Color> digraphColors = {
    'ou': Colors.red,
    'an': Colors.orange,
    'en': Colors.orange,
    'on': Colors.brown,
    'in': Colors.purple,
    'oi': Colors.blue,
    'eau': Colors.blue,
    'au': Colors.yellow,
    'ai': Colors.blue,
    'ei': Colors.blue,
    'eu': Colors.blue,
    'oeu': Colors.blue,
    'un': Colors.purple,
    'gn': Colors.green,
    'ph': Colors.green,
    'ch': Colors.green,
  };

  // Code couleur strict : consonnes = noir, voyelles = bleu, lettres muettes = gris
  static const Color consonantColor = Colors.black;
  static const Color vowelColor = Color(0xFF1565C0); // Bleu franc
  static const Color silentLetterColor = Color(0xFF9E9E9E); // Gris marqué (lettres muettes)

  /// Analyse une syllabe et retourne une liste de TextSpan avec les couleurs
  static List<TextSpan> getStyledSyllable(String syllable, {bool isLastSyllable = false}) {
    List<TextSpan> spans = [];
    String remaining = syllable; // Keep original for display
    String remainingLower = syllable.toLowerCase(); // For logic
    
    // Parsing : digraphes, voyelles, consonnes, lettres muettes
    while (remaining.isNotEmpty) {
      bool matched = false;
      
      // 1. Lettre muette : E final (syllabe unique "e")
      if (isLastSyllable && remainingLower == 'e') {
         spans.add(TextSpan(
            text: remaining,
            style: const TextStyle(
              color: silentLetterColor,
              fontWeight: FontWeight.normal,
            ),
          ));
          remaining = '';
          remainingLower = '';
          matched = true;
          continue;
      }

      // 2. Digraphes (ou, an, ch, etc.) — couleurs sémantiques
      var keys = digraphColors.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
      
      for (var digraph in keys) {
        if (remainingLower.startsWith(digraph)) {
          String displaySlice = remaining.substring(0, digraph.length);
          spans.add(TextSpan(
            text: displaySlice,
            style: TextStyle(
              color: digraphColors[digraph],
              fontWeight: FontWeight.bold,
            ),
          ));
          remaining = remaining.substring(digraph.length);
          remainingLower = remainingLower.substring(digraph.length);
          matched = true;
          break;
        }
      }

      if (!matched) {
        String char = remaining[0];
        String charLower = remainingLower[0];
        String vowelsList = "aeiouyéèêëàâîïôöùûü";
        Color charColor = vowelsList.contains(charLower) ? vowelColor : consonantColor;

        spans.add(TextSpan(
          text: char,
          style: TextStyle(
            color: charColor,
            fontWeight: FontWeight.bold,
          ),
        ));
        remaining = remaining.substring(1);
        remainingLower = remainingLower.substring(1);
      }
    }
    return spans;
  }

  // --- Logic for Voice Validation ---

  static String normalize(String text) {
    if (text.isEmpty) return "";
    String res = text.toLowerCase();
    
    // Accents & Ligatures
    // STRICT MODE: We keep accents to differentiate 'blé' vs 'ble'.
    // We only normalize standard ligatures/case.
    
    // However, typical normalization maps oe -> œ. 
    // Here we split ligatures to standard chars to help engine matching if engine outputs separate chars.
    res = res.replaceAll('œ', 'oe');
    res = res.replaceAll('æ', 'ae');
    
    // Remove punctuation (keep accents!)
    res = res.replaceAll(RegExp(r'[^\w\sàáâäéèêëîïôöùûüÿçÀÁÂÄÉÈÊËÎÏÔÖÙÛÜŸÇ-]'), ''); // Added accents to allowed char class
    return res.trim();
  }

  // Common reading mistakes/homophones
  static const Map<String, List<String>> manualHomophones = {
    'lait': ['les', 'laid', 'laie', 'le', 'l\'ai', 'lai'],
    'oeuf': ['euf', 'neuf', 'oeufs'],
    'mer': ['maire', 'mere', 'mre'],
    'fils': ['fis', 'fil'],
    'dos': ['do', 'd\'eau', 'deau', 'dau'],
    'riz': ['ri', 'rit', 'rie', 'ry'],
    'sel': ['selle', 'celle', 'c\'est', 'cel'],
    'ail': ['aie', 'aille', 'aye'],
    'eau': ['o', 'au', 'aux', 'haut'],
    'pain': ['pin', 'peins', 'pains'],
    'miel': ['mielle'],
    'noix': ['noi', 'noie'],
    'vin': ['vain', 'vingt'],
    'bol': ['bole', 'ball'],
    'bus': ['buse', 'boss'],
  };

  static bool isValidReading(String spoken, String target) {
    String nSpoken = normalize(spoken);
    String nTarget = normalize(target);

    if (nSpoken.isEmpty) return false;

    // 0. STRIP DETERMINERS (le, la, un, une, du, des, mon, ton, son...)
    // This allows "le lit" to match "lit" cleanly
    List<String> determiners = ['le', 'la', 'un', 'une', 'du', 'des', 'mon', 'ton', 'son', 'ma', 'ta', 'sa', 'ce', 'cette'];
    for (var det in determiners) {
        if (nSpoken.startsWith("$det ")) {
            nSpoken = nSpoken.substring(det.length + 1).trim();
            break; // Only strip the first one
        }
    }

    // 0. MANUAL HOMOPHONES — égalité stricte uniquement (pas contains)
    if (manualHomophones.containsKey(nTarget)) {
      for (String variant in manualHomophones[nTarget]!) {
        if (nSpoken == variant) return true;
      }
    }

    // 1. Exact Match (after normalization)
    if (nSpoken == nTarget) return true;

    // 2. Levenshtein — 1 erreur max ; 2 uniquement si même première lettre (évite chat/lion)
    int dist = levenshtein(nSpoken, nTarget);
    int threshold = 1;
    if (nTarget.length >= 4 && dist == 2) {
      if (nSpoken.isNotEmpty && nTarget.isNotEmpty && nSpoken[0] == nTarget[0]) {
        threshold = 2;
      }
    }
    if (nTarget.length <= 1 && dist > 0) threshold = 0;
    if (dist <= threshold) return true;

    // 3. Contenance — uniquement si phrase courte (déterminant + mot), pas phrase longue
    if (nTarget.length >= 4 && nSpoken.contains(nTarget) && nSpoken.length <= nTarget.length + 4) {
      return true;
    }
    return false; 
  }

  // Simplistic syllable error finder
  static int findFirstErrorSyllable(String spoken, List<String> targetSyllables) {
    String nSpoken = normalize(spoken);
    int currentSearchIndex = 0;
    
    for (int i = 0; i < targetSyllables.length; i++) {
        String syl = normalize(targetSyllables[i]);
        if (syl.isEmpty) continue;

        int matchIndex = nSpoken.indexOf(syl, currentSearchIndex);
        if (matchIndex == -1) {
            return i; // Syllable not found in sequence
        }
        currentSearchIndex = matchIndex + syl.length;
    }
    return -1; 
  }
}
