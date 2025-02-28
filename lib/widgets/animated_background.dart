import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;
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

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();
  
  // Touch interaction variables
  Offset _touchPoint = Offset.zero;
  bool _isTouching = false;
  
  // Motion variables
  double _motionX = 0.0;
  double _motionY = 0.0;
  AccelerometerEvent? _accelerometerEvent;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    
    // Create multiple animation controllers for different elements
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(seconds: 10 + index * 5), // Different durations
        vsync: this,
      )..repeat(reverse: index % 2 == 0), // Some reverse, some don't
    );
    
    // Create animations with different curves
    _animations = [
      _controllers[0].drive(CurveTween(curve: Curves.easeInOut)),
      _controllers[1].drive(CurveTween(curve: Curves.easeInOutCubic)),
      _controllers[2].drive(CurveTween(curve: Curves.slowMiddle)),
      _controllers[3].drive(CurveTween(curve: Curves.easeInOutSine)),
    ];
    
    // Adjust speed
    for (var controller in _controllers) {
      controller.value = _random.nextDouble(); // Start from random positions
      controller.duration = Duration(seconds: (controller.duration!.inSeconds / widget.speed).round());
    }
    
    // Initialize motion detection if enabled
    if (widget.respondToMotion) {
      _initAccelerometer();
    }
  }
  
  void _initAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelerometerEvent = event;
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
    for (var controller in _controllers) {
      controller.dispose();
    }
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
          AnimatedBuilder(
            animation: Listenable.merge(_controllers),
            builder: (context, child) {
              return CustomPaint(
                painter: PsychedelicPainter(
                  animation1: _animations[0].value,
                  animation2: _animations[1].value,
                  animation3: _animations[2].value,
                  animation4: _animations[3].value,
                  touchPoint: _touchPoint,
                  isTouching: _isTouching,
                  motionX: _motionX,
                  motionY: _motionY,
                ),
                isComplex: true,
                willChange: true,
                child: const SizedBox.expand(),
              );
            },
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

class PsychedelicPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final double animation4;
  final Offset touchPoint;
  final bool isTouching;
  final double motionX;
  final double motionY;
  
  PsychedelicPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.animation4,
    this.touchPoint = Offset.zero,
    this.isTouching = false,
    this.motionX = 0.0,
    this.motionY = 0.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Create a list of color schemes for the psychedelic effect
    final List<List<Color>> colorSchemes = [
      [Color(0xFFFF00CC), Color(0xFF3333FF), Color(0xFFFF9900)],
      [Color(0xFF00FFCC), Color(0xFFFF00FF), Color(0xFFFFFF00)],
      [Color(0xFF6600FF), Color(0xFF00FFFF), Color(0xFFFF0066)],
      [Color(0xFFFF6600), Color(0xFF00FF66), Color(0xFF6600FF)],
    ];
    
    // Choose colors based on animation values - make color transitions more dynamic
    final colorIndex1 = (animation3 * colorSchemes.length).floor() % colorSchemes.length;
    final colorIndex2 = (colorIndex1 + 1) % colorSchemes.length;
    final colorBlend = animation3 * colorSchemes.length - colorIndex1.toDouble();
    
    // Blend between two color schemes for smoother transitions
    final colors = [
      Color.lerp(colorSchemes[colorIndex1][0], colorSchemes[colorIndex2][0], colorBlend)!,
      Color.lerp(colorSchemes[colorIndex1][1], colorSchemes[colorIndex2][1], colorBlend)!,
      Color.lerp(colorSchemes[colorIndex1][2], colorSchemes[colorIndex2][2], colorBlend)!,
    ];
    
    // Apply motion tilt to the gradient alignment
    final motionOffsetX = motionX;
    final motionOffsetY = motionY;
    
    // Make the background gradient more dynamic even when static
    final animatedGradientOffset = sin(animation1 * pi * 2) * 0.3;
    
    // Base gradient background
    final rect = Rect.fromLTWH(0, 0, width, height);
    final backgroundGradient = LinearGradient(
      begin: Alignment(-1 + animation1 * 2 + motionOffsetX + animatedGradientOffset, 
                     -1 + animation2 * 2 + motionOffsetY + animatedGradientOffset),
      end: Alignment(animation1 + motionOffsetX - animatedGradientOffset, 
                   animation2 + motionOffsetY - animatedGradientOffset),
      colors: [
        colors[0],
        colors[1],
      ],
    );
    
    final paint = Paint()
      ..shader = backgroundGradient.createShader(rect)
      ..style = PaintingStyle.fill;
      
    canvas.drawRect(rect, paint);
    
    // Calculate touch influence (ripple effect)
    double touchInfluence = 0.0;
    double touchDistanceNormalized = 0.0;
    
    if (isTouching) {
      // Create a ripple effect from the touch point
      touchInfluence = 1.0;
      // Normalize touch position to 0-1 range
      final normalizedTouchX = touchPoint.dx / width;
      final normalizedTouchY = touchPoint.dy / height;
      touchDistanceNormalized = sqrt(pow(normalizedTouchX - 0.5, 2) + pow(normalizedTouchY - 0.5, 2)) * 2;
    }
    
    // Draw animated blob circles with enhanced movement
    for (int i = 0; i < 5; i++) {
      final blobAnimation = (animation1 + i * 0.2) % 1.0;
      
      // Apply touch and motion influence to blob size and position
      final touchSizeBoost = isTouching ? sin(touchDistanceNormalized * pi) * 0.2 : 0.0;
      final motionSizeEffect = (motionX.abs() + motionY.abs()) * 0.1;
      
      // Enhanced pulsing effect even when static
      final staticPulse = sin(animation4 * pi * 2 + i) * 0.15;
      
      final size = width * 0.4 + 
                  width * 0.3 * sin(blobAnimation * 2 * pi) + 
                  width * touchSizeBoost +
                  width * motionSizeEffect +
                  width * staticPulse; // Add static pulse
                  
      // Enhance movement when static
      final staticMovementX = cos(animation2 * pi * 2 + i * 0.7) * width * 0.1;
      final staticMovementY = sin(animation3 * pi * 2 + i * 0.7) * height * 0.1;
                  
      // Adjust position based on device tilt
      final x = width * 0.5 + 
               width * 0.5 * cos(animation2 * 2 * pi + i) * (i % 2 == 0 ? 1 : -1) +
               width * motionX * 0.3 +
               staticMovementX; // Add static movement
               
      final y = height * 0.5 + 
               height * 0.4 * sin(animation3 * 2 * pi + i) +
               height * motionY * 0.3 +
               staticMovementY; // Add static movement
      
      // If touching, make the blob closest to touch point pulse
      final distToTouch = isTouching ? 
          sqrt(pow(x - touchPoint.dx, 2) + pow(y - touchPoint.dy, 2)) / (width * 0.5) : 
          1.0;
      
      final touchPulseEffect = isTouching && distToTouch < 0.5 ? 
          sin(animation4 * 10 * pi) * (1.0 - distToTouch) * width * 0.1 : 
          0.0;
      
      // More dynamic gradient center for blobs
      final dynamicCenter = Alignment(
        0.5 + cos(animation4 * pi * 1.5) * 0.5, 
        0.5 + sin(animation2 * pi * 1.5) * 0.5
      );
      
      final blobGradient = RadialGradient(
        center: dynamicCenter,
        radius: 1.0 + sin(animation1 * pi) * 0.2, // Animate radius too
        colors: [
          colors[i % colors.length].withOpacity(0.6 + (isTouching && distToTouch < 0.3 ? 0.2 : 0.0) + staticPulse * 0.3),
          colors[(i + 1) % colors.length].withOpacity(0.0),
        ],
        stops: [0.2, 1.0],
      );
      
      paint.shader = blobGradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: size + touchPulseEffect),
      );
      
      canvas.drawCircle(Offset(x, y), size + touchPulseEffect, paint);
    }
    
    // Draw animated wavy lines with enhanced movement
    for (int i = 0; i < 3; i++) {
      final path = Path();
      
      // Apply motion and touch to wave properties
      final touchWaveEffect = isTouching ? sin(animation1 * 8 * pi) * 0.02 : 0.0;
      final motionWaveEffect = (motionX.abs() + motionY.abs()) * 0.02;
      
      // Enhanced wave animation when static
      final staticWaveEffect = sin(animation4 * pi * (i + 1) * 0.5) * 0.03;
      
      final waveHeight = height * (0.05 + touchWaveEffect + motionWaveEffect + staticWaveEffect) + 
                        height * 0.03 * sin(animation2 * pi);
                        
      final waveLength = width / (3 + i + sin(animation1 * pi) * 0.5); // Animate wavelength
      
      // More dynamic wave position
      final staticYOffset = height * 0.1 * sin(animation4 * pi * (i + 1) * 0.7);
      
      final yOffset = height * (0.3 + i * 0.2) + 
                     height * 0.1 * sin(animation3 * 2 * pi + i) +
                     height * motionY * 0.2 +
                     staticYOffset;
      
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2 + i * 2.0;
      
      // Animate wave color opacity
      final waveOpacity = 0.7 + sin(animation2 * pi * 2) * 0.2;
      paint.color = colors[i % colors.length].withOpacity(waveOpacity);
      paint.shader = null;
      
      path.moveTo(0, yOffset);
      
      // More detailed wave with more points for smoother animation
      final step = width / 200; // More points for smoother curves
      
      for (double x = 0; x <= width; x += step) {
        final normalizedX = x / width;
        final animatedPhase = (animation1 + animation4) * 2 * pi;
        
        // Add touch-based distortion to waves
        double touchDistortion = 0.0;
        if (isTouching) {
          final distToTouchX = (x - touchPoint.dx).abs() / width;
          if (distToTouchX < 0.2) {
            touchDistortion = sin(distToTouchX * pi * 5) * (0.2 - distToTouchX) * height * 0.2;
          }
        }
        
        // Add secondary wave component for more complex movement
        final secondaryWave = sin((normalizedX * 4 * pi) + animation2 * pi) * waveHeight * 0.3;
        
        final y = yOffset + 
                sin((normalizedX * 2 * pi * (width / waveLength)) + animatedPhase) * waveHeight + 
                secondaryWave +
                touchDistortion;
                
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
    
    // Draw swirls with enhanced movement
    final swirlCenter = Offset(
      width * (0.5 + 0.3 * cos(animation2 * 2 * pi) + motionX * 0.2),
      height * (0.5 + 0.4 * sin(animation3 * 2 * pi) + motionY * 0.2)
    );
    
    // If touching, move one swirl toward touch point
    final touchSwirlCenter = isTouching ? 
        Offset.lerp(swirlCenter, touchPoint, 0.3)! : 
        swirlCenter;
    
    for (int i = 0; i < 4; i++) {
      final swirlPath = Path();
      
      // More dynamic starting angle for continuous rotation
      final startAngle = animation1 * 4 * pi + i * (pi / 2);
      
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3 - i * 0.5;
      
      // Make swirls more vibrant when touching
      final touchOpacityBoost = isTouching ? 0.2 : 0.0;
      
      // Animate swirl opacity for pulsing effect
      final staticOpacityPulse = sin(animation4 * pi * 2 + i) * 0.15;
      
      paint.color = colors[i % colors.length].withOpacity(0.6 + touchOpacityBoost + staticOpacityPulse);
      
      // Use touch point for the first swirl when touching
      final currentSwirlCenter = (i == 0 && isTouching) ? touchSwirlCenter : swirlCenter;
      
      // Add motion influence to swirl density
      final motionSwirlDensity = 0.1 + (motionX.abs() + motionY.abs()) * 0.05;
      
      // Enhanced swirl density animation when static
      final staticSwirlDensity = 0.1 + sin(animation3 * pi * 2 + i) * 0.05;
      
      // More detailed swirl with smaller angle steps for smoother curves
      final angleStep = 0.05;
      
      for (double angle = startAngle; angle <= startAngle + 2 * pi; angle += angleStep) {
        final radius = min(width, height) * (0.1 + 0.05 * i + motionSwirlDensity + staticSwirlDensity) * 
                      (1 + 0.5 * angle / (2 * pi));
                      
        // Add wobble effect to swirls
        final wobble = sin(angle * 3 + animation2 * pi * 4) * radius * 0.05;
        
        final x = currentSwirlCenter.dx + (radius + wobble) * cos(angle);
        final y = currentSwirlCenter.dy + (radius + wobble) * sin(angle);
        
        if (angle == startAngle) {
          swirlPath.moveTo(x, y);
        } else {
          swirlPath.lineTo(x, y);
        }
      }
      
      canvas.drawPath(swirlPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PsychedelicPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2 ||
        oldDelegate.animation3 != animation3 ||
        oldDelegate.animation4 != animation4 ||
        oldDelegate.touchPoint != touchPoint ||
        oldDelegate.isTouching != isTouching ||
        oldDelegate.motionX != motionX ||
        oldDelegate.motionY != motionY;
  }
} 