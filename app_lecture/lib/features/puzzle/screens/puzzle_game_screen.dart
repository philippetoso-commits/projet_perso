import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/word.dart';
import '../../../services/tts_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/log_service.dart';
import '../models/puzzle_cut_data.dart';
import '../widgets/puzzle_board_painter.dart';
import '../widgets/puzzle_piece_painter.dart';
import '../widgets/puzzle_piece_rain_celebration.dart';

class PuzzleGameScreen extends StatefulWidget {
  final List<Word> words;
  final int profileKey;

  const PuzzleGameScreen({
    super.key,
    required this.words,
    required this.profileKey,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  late TtsService _tts;
  int _wordIndex = 0;
  int _score = 0;

  bool _loading = true;
  ui.Image? _currentImage;

  // État du puzzle
  late List<String> _syllables;
  late int _totalPieces;
  late List<PuzzleCutData> _cuts;
  late List<bool> _placedPieces;
  
  // Le tiroir contient les index des pièces non placées, mélangés
  late List<int> _trayPieces;

  bool _showCelebration = false;

  Word get _currentWord => widget.words[_wordIndex];

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
    _tts.init();
    _loadWord();
  }

  Future<void> _loadWord() async {
    setState(() {
      _loading = true;
      _showCelebration = false;
    });

    final word = _currentWord;
    _syllables = List<String>.from(word.syllables);
    _totalPieces = _syllables.length;
    _placedPieces = List<bool>.filled(_totalPieces, false);

    // Initialiser les objets mathématiques des coupes aléatoires
    final rng = Random();
    _cuts = List.generate(
      _totalPieces - 1, 
      (_) => PuzzleCutData.random(rng),
    );

    // Mélanger les pièces pour le tiroir
    _trayPieces = List<int>.generate(_totalPieces, (i) => i);
    _trayPieces.shuffle(rng);

    // Charger l'image (ui.Image)
    _currentImage = await _loadImage(word);

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<ui.Image?> _loadImage(Word word) async {
    // Essaie d'abord l'image exacte en .jpg puis .png
    final bases = [
      word.imagePath.replaceAll('\\', '/').trim(),
      'assets/images/${word.theme}/${word.text.toLowerCase().replaceAll(' ', '_')}.jpg',
      'assets/images/${word.theme}/${word.text.toLowerCase().replaceAll(' ', '_')}.png',
      word.imagePath.endsWith('.jpg') ? word.imagePath.replaceAll('.jpg', '.png') : word.imagePath.replaceAll('.png', '.jpg'),
    ];

    for (var path in bases) {
      if (path.startsWith('/')) path = path.substring(1);
      try {
        final ByteData data = await rootBundle.load(path);
        final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final ui.FrameInfo fi = await codec.getNextFrame();
        return fi.image;
      } catch (_) {
        // Continue sur l'essai suivant
      }
    }
    return null; // Si tout échoue, renvoie null.
  }

  void _onPieceDropped(int pieceIndex) {
    setState(() {
      _placedPieces[pieceIndex] = true;
      _trayPieces.remove(pieceIndex);
    });
    _checkCompletion();
  }

  void _checkCompletion() {
    if (_trayPieces.isNotEmpty) return; // pas fini

    setState(() => _showCelebration = true);
    _tts.speak(_currentWord.text);
    _score++;

    // Sauvegarder la progression
    try {
      final wordKey = _currentWord.key;
      if (wordKey != null) {
        ProfileService.instance.saveWordProgress(
          widget.profileKey,
          wordKey as int,
          success: true,
          attempts: 1,
        );
      }
    } catch (e) {
      LogService().add('Puzzle save error: $e');
    }
  }

  void _nextWord() {
    if (_wordIndex < widget.words.length - 1) {
      setState(() {
        _wordIndex++;
        _loadWord();
      });
    } else {
      // Fin de la session
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mot ${_wordIndex + 1} / ${widget.words.length}',
          style: const TextStyle(
            color: Color(0xFF7C4DFF),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF7C4DFF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.extension_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : _currentImage == null
              ? const Center(child: Text('Impossible de charger l\'image.'))
              : Stack(
                  children: [
                    _buildGameArea(),
                    if (_showCelebration)
                      PuzzlePieceRainCelebration(
                        onComplete: () {
                          if (mounted) setState(() => _showCelebration = false);
                        },
                      ),
                    if (_showCelebration) ...[
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _nextWord,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C4DFF),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Mot suivant',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildGameArea() {
    return Column(
      children: [
        // Consigne
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0, top: 12),
          child: Text(
            'Glisse chaque pièce à sa place !',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Le plateau
        Expanded(
          flex: 4,
          child: Center(
            child: _buildBoard(),
          ),
        ),

        const SizedBox(height: 20),

        // Le tiroir des pièces mélangées
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: _trayPieces.isEmpty
                ? Center(
                    child: Text(
                      _currentWord.text.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 4,
                      ),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 24,
                    children: _trayPieces.map((pieceIdx) {
                       return _buildDraggablePiece(pieceIdx);
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  // Largeur et Hauteur de base pour l'affichage du puzzle sur l'écran
  final double boardTargetWidth = 320;
  final double boardTargetHeight = 220;

  Widget _buildBoard() {
    return Container(
      width: boardTargetWidth,
      height: boardTargetHeight,
      // Petit shadow du cadre global
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Dessin du board complet via CustomPaint
          CustomPaint(
            size: Size(boardTargetWidth, boardTargetHeight),
            painter: PuzzleBoardPainter(
              image: _currentImage!,
              totalPieces: _totalPieces,
              cuts: _cuts,
              placedPieces: _placedPieces,
              syllables: _syllables,
            ),
          ),

          // Grille de DragTargets invisibles par-dessus
          Row(
            children: List.generate(_totalPieces, (i) {
              return Expanded(
                child: DragTarget<int>(
                  builder: (context, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    // Highlight quand une piece survole s'il n'est pas déjà placé
                    return Container(
                      color: isHovered && !_placedPieces[i]
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.transparent,
                    );
                  },
                  onWillAcceptWithDetails: (details) {
                    // N'accepte que si c'est le bon index
                    return details.data == i && !_placedPieces[i];
                  },
                  onAcceptWithDetails: (details) {
                    _onPieceDropped(details.data);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePiece(int pieceIdx) {
    // Calcul de la taille de la pièce (largeur + de la marge pour les tenons)
    final pieceBaseWidth = boardTargetWidth / _totalPieces;
    
    // Pour ne pas couper le dessin d'un tenon sortant, le SizedBox du CustomPaint 
    // doit être un peu plus large (environ pieceBaseWidth * 1.5 pour gauche et droite).
    // Sur l'écran, le _getPiecePath de PuzzlePiecePainter est aligné à X=0 
    // avec un débordement Y=0..height et X=0..width. MAIS l'image doit s'afficher bien.
    
    final viewWidth = pieceBaseWidth * 1.5;

    final child = SizedBox(
      width: viewWidth,
      height: boardTargetHeight, // même hauteur que le board
      child: CustomPaint(
        painter: PuzzlePiecePainter(
          image: _currentImage!,
          boardSize: Size(boardTargetWidth, boardTargetHeight),
          pieceIndex: pieceIdx,
          totalPieces: _totalPieces,
          text: _syllables[pieceIdx],
          leftCut: pieceIdx > 0 ? _cuts[pieceIdx - 1] : null,
          rightCut: pieceIdx < _totalPieces - 1 ? _cuts[pieceIdx] : null,
          isPlaced: false,
          isDragging: false,
        ),
      ),
    );

    final feedback = SizedBox(
      width: viewWidth * 1.05, // un poil plus grand pendant le drag
      height: boardTargetHeight * 1.05,
      child: CustomPaint(
        painter: PuzzlePiecePainter(
          image: _currentImage!,
          boardSize: Size(boardTargetWidth, boardTargetHeight),
          pieceIndex: pieceIdx,
          totalPieces: _totalPieces,
          text: _syllables[pieceIdx],
          leftCut: pieceIdx > 0 ? _cuts[pieceIdx - 1] : null,
          rightCut: pieceIdx < _totalPieces - 1 ? _cuts[pieceIdx] : null,
          isPlaced: false,
          isDragging: true,
        ),
      ),
    );

    return Draggable<int>(
      data: pieceIdx,
      feedback: Material(
        color: Colors.transparent,
        child: feedback,
      ),
      childWhenDragging: Opacity(
        opacity: 0.1,
        child: child,
      ),
      child: child,
    );
  }
}
