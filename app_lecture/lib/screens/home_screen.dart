import 'package:flutter/material.dart';
import 'dart:async';
import '../services/log_service.dart';
import '../services/profile_service.dart';
import '../widgets/game_hub_card.dart';
import 'profile_select_screen.dart';
import 'parent_gate_screen.dart';
import 'parent_dashboard_screen.dart';
import '../features/mot_mystere/screens/mot_mystere_entry_screen.dart';
import '../features/puzzle/screens/puzzle_coming_soon_screen.dart';
import '../features/attrape_syllabe/screens/attrape_syllabe_entry_screen.dart';
import '../features/tape_mains/screens/tape_mains_entry_screen.dart';
import '../features/audiobook/screens/audiobook_screen.dart';
import '../models/audiobook.dart';

const List<IconData> _avatarIcons = [
  Icons.face,
  Icons.face_2,
  Icons.face_3,
  Icons.child_care,
  Icons.emoji_emotions,
  Icons.person,
  Icons.person_outline,
  Icons.star,
];

IconData _avatarIcon(int id) =>
    _avatarIcons[id.clamp(0, _avatarIcons.length - 1)];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/main_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main content ──────────────────────────────────────────
              Column(
                children: [
                  // ► Top bar: profil + réglages
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                                  child: Icon(_avatarIcon(p.avatarId),
                                      color: Colors.blue.shade700, size: 22),
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
                          icon: const Icon(Icons.settings,
                              color: Colors.black54),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileSelectScreen(
                                    fromSettings: true),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),

                  // ► Mascotte + titre
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _AnimatedMascotte(
                          onTap: _onMascotteTap,
                          imagePath: 'assets/images/mascotte.png',
                          height: 110,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'SyllaboJeux',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 4.0,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ► Grille 2×2 des modules
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // 1. Mot Mystère
                          GameHubCard(
                            title: 'Mot Mystère',
                            subtitle: 'Trouve le mot caché',
                            icon: Icons.search_rounded,
                            cardColor: const Color(0xFF7C4DFF),
                            iconBgColor: const Color(0xFF9C6FFF),
                            iconColor: Colors.white,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MotMystereEntryScreen()),
                            ),
                          ),
                          // 2. Puzzle
                          GameHubCard(
                            title: 'Puzzle',
                            subtitle: 'Assemble les pièces',
                            icon: Icons.extension_rounded,
                            cardColor: const Color(0xFFFF6D00),
                            iconBgColor: const Color(0xFFFF9100),
                            iconColor: Colors.white,
                            onTap: () {
                              final profile = _profileService.getCurrentProfile();
                              if (profile == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PuzzleEntryScreen(
                                    profileKey: profile.key as int,
                                  ),
                                ),
                              );
                            },
                          ),
                          // 3. Attrape Syllabe
                          GameHubCard(
                            title: 'Attrape\nSyllabe',
                            subtitle: 'Attrape la bonne syllabe',
                            icon: Icons.music_note_rounded,
                            cardColor: const Color(0xFF2E7D32),
                            iconBgColor: const Color(0xFF43A047),
                            iconColor: Colors.white,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AttrapeSyllabeEntryScreen()),
                            ),
                          ),
                          // 4. Tape dans les Mains
                          GameHubCard(
                            title: 'Tape les\nMains',
                            subtitle: 'Bats le rythme',
                            icon: Icons.back_hand_rounded,
                            cardColor: const Color(0xFFD81B60),
                            iconBgColor: const Color(0xFFE91E63),
                            iconColor: Colors.white,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const TapeMainsEntryScreen()),
                            ),
                          ),
                          // 5. Audiobook
                          GameHubCard(
                            title: 'Livre Audio',
                            subtitle: 'Le Petit Poucet',
                            icon: Icons.menu_book_rounded,
                            cardColor: const Color(0xFF009688),
                            iconBgColor: const Color(0xFF4DB6AC),
                            iconColor: Colors.white,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AudiobookScreen(
                                  audiobook: petitPoucetAudiobook,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ► Bouton Album en bas
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Mon Album"),
                            content: const Text(
                                "Tu pourras bientôt voir ici tous les mots que tu as appris !"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Super !"),
                              )
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.book,
                          color: Color(0xFF006064), size: 20),
                      label: const Text(
                        'Mon Album',
                        style: TextStyle(
                          color: Color(0xFF006064),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Debug overlay ─────────────────────────────────────────
              if (_showDebug)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("CONSOLE DE DEBUG (ACCUEIL)",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    String path =
                                        await LogService().exportLogs();
                                    LogService()
                                        .add("Logs exportés vers: $path");
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text("Exporter"),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () =>
                                        setState(() => _showDebug = false)),
                              ],
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: LogService().logs.length,
                            itemBuilder: (context, i) => Text(
                                LogService().logs[i],
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontFamily: 'monospace')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Debug toggle button ───────────────────────────────────
              Positioned(
                top: 60,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.terminal,
                        color: Colors.red, size: 26),
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

// ─────────────────────────────────────────────────────────────────────────────
/// Mascotte avec animation de « respiration » et rebond au tap.
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
        tween:
            Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
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
      if (mounted)
        _tapController!.reverse().then((_) {
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
          return Transform.scale(scale: scale, child: child);
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
