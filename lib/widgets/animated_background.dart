import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
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
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BackgroundPainter(
                animation: _controller,
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: widget.child,
        ),
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _BackgroundPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.4;

    for (var i = 0; i < 3; i++) {
      final angle = (animation.value * 2 * 3.14159) + (i * 2.0944);
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        size.width * 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 