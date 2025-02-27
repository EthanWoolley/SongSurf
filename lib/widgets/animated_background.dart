import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final int _numBlobs = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _numBlobs,
      (index) => AnimationController(
        duration: Duration(seconds: 10 + index * 2),
        vsync: this,
      )..repeat(),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
            Colors.cyan.withOpacity(0.3),
          ]
        : [
            Colors.blue.withOpacity(0.2),
            Colors.purple.withOpacity(0.2),
            Colors.cyan.withOpacity(0.2),
          ];

    return Stack(
      children: [
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        ...List.generate(_numBlobs, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Positioned(
                left: math.sin(_animations[index].value * 2 * math.pi) * 100 +
                    MediaQuery.of(context).size.width / 2,
                top: math.cos(_animations[index].value * 2 * math.pi) * 100 +
                    MediaQuery.of(context).size.height / 2,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[index],
                  ),
                ),
              );
            },
          );
        }),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            child: widget.child,
          ),
        ),
      ],
    );
  }
} 