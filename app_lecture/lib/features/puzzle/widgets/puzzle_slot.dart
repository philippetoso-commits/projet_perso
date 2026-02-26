import 'package:flutter/material.dart';

/// Un slot vide (ou rempli) dans la zone de réponse du puzzle.
class PuzzleSlot extends StatefulWidget {
  final String? content;
  final Color color;
  final bool isCorrect;
  final bool doShake;
  final VoidCallback? onTap;

  const PuzzleSlot({
    super.key,
    this.content,
    required this.color,
    this.isCorrect = false,
    this.doShake = false,
    this.onTap,
  });

  @override
  State<PuzzleSlot> createState() => _PuzzleSlotState();
}

class _PuzzleSlotState extends State<PuzzleSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _snapAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(PuzzleSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.doShake && !oldWidget.doShake) {
      _shakeCtrl.forward(from: 0);
    }
    if (widget.content != null && oldWidget.content == null) {
      // snap animation quand une pièce se place
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.content == null;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (_, child) {
          final offset = widget.doShake ? _shakeAnim.value : 0.0;
          final scale = (widget.content != null && !widget.doShake)
              ? 1.0
              : _snapAnim.value;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: isEmpty
                ? Colors.grey.shade100
                : widget.isCorrect
                    ? widget.color.withValues(alpha: 0.9)
                    : widget.color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEmpty
                  ? Colors.grey.shade300
                  : widget.isCorrect
                      ? Colors.green.shade400
                      : widget.color,
              width: isEmpty ? 2 : 2.5,
              style: isEmpty ? BorderStyle.solid : BorderStyle.solid,
            ),
            boxShadow: isEmpty
                ? []
                : [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Center(
            child: isEmpty
                ? Icon(Icons.add_rounded,
                    color: Colors.grey.shade400, size: 24)
                : Text(
                    widget.content!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
