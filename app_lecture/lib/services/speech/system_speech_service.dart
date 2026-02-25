import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'i_speech_service.dart';
import '../log_service.dart';

class SystemSpeechService implements ISpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  String? _currentLocaleId;

  @override
  Future<bool> init({Function(String error)? onError}) async {
    LogService().add("SystemStt: Initializing plugin...");
    try {
      _isAvailable = await _speech.initialize(
        debugLogging: false,
        onError: (val) {
          LogService().add('SystemStt onError: ${val.errorMsg} (permanent: ${val.permanent})');
          if (onError != null) onError(val.errorMsg);
        },
        onStatus: (val) => LogService().add('SystemStt onStatus: $val'),
      );

      LogService().add("SystemStt: Plugin initialize result: $_isAvailable");

      if (_isAvailable) {
          final locales = await _speech.locales();
          LogService().add("SystemStt: Found ${locales.length} locales");
          
          _currentLocaleId = "fr_FR";
          bool hasFr = locales.any((l) => l.localeId.contains("fr"));
          
          if (!hasFr) {
              final systemLocale = await _speech.systemLocale();
              _currentLocaleId = systemLocale?.localeId;
              LogService().add("SystemStt: No French found. Using system default: $_currentLocaleId");
          } else {
              _currentLocaleId = locales.firstWhere(
                (l) => l.localeId == "fr_FR" || l.localeId == "fr-FR",
                orElse: () => locales.firstWhere((l) => l.localeId.startsWith("fr"))
              ).localeId;
              LogService().add("SystemStt: Selected locale: $_currentLocaleId");
          }
      }

    } catch (e) {
      LogService().add("SystemStt: CRITICAL INIT ERROR: $e");
      _isAvailable = false;
    }
    LogService().add("SystemStt: Init finished. Available: $_isAvailable");
    return _isAvailable;
  }

  @override
  Future<void> listen({
    required Function(String result, bool isFinal) onResult,
    List<String> grammar = const [], // Ignored by System STT
  }) async {
    if (_isAvailable && !_speech.isListening) {
      LogService().add("SystemStt: Starting listen with locale: $_currentLocaleId");
      _speech.listen(
        onResult: (val) {
           LogService().add("SystemStt onResult: '${val.recognizedWords}' (final: ${val.finalResult})");
           onResult(val.recognizedWords, val.finalResult);
        },
        localeId: _currentLocaleId,
        pauseFor: const Duration(seconds: 4), 
        listenFor: const Duration(seconds: 30),
        partialResults: true,
        onSoundLevelChange: (level) {
          if (level > 1.0) {
            LogService().add("🎤 Micro activity detected (Level: ${level.toStringAsFixed(1)})");
          }
        },
      );
    }
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _speech.isListening;
}
