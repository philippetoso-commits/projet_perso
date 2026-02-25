import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../services/adaptive_reader.dart';
import '../services/speech/vosk_speech_service.dart';

/// Runner for Pedagogic Scenarios
class PedagogicTestRunner {
  final VoskSpeechService _voskService = VoskSpeechService();
  final VoskFlutterPlugin _voskPlugin = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;

  Future<void> runTests() async {
    print("🚀 Démarrage du Test Runner Pédagogique...");

    // 1. Init Vosk Model
    // We assume VoskSpeechService has already extracted the model in its init().
    // If not, we might fail. Ideally we call init() first.
    await _voskService.init(); 
    // We need direct access to Model to create our own Recognizer for file processing
    // Or we assume we can create one using the path.
    // Hack: We'll re-load model path to create a dedicated model for file processing
    final modelPath = await _getModelPath(); 
    if (modelPath == null) {
      print("❌ Erreur: Modèle non trouvé.");
      return;
    }
    _model = await _voskPlugin.createModel(modelPath);

    // 2. Load Scenarios
    final scenarios = await _loadScenarios();
    print("📋 ${scenarios.length} scénarios chargés.");

    int passed = 0;
    int failed = 0;

    List<String> failedScenarios = [];

    for (var scenario in scenarios) {
      print("\n🔹 Running Test: ${scenario['id']} (${scenario['word']})");
      final result = await _runScenario(scenario);
      
      if (result) {
        print("✅ PASS");
        passed++;
      } else {
        print("❌ FAIL");
        failed++;
        failedScenarios.add("${scenario['word']} (ID: ${scenario['id']})");
      }
    }

    print("\n════════════════════════════════════");
    print("RÉSULTATS FINAUX: $passed PASS / $failed FAIL");
    print("════════════════════════════════════");
    
    if (failedScenarios.isNotEmpty) {
      print("\n❌ RÉCAPITULATIF DES ÉCHECS ($failed) :");
      for (var fail in failedScenarios) {
        print(" - $fail");
      }
      print("════════════════════════════════════");
    }

  }

  Future<bool> _runScenario(Map<String, dynamic> scenario) async {
    final String word = scenario['word'];
    final String expected = scenario['expected_result'];
    final String audioAsset = scenario['audio_file'];
    final String levelStr = scenario['level'];
    
    ReadingLevel level = ReadingLevel.cp;
    if (levelStr == "ps") level = ReadingLevel.ps;
    if (levelStr == "ms") level = ReadingLevel.ms;
    if (levelStr == "gs") level = ReadingLevel.gs;

    // Setup AdaptiveReader
    final reader = AdaptiveReader(target: word, level: level, debugEnabled: true);
    reader.startAttempt();

    // Setup Recognizer for this word
    final grammar = _buildGrammar(word);
    _recognizer = await _voskPlugin.createRecognizer(
      model: _model!,
      sampleRate: 16000,
      grammar: grammar,
    );

    // Process Audio
    // Load asset bytes
    try {
      final ByteData data = await rootBundle.load(audioAsset);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Basic WAV header skip? 
      // Vosk acceptWaveformBytes usually expects PCM 16k Mono. 
      // If WAV provided, we should ideally skip 44 bytes.
      // But let's try feeding generic bytes.
      // NOTE: acceptWaveform might fail if header is present. 
      // Let's strip 44 bytes if it looks like WAV.
      
      Uint8List pcmData = bytes;
      if (bytes.length > 44 && String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF') {
           pcmData = bytes.sublist(44);
      }
      
      // Feed chunk by chunk or all at once?
      // Real time simulation: Feed in chunks of 4000 bytes (0.25s) with delay?
      // For "Fast" validation, file processing is typically faster than RT.
      // But AdaptiveReader relies on `DateTime.now()` for start/end.
      // This is TRIGGY! 
      // AdaptiveReader uses `DateTime.now()` inside `onSpeech`.
      // If we feed all bytes instantly, `duration` will be 0ms.
      // This simulates exactly the "Flash" behavior we want to test!
      // So feeding instantly is actually good for testing "Fast Credible".
      // If we wanted to test "Slow" reading, we'd need to mock DateTime or wait.
      
      // Let's feed it.
      await _recognizer!.acceptWaveformBytes(pcmData);
      
      // Get Result
      // Note: Vosk usually returns partials in a stream or via acceptWaveform calls if we check result.
      // But here we might just get Final Result.
      final resultJson = await _recognizer!.getResult();
      // Parse result
      final res = jsonDecode(resultJson);
      final text = res['text'].toString();

      // Pass to Reader
      // (Simulate Final result)
      final readingResult = reader.onSpeech(text, true);
      
      print("   Voice Recognized: '$text'");
      print("   Reader State: $readingResult");
      print("   Stats: Tech=${reader.technicalSuccess} Peda=${reader.pedagogicSuccess}");

      // Assert
      bool isPass = false;
      if (expected == "success") {
         isPass = (readingResult == ReadingResult.success || readingResult == ReadingResult.mastered || reader.pedagogicSuccess > 0);
      } else if (expected == "fail") {
         isPass = (readingResult == ReadingResult.fail || reader.technicalSuccess > 0 && reader.pedagogicSuccess == 0);
      }
      
      // Cleanup
      await _recognizer!.dispose();
      
      return isPass;

    } catch (e) {
      print("   ⚠️ Erreur Audio/Processing: $e");
      return false;
    }
  }

  Future<List<dynamic>> _loadScenarios() async {
    final String jsonString = await rootBundle.loadString('assets/tests/scenarios.json');
    return jsonDecode(jsonString);
  }

  // Helper to re-find model path (duplicated logic is ugly but safer here to avoid exposing internal methods)
  Future<String?> _getModelPath() async {
     // Re-use existing service logic via hack or re-implement
     // Let's assume the service put it in AppDocs/models/model-fr
     final appDir = await getApplicationDocumentsDirectory();
     final modelPath = "${appDir.path}/models/model-fr";
     // Check for am/final.mdl
     if (File("$modelPath/am/final.mdl").existsSync()) return modelPath;
     
     // Fallback search
     final dir = Directory(appDir.path);
     if (await dir.exists()) {
       final entries = dir.listSync(recursive: true);
       for (var e in entries) {
         if (e.path.endsWith("final.mdl")) {
           return e.parent.parent.path; 
         }
       }
     }
     return null;
  }

  List<String> _buildGrammar(String word) {
    return [word, "[unk]"];
  }
}
