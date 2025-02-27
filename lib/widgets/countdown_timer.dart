import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime? lastRecommendationTime;

  const CountdownTimer({
    super.key,
    required this.lastRecommendationTime,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _progressController;
  String _timeLeft = '';
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _updateTimer();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    if (widget.lastRecommendationTime == null) {
      setState(() {
        _timeLeft = 'Ready to recommend!';
        _isReady = true;
        _progressController.value = 1.0;
      });
      return;
    }

    final now = DateTime.now();
    final nextRecommendation =
        widget.lastRecommendationTime!.add(const Duration(hours: 24));
    final difference = nextRecommendation.difference(now);

    if (difference.isNegative) {
      setState(() {
        _timeLeft = 'Ready to recommend!';
        _isReady = true;
        _progressController.value = 1.0;
      });
      return;
    }

    final totalSeconds = const Duration(hours: 24).inSeconds;
    final remainingSeconds = difference.inSeconds;
    final progress = 1 - (remainingSeconds / totalSeconds);

    _progressController.animateTo(
      progress,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    final hours = difference.inHours;
    final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');

    setState(() {
      _timeLeft = '$hours:$minutes:$seconds';
      _isReady = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _progressController.value,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      color: _isReady
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      strokeWidth: 4,
                    );
                  },
                ),
                if (_isReady)
                  Center(
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isReady ? 'Ready!' : 'Next recommendation in',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeLeft,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 