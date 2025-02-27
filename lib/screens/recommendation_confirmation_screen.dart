import 'package:flutter/material.dart';
import 'package:songsurf/screens/recommendation_received_screen.dart';
import 'package:songsurf/screens/home_screen.dart';
import 'package:songsurf/services/supabase_service.dart';
import 'package:songsurf/widgets/animated_background.dart';
import 'package:songsurf/widgets/wide_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecommendationConfirmationScreen extends StatefulWidget {
  final String name;
  final String userId;
  final Map<String, dynamic> song;

  const RecommendationConfirmationScreen({
    super.key,
    required this.name,
    required this.userId,
    required this.song,
  });

  @override
  State<RecommendationConfirmationScreen> createState() =>
      _RecommendationConfirmationScreenState();
}

class _RecommendationConfirmationScreenState
    extends State<RecommendationConfirmationScreen>
    with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Validate song data
      if (widget.song['id'] == null || 
          widget.song['name'] == null || 
          widget.song['artist'] == null) {
        throw Exception('Invalid song data: missing required fields');
      }

      print('Creating recommendation with song data:');
      print('ID: ${widget.song['id']}');
      print('Name: ${widget.song['name']}');
      print('Artist: ${widget.song['artist']}');
      print('User ID: ${widget.userId}');
      
      if (widget.userId == null || widget.userId.isEmpty) {
        throw Exception('Invalid user ID: ${widget.userId}');
      }
      
      try {
        // Create the recommendation
        final recommendation = await _supabaseService.createRecommendation(
          senderId: widget.userId,
          songId: widget.song['id'].toString(),
          songName: widget.song['name'].toString(),
          artistName: widget.song['artist'].toString(),
          albumArt: widget.song['albumArt']?.toString(),
        );
        print('Recommendation created successfully: ${recommendation.id}');
      } catch (e, stackTrace) {
        print('Error creating recommendation:');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }

      print('Updating last recommendation time...');
      // Update user's last recommendation time
      await _supabaseService.updateLastRecommendationTime(widget.userId);
      print('Last recommendation time updated');

      print('Getting random pending recommendation...');
      // Get a random pending recommendation
      final receivedRecommendation =
          await _supabaseService.getRandomPendingRecommendation(widget.userId);
      print('Random pending recommendation result: ${receivedRecommendation?.id ?? 'none found'}');

      if (!mounted) return;

      if (receivedRecommendation != null) {
        print('Matching recommendation...');
        // Match the received recommendation
        final matchSuccess = await _supabaseService.matchRecommendation(
          receivedRecommendation.id,
          widget.userId,
        );
        print('Match result: ${matchSuccess ? 'success' : 'failed'}');

        if (!matchSuccess) {
          print('Match failed, showing error');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to match recommendation. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        print('Starting reverse animation...');
        // Animate out and navigate to received screen
        await _controller.reverse();

        if (!mounted) return;

        print('Navigating to received screen...');
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RecommendationReceivedScreen(
              name: widget.name,
              userId: widget.userId,
              recommendation: receivedRecommendation,
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
      } else {
        print('No matching recommendation found');
        // No matching recommendation found, show feedback and navigate to home
        await _controller.reverse();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recommendation sent! No matching recommendations found yet.'),
            duration: Duration(seconds: 3),
          ),
        );

        print('Navigating to home screen...');
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomeScreen(
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
    } catch (e) {
      print('Error in confirmation flow: ${e.toString()}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  'Confirm your\nrecommendation',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const Spacer(),
                Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: widget.song['albumArt'],
                                  width: 280,
                                  height: 280,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                widget.song['name'],
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
                                widget.song['artist'],
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
                      );
                    },
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: WideButton(
                    text: 'Confirm',
                    onPressed: _confirm,
                    isLoading: _isLoading,
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