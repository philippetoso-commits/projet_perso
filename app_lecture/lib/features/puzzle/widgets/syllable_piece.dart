import 'package:flutter/material.dart';

/// Une pièce syllabe du puzzle — tap pour sélectionner / désélectionner.
class SyllablePiece extends StatefulWidget {
  final String text;
  final Color color;
  final bool isSelected;
  final bool isPlaced;
  final VoidCallback? onTap;

  const SyllablePiece({
    super.key,
    required this.text,
    required this.color,
    this.isSelected = false,
    this.isPlaced = false,
    this.onTap,
  });

  @override
  State<SyllablePiece> createState() => _SyllablePieceState();
}

class _SyllablePieceState extends State<SyllablePiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isPlaced && widget.onTap != null;
    return GestureDetector(
      onTapDown: isInteractive ? _onTapDown : null,
      onTapUp: isInteractive ? _onTapUp : null,
      onTapCancel: isInteractive ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isPlaced
                ? widget.color.withValues(alpha: 0.35)
                : widget.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white
                  : widget.color.withValues(alpha: 0.0),
              width: widget.isSelected ? 3 : 0,
            ),
            boxShadow: widget.isPlaced
                ? []
                : [
                    BoxShadow(
                      color: widget.isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : widget.color.withValues(alpha: 0.45),
                      blurRadius: widget.isSelected ? 14 : 8,
                      spreadRadius: widget.isSelected ? 3 : 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.isPlaced ? Colors.grey : Colors.white,
              letterSpacing: 1.2,
              shadows: widget.isPlaced
                  ? []
                  : const [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}
