import 'package:flutter/material.dart';
import 'dart:math' as math;

class MeshGradientBackground extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Widget child;

  const MeshGradientBackground({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.child,
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshPainter(
            animationValue: _controller.value,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  _MeshPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Dynamic blobs
    void drawBlob(double xFactor, double yFactor, double sizeFactor, Color color, double speed) {
      final x = size.width * (xFactor + 0.2 * math.sin(animationValue * 2 * math.pi * speed));
      final y = size.height * (yFactor + 0.2 * math.cos(animationValue * 2 * math.pi * speed));
      final radius = size.width * sizeFactor;
      
      canvas.drawCircle(Offset(x, y), radius, paint..color = color.withValues(alpha: 0.3));
    }

    // Background base
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = primaryColor.withValues(alpha: 0.05));

    // Blobs
    drawBlob(0.2, 0.2, 0.6, secondaryColor, 0.5);
    drawBlob(0.8, 0.8, 0.5, primaryColor, 0.3);
    drawBlob(0.5, 0.5, 0.4, secondaryColor.withAlpha(100), 0.7);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue || 
      oldDelegate.primaryColor != primaryColor;
}
