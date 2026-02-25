# Documentation Reconnaissance Vocale (DEBUG SON)

Voici le code utilisé pour la capture de la voix et la validation "intelligente" dans l'application.

## 1. Service de Reconnaissance (`stt_service.dart`)

Ce service utilise le package `speech_to_text`.
Nous avons configuré le délai de pause à **2 secondes** pour être réactif sur les mots courts.

```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<bool> init({Function(String)? onError}) async {
    _isAvailable = await _speech.initialize(
      onError: (val) {
        print('onError: $val');
        if (onError != null) onError(val.errorMsg);
      },
      onStatus: (val) => print('onStatus: $val'),
    );
    return _isAvailable;
  }

  Future<void> listen(Function(String, bool) onResult) async {
    if (_isAvailable && !_speech.isListening) {
      _speech.listen(
        onResult: (val) => onResult(val.recognizedWords, val.finalResult),
        localeId: "fr_FR",
        pauseFor: const Duration(seconds: 2), // ATTENTE SILENCE : 2 sec
        listenFor: const Duration(seconds: 30),
        partialResults: true,
      );
    }
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      _speech.stop();
    }
  }
}
```

## 2. Validation Intelligente (`pedagogic_utils.dart`)

C'est ici que nous nettoyons le texte (suppression des accents, minuscules) et gérons les **Homophones** (Dos = Do, D'eau) pour éviter les faux négatifs.

```dart
  // Nettoyage (Accents, Ponctuation)
  static String normalize(String text) {
    if (text.isEmpty) return "";
    String res = text.toLowerCase();
    
    // Accents
    res = res.replaceAll(RegExp(r'[àáâä]'), 'a');
    res = res.replaceAll(RegExp(r'[éèêë]'), 'e');
    res = res.replaceAll(RegExp(r'[îï]'), 'i');
    res = res.replaceAll(RegExp(r'[ôö]'), 'o');
    res = res.replaceAll(RegExp(r'[ùûü]'), 'u');
    // ...
    // Ponctuation
    res = res.replaceAll(RegExp(r'[^\w\s]'), '');
    return res.trim();
  }

  // Liste des Homophones Manuels (Pour corriger le moteur vocal)
  static const Map<String, List<String>> manualHomophones = {
    'lait': ['les', 'laid', 'laie', 'le', 'l\'ai', 'lai'],
    'oeuf': ['euf', 'neuf', 'oeufs'],
    'mer': ['maire', 'mere', 'mre'],
    'fils': ['fis', 'fil'],
    'dos': ['do', 'd\'eau', 'deau', 'dau'],  // <--- Ajout pour DOS
    'riz': ['ri', 'rit', 'rie', 'ry'],
    'sel': ['selle', 'celle', 'c\'est', 'cel'],
    'ail': ['aie', 'aille', 'aye'],
    'eau': ['o', 'au', 'aux', 'haut'],
    'pain': ['pin', 'peins', 'pains'],
    'miel': ['mielle'],
    // ...
  };

  // Algorithme de Validation
  static bool isValidReading(String spoken, String target) {
    String nSpoken = normalize(spoken); // ex: "d'eau" -> "deau"
    String nTarget = normalize(target); // ex: "dos" -> "dos"

    if (nSpoken.isEmpty) return false;

    // 1. Vérification Homophones
    if (manualHomophones.containsKey(nTarget)) {
       for (String variant in manualHomophones[nTarget]!) {
         // Si le mot dit correspond à une variante connue (ex: "deau" pour "dos")
         if (nSpoken.contains(variant) || nSpoken == variant) {
           return true; 
         }
       }
    }

    // 2. Mots très courts (<= 3 lettres)
    // Si pas dans les homophones, on exige que le mot cible soit DANS ce qui est dit.
    if (nTarget.length <= 3) {
      return nSpoken.contains(nTarget); 
    }

    // 3. Distance de Levenshtein (Tolérance aux petites fautes pour mots longs)
    int dist = levenshtein(nSpoken, nTarget);
    int threshold = nTarget.length >= 7 ? 2 : 1;
    
    if (nSpoken.contains(nTarget)) return true;

    return dist <= threshold; 
  }
```
