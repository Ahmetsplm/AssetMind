import 'package:flutter/material.dart';

class AnimatedPriceWidget extends StatefulWidget {
  final double numericValue;
  final String displayString; // Pre-formatted string
  final TextStyle style;

  const AnimatedPriceWidget({
    super.key,
    required this.numericValue,
    required this.displayString,
    required this.style,
  });

  @override
  State<AnimatedPriceWidget> createState() => _AnimatedPriceWidgetState();
}

class _AnimatedPriceWidgetState extends State<AnimatedPriceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent, // Initial state
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedPriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.numericValue != oldWidget.numericValue) {
      if (widget.numericValue > (oldWidget.numericValue)) {
        _animateColor(Colors.green);
      } else if (widget.numericValue < (oldWidget.numericValue)) {
        _animateColor(Colors.red);
      }
    }
  }

  void _animateColor(Color color) {
    _colorAnimation = ColorTween(
      begin: color,
      end: widget.style.color,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format value? The widget should probably accept Display String to be safe.
    // I'll update constructor to take `displayString` and `numericValue`.
    // Wait, let me re-write this class properly.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          widget.displayString,
          style: widget.style.copyWith(
            color: _controller.isAnimating
                ? _colorAnimation.value
                : widget.style.color,
          ),
        );
      },
    );
  }
}
