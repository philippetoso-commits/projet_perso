import 'package:flutter/material.dart';
import 'tape_mains_game_screen.dart';

class TapeMainsEntryScreen extends StatefulWidget {
  const TapeMainsEntryScreen({Key? key}) : super(key: key);

  @override
  _TapeMainsEntryScreenState createState() => _TapeMainsEntryScreenState();
}

class _TapeMainsEntryScreenState extends State<TapeMainsEntryScreen> {
  int _selectedLevel = 1;

  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TapeMainsGameScreen(level: _selectedLevel),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Tape les Mains',
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.front_hand_rounded, color: Colors.white, size: 80),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          'Tape l\'écran pour chaque syllabe !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Niveau dropdown
                      const Text(
                        'Choisis la difficulté :',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8)
                          ],
                        ),
                        child: DropdownButton<int>(
                          value: _selectedLevel,
                          underline: Container(),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFE65100)),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text("Niveau 1 (1 à 3 syllabes)", style: TextStyle(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 2, child: Text("Niveau 2 (4 syllabes et plus)", style: TextStyle(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 3, child: Text("Niveau 3 (Tous les mots)", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLevel = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Start Button
                      GestureDetector(
                        onTap: _startGame,
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
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
