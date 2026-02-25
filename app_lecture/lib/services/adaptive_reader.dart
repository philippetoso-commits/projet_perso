import 'pedagogic_utils.dart';
import 'log_service.dart';

enum ReadingLevel { ps, ms, gs, cp }

enum ReadingResult {
  listening,
  success,
  fail,
  needHelp,
  mastered,
  tooManyAttempts, // New status for Rule 7
}

class PedagogicDebug {
  final String target;
  final List<String> recognizedChunks;
  final int durationMs;
  final String detectedBlock;
  final int successStreak;
  final int failCount;
  final int pedagogicSuccess;
  final int technicalSuccess;

  PedagogicDebug({
    required this.target,
    required this.recognizedChunks,
    required this.durationMs,
    required this.detectedBlock,
    required this.successStreak,
    required this.failCount,
    this.pedagogicSuccess = 0,
    this.technicalSuccess = 0,
  });

  @override
  String toString() {
    return '''
[DEBUG PEDA]
Mot cible        : $target
Reconnu          : ${recognizedChunks.join(" | ")}
Durée (ms)       : $durationMs
Blocage détecté  : $detectedBlock
Streak succès    : $successStreak
Échecs récents   : $failCount
Succès Pédago    : $pedagogicSuccess
Succès Tech      : $technicalSuccess
''';
  }
}

class AdaptiveReader {
  final String target;
  final ReadingLevel level;
  final bool debugEnabled;

  final List<String> _buffer = [];
  DateTime? _startTime;
  DateTime? _lastSpeech;
  DateTime? _listeningStart;

  int successStreak = 0;
  int failCount = 0;
  int pedagogicSuccess = 0;
  int technicalSuccess = 0;

  AdaptiveReader({
    required this.target,
    required this.level,
    this.debugEnabled = true,
  });

  // -----------------------------
  // Paramètres par niveau
  // -----------------------------
  // -----------------------------
  // Paramètres par niveau
  // -----------------------------
  int get requiredStreak {
     // Rule 4: "2 bonnes reconnaissances consécutives = acquis"
     // Uniform rule for now, regardless of level.
     return 2;
  }
  
  // ... (Silence/Latency params omitted, keep existing or assume close context) ...

  // (Skipping to _handleFail modification)

  ReadingResult _handleFail(String spoken, int duration) {
    failCount++;
    successStreak = successStreak > 0 ? successStreak - 1 : 0;

    final block = _detectBlock(spoken);

    if (debugEnabled) {
      _logDebug(spoken, duration, block);
    }

    _resetCycle();

    // Rule 7: "2 échecs -> ... dire bravo puis le mot et passer à la suite"
    if (failCount >= 2) {
      return ReadingResult.tooManyAttempts; // New Enum Value
    }
    return ReadingResult.fail;
  }

  int get silenceMs {
    switch (level) {
      case ReadingLevel.ps:
        return 1500;
      case ReadingLevel.ms:
        return 1200;
      case ReadingLevel.gs:
        return 1000;
      case ReadingLevel.cp:
        return 800;
    }
  }

  int get maxLatencyMs {
    switch (level) {
      case ReadingLevel.ps:
        return 5000;
      case ReadingLevel.ms:
        return 4000;
      case ReadingLevel.gs:
        return 3000;
      case ReadingLevel.cp:
        return 2000;
    }
  }

  int get minDurationMs {
    switch (level) {
      case ReadingLevel.ps:
      case ReadingLevel.ms:
        return 600;
      case ReadingLevel.gs:
        return 450;
      case ReadingLevel.cp:
        return 300;
    }
  }

  void startAttempt() {
    _listeningStart = DateTime.now();
    _resetCycle();
  }

  // -----------------------------
  // Entrée STT
  // -----------------------------
  ReadingResult onSpeech(String recognized, bool isFinal) {
    if (recognized.trim().isEmpty) return ReadingResult.listening;

    final now = DateTime.now();

    if (_buffer.isEmpty && _listeningStart != null) {
      final latency = now.difference(_listeningStart!).inMilliseconds;
      if (latency > maxLatencyMs) {
        _logDebug(recognized, 0, "Démarrage tardif (${latency}ms)");
        return _handleFail(recognized, 0);
      }
    }

    _startTime ??= now;
    _lastSpeech = now;

    final normalized = PedagogicUtils.normalize(recognized);
    if (normalized.isNotEmpty) {
      _buffer.add(normalized);
    }

    final spokenSoFar = _buffer.join();

    if (PedagogicUtils.isValidReading(spokenSoFar, target)) {
      return _handleSuccess(spokenSoFar, now);
    }

    if (_silenceExceeded(now)) {
      return _commitAttempt(now);
    }

    return ReadingResult.listening;
  }

  ReadingResult checkSilence() {
    if (_lastSpeech != null && _silenceExceeded(DateTime.now())) {
      return _commitAttempt(DateTime.now());
    }
    return ReadingResult.listening;
  }

  ReadingResult _commitAttempt(DateTime now) {
    final spoken = _buffer.join();
    final duration = _startTime != null
        ? now.difference(_startTime!).inMilliseconds
        : 0;

    final isCorrect = PedagogicUtils.isValidReading(spoken, target);

    if (isCorrect) {
      return _handleSuccess(spoken, now);
    } else {
      return _handleFail(spoken, duration);
    }
  }

  // -----------------------------
  // Succès / Échec
  // -----------------------------
  ReadingResult _handleSuccess(String spoken, DateTime now) {
    final duration = _startTime != null
        ? now.difference(_startTime!).inMilliseconds
        : 0;

    if (_lexicalMismatch(spoken)) {
      technicalSuccess++;
      _logDebug(spoken, duration, "SUBSTITUTION LEXICALE -> REJET");
      return _handleFail(spoken, duration);
    }

    // MODIFIED: Allow fast matches for long words ("Fast Credible")
    // If target >= 3 chars, we tolerate short durations (Vosk artifact)
    bool isLongWord = PedagogicUtils.normalize(target).length >= 3;
    
    // If duration is too short AND it's NOT a long word (meaning it's a short word), reject it.
    if (duration < minDurationMs && !isLongWord) {
      technicalSuccess++;
      _logDebug(spoken, duration, "TROP RAPIDE -> GUESS");
      return _handleFail(spoken, duration);
    }

    if (_isForcedMatch(spoken, duration)) {
      technicalSuccess++;
      _logDebug(spoken, duration, "MATCH FORCÉ -> REJETÉ");
      return _handleFail(spoken, duration);
    }

    pedagogicSuccess++;
    successStreak++;

    if (debugEnabled) {
      _logDebug(spoken, duration, "succès pédagogique");
    }

    if (failCount > 0 && successStreak >= 2) {
      failCount--; // Decay fail count
    }

    _resetCycle();

    if (successStreak >= requiredStreak) {
      return ReadingResult.mastered;
    }

    return ReadingResult.success;
  }



  // -----------------------------
  // Heuristiques
  // -----------------------------
  bool _lexicalMismatch(String spoken) {
    final s = PedagogicUtils.normalize(spoken);
    final t = PedagogicUtils.normalize(target);
    return (s.length - t.length).abs() >= 4;
  }

  bool _isForcedMatch(String spoken, int duration) {
    final nTarget = PedagogicUtils.normalize(target);
    final nSpoken = PedagogicUtils.normalize(spoken);

    if (nSpoken != nTarget) return false;

    // Exception for long words: If >= 3 chars, we accept single chunk / fast match
    if (nTarget.length >= 3) return false;

    if (_buffer.length == 1) return true;
    
    // Check duration relative to minDurationMs (already done in handleSuccess but good for redundancy)
    if (duration < minDurationMs) {
      return true;
    }

    return false;
  }

  String _detectBlock(String spoken) {
    if (spoken.isEmpty) return "silence";

    final t = PedagogicUtils.normalize(target);
    final s = PedagogicUtils.normalize(spoken);

    if (!t.startsWith(s)) {
      return "attaque du mot";
    }
    if (!t.endsWith(s)) {
      return "finale du mot";
    }
    return "segment médian";
  }

  // -----------------------------
  // Debug
  // -----------------------------
  void _logDebug(String spoken, int durationMs, String block) {
    final debug = PedagogicDebug(
      target: target,
      recognizedChunks: List.from(_buffer),
      durationMs: durationMs,
      detectedBlock: block,
      successStreak: successStreak,
      failCount: failCount,
      pedagogicSuccess: pedagogicSuccess,
      technicalSuccess: technicalSuccess,
    );
    LogService().add(debug.toString().replaceAll('\n', ' '));
  }

  void _resetCycle() {
    _buffer.clear();
    _startTime = null;
    _lastSpeech = null;
  }

  bool _silenceExceeded(DateTime now) {
    if (_lastSpeech == null) return false;
    return now.difference(_lastSpeech!).inMilliseconds >= silenceMs;
  }
}
