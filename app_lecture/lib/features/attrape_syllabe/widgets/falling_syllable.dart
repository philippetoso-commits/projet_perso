import 'package:flutter/material.dart';

class FallingSyllableWidget extends StatefulWidget {
  final String text;
  final bool isTarget;
  final bool isSecondChance;
  final bool isFallingAllowed;
  final double screenHeight;
  final double screenWidth;
  final double startX;
  final double startYOffset;
  final Color bubbleColor;
  final Duration fallDuration;
  final VoidCallback onTap;
  final VoidCallback onGroundReached;

  const FallingSyllableWidget({
    Key? key,
    required this.text,
    required this.isTarget,
    required this.isSecondChance,
    required this.isFallingAllowed,
    required this.screenHeight,
    required this.screenWidth,
    required this.startX,
    required this.startYOffset,
    required this.bubbleColor,
    required this.fallDuration,
    required this.onTap,
    required this.onGroundReached,
  }) : super(key: key);

  @override
  _FallingSyllableWidgetState createState() => _FallingSyllableWidgetState();
}

class _FallingSyllableWidgetState extends State<FallingSyllableWidget> with TickerProviderStateMixin {
  late AnimationController _fallController;
  late Animation<double> _fallAnimation;

  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    _fallController = AnimationController(
      vsync: this,
      duration: widget.fallDuration, // Variable speed based on level
    );

    // From startYOffset (above the screen) down to the bottom
    _fallAnimation = Tween<double>(begin: widget.startYOffset, end: widget.screenHeight).animate(
      CurvedAnimation(parent: _fallController, curve: Curves.linear),
    );

    if (widget.isFallingAllowed) {
       _fallController.forward();
    }
    
    _fallController.addListener(() {
      // If we reach the bottom, we count it as "hitting the ground"
      if (_fallAnimation.value >= widget.screenHeight - 100 && !_hitGround) {
        _hitGround = true;
        widget.onGroundReached();
      }
    });

    _blinkController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 400),
    );
    if (widget.isTarget && widget.isSecondChance) {
        _blinkController.repeat(reverse: true);
    }
  }

  bool _hitGround = false;

  @override
  void didUpdateWidget(FallingSyllableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTarget && widget.isSecondChance && !oldWidget.isSecondChance) {
        _blinkController.repeat(reverse: true);
    }
    
    if (widget.isFallingAllowed && !oldWidget.isFallingAllowed) {
       _fallController.forward();
    }
  }

  @override
  void dispose() {
    _fallController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // If the widget is tapped, stop falling (maybe explode/disappear in game logic)
    // The parent will handle the game logic (removing it from list, adding points)
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fallAnimation,
      builder: (context, child) {
        return Positioned(
          left: widget.startX,
          top: _fallAnimation.value,
          child: GestureDetector(
            onTap: _handleTap,
            child: widget.isTarget && widget.isSecondChance 
                ? FadeTransition(
                    opacity: Tween(begin: 0.3, end: 1.0).animate(_blinkController),
                    child: _buildBubble(),
                  )
                : _buildBubble(),
          ),
        );
      },
    );
  }

  Widget _buildBubble() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: widget.bubbleColor,
        shape: BoxShape.circle,
        border: Border.all(
          // For blinking target, maybe give it a bright border.
          color: (widget.isTarget && widget.isSecondChance) ? Colors.amberAccent : Colors.white60,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Center(
        child: Text(
          widget.text,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // High contrast
          ),
        ),
      ),
    );
  }
}
