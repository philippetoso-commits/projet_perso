import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import '../../../models/word.dart';
import '../../../services/tts_service.dart';
import '../widgets/clapping_hands.dart';

class TapeMainsGameScreen extends StatefulWidget {
  final int level;
  const TapeMainsGameScreen({Key? key, required this.level}) : super(key: key);

  @override
  _TapeMainsGameScreenState createState() => _TapeMainsGameScreenState();
}

class _TapeMainsGameScreenState extends State<TapeMainsGameScreen> with SingleTickerProviderStateMixin {
  final TtsService _ttsService = TtsService();
  final Random _random = Random();

  List<Word> _words = [];
  bool _loading = true;

  int _currentIndex = 0;
  Word? get _currentWord => _words.isNotEmpty ? _words[_currentIndex] : null;

  int _tapCount = 0;
  List<Widget> _clapWidgets = [];

  int _consecutiveFailures = 0;
  bool _showHelpButtons = false;
  bool _isAnimatingFeedback = false; // Prevents interactions during feedback animations

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadWords();
  }

  Future<void> _initServices() async {
    await _ttsService.init();
  }

  Future<void> _loadWords() async {
    final box = Hive.box<Word>('words');
    final all = box.values.toList();

    List<Word> eligible = [];
    if (widget.level == 1) {
      eligible = all.where((w) {
        final len = w.syllables.where((s) => s.trim().isNotEmpty).length;
        return len >= 1 && len <= 3;
      }).toList();
    } else if (widget.level == 2) {
      eligible = all.where((w) {
        final len = w.syllables.where((s) => s.trim().isNotEmpty).length;
        return len >= 4;
      }).toList();
    } else {
      eligible = all;
    }

    eligible.shuffle(_random);

    setState(() {
      _words = eligible.take(50).toList();
      _loading = false;
    });

    // Start first word instruction
    _playInstruction();
  }

  int get _expectedSyllables {
    if (_currentWord == null) return 0;
    return _currentWord!.syllables.where((s) => s.trim().isNotEmpty).length;
  }

  void _playInstruction() async {
    if (_currentWord == null) return;
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_currentIndex == 0) {
        _ttsService.speak("${_currentWord!.text}, tape autant de fois que tu entends de morceaux !");
    } else {
        _ttsService.speak(_currentWord!.text); // Prononce juste le mot entier normalement
    }
  }

  void _onScreenTapped() {
    if (_loading || _currentWord == null || _isAnimatingFeedback) return;

    // Haptic feedback & Sound (System click)
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    setState(() {
      _tapCount++;
      _clapWidgets.add(ClappingHandsWidget(index: _tapCount, key: ValueKey("user_tap_$_tapCount")));
    });
  }

  void _onHelpButtonTapped(int count) {
    if (_isAnimatingFeedback) return;
    // Simulate tapping X times quickly
    setState(() {
       _tapCount = count;
       _clapWidgets.clear();
       for(int i=1; i<=count; i++) {
          _clapWidgets.add(ClappingHandsWidget(index: i, key: ValueKey("help_tap_$i")));
       }
    });

    // Automatically validate when they push a help button
    Future.delayed(const Duration(milliseconds: 500), _validateTapCount);
  }

  void _validateTapCount() async {
    if (_tapCount == 0 || _currentWord == null || _isAnimatingFeedback) return;

    setState(() {
      _isAnimatingFeedback = true;
    });

    if (_tapCount == _expectedSyllables) {
      // Success 🎉
      _consecutiveFailures = 0;
      _showHelpButtons = false;
      String syllableText = _expectedSyllables == 1 ? "une syllabe" : "$_expectedSyllables syllabes";
      _ttsService.speak("Super ! ${_currentWord!.text}, $syllableText.");

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _currentIndex++;
          _tapCount = 0;
          _clapWidgets.clear();
          _isAnimatingFeedback = false;
        });
        _playInstruction();
      }
    } else {
      // Failure ❌
      _consecutiveFailures++;
      if (_consecutiveFailures >= 2) {
         _showHelpButtons = true; // Reveal hybrid safety net
      }

      _ttsService.speak("Presque ! On réécoute et on retape ensemble.");

      await Future.delayed(const Duration(seconds: 3));

      // Automated clapping feedback
      if (mounted) {
         setState(() {
            _tapCount = 0;
            _clapWidgets.clear();
         });
         
         final cleanSyllables = _currentWord!.syllables.where((s) => s.trim().isNotEmpty).toList();

         for (int i = 0; i < cleanSyllables.length; i++) {
            if (!mounted) break;
            // Speak the syllable
            _ttsService.speak(cleanSyllables[i]);
            
            // Add visual and haptic feedback
            HapticFeedback.mediumImpact();
            SystemSound.play(SystemSoundType.click);
            
            if (mounted) {
                setState(() {
                   _tapCount++;
                   _clapWidgets.add(ClappingHandsWidget(index: _tapCount, key: ValueKey("auto_tap_$_tapCount")));
                });
            }
            
            await Future.delayed(const Duration(milliseconds: 800));
         }

         await Future.delayed(const Duration(seconds: 1));

         if (mounted) {
            setState(() {
               // Reset state for them to try again
               _tapCount = 0;
               _clapWidgets.clear();
               _isAnimatingFeedback = false;
            });
         }
      }
    }
  }

  Widget _buildHybridHelpButtons() {
     if (!_showHelpButtons) return const SizedBox.shrink();
     
     return Padding(
       padding: const EdgeInsets.only(top: 20, bottom: 10),
       child: Column(
         children: [
           const Text("Besoin d'aide ? Appuie sur un bouton :", style: TextStyle(color: Colors.white, fontSize: 16)),
           const SizedBox(height: 10),
           Wrap(
             alignment: WrapAlignment.center,
             spacing: 15,
             runSpacing: 10,
             children: List.generate(
                _expectedSyllables > 4 ? _expectedSyllables : 4, // Ensure right answer is always visible
                (index) {
                   int number = index + 1;
                   return GestureDetector(
                     onTap: () => _onHelpButtonTapped(number),
                     child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                           boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]
                        ),
                        child: Center(
                           child: Text("$number", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF57C00))),
                        )
                     ),
                   );
                }
             ),
           ),
         ],
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _currentWord == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onScreenTapped, // Tap anywhere logic
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
             gradient: LinearGradient(
               begin: Alignment.topCenter,
               end: Alignment.bottomCenter,
               colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
             ),
          ),
          child: SafeArea(
             child: Column(
               children: [
                 // Header
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   child: Row(
                     children: [
                       IconButton(
                         icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                         onPressed: () => Navigator.pop(context),
                       ),
                       const Spacer(),
                       // Score or Progress
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.white.withValues(alpha: 0.2),
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text(
                           "${_currentIndex + 1} / ${_words.length}",
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                         ),
                       ),
                     ],
                   ),
                 ),
                 
                 const SizedBox(height: 20),

                 // Image & Word Display
                 Expanded(
                   flex: 3,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        // Image Container
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: _currentWord!.imagePath.isNotEmpty
                                ? Image.asset(_currentWord!.imagePath, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey))
                                : const Center(child: Text("?", style: TextStyle(fontSize: 80, color: Colors.grey))),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Word Text Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text(
                            _currentWord!.text.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                     ],
                   ),
                 ),

                 // Clapping Visualization Center
                 Expanded(
                   flex: 2,
                   child: AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     width: double.infinity,
                     margin: const EdgeInsets.symmetric(horizontal: 20),
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                     ),
                     child: Center(
                       child: _clapWidgets.isEmpty 
                         ? const Text("Tape l'écran pour compter !", style: TextStyle(color: Colors.white70, fontSize: 20))
                         : SingleChildScrollView(
                             scrollDirection: Axis.horizontal,
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: _clapWidgets,
                             ),
                           ),
                     ),
                   ),
                 ),

                 _buildHybridHelpButtons(),
                 const SizedBox(height: 10),

                 // Validate Button
                 Expanded(
                   flex: 1,
                   child: Center(
                     child: AnimatedOpacity(
                       opacity: _tapCount > 0 ? 1.0 : 0.0,
                       duration: const Duration(milliseconds: 200),
                       child: IgnorePointer(
                         ignoring: _tapCount == 0 || _isAnimatingFeedback,
                         child: ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 8,
                           ),
                           onPressed: _validateTapCount,
                           child: const Text("J'ai fini !", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                         ),
                       ),
                     ),
                   ),
                 )
               ],
             ),
          )
        ),
      ),
    );
  }
}
