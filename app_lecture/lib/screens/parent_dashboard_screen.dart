import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/word.dart';
import '../models/word_progress.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import 'album_screen.dart';

/// Dashboard parents : statistiques et mots en difficulté pour le profil courant.
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService.instance;
    final profile = profileService.getCurrentProfile();
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Espace Parents')),
        body: const Center(child: Text('Aucun profil sélectionné.')),
      );
    }

    final progressList = profileService.getAllProgressForProfile(profile.keyAsId);
    final wordsBox = Hive.box<Word>('words');

    int totalSeen = progressList.length;
    int totalSuccess = 0;
    int totalFail = 0;
    for (final wp in progressList) {
      totalSuccess += wp.successCount;
      totalFail += wp.failCount;
    }
    final totalAttempts = totalSuccess + totalFail;
    final successRate = totalAttempts > 0
        ? (100.0 * totalSuccess / totalAttempts).round()
        : 0;

    final now = DateTime.now();
    final inDifficulty = progressList.where((wp) {
      if (wp.failCount == 0) return false;
      final word = wordsBox.get(wp.wordKey);
      if (word == null) return false;
      return wp.failCount >= wp.successCount ||
          wp.nextReview.isBefore(now) ||
          wp.nextReview.isAtSameMomentAs(now);
    }).toList();
    inDifficulty.sort((a, b) => b.failCount.compareTo(a.failCount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Parents'),
        backgroundColor: const Color(0xFF006064),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF006064),
                      child: Text(
                        profile.name.isNotEmpty
                            ? profile.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Profil : ${profile.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006064),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatRow('Mots vus', '$totalSeen'),
                    const Divider(),
                    _StatRow('Réussites', '$totalSuccess'),
                    _StatRow('Échecs', '$totalFail'),
                    const Divider(),
                    _StatRow(
                      'Taux de réussite (reconnaissance vocale)',
                      '$successRate %',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF006064)),
                title: const Text('Album – Photos et mots'),
                subtitle: const Text(
                  'Voir toutes les photos avec le mot associé pour repérer celles qui ne conviennent pas.',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AlbumScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mots en difficulté (à revoir)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006064),
              ),
            ),
            const SizedBox(height: 8),
            if (inDifficulty.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Aucun mot en difficulté pour l\'instant.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            else
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: inDifficulty.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final wp = inDifficulty[i];
                    final word = wordsBox.get(wp.wordKey);
                    final label = word?.text ?? 'Mot #${wp.wordKey}';
                    final theme = word?.theme ?? '—';
                    return ListTile(
                      title: Text(label),
                      subtitle: Text(
                        '$theme · ✓ ${wp.successCount} · ✗ ${wp.failCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
