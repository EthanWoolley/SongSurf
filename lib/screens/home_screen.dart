import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:songsurf/models/recommendation_model.dart';
import 'package:songsurf/screens/song_selection_screen.dart';
import 'package:songsurf/services/spotify_service.dart';
import 'package:songsurf/services/supabase_service.dart';
import 'package:songsurf/widgets/animated_background.dart';
import 'package:songsurf/widgets/countdown_timer.dart';
import 'package:songsurf/widgets/wide_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  final String name;
  final String userId;

  const HomeScreen({
    super.key,
    required this.name,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabaseService = SupabaseService();
  final _spotifyService = SpotifyService();
  List<RecommendationModel> _recommendations = [];
  DateTime? _lastRecommendationTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _supabaseService.getUser(widget.userId);
      final recommendations = await _supabaseService.getUserRecommendations(widget.userId);

      if (mounted) {
        setState(() {
          _lastRecommendationTime = user?.lastRecommendationTime;
          _recommendations = recommendations;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToSongSelection() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SongSelectionScreen(
          name: widget.name,
          userId: widget.userId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildRecommendationPair(RecommendationModel sent, RecommendationModel received) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        children: [
          Expanded(
            child: _buildRecommendationCard(sent, isSent: true),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildRecommendationCard(received, isSent: false),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationModel recommendation, {required bool isSent}) {
    return GestureDetector(
      onTap: () => _spotifyService.openSpotifyTrack(recommendation.songId),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: 'https://i.scdn.co/image/${recommendation.songId}',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.songName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.artistName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSent ? '→ Sent' : '← Received',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group recommendations by date
    final recommendationsByDate = <DateTime, List<RecommendationModel>>{};
    for (final recommendation in _recommendations) {
      final date = DateTime(
        recommendation.createdAt.year,
        recommendation.createdAt.month,
        recommendation.createdAt.day,
      );
      recommendationsByDate.putIfAbsent(date, () => []).add(recommendation);
    }

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,\n${widget.name}! 👋',
                                style: Theme.of(context).textTheme.displayLarge,
                              ),
                              const SizedBox(height: 24),
                              CountdownTimer(
                                lastRecommendationTime: _lastRecommendationTime,
                              ),
                              const SizedBox(height: 16),
                              WideButton(
                                text: 'Recommend a Song',
                                onPressed: _lastRecommendationTime == null ||
                                        DateTime.now().difference(_lastRecommendationTime!) >
                                            const Duration(hours: 24)
                                    ? _navigateToSongSelection
                                    : null,
                              ),
                              const SizedBox(height: 48),
                              Text(
                                'Your Recommendations',
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final date = recommendationsByDate.keys.toList()
                                ..sort((a, b) => b.compareTo(a))[index];
                              final recommendations = recommendationsByDate[date]!;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Text(
                                      DateFormat('MMMM d, y').format(date),
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  ...recommendations
                                      .where((r) => r.status == RecommendationStatus.matched)
                                      .map((sent) {
                                    final received = recommendations.firstWhere(
                                      (r) =>
                                          r.status == RecommendationStatus.matched &&
                                          r != sent,
                                      orElse: () => sent,
                                    );
                                    return _buildRecommendationPair(sent, received);
                                  }).toList(),
                                ],
                              );
                            },
                            childCount: recommendationsByDate.length,
                          ),
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