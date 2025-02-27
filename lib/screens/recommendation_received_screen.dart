import 'package:flutter/material.dart';
import 'package:songsurf/models/recommendation_model.dart';
import 'package:songsurf/screens/home_screen.dart';
import 'package:songsurf/services/spotify_service.dart';
import 'package:songsurf/widgets/animated_background.dart';
import 'package:songsurf/widgets/wide_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecommendationReceivedScreen extends StatefulWidget {
  final String name;
  final String userId;
  final RecommendationModel recommendation;

  const RecommendationReceivedScreen({
    super.key,
    required this.name,
    required this.userId,
    required this.recommendation,
  });

  @override
  State<RecommendationReceivedScreen> createState() =>
      _RecommendationReceivedScreenState();
}

class _RecommendationReceivedScreenState
    extends State<RecommendationReceivedScreen>
    with SingleTickerProviderStateMixin {
  final _spotifyService = SpotifyService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playSong() async {
    try {
      await _spotifyService.openSpotifyTrack(widget.recommendation.songId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          name: widget.name,
          userId: widget.userId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'You received a\nrecommendation! 🎉',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const Spacer(),
                Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Opacity(
                            opacity: _opacityAnimation.value,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://i.scdn.co/image/${widget.recommendation.songId}',
                                    width: 280,
                                    height: 280,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  widget.recommendation.songName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.recommendation.artistName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.7),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    children: [
                      WideButton(
                        text: 'Play on Spotify',
                        onPressed: _playSong,
                      ),
                      const SizedBox(height: 16),
                      WideButton(
                        text: 'Go to Home',
                        onPressed: _goToHome,
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 