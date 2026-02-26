import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/word.dart';
import '../../../services/profile_service.dart';
import 'puzzle_game_screen.dart';

/// Écran d'entrée du module Puzzle.
/// Charge les mots éligibles (≥3 syllabes) et lance le jeu.
class PuzzleEntryScreen extends StatefulWidget {
  final int profileKey;

  const PuzzleEntryScreen({super.key, required this.profileKey});

  @override
  State<PuzzleEntryScreen> createState() => _PuzzleEntryScreenState();
}

class _PuzzleEntryScreenState extends State<PuzzleEntryScreen> {
  List<Word>? _puzzleWords;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final box = Hive.box<Word>('words');
    final all = box.values.toList();

    // Filtrer : au moins 3 syllabes, chaque syllabe non vide
    var eligible = all.where((w) {
      final syls = w.syllables.where((s) => s.trim().isNotEmpty).toList();
      return syls.length >= 3;
    }).toList();

    // Trier par nombre de syllabes décroissant, puis alphabétique
    eligible.sort((a, b) {
      final cmp = b.syllables.length.compareTo(a.syllables.length);
      return cmp != 0 ? cmp : a.text.compareTo(b.text);
    });

    // Prendre les 100 premiers, mélanger pour la session
    final words = eligible.take(100).toList()..shuffle(Random());

    setState(() {
      _puzzleWords = words;
      _loading = false;
    });
  }

  void _startGame() {
    if (_puzzleWords == null || _puzzleWords!.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleGameScreen(
          words: _puzzleWords!,
          profileKey: widget.profileKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Puzzle Syllabes',
          style: TextStyle(
            color: Color(0xFF7C4DFF),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF7C4DFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final count = _puzzleWords?.length ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône puzzle animée
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C4DFF), Color(0xFF5C35CC)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.extension_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'Puzzle Syllabes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C4DFF),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Remets les syllabes dans le bon ordre\npour former le mot !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$count mots disponibles',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 48),

            // Bouton jouer
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C4DFF), Color(0xFFFF6D00)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Jouer !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Indicateur de mots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  'Mots de 3 à 5 syllabes',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
