
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/word.dart';
import '../services/pedagogic_utils.dart';
import '../services/tts_service.dart';
import '../services/speech/hybrid_speech_service.dart';
import '../services/adaptive_reader.dart';
import '../services/log_service.dart';
import '../services/profile_service.dart';
import '../services/syllabary_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  final Word word;
  final int level;
  final int profileKey;
  /// Mode parcours : liste de mots de l'étape (si non null, on pioche dedans au lieu du niveau).
  final List<Word>? stepWords;
  /// Index de l'étape carte (pour déblocage et étoiles).
  final int? stepIndex;

  const GameScreen({
    super.key,
    required this.word,
    this.level = 1,
    required this.profileKey,
    this.stepWords,
    this.stepIndex,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Word _currentWord;
  // ...
  
  String _getSchoolLevel(int lvl) {
      if (lvl == 1) return "PS";
      if (lvl == 2) return "MS"; // Or GS if 2 is GS? Let's assume linear
      if (lvl == 3) return "GS";
      if (lvl >= 4) return "CP";
      return "Niveau $lvl";
  }

  bool _isListening = false;
  bool _isRevealed = false;
  int _attempts = 0;
  bool _showCelebration = false;
  int _sessionStarsCount = 0;
  int _starsEarnedThisWord = 0;
  final TtsService _ttsService = TtsService();
  final SyllabaryService _syllabary = SyllabaryService.instance;

  List<String> get _displaySyllables =>
      _syllabary.getSyllablesForDisplay(_currentWord.text, _currentWord.syllables);
  String get _displayWord => _syllabary.getDisplayWord(_currentWord.text);
  final HybridSpeechService _sttService = HybridSpeechService();
  final ProfileService _profileService = ProfileService.instance;
  late AdaptiveReader _adaptiveReader;
  Timer? _silenceTimer;
  final List<String> _logs = []; // IN-APP CONSOLE

  void _addLog(String msg) {
      if (mounted) {
          setState(() {
              _logs.insert(0, "[${DateTime.now().toString().split(' ').last.substring(0, 8)}] $msg");
              if (_logs.length > 50) _logs.removeLast();
          });
      }
  }

  /// Affiche l'image en plein cadre (250x250). Tente .jpg puis .png, puis theme/mot.
  Widget _buildFullFrameImage(String imagePath, {String? theme, String? wordText}) {
    return SizedBox(
      width: 250,
      height: 250,
      child: _AssetImageWithExtensionFallback(
        imagePath: imagePath.replaceAll(r'\', '/').trim().replaceFirst(RegExp(r'^/'), ''),
        width: 250,
        height: 250,
        theme: theme ?? _currentWord.theme,
        wordText: wordText ?? _currentWord.text,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentWord = widget.word;
    LogService().onNewLog = (msg) {
        if (mounted) setState(() {});
    };
    _initReader();
    _initServices();
  }

  void _initReader() {
     // Map widget.level to ReadingLevel
     ReadingLevel rLevel = ReadingLevel.cp; // Default
     if (widget.level == 1) rLevel = ReadingLevel.ps;
     if (widget.level == 2) rLevel = ReadingLevel.gs;
     if (widget.level == 3) rLevel = ReadingLevel.cp;

     _adaptiveReader = AdaptiveReader(
        target: _currentWord.text,
        level: rLevel,
     );
  }

  void _initServices() async {
    LogService().add("Checking Microphone Permission...");
    var status = await Permission.microphone.request();
    LogService().add("Microphone Permission: $status");

    _ttsService.onLog = (m) => LogService().add("TTS: $m");
    LogService().add("Initializing game services...");
    
    bool ttsOk = await _ttsService.init();
    if (!ttsOk) {
        LogService().add("ERROR: TTS Init Failed");
    }
    LogService().add("STT: Initializing hybrid engine...");
    bool sttOk = await _sttService.init(onError: (msg) {
        LogService().add("STT ERROR callback: $msg");
    });
    LogService().add("STT: Engine ready? $sttOk");
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _ttsService.stop();
    _sttService.stop();
    super.dispose();
  }

  void _nextWord() {
    final box = Hive.box<Word>('words');
    List<Word> availableWords;
    if (widget.stepWords != null && widget.stepWords!.isNotEmpty) {
      availableWords = List.from(widget.stepWords!);
    } else {
      availableWords = box.values.where((w) => w.level == widget.level).toList();
      if (widget.level == 1) {
        final allowed = _profileService.getAllowedPsThemes(widget.profileKey);
        availableWords = availableWords.where((w) => allowed.contains(w.theme)).toList();
      }
    }
    if (availableWords.isEmpty) {
      final random = Random();
      setState(() {
        _currentWord = box.getAt(random.nextInt(box.length))!;
        _isRevealed = false;
        _isListening = false;
        _attempts = 0;
      });
      return;
    }
    final next = _profileService.pickNextWord(widget.profileKey, availableWords, random: Random());
    setState(() {
      _currentWord = next ?? availableWords[Random().nextInt(availableWords.length)];
      _isRevealed = false;
      _isListening = false;
      _attempts = 0;
      _initReader();
    });
  }

  /// Grammaire Vosk : mot, déterminants, homophones, syllabes (découpage V4 avec accents).
  List<String> _buildGrammar(String target) {
      final t = target.trim();
      final tLower = t.toLowerCase();
      final Set<String> g = {tLower};
      g.add("le $tLower");
      g.add("la $tLower");
      g.add("un $tLower");
      g.add("une $tLower");
      String nTarget = PedagogicUtils.normalize(t);
      if (PedagogicUtils.manualHomophones.containsKey(nTarget)) {
        for (final v in PedagogicUtils.manualHomophones[nTarget]!) {
          g.add(v);
        }
      }
      for (final syl in _displaySyllables) {
        if (syl.isNotEmpty) g.add(syl.toLowerCase());
      }
      return g.toList();
  }

  void _handleReadingResult(ReadingResult result) {
      if (result == ReadingResult.listening) return;

      _stopListening();
      setState(() {}); 

      switch (result) {
        // RULE 4 & 6: Success / Mastered
        case ReadingResult.success:
        case ReadingResult.mastered:
           final starsEarned = _attempts == 0 ? 3 : (_attempts == 1 ? 2 : 1);
           setState(() {
             _isRevealed = true;
             _starsEarnedThisWord = starsEarned;
             _sessionStarsCount += starsEarned;
             _attempts = 0;
           });
           _saveProgress(success: true);
           if (widget.level == 1) _tryUnlockNextPsSound();
           if (result == ReadingResult.mastered) {
               _ttsService.speak("Excellent ! Tu maîtrises le mot $_displayWord !");
           } else {
               _ttsService.speak("Bravo ! $_displayWord.");
           }
           // Attendre que le STT soit bien arrêté puis laisser l'overlay natif (écran rouge) se fermer avant la célébration.
           _sttService.stop().then((_) async {
             await Future.delayed(const Duration(milliseconds: 900));
             if (mounted) setState(() => _showCelebration = true);
           });
           break;

        case ReadingResult.fail:
           setState(() => _attempts++);
           _giveFeedback(isFinalFail: false);
           break;

        case ReadingResult.tooManyAttempts:
           setState(() {
               _isRevealed = true;
               _attempts = 0;
           });
           _saveProgress(success: false);
           _ttsService.speak("Bravo ! Le mot est $_displayWord.");
           // STOP Auto-next. Wait for user input.
           break;
           
        default: break;
      }
  }

  void _saveProgress({required bool success}) {
    try {
      final wordKey = _currentWord.key;
      if (wordKey != null) {
        final attempts = success ? (_attempts + 1) : null;
        _profileService.saveWordProgress(
          widget.profileKey,
          wordKey as int,
          success: success,
          attempts: attempts,
        );
        if (success && widget.stepIndex != null) {
          _profileService.tryUnlockNextMapStep(widget.profileKey, widget.stepIndex!);
        }
      }
    } catch (e) {
      LogService().add("Save progress error: $e");
    }
  }

  /// En PS : débloque le son suivant après 5 mots réussis dans le groupe actuel.
  void _tryUnlockNextPsSound() {
    try {
      final box = Hive.box<Word>('words');
      final wordsInGroup = box.values
          .where((w) => w.level == 1 && w.theme == _currentWord.theme)
          .toList();
      _profileService.tryUnlockNextPsSound(widget.profileKey, wordsInGroup);
    } catch (e) {
      LogService().add("tryUnlockNextPsSound error: $e");
    }
  }

  void _giveFeedback({required bool isFinalFail}) {
       if (_attempts == 1) {
           _ttsService.speak("Essaie encore !");
       } else {
           _ttsService.speak("Écoute bien...");
           _ttsService.speakSlowly(_displayWord);
       }
  }

  void _startListening() {
      _isListening = true;
      _adaptiveReader.startAttempt(); // Start latency timer
      _sttService.listen(
          grammar: _buildGrammar(_displayWord),
          onResult: (text, isFinal) {
             LogService().add("STT callback: '$text' (isFinal: $isFinal)");
             final result = _adaptiveReader.onSpeech(text, isFinal);
             LogService().add("AdaptiveReader decision: $result");
             _handleReadingResult(result);
          },
      );
      
      // Periodic check for silence timeout (in case no new speech events come in)
      _silenceTimer?.cancel();
      _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
          if (!_isListening) { 
            timer.cancel(); 
            return;
          }
          final result = _adaptiveReader.checkSilence();
          if (result != ReadingResult.listening) {
             _handleReadingResult(result);
          }
      });
  }

  void _stopListening() {
      _sttService.stop();
      _silenceTimer?.cancel();
      _isListening = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 112,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 22),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              SizedBox(
                width: 40,
                height: 34,
                child: GestureDetector(
                  onTap: () => _ttsService.speak("Courage ! Tu peux y arriver."),
                  child: Image.asset('assets/images/mascotte.png', fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
        title: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
                 Text(
                     widget.stepIndex != null
                         ? "Parcours – Étape ${widget.stepIndex! + 1}"
                         : "Niveau ${widget.level} (${_getSchoolLevel(widget.level)})",
                     style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                 ),
                 Text(
                     _currentWord.theme.toUpperCase(),
                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
                 )
             ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: _AppBarStarChest(stars: _sessionStarsCount),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Zone Mystère (Mascotte + Image)
              Expanded(
                flex: 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Image Box — image en plein cadre, sans bandes grises
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: AnimatedCrossFade(
                          firstChild: _isRevealed
                              ? _buildFullFrameImage(_currentWord.imagePath, theme: _currentWord.theme, wordText: _currentWord.text)
                              : Container(
                                  width: 250,
                                  height: 250,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.question_mark_rounded, size: 80, color: Colors.white),
                                  ),
                                ),
                          secondChild: _isRevealed
                              ? _buildFullFrameImage(_currentWord.imagePath, theme: _currentWord.theme, wordText: _currentWord.text)
                              : const SizedBox.shrink(),
                          crossFadeState: _isRevealed ? CrossFadeState.showFirst : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 500),
                          sizeCurve: Curves.easeOut,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Zone Lecture — Cartes syllabes (segmentation très marquée)
              Expanded(
                flex: 3,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _displaySyllables.asMap().entries.map((entry) {
                        final syl = entry.value;
                        final isLast = syl == _displaySyllables.last;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text.rich(
                              TextSpan(
                                children: PedagogicUtils.getStyledSyllable(syl, isLastSyllable: isLast),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 3. Actions (Micro + Next)
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Speaker Button (Lecture hachée)
                        GestureDetector(
                          onTap: () async {
                            if (!_ttsService.isReady) {
                                LogService().add("TTS not ready yet...");
                                return;
                            }
                            LogService().add("Manual play triggered");
                            for (var syl in _displaySyllables) {
                              await _ttsService.speakSlowly(syl);
                              await Future.delayed(const Duration(milliseconds: 600));
                            }
                            await Future.delayed(const Duration(milliseconds: 400));
                            await _ttsService.speak(_displayWord);
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _ttsService.isReady ? Colors.orangeAccent : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.orangeAccent.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
                              ],
                            ),
                            child: _ttsService.isReady 
                                ? const Icon(Icons.volume_up_rounded, color: Colors.white, size: 35)
                                : const SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        
                        // Mic Button
                        GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_isListening) {
                                   _stopListening();
                                } else {
                                  _startListening();
                                }
                              });
                            },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _isListening ? 100 : 80,
                            height: _isListening ? 100 : 80,
                            decoration: BoxDecoration(
                              color: _isListening ? Colors.redAccent : Colors.blueAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        
                        // Next Button (Visible only if revealed)
                        if (_isRevealed) ...[
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap: _nextWord,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 10)
                                ],
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 40),
                            ),
                          ),
                        ]
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    Text(
                      _isListening 
                          ? ((!_sttService.isVoskReady && _displayWord.length <= 3) ? "Dis : LE ${_displayWord.toUpperCase()}" : "Je t'écoute...") 
                          : "Appuie pour lire !",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Célébration : pluie d'étoiles + coffre
          if (_showCelebration)
            StarRainCelebration(
              starsEarned: _starsEarnedThisWord,
              totalSessionStars: _sessionStarsCount,
              onComplete: () {
                if (mounted) setState(() => _showCelebration = false);
              },
            ),

        ],
      ),
    );
  }
}

