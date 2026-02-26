import 'package:flutter/material.dart';

class ClappingHandsWidget extends StatefulWidget {
  final int index;
  const ClappingHandsWidget({Key? key, required this.index}) : super(key: key);

  @override
  _ClappingHandsWidgetState createState() => _ClappingHandsWidgetState();
}

class _ClappingHandsWidgetState extends State<ClappingHandsWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 300),
    );

    // Initial pop-in scale
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    // Slight rotation to give it a "clapping" feel
    _rotationAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: -0.2, end: 0.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
             angle: _rotationAnimation.value,
             child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))
                  ]
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.front_hand, color: Color(0xFFF57C00), size: 30),
                      Text("${widget.index}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                ),
             ),
          ),
        );
      },
    );
  }
}
