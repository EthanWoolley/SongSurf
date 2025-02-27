import 'package:flutter/material.dart';
import 'package:songsurf/screens/song_selection_screen.dart';
import 'package:songsurf/services/spotify_service.dart';
import 'package:songsurf/services/supabase_service.dart';
import 'package:songsurf/widgets/animated_background.dart';
import 'package:songsurf/widgets/wide_button.dart';

class EmailScreen extends StatefulWidget {
  final String name;

  const EmailScreen({
    super.key,
    required this.name,
  });

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _emailController = TextEditingController();
  final _spotifyService = SpotifyService();
  final _supabaseService = SupabaseService();
  bool _isValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      final email = _emailController.text.trim();
      _isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
    });
  }

  Future<void> _continue() async {
    if (!_isValid || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Create user in Supabase
      final user = await _supabaseService.createUser(_emailController.text.trim());

      // Authenticate with Spotify
      await _spotifyService.authenticate();

      if (!mounted) return;

      // Navigate to song selection screen
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SongSelectionScreen(
            name: widget.name,
            userId: user.id,
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
    } catch (e) {
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
                  'Hi ${widget.name}! 👋',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 32),
                Text(
                  'What\'s your email?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  onSubmitted: (_) => _continue(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: WideButton(
                    text: 'Continue',
                    onPressed: _continue,
                    isLoading: _isLoading,
                    isPrimary: _isValid,
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