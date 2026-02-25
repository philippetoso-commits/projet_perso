
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:math';
import 'dart:async';
import '../models/word.dart';
import 'game_screen.dart';
import 'map_screen.dart';
import 'profile_select_screen.dart';
import 'parent_gate_screen.dart';
import 'parent_dashboard_screen.dart';
import '../services/log_service.dart';
import '../services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const List<IconData> _avatarIcons = [
  Icons.face, Icons.face_2, Icons.face_3, Icons.child_care,
  Icons.emoji_emotions, Icons.person, Icons.person_outline, Icons.star,
];

IconData _avatarIcon(int id) =>
    _avatarIcons[id.clamp(0, _avatarIcons.length - 1)];

class _HomeScreenState extends State<HomeScreen> {
  int _selectedLevel = 1;
  bool _showDebug = false;
  int _mascotteTapCount = 0;
  Timer? _mascotteTapReset;
  final ProfileService _profileService = ProfileService.instance;

  @override
  void initState() {
    super.initState();
    LogService().onNewLog = (msg) {
        if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _mascotteTapReset?.cancel();
    super.dispose();
  }

  void _onMascotteTap() {
    _mascotteTapReset?.cancel();
    _mascotteTapReset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mascotteTapCount = 0);
    });
    setState(() => _mascotteTapCount++);
    if (_mascotteTapCount >= 5) {
      _mascotteTapCount = 0;
      _mascotteTapReset?.cancel();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ParentGateScreen(
            childOnSuccess: ParentDashboardScreen(),
          ),
        ),
      );
    }
  }

  void _startGame(BuildContext context) {
    final profile = _profileService.getCurrentProfile();
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choisis un profil pour jouer.")),
      );
      return;
    }
    LogService().add("Starting game with level $_selectedLevel for ${profile.name}");
    try {
        final box = Hive.box<Word>('words');
        var availableWords = box.values.where((w) => w.level == _selectedLevel).toList();
        if (_selectedLevel == 1) {
          final allowed = _profileService.getAllowedPsThemes(profile.keyAsId);
          availableWords = availableWords.where((w) => allowed.contains(w.theme)).toList();
        }
        if (availableWords.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pas de mots trouvés pour ce niveau !")),
          );
          return;
        }
        final word = _profileService.pickNextWord(profile.keyAsId, availableWords, random: Random())
            ?? availableWords[Random().nextInt(availableWords.length)];
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
        LogService().add("ERROR in _startGame: $e");
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
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)], 
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Background Elements (Positioned)
              
              // Bottom Left : Album
              Positioned(
                bottom: 30,
                left: 30,
                child: _SmallButton(
                  icon: Icons.book,
                  color: Colors.blueAccent,
                  label: "Album",
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Mon Album"),
                        content: const Text("Tu pourras bientôt voir ici tous les mots que tu as appris !"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Super !"),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Top: profil courant + paramètres
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) {
                        final p = _profileService.getCurrentProfile();
                        if (p == null) return const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(_avatarIcon(p.avatarId), color: Colors.blue.shade700, size: 22),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006064),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.black54),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileSelectScreen(fromSettings: true),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              // 2. Main Content (Column for Spacing)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     const SizedBox(height: 40), // Top Spacing
                     
                     // Header (5 taps sur la mascotte = Espace Parents)
                     _AnimatedMascotte(
                        onTap: _onMascotteTap,
                        imagePath: 'assets/images/mascotte.png',
                        height: 150,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Le Mot Mystère",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006064),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // LEVEL SELECTOR
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: DropdownButton<int>(
                          value: _selectedLevel,
                          underline: Container(),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF006064)),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text("Niveau 1 (PS)", style: TextStyle(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 2, child: Text("Niveau 2 (MS)", style: TextStyle(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 3, child: Text("Niveau 3 (GS)", style: TextStyle(fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 4, child: Text("Niveau 4 (CP)", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLevel = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bouton Parcours (carte)
                      TextButton.icon(
                        onPressed: () {
                          final profile = _profileService.getCurrentProfile();
                          if (profile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Choisis un profil pour jouer.")),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(profileKey: profile.keyAsId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_rounded, color: Color(0xFF006064), size: 22),
                        label: const Text("Parcours", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006064), fontSize: 16)),
                      ),
                      
                      const Spacer(), // Pushes Play Button down
                      
                      // Play Button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _startGame(context),
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 90,
                              color: Color(0xFFFF7043), 
                            ),
                          ),
                        ),
                      ),
                      
                      const Spacer(), // Bottom Spacing
                  ],
                ),
              ),

              // DEBUG CONSOLE OVERLAY
              if (_showDebug)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("CONSOLE DE DEBUG (ACCUEIL)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    String path = await LogService().exportLogs();
                                    LogService().add("Logs exportés vers: $path");
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text("Exporter"),
                                ),
                                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _showDebug = false)),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: LogService().logs.length,
                            itemBuilder: (context, i) => Text(LogService().logs[i], style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // DEBUG TOGGLE BUTTON
              Positioned(
                top: 100,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.terminal, color: Colors.red, size: 30),
                    onPressed: () {
                        LogService().add("Debug Toggle Pressed");
                        setState(() => _showDebug = !_showDebug);
                    },
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

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006064),
          ),
        ),
      ],
    );
  }
}

/// Mascotte avec animation de « respiration » (léger scale) et rebond au tap.
class _AnimatedMascotte extends StatefulWidget {
  final VoidCallback onTap;
  final String imagePath;
  final double height;

  const _AnimatedMascotte({
    required this.onTap,
    required this.imagePath,
    required this.height,
  });

  @override
  State<_AnimatedMascotte> createState() => _AnimatedMascotteState();
}

class _AnimatedMascotteState extends State<_AnimatedMascotte>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathScale;
  AnimationController? _tapController;
  Animation<double>? _tapScale;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();

    _breathScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 1,
      ),
    ]).animate(_breathController);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _tapController?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (_tapController != null) return;
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController!, curve: Curves.easeInOut),
    );
    setState(() {});
    _tapController!.forward().then((_) {
      if (mounted) _tapController!.reverse().then((_) {
        if (mounted) {
          _tapController?.dispose();
          _tapController = null;
          setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (_) => widget.onTap(),
      onTapCancel: () {},
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breathController,
          if (_tapController != null) _tapController!,
        ]),
        builder: (context, child) {
          double scale = _breathScale.value;
          if (_tapController != null && _tapScale != null) {
            scale = scale * _tapScale!.value;
          }
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Image.asset(
          widget.imagePath,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
