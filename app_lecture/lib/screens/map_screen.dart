import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/word.dart';
import '../services/profile_service.dart';
import '../services/map_config.dart';
import 'game_screen.dart';

/// Écran de la carte (parcours gamification) : fond + îles débloquées/verrouillées + étoiles.
class MapScreen extends StatelessWidget {
  final int profileKey;

  const MapScreen({super.key, required this.profileKey});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService.instance;
    final unlockedIndex = profileService.getUnlockedMapStepIndex(profileKey);
    final box = Hive.box<Word>('words');
    final allWords = box.values.toList();

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
              // Fond carte (dossier assets/images/carte/ : .png ou .jpg)
              Positioned.fill(
                child: _CarteAssetImage(
                  baseName: 'carte_fond',
                  fit: BoxFit.cover,
                  fullSize: true,
                  placeholder: Container(
                    color: const Color(0xFFE0F7FA),
                    child: const Center(child: Icon(Icons.map_outlined, size: 80, color: Colors.white70)),
                  ),
                ),
              ),
              // Bouton retour
              Positioned(
                top: 12,
                left: 12,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Titre
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Parcours',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              // Nœuds (îles) : disposition en courbe / ligne
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 60, bottom: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(MapConfig.steps.length, (i) {
                      final step = MapConfig.steps[i];
                      final isUnlocked = i <= unlockedIndex;
                      final stepWords = profileService.getWordsForStep(i, allWords);
                      final stars = profileService.getStarsForStep(profileKey, i, stepWords);
                      final maxStars = stepWords.length * 3;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _MapNode(
                          step: step,
                          isUnlocked: isUnlocked,
                          stars: stars,
                          maxStars: maxStars,
                          stepWords: stepWords,
                          stepIndex: i,
                          profileKey: profileKey,
                        ),
                      );
                    }),
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

class _MapNode extends StatelessWidget {
  final MapStep step;
  final bool isUnlocked;
  final int stars;
  final int maxStars;
  final List<Word> stepWords;
  final int stepIndex;
  final int profileKey;

  const _MapNode({
    required this.step,
    required this.isUnlocked,
    required this.stars,
    required this.maxStars,
    required this.stepWords,
    required this.stepIndex,
    required this.profileKey,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUnlocked && stepWords.isNotEmpty
            ? () {
                final first = stepWords.first;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      word: first,
                      level: first.level,
                      profileKey: profileKey,
                      stepWords: stepWords,
                      stepIndex: stepIndex,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isUnlocked
                ? Colors.white.withOpacity(0.9)
                : Colors.grey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CarteAssetImage(
                baseName: isUnlocked ? 'carte_ile_debloquee' : 'carte_ile_verrouillee',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                placeholder: Icon(
                  isUnlocked ? Icons.check_circle : Icons.lock,
                  size: 56,
                  color: isUnlocked ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Étape ${step.id + 1} – ${step.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isUnlocked ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (isUnlocked && maxStars > 0)
                    Row(
                      children: [
                        ...List.generate(3, (i) {
                          final threshold = (i + 1) * (maxStars / 3);
                          final filled = stars >= threshold;
                          return Icon(
                            Icons.star,
                            size: 18,
                            color: filled ? Colors.amber : Colors.grey.shade300,
                          );
                        }),
                        Text(
                          ' $stars / $maxStars',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                ],
              ),
              if (isUnlocked && stepWords.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.play_circle_fill, color: Color(0xFF006064), size: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Charge une image du dossier assets/images/carte/ en essayant .png puis .jpg.
class _CarteAssetImage extends StatefulWidget {
  final String baseName;
  final BoxFit fit;
  final bool fullSize;
  final double? width;
  final double? height;
  final Widget placeholder;

  const _CarteAssetImage({
    required this.baseName,
    required this.fit,
    required this.placeholder,
    this.fullSize = false,
    this.width,
    this.height,
  });

  @override
  State<_CarteAssetImage> createState() => _CarteAssetImageState();
}

class _CarteAssetImageState extends State<_CarteAssetImage> {
  int _attempt = 0;

  String get _path {
    final ext = _attempt == 0 ? '.png' : '.jpg';
    return 'assets/images/carte/${widget.baseName}$ext';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _path,
      fit: widget.fit,
      width: widget.fullSize ? null : widget.width,
      height: widget.fullSize ? null : widget.height,
      errorBuilder: (_, __, ___) {
        if (_attempt == 0 && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _attempt = 1);
          });
          return SizedBox(
            width: widget.fullSize ? null : widget.width,
            height: widget.fullSize ? null : widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return widget.placeholder;
      },
    );
  }
}
