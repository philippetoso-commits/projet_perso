import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/word.dart';

/// Écran "Album" : affiche toutes les photos avec le mot associé
/// pour repérer les images qui ne conviennent pas.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Word>('words');
    final words = box.values.toList();
    words.sort((a, b) {
      final themeCompare = a.theme.compareTo(b.theme);
      if (themeCompare != 0) return themeCompare;
      return a.text.compareTo(b.text);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Album – Photo / Mot'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${words.length} mots · Vérifiez que chaque photo correspond au mot.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  final word = words[index];
                  return _AlbumCard(word: word);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final Word word;

  const _AlbumCard({required this.word});

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  int _attempt = 0;

  String get _currentPath {
    final path = widget.word.imagePath.replaceAll(r'\', '/').trim().replaceFirst(RegExp(r'^/'), '');
    if (_attempt == 0) return path;
    if (_attempt == 1) {
      if (path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg')) {
        return path.replaceAll(RegExp(r'\.jpe?g$', caseSensitive: false), '.png');
      }
      if (path.toLowerCase().endsWith('.png')) {
        return path.replaceAll(RegExp(r'\.png$', caseSensitive: false), '.jpg');
      }
    }
    final theme = widget.word.theme;
    final word = widget.word.text.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-]'), '');
    if (_attempt == 2) return 'assets/images/$theme/$word.jpg';
    if (_attempt == 3) return 'assets/images/$theme/$word.png';
    return path;
  }

  void _tryNext() {
    if (mounted && _attempt < 3) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.asset(
              _currentPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                if (_attempt < 3) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _tryNext());
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 40, color: Colors.white),
                        SizedBox(height: 4),
                        Text('Image absente', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.word.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.word.theme,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