/// Compteur d'étoiles compact dans la barre (haut droite).
class _AppBarStarChest extends StatelessWidget {
  final int stars;

  const _AppBarStarChest({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B4513), Color(0xFF654321)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.amber.withOpacity(0.25), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 22, color: Colors.amber.shade200),
          const SizedBox(width: 6),
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

/// Charge une image asset ; en cas d'échec, réessaie .jpg/.png puis theme/mot.
class _AssetImageWithExtensionFallback extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final String? theme;
  final String? wordText;

  const _AssetImageWithExtensionFallback({
    required this.imagePath,
    required this.width,
    required this.height,
    this.theme,
    this.wordText,
  });

  @override
  State<_AssetImageWithExtensionFallback> createState() =>
      _AssetImageWithExtensionFallbackState();
}

class _AssetImageWithExtensionFallbackState
    extends State<_AssetImageWithExtensionFallback> {
  int _attempt = 0;

  static String _normalize(String p) {
    p = p.replaceAll(r'\', '/').trim();
    if (p.startsWith('/')) p = p.substring(1);
    return p;
  }

  String _pathForAttempt() {
    final base = _normalize(widget.imagePath);
    if (_attempt == 0) return base;
    if (_attempt == 1) {
      if (base.toLowerCase().endsWith('.jpg') || base.toLowerCase().endsWith('.jpeg')) {
        return base.replaceAll(RegExp(r'\.jpe?g$', caseSensitive: false), '.png');
      }
      if (base.toLowerCase().endsWith('.png')) {
        return base.replaceAll(RegExp(r'\.png$', caseSensitive: false), '.jpg');
      }
      return base;
    }
    final theme = widget.theme ?? '';
    final word = (widget.wordText ?? '').toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-]'), '');
    if (word.isEmpty) return base;
    if (_attempt == 2) return 'assets/images/$theme/$word.jpg';
    if (_attempt == 3) return 'assets/images/$theme/$word.png';
    return base;
  }

  void _nextAttempt() {
    if (mounted && _attempt < 3) {
      setState(() => _attempt++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _pathForAttempt();
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        if (_attempt < 3) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _nextAttempt();
          });
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white),
        );
      },
    );
  }
}

