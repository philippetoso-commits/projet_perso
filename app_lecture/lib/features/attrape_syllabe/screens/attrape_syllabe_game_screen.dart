import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/tts_service.dart';
import '../data/syllabes_list.dart';
import '../widgets/falling_syllable.dart';
import '../widgets/animated_background.dart';

class SyllableItem {
  final String text;
  final bool isTarget;
  final double startX;
  final double startYOffset; // How high above the screen it starts (to desynchronize them)
  final Color bubbleColor; // Uniquely colored bubbles

  SyllableItem({
    required this.text,
    required this.isTarget,
    required this.startX,
    required this.startYOffset,
    required this.bubbleColor,
  });
}

class AttrapeSyllabeGameScreen extends StatefulWidget {
  final int initialLevel;

  const AttrapeSyllabeGameScreen({Key? key, required this.initialLevel}) : super(key: key);

  @override
  _AttrapeSyllabeGameScreenState createState() => _AttrapeSyllabeGameScreenState();
}

class _AttrapeSyllabeGameScreenState extends State<AttrapeSyllabeGameScreen> {
  final TtsService _ttsService = TtsService();
  final Random _random = Random();
  
  late String _targetSyllable;
  List<SyllableItem> _activeSyllables = [];
  bool _isSecondChance = false;
  int _score = 0;
  int _round = 1;
  final int _maxRounds = 100; // Increased to 100
  late int _currentLevel;
  
  // Tracking success for adaptive difficulty
  int _consecutiveSuccess = 0;
  int _consecutiveFailures = 0;
  
  bool _isPlaying = false;
  bool _isFirstRound = true;
  bool _isFallingAllowed = false; // Indicates if they should start falling

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel;
    _initGame();
  }

  Future<void> _initGame() async {
    await _ttsService.init();
    _startRound();
  }

  void _startRound() {
    if (_round > _maxRounds) {
      _showGameOver();
      return;
    }

    final allSyllables = SyllabesData.getSyllabesForLevel(_currentLevel);
    _targetSyllable = allSyllables[_random.nextInt(allSyllables.length)];
    
    // Choose distractions + 1 target
    final roundSyllables = SyllabesData.getRandomSyllables(
      level: _currentLevel,
      targetSyllable: _targetSyllable,
      count: 4,
    );

    _isSecondChance = false;
    _spawnSyllables(roundSyllables);
    
    setState(() {
      _isPlaying = true;
      _isFallingAllowed = false; // Stop at top initially
    });

    _playInstructionAndStart();
  }

  Future<void> _playInstructionAndStart() async {
    if (_isFirstRound) {
        await _ttsService.speakSlowly("Attrape la syllabe : $_targetSyllable");
        _isFirstRound = false;
    } else {
        await _ttsService.speakSlowly(_targetSyllable);
    }
    
    // Wait a brief moment before they start falling
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && _isPlaying) {
       setState(() {
          _isFallingAllowed = true;
       });
    }
  }

  Future<void> _repeatInstruction() async {
    await _ttsService.speakSlowly(_targetSyllable);
  }

  void _spawnSyllables(List<String> texts) {
    // Generate distinct horizontal positions and staggered vertical offsets
    final double step = MediaQuery.of(context).size.width / (texts.length + 1);
    
    List<double> positionsX = [];
    List<double> offsetsY = [];
    for (int i = 0; i < texts.length; i++) {
        // Offset starting from step, with small random jitter
        positionsX.add(step * (i + 1) - 45 + (_random.nextDouble() * 20 - 10)); // -45 to center the 90px width bubble
        offsetsY.add(_random.nextDouble() * 200); // Random stagger up to 200px higher
    }
    positionsX.shuffle();
    
    // Colorful bubbles
    final List<Color> bubbleColors = [
      Colors.redAccent.shade100,
      Colors.blueAccent.shade100,
      Colors.greenAccent.shade100,
      Colors.orangeAccent.shade100,
      Colors.purpleAccent.shade100,
      Colors.pinkAccent.shade100,
      Colors.cyanAccent.shade100,
    ];
    bubbleColors.shuffle();

    _activeSyllables = [];
    for (int i = 0; i < texts.length; i++) {
        _activeSyllables.add(SyllableItem(
           text: texts[i],
           isTarget: texts[i] == _targetSyllable,
           startX: positionsX[i].clamp(0.0, MediaQuery.of(context).size.width - 90.0),
           startYOffset: -100 - offsetsY[i], 
           bubbleColor: bubbleColors[i % bubbleColors.length],
        ));
    }
  }

  void _onSyllableTapped(SyllableItem item) {
    if (!_isPlaying) return;

    if (item.isTarget) {
      // Good!
      _consecutiveSuccess++;
      _consecutiveFailures = 0;
      
      _ttsService.speak("Bravo !");
      setState(() {
        _score++;
        _isPlaying = false; 
        _activeSyllables.clear();
      });
      
      _checkAdaptiveDifficulty();
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _round++;
          _startRound();
        }
      });
    } else {
      // Wrong!
      _consecutiveSuccess = 0;
      _consecutiveFailures++;
      _ttsService.speak("Oops ! Essaie encore.");
      setState(() {
         _activeSyllables.remove(item);
      });
    }
  }

  void _checkAdaptiveDifficulty() {
     // If 5 consecutive successes and not max level, go up
     if (_consecutiveSuccess >= 5 && _currentLevel < 4) {
         setState(() {
            _currentLevel++;
         });
         _ttsService.speak("Super ! C'est plus difficile maintenant.");
         _consecutiveSuccess = 0; // reset
     }
  }

  void _onGroundReached(SyllableItem item) {
    // If the target reaches the ground and the game is active, trigger second chance or failure
    if (item.isTarget && _isPlaying) {
        if (!_isSecondChance) {
             // First time missing it, go to second chance
             setState(() {
                _isPlaying = false;
                _isSecondChance = true;
                _activeSyllables.clear();
             });
             _ttsService.speak("Oh non ! Regarde bien, elle va revenir.");
             
             // Respawn the same options, but now second chance is true
             Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                   // Keep same round variables but reshuffle positions
                   final texts = [_targetSyllable, ...SyllabesData.getRandomSyllables(
                     level: _currentLevel,
                     targetSyllable: _targetSyllable,
                     count: 4
                   ).where((s) => s != _targetSyllable).take(3)];
                   texts.shuffle();
                   _spawnSyllables(texts);
                   setState(() { 
                       _isPlaying = true;
                       _isFallingAllowed = false; 
                   });
                   _playInstructionAndStart();
                }
             });
        } else {
             // Second time missing it, move to next round
             _consecutiveSuccess = 0;
             _consecutiveFailures++;
             
             setState(() {
                _isPlaying = false;
                _activeSyllables.clear();
             });
             _ttsService.speak("C'était la syllabe $_targetSyllable.");
             
             Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                   _round++;
                   _startRound();
                }
             });
        }
    }
  }

  void _showGameOver() {
    setState(() {
      _isPlaying = false;
      _activeSyllables.clear();
    });
    _ttsService.speak("Super partie ! Tu as eu $_score points.");
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Partie terminée !"),
        content: Text("Tu as attrapé $_score syllabe${_score > 1 ? 's' : ''} sur $_maxRounds !"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to hub
            },
            child: const Text("Retour à l'accueil"),
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // The duration determines how fast it falls. Slower now.
    Duration fallDuration = Duration(seconds: 10 - _currentLevel); // Lvl 1 = 9s, Lvl 4 = 6s.
    if (_isSecondChance) fallDuration = fallDuration + const Duration(seconds: 3); // Even Slower on second chance

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/attrape_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30, shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))]),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            "Manche $_round/$_maxRounds",
                            style: const TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))]
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 30, shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))]),
                              const SizedBox(width: 5),
                              Text("$_score", style: const TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))]
                              )),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Game Area
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Stack(
                    children: [
                       AnimatedBackgroundWidget(ttsService: _ttsService),
                       ..._activeSyllables.map((item) {
                          // We need a unique key for each fall so the animation restarts if recreated, but we want it unique to avoid Flutter recycling the state incorrectly when the list shrinks
                          final keyString = "${item.text}_${item.startX}_${_round}_$_isSecondChance";
                          return FallingSyllableWidget(
                            key: ValueKey(keyString),
                            text: item.text,
                            isTarget: item.isTarget,
                            isSecondChance: _isSecondChance,
                            isFallingAllowed: _isFallingAllowed,
                            bubbleColor: item.bubbleColor,
                            screenHeight: screenHeight - 150, // Available height approx
                            screenWidth: screenWidth,
                            startX: item.startX,
                            startYOffset: item.startYOffset,
                            fallDuration: fallDuration,
                            onTap: () => _onSyllableTapped(item),
                            onGroundReached: () => _onGroundReached(item),
                          );
                       }).toList(),

                       // Optional: Ground visually with lovely child icons
                       Positioned(
                         bottom: 0,
                         left: 0,
                         right: 0,
                         child: Container(
                           height: 60,
                           decoration: BoxDecoration(
                             color: Colors.brown.shade400.withValues(alpha: 0.0), // Fully transparent to see the river/grass
                             borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: [
                                Icon(Icons.boy, color: Colors.blue.shade100, size: 50, shadows: const [Shadow(color: Colors.black45, blurRadius: 6)]),
                                Icon(Icons.child_care, color: Colors.pink.shade100, size: 45, shadows: const [Shadow(color: Colors.black45, blurRadius: 6)]),
                                Icon(Icons.girl, color: Colors.green.shade100, size: 50, shadows: const [Shadow(color: Colors.black45, blurRadius: 6)]),
                                Icon(Icons.child_friendly, color: Colors.orange.shade100, size: 45, shadows: const [Shadow(color: Colors.black45, blurRadius: 6)]),
                                Icon(Icons.boy, color: Colors.yellow.shade100, size: 50, shadows: const [Shadow(color: Colors.black45, blurRadius: 6)]),
                             ],
                           ),
                         ),
                       )
                    ],
                  ),
                ),
              ),
              
              // Instruction button at the bottom
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: GestureDetector(
                  onTap: _repeatInstruction,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up, color: Colors.white, size: 30, shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))]),
                            SizedBox(width: 10),
                            Text("Répéter", style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white, 
                              shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1,1))]
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
