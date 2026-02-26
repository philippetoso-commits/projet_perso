import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../models/word.dart';
import '../../../screens/game_screen.dart';
import '../../../screens/map_screen.dart';
import '../../../services/log_service.dart';
import '../../../services/profile_service.dart';

/// Écran d'entrée du module Mot Mystère.
/// Permet de choisir un niveau et de démarrer une partie.
class MotMystereEntryScreen extends StatefulWidget {
  const MotMystereEntryScreen({super.key});

  @override
  State<MotMystereEntryScreen> createState() => _MotMystereEntryScreenState();
}

class _MotMystereEntryScreenState extends State<MotMystereEntryScreen> {
  int _selectedLevel = 1;
  final ProfileService _profileService = ProfileService.instance;

  void _startGame(BuildContext context) {
    final profile = _profileService.getCurrentProfile();
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choisis un profil pour jouer.")),
      );
      return;
    }
    LogService().add(
        "Starting Mot Mystère – level $_selectedLevel for ${profile.name}");
    try {
      final box = Hive.box<Word>('words');
      var availableWords =
          box.values.where((w) => w.level == _selectedLevel).toList();
      if (_selectedLevel == 1) {
        final allowed =
            _profileService.getAllowedPsThemes(profile.keyAsId);
        availableWords =
            availableWords.where((w) => allowed.contains(w.theme)).toList();
      }
      if (availableWords.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Pas de mots trouvés pour ce niveau !")),
        );
        return;
      }
      final word =
          _profileService.pickNextWord(profile.keyAsId, availableWords,
              random: Random()) ??
              availableWords[Random().nextInt(availableWords.length)];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            word: word,
            level: _selectedLevel,
            profileKey: profile.keyAsId,
          ),
        ),
      );
    } catch (e) {
      LogService().add("ERROR in MotMystere _startGame: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar custom
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Mot Mystère',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icone décorative
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Trouve le mot caché !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Sélecteur de niveau
                    const Text(
                      'Choisis ton niveau :',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26, blurRadius: 8)
                        ],
                      ),
                      child: DropdownButton<int>(
                        value: _selectedLevel,
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down_rounded,
                            color: Color(0xFF512DA8)),
                        items: const [
                          DropdownMenuItem(
                              value: 1,
                              child: Text("Niveau 1 (PS)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold))),
                          DropdownMenuItem(
                              value: 2,
                              child: Text("Niveau 2 (MS)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold))),
                          DropdownMenuItem(
                              value: 3,
                              child: Text("Niveau 3 (GS)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold))),
                          DropdownMenuItem(
                              value: 4,
                              child: Text("Niveau 4 (CP)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedLevel = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bouton Parcours
                    TextButton.icon(
                      onPressed: () {
                        final profile =
                            _profileService.getCurrentProfile();
                        if (profile == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MapScreen(profileKey: profile.keyAsId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded,
                          color: Colors.white70, size: 20),
                      label: const Text(
                        "Voir mon parcours",
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Bouton Jouer
                    GestureDetector(
                      onTap: () => _startGame(context),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 90,
                            color: Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