/// Overlay célébration : pluie d'étoiles (clippée, sans overflow) + Bravo + coffre.
class StarRainCelebration extends StatefulWidget {
  final int starsEarned;
  final int totalSessionStars;
  final VoidCallback onComplete;

  const StarRainCelebration({
    super.key,
    required this.starsEarned,
    required this.totalSessionStars,
    required this.onComplete,
  });

  @override
  State<StarRainCelebration> createState() => _StarRainCelebrationState();
}

class _StarRainCelebrationState extends State<StarRainCelebration>
    with TickerProviderStateMixin {
  static const int _starCount = 24;
  static const int _durationMs = 5500;
  static const double _starSize = 28.0;

  late AnimationController _controller;
  List<double> _starStartX = [];
  List<double> _starDelays = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: _durationMs),
      vsync: this,
    );
  }

  void _initPositions(double screenWidth) {
    if (_initialized) return;
    _initialized = true;
    final random = Random();
    final padding = _starSize + 8;
    _starStartX = List.generate(
      _starCount,
      (_) => padding + random.nextDouble() * (screenWidth - 2 * padding),
    );
    _starDelays = List.generate(_starCount, (_) => random.nextDouble() * 0.25);
    // Lancer l'animation au prochain microtask pour ne pas appeler forward() pendant le build
    Future.microtask(() {
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted) widget.onComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = MediaQuery.sizeOf(context).height;
        // Initialisation synchrone lors du 1er layout — pas de flash
        _initPositions(w);
        final bottomY = h + _starSize;
        final starStarts = _starStartX.isNotEmpty
            ? _starStartX
            : List.generate(_starCount, (i) => w * (i + 1) / (_starCount + 1));
        final starDelays =
            _starDelays.isNotEmpty ? _starDelays : List.filled(_starCount, 0.0);
        return _buildContent(context, w, h, bottomY, starStarts, starDelays);
      },
    );
  }

  Widget _buildContent(BuildContext context, double w, double h, double bottomY,
      List<double> starStarts, List<double> starDelays) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final overlayOpacity =
                (_controller.value / 0.2).clamp(0.0, 1.0) * 0.5;
            return Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(overlayOpacity),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Étoiles : positions bornées pour éviter tout overflow
                  ...List.generate(_starCount, (i) {
                    final delay = starDelays[i];
                    final t = ((_controller.value - delay) / (1.0 - delay))
                        .clamp(0.0, 1.0);
                    final curveT = Curves.easeIn.transform(t);
                    final y = -_starSize + curveT * (bottomY + _starSize);
                    final sway = 12 * sin(t * 3 + i);
                    final x = (starStarts[i] + sway)
                        .clamp(0.0, w - _starSize)
                        .toDouble();
                    final scale = 0.5 + 0.5 * (1 - t);
                    final opacity = t < 0.1
                        ? t / 0.1
                        : (t > 0.9 ? (1 - t) / 0.1 : 1.0);
                    return Positioned(
                      left: x,
                      top: y,
                      width: _starSize,
                      height: _starSize,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale,
                          child: Icon(
                            Icons.star_rounded,
                            size: _starSize,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Titre Bravo
                  Positioned(
                    top: h * 0.08,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Text(
                              'Bravo !',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Coffre en bas
                  Positioned(
                    left: w * 0.5 - 44,
                    bottom: h * 0.08,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final showChest = _controller.value > 0.2;
                        final glow = 0.4 +
                            0.6 *
                                (1 -
                                    (_controller.value.clamp(0.2, 1.0) - 0.2) /
                                        0.8);
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: showChest ? 1.0 : 0.0,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.4 * glow),
                                  blurRadius: 28,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.25),
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8B4513),
                                      Color(0xFF654321),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.workspace_premium,
                                  size: 40,
                                  color: Colors.amber.shade200,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
