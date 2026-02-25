export 'system_speech_service.dart';
export 'vosk_speech_service.dart';
export 'hybrid_speech_service.dart';

abstract class ISpeechService {
  /// Initializes the engine. Returns true if successful.
  Future<bool> init({Function(String error)? onError});

  /// Starts listening.
  /// [onResult] is called with the partial/final text.
  /// [grammar] is a list of expected words (used by Vosk for closed vocabulary).
  Future<void> listen({
    required Function(String result, bool isFinal) onResult,
    List<String> grammar = const [],
  });

  /// Stops listening.
  Future<void> stop();

  /// Returns true if the engine is ready/available.
  bool get isAvailable;

  /// Returns true if currently listening.
  bool get isListening;
}
