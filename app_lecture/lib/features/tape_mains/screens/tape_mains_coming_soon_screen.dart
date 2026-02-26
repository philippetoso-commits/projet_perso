import 'package:flutter/material.dart';
import '../../../widgets/coming_soon_screen.dart';

class TapeMainsComingSoonScreen extends StatelessWidget {
  const TapeMainsComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonScreen(
        title: 'Tape dans les Mains',
        icon: Icons.back_hand_rounded,
        gradientColors: [Color(0xFFD81B60), Color(0xFF880E4F)],
        iconBgColor: Color(0xFFE91E63),
        description:
            'Bats le rythme des syllabes en tapant dans tes mains !',
      );
}
