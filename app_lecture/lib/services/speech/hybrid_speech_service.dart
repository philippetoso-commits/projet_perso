import 'i_speech_service.dart';
import 'system_speech_service.dart';
import 'vosk_speech_service.dart';
import '../log_service.dart';

class HybridSpeechService implements ISpeechService {
  final VoskSpeechService _vosk = VoskSpeechService();
  final SystemSpeechService _system = SystemSpeechService();
  
  bool _preferVosk = true;
  bool _voskAvailable = false;
  bool _systemAvailable = false;

  @override
  Future<bool> init({Function(String error)? onError}) async {
    // 1. Try Initialize System (Always good to have)
    _systemAvailable = await _system.init(onError: (e) {
       LogService().add("System Init Warning: $e");
    });
    LogService().add("System STT Available: $_systemAvailable");

    // 2. Try Initialize Vosk
    _voskAvailable = await _vosk.init(onError: (e) {
      LogService().add("Vosk Init Failed: $e -> Fallback to System");
      if (onError != null) onError("Vosk indisponible, bascule système.");
    });
    LogService().add("Vosk STT Available: $_voskAvailable");

    return _voskAvailable || _systemAvailable;
  }

  @override
  Future<void> listen({
    required Function(String result, bool isFinal) onResult,
    List<String> grammar = const [],
  }) async {
    // Toujours préférer Vosk quand disponible (grammaire fermée = meilleure reconnaissance).
    if (_voskAvailable) {
      LogService().add("🎤 Using: VOSK (Grammar: ${grammar.length} phrases)");
      await _vosk.listen(onResult: onResult, grammar: grammar);
      return;
    }
    if (_systemAvailable) {
      LogService().add("🎤 Using: SYSTEM (Fallback, Vosk indisponible)");
      await _system.listen(onResult: onResult);
    } else {
      LogService().add("❌ No Engine Available!");
    }
  }

  @override
  Future<void> stop() async {
    if (_vosk.isListening) await _vosk.stop();
    if (_system.isListening) await _system.stop();
  }

  @override
  bool get isAvailable => _voskAvailable || _systemAvailable;

  @override
  bool get isListening => _vosk.isListening || _system.isListening;
  
  bool get isVoskReady => _voskAvailable;
}
