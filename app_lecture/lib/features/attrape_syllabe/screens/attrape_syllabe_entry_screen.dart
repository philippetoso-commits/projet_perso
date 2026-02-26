import 'package:flutter/material.dart';
import 'attrape_syllabe_game_screen.dart';

class AttrapeSyllabeEntryScreen extends StatefulWidget {
  const AttrapeSyllabeEntryScreen({Key? key}) : super(key: key);

  @override
  _AttrapeSyllabeEntryScreenState createState() => _AttrapeSyllabeEntryScreenState();
}

class _AttrapeSyllabeEntryScreenState extends State<AttrapeSyllabeEntryScreen> {
  int _selectedLevel = 1;

  void _startGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttrapeSyllabeGameScreen(
          initialLevel: _selectedLevel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81C784), Color(0xFF388E3C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar custom
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
                        'Attrape Syllabe',
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
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Attrape la bonne syllabe !',
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
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF388E3C)),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("Niveau 1 (Syllabes simples)", style: TextStyle(fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 2, child: Text("Niveau 2 (Sons composés)", style: TextStyle(fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 3, child: Text("Niveau 3 (Consonnes doubles)", style: TextStyle(fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 4, child: Text("Niveau 4 (Sons complexes)", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedLevel = val);
                        },
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
                            color: Color(0xFF388E3C),
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
