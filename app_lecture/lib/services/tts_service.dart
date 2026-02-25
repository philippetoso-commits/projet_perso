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
    _log("Speaking '$text'");
    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setSpeechRate(0.5);
    var res = await flutterTts.speak(text);
    _log("Speak result: $res");
  }

  // Manual overrides for pronunciation
  static const Map<String, String> phoneticMap = {
      'ca': 'ka',
      'qu': 'ke',
  };

  String _refineText(String text) {
      String lower = text.toLowerCase();
      if (phoneticMap.containsKey(lower)) {
          return phoneticMap[lower]!;
      }
      return text;
  }

  Future<void> speakSlowly(String text) async {
    if (!_isInitialized) return;
    print("TTS: Speaking slowly '$text'");
    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setSpeechRate(0.2);
    String toSpeak = _refineText(text);
    await flutterTts.speak(toSpeak);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }
}
