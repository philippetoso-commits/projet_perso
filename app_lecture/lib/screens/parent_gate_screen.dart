import 'dart:math';
import 'package:flutter/material.dart';

/// Accès sécurisé : question mathématique simple pour éviter que l'enfant ouvre l'espace parents.
class ParentGateScreen extends StatefulWidget {
  final Widget childOnSuccess;

  const ParentGateScreen({
    super.key,
    required this.childOnSuccess,
  });

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  final _controller = TextEditingController();
  late int _a;
  late int _b;
  late int _expected;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    final rnd = Random();
    _a = 2 + rnd.nextInt(8);
    _b = 2 + rnd.nextInt(8);
    _expected = _a + _b;
  }

  void _validate() {
    final text = _controller.text.trim();
    final value = int.tryParse(text);
    setState(() {
      _error = null;
      if (value == _expected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => widget.childOnSuccess,
          ),
        );
      } else {
        _error = 'Réponse incorrecte. Réessaie.';
        _generateQuestion();
        _controller.clear();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFF006064)),
                const SizedBox(height: 16),
                const Text(
                  'Espace Parents',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006064),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_a + $_b = ?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006064),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Réponse',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _validate(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _validate,
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006064),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
