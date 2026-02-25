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
        pauseFor: const Duration(seconds: 2), // Wait 2s silence (better for short words)
        listenFor: const Duration(seconds: 30), // Keep listening longer
        partialResults: true,
      );
    }
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      _speech.stop();
    }
  }
  
  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;
}
