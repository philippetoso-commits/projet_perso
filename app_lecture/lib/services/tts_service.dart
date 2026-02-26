import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

class TtsService {
  final FlutterTts flutterTts = FlutterTts();
  bool _isInitialized = false;
  Function(String)? onLog;

  void _log(String msg) {
    print("TTS: $msg");
    if (onLog != null) onLog!(msg);
  }

  Future<bool> init() async {
    try {
      _log("Initializing...");
      
      // On Windows, SAPI is used. 
      if (Platform.isWindows) {
          _log("Platform confirmed: Windows");
          // Avoid awaiting getVoices here as it might hang on some systems
          flutterTts.getVoices.then((v) => _log("Available voices: $v")).catchError((e) => _log("GetVoices error: $e"));
          
          try {
            await flutterTts.setLanguage("fr-FR");
            _log("Language set to fr-FR");
          } catch(e) {
            _log("Failed to set language fr-FR: $e");
          }
      } else {
          await flutterTts.setLanguage("fr-FR");
      }
      
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
      await flutterTts.setSpeechRate(0.5);
      
      _isInitialized = true;
      _log("Ready.");
      return true;
    } catch (e) {
      _log("Init Error: $e");
      return false;
    }
  }

  bool get isReady => _isInitialized;

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      _log("Not initialized yet. Skipping speak.");
      return;
    }
    String toSpeak = _refineText(text);
    _log("Speaking '$toSpeak' (original: '$text')");
    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setSpeechRate(0.5);
    var res = await flutterTts.speak(toSpeak);
    _log("Speak result: $res");
  }

  // Dictionnaire de correction phonétique pour forcer le TTS Android
  // à prononcer à la française même en l'absence d'accents ou sur des syllabes seules.
  static const Map<String, String> phoneticMap = {
      'ca': 'ka',
      'qu': 'ke',
      'television': 'télévision',
      'télévision': 'télévision',
      'bibliotheque': 'bibliothèque',
      'bibliothèque': 'bibliothèque',
      'helicoptere': 'hélicoptère',
      'helico': 'hélico',
      'elephant': 'éléphant',
      'rhinoceros': 'rhinocéros',
      'vélo': 'vélo',
      'appareil photo': 'appareil photo', // sécurité
      'super': 'supère', // empêche la francisation en supé
      // Syllabes ambiguës
      'von': 'vont',
      'mon': 'mont',
      'ton': 'ton', // usually ok, but explicitly 'ton'
      'son': 'son',
      'bon': 'bond',
      'don': 'don',
      'pa': 'pas',
      'ma': 'ma',
      'ta': 'ta',
      'sa': 'ça',
      'pe': 'peuh',
      'me': 'meuh',
      'te': 'teuh',
      'se': 'ceuh',
      'le': 'leuh',
      'be': 'beuh', 'ce': 'seuh', 'de': 'deuh', 'fe': 'feuh', 'je': 'jeuh', 'ne': 'nœud', 're': 'reuh', 've': 'veuh', // Added 'h' to ensure sound
      'bo': 'bot', 'fo': 'faux', 'do': 'dos', 'lo': 'lot', 'no': 'nos', 'po': 'pot', 'ro': 'rot', 'vo': 'vos',
      'bu': 'bu', 'du': 'du', 'fu': 'fu', 'lu': 'lutte', 'nu': 'nu', 'pu': 'pu', 'ru': 'ru', 'vu': 'vu',

      // an / en
      'pan': 'pan', 'man': 'ment', 'tan': 'temps', 'lan': 'lent', 'ran': 'rang', 'san': 'sang', 'fan': 'faon', 'van': 'vent', 'nan': 'nant', 'dan': 'dans', 'ban': 'banc',
      'pen': 'pand', 'men': 'ment', 'ten': 'tend', 'len': 'lent', 'ren': 'rend', 'sen': 'sent', 'fen': 'fend', 'ven': 'vent', 'nen': 'nant', 'den': 'dent', 'ben': 'ban',
      
      // in
      'pin': 'pain', 'min': 'main', 'tin': 'teint', 'lin': 'lin', 'rin': 'rein', 'sin': 'sain', 'fin': 'fin', 'vin': 'vin', 'nin': 'nain', 'din': 'daim', 'bin': 'bain',
      
      // oi
      'poi': 'poids', 'moi': 'moi', 'toi': 'toi', 'loi': 'loi', 'roi': 'roi', 'soi': 'soi', 'foi': 'foi', 'voi': 'voit', 'noi': 'noix', 'doi': 'doigt', 'boi': 'bois',
      
      // ch
      'cha': 'chat', 'che': 'cheu', 'cho': 'chaud', 'chu': 'chut', 'chou': 'chou', 'chan': 'chant', 'chon': 'chon',    
      
      // Consonnes finales (C, K, etc.)
      'ec': 'ek', 'ic': 'ik', 'ac': 'ak', 'oc': 'ok', 'uc': 'uk',
      
      // Consonnes doubles (R)
      'bra': 'brah', 'bre': 'breuh', 'bro': 'broh', 'bru': 'bruh',
      'cra': 'crah', 'cre': 'creuh', 'cro': 'croh', 'cru': 'cruh',
      'dra': 'drah', 'dre': 'dreuh', 'dro': 'droh', 'dru': 'druh',
      'fra': 'frah', 'fre': 'freuh', 'fro': 'froh', 'fru': 'fruh',
      'gra': 'grah', 'gre': 'greuh', 'gro': 'groh', 'gru': 'gruh',
      'pra': 'prah', 'pre': 'preuh', 'pro': 'proh', 'pru': 'pruh',
      'tra': 'trah', 'tre': 'treuh', 'tro': 'troh', 'tru': 'truh',
      'vra': 'vrah', 'vre': 'vreuh', 'vro': 'vroh', 'vru': 'vruh',
      
      // Consonnes doubles (L)
      'bla': 'blah', 'ble': 'bleuh', 'blo': 'bloh', 'blu': 'bluh',
      'cla': 'clah', 'cle': 'cleuh', 'clo': 'cloh', 'clu': 'cluh',
      'fla': 'flah', 'fle': 'fleuh', 'flo': 'floh', 'flu': 'fluh',
      'gla': 'glah', 'gle': 'gleuh', 'glo': 'gloh', 'glu': 'gluh',
      'pla': 'plah', 'ple': 'pleuh', 'plo': 'ploh', 'plu': 'pluh',
      
      // sons complexes
      'tion': 'scion', 'sion': 'scion', 'eil': 'èye', 'euil': 'euye', 'ouil': 'ouye', 'ail': 'aïe',
      'geon': 'jon', 'geo': 'jo', 'gea': 'ja', 'geau': 'jo',
  };

  String _refineText(String text) {
      String lower = text.toLowerCase().trim();
      
      // Séparer les mots pour appliquer le dictionnaire à chaque mot individuellement
      List<String> words = lower.split(' ');
      for (int i = 0; i < words.length; i++) {
         String word = words[i].replaceAll(RegExp(r'[^\w\sàâäéèêëîïôöùûüç]'), ''); // remove punctuation for dictionary check
         if (phoneticMap.containsKey(word)) {
            // Reconstruct with punctuation if any existed (simple approach: just replace the word)
            words[i] = words[i].replaceAll(word, phoneticMap[word]!);
         }
      }
      
      return words.join(' ');
  }

  Future<void> speakSlowly(String text) async {
    if (!_isInitialized) return;
    String toSpeak = _refineText(text);
    print("TTS: Speaking slowly '$toSpeak'");
    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setSpeechRate(0.2);
    await flutterTts.speak(toSpeak);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }
}
