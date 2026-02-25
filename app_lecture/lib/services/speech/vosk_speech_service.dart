import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'i_speech_service.dart';
import '../log_service.dart';

class VoskSpeechService implements ISpeechService {
  static const String _modelName = 'vosk-model-small-fr-0.22';
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  
  // Singleton Pattern
  static final VoskSpeechService _instance = VoskSpeechService._internal();
  factory VoskSpeechService() => _instance;
  VoskSpeechService._internal();

  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService; // Vosk's own SpeechService class
  bool _isAvailable = false;
  bool _isListening = false;
  bool _isInitializing = false; 

  @override
  Future<bool> init({Function(String error)? onError}) async {
    // If already available, return true immediately to avoid re-init error
    if (_isAvailable) return true;
    if (_isInitializing) return false; 
    
    _isInitializing = true;
    try {
      LogService().add("Vosk: Checking model...");
      
      final modelPath = await _getModelPath();
      if (modelPath == null) {
          LogService().add("Vosk Error: Model zip or directory not found.");
          if (onError != null) onError("Modèle Vosk non trouvé");
          _isInitializing = false;
          return false;
      }

      LogService().add("Vosk: Creating model from $modelPath");
      _model = await _vosk.createModel(modelPath);
      _isAvailable = true;
      _isInitializing = false;
      LogService().add("Vosk: Success! Ready to listen.");
      return true;

    } catch (e) {
      LogService().add("Vosk Init Error: $e");
      if (onError != null) onError(e.toString());
      _isAvailable = false;
      _isInitializing = false;
      return false;
    }
  }

  Future<String?> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final zipName = 'model-fr.zip'; 
    final relativeZipPath = 'assets/models/$zipName';

    try {
        LogService().add("Vosk: Extracting model from assets...");
        final modelRoot = await ModelLoader().loadFromAssets(relativeZipPath);
        LogService().add("Vosk: Model path: $modelRoot");
        
        if (File("$modelRoot/am/final.mdl").existsSync()) {
            return modelRoot;
        }

        final dir = Directory(modelRoot);
        if (await dir.exists()) {
           final entries = dir.listSync();
           for (var e in entries) {
              if (e is Directory) {
                  if (File("${e.path}/am/final.mdl").existsSync()) {
                      return e.path;
                  }
                  final subEntries = e.listSync();
                  for (var s in subEntries) {
                      if (s is Directory && File("${s.path}/am/final.mdl").existsSync()) {
                          return s.path;
                      }
                  }
              }
           }
        }
        return modelRoot; 
    } catch(e, stack) {
        LogService().add("Vosk Asset Loader Error: $e");
        print(stack);
        return null; 
    }
  }

  @override
  Future<void> listen({
    required Function(String result, bool isFinal) onResult,
    List<String> grammar = const [],
  }) async {
    if (!_isAvailable || _model == null) return;
    
    try {
      // CLEANUP BEFORE CREATION!
      if (_speechService != null) {
          await _speechService!.cancel();
          await _speechService!.dispose(); 
          _speechService = null;
      }
      if (_recognizer != null) {
          await _recognizer!.dispose();
          _recognizer = null;
      }

      // Configure Grammar if provided
      if (grammar.isNotEmpty) {
        final cleanGrammar = grammar.map((w) => w.toLowerCase().trim()).toList();
        cleanGrammar.add("[unk]"); 
        _recognizer = await _vosk.createRecognizer(
          model: _model!,
          sampleRate: 16000,
          grammar: cleanGrammar,
        );
      } else {
        _recognizer = await _vosk.createRecognizer(
            model: _model!, 
            sampleRate: 16000
        );
      }

      _speechService = await _vosk.initSpeechService(_recognizer!);
      
      _speechService!.onPartial().listen((partial) {
         try {
             final data = jsonDecode(partial);
             final text = data['partial'].toString();
             if (text.isNotEmpty) {
                 onResult(text, false);
             }
         } catch(e) {}
      });

      _speechService!.onResult().listen((result) {
         try {
             final data = jsonDecode(result);
             final text = data['text'].toString();
             if (text.isNotEmpty) {
                 onResult(text, true); 
             }
         } catch(e) {}
      });

      LogService().add("Vosk: Mic STARTING...");
      await _speechService!.start();
      _isListening = true;
      LogService().add("Vosk: Mic is OPEN.");

    } catch (e) {
      LogService().add("Vosk Listen Error: $e");
      _isListening = false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_speechService != null) {
        await _speechService!.stop();
        LogService().add("Vosk: Mic CLOSED.");
      }
       _isListening = false;
    } catch (e) {
      LogService().add("Vosk Stop Error: $e");
    }
  }

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _isListening;
}
