import 'package:flutter/material.dart';
import '../../../widgets/coming_soon_screen.dart';

class AttrapeSyllabeComingSoonScreen extends StatelessWidget {
  const AttrapeSyllabeComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Attrape Syllabe',
        icon: Icons.music_note_rounded,
        gradientColors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        iconBgColor: Color(0xFF388E3C),
        description:
            'Attrape la bonne syllabe au bon moment pour composer des mots !',
      );
}
