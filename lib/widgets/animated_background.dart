import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final double speed;
  final bool respondToTouch;
  final bool respondToMotion;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.speed = 0.5,
    this.respondToTouch = true,
    this.respondToMotion = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
  // Animation variables
  double _time = 0.0;
  Timer? _timer;
  final Random _random = Random();
  
  // Touch interaction variables
  Offset _touchPoint = Offset.zero;
  bool _isTouching = false;
  
  // Motion variables
  double _motionX = 0.0;
  double _motionY = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    
    // Start a timer to drive the animation at 60fps
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        setState(() {
          // Increment time for animation
          _time += 0.016 * widget.speed * 2; // Multiply by speed factor
        });
      }
    });
    
    // Initialize motion detection if enabled
    if (widget.respondToMotion) {
      _initAccelerometer();
    }
  }
  
  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Apply some smoothing and scaling to the motion values
          _motionX = _motionX * 0.8 + (event.x * 0.01) * 0.2;
          _motionY = _motionY * 0.8 + (event.y * 0.01) * 0.2;
          // Clamp values to prevent extreme tilting effects
          _motionX = _motionX.clamp(-0.3, 0.3);
          _motionY = _motionY.clamp(-0.3, 0.3);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: widget.respondToTouch ? _handlePanStart : null,
      onPanUpdate: widget.respondToTouch ? _handlePanUpdate : null,
      onPanEnd: widget.respondToTouch ? _handlePanEnd : null,
      child: Stack(
        children: [
          CustomPaint(
            painter: BasicAnimationPainter(
              time: _time,
              touchPoint: _touchPoint,
              isTouching: _isTouching,
              motionX: _motionX,
              motionY: _motionY,
            ),
            size: Size.infinite,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: widget.child,
          ),
        ],
      ),
    );
  }
  
  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _touchPoint = details.localPosition;
      _isTouching = true;
    });
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _touchPoint = details.localPosition;
    });
  }
  
  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isTouching = false;
    });
  }
}

class BasicAnimationPainter extends CustomPainter {
  final double time;
  final Offset touchPoint;
  final bool isTouching;
  final double motionX;
  final double motionY;
  
  BasicAnimationPainter({
    required this.time,
    this.touchPoint = Offset.zero,
    this.isTouching = false,
    this.motionX = 0.0,
    this.motionY = 0.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Define colors
    final colors = [
      const Color(0xFFFF00CC),
      const Color(0xFF3333FF),
      const Color(0xFFFF9900),
      const Color(0xFF00FFCC),
      const Color(0xFFFF00FF),
      const Color(0xFFFFFF00),
    ];
    
    // Draw background
    final bgColor = Color.lerp(
      colors[0].withOpacity(0.3),
      colors[1].withOpacity(0.3),
      (sin(time) + 1) / 2
    )!;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = bgColor
    );
    
    // Draw animated circles
    for (int i = 0; i < 5; i++) {
      final phase = i * 0.2;
      final color = colors[i % colors.length].withOpacity(0.7);
      
      // Calculate position with continuous movement
      final x = width * 0.5 + 
               width * 0.3 * cos(time * 2 + phase * 10) + 
               width * motionX * 0.3;
               
      final y = height * 0.5 + 
               height * 0.3 * sin(time * 1.5 + phase * 8) + 
               height * motionY * 0.3;
      
      // Calculate size with pulsing effect
      final baseSize = width * 0.15;
      final pulseAmount = width * 0.05 * sin(time * 3 + phase * 15);
      final size = baseSize + pulseAmount;
      
      // Draw the circle
      canvas.drawCircle(
        Offset(x, y),
        size,
        Paint()..color = color
      );
    }
    
    // Draw animated waves
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveColor = colors[(i + 2) % colors.length].withOpacity(0.7);
      
      final yBase = height * (0.3 + i * 0.2);
      final amplitude = height * 0.05;
      
      path.moveTo(0, yBase);
      
      for (double x = 0; x <= width; x += width / 100) {
        final normalizedX = x / width;
        
        // Create wave pattern with multiple frequencies
        final y = yBase + 
                amplitude * sin(normalizedX * 10 + time * 3) + 
                amplitude * 0.5 * sin(normalizedX * 20 + time * 2);
                
        path.lineTo(x, y);
      }
      
      canvas.drawPath(
        path,
        Paint()
          ..color = waveColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + i * 2.0
      );
    }
    
    // Draw swirls
    final swirlCenter = Offset(
      width * 0.5 + width * 0.2 * cos(time),
      height * 0.5 + height * 0.2 * sin(time * 1.3)
    );
    
    for (int i = 0; i < 3; i++) {
      final swirlPath = Path();
      final swirlColor = colors[(i + 4) % colors.length].withOpacity(0.7);
      
      final startAngle = time * 3 + i * (pi / 1.5);
      final spiralFactor = 0.2 + i * 0.05;
      
      swirlPath.moveTo(swirlCenter.dx, swirlCenter.dy);
      
      for (double angle = 0; angle <= pi * 4; angle += 0.1) {
        final radius = angle * min(width, height) * spiralFactor;
        final x = swirlCenter.dx + radius * cos(angle + startAngle);
        final y = swirlCenter.dy + radius * sin(angle + startAngle);
        
        swirlPath.lineTo(x, y);
      }
      
      canvas.drawPath(
        swirlPath,
        Paint()
          ..color = swirlColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 - i * 0.5
      );
    }
    
    // Add touch effects if touching
    if (isTouching) {
      // Draw touch ripple
      for (int i = 0; i < 3; i++) {
        final rippleRadius = (time * 100) % 150 + i * 50;
        final opacity = 1.0 - (rippleRadius / 300);
        
        if (opacity > 0) {
          canvas.drawCircle(
            touchPoint,
            rippleRadius,
            Paint()
              ..color = colors[i].withOpacity(opacity * 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
          );
        }
      }
      
      // Draw touch point
      canvas.drawCircle(
        touchPoint,
        20,
        Paint()..color = Colors.white.withOpacity(0.5)
      );
    }
  }

  @override
  bool shouldRepaint(covariant BasicAnimationPainter oldDelegate) {
    return true; // Always repaint
  }
} 