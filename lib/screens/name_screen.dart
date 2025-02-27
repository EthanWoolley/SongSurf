import 'package:flutter/material.dart';
import 'package:songsurf/screens/email_screen.dart';
import 'package:songsurf/widgets/animated_background.dart';
import 'package:songsurf/widgets/wide_button.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _nameController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isValid = _nameController.text.trim().length >= 2;
    });
  }

  void _continue() {
    if (!_isValid) return;
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EmailScreen(
          name: _nameController.text.trim(),
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
                  'Welcome to\nSongSurf',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 32),
                Text(
                  'What\'s your name?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  onSubmitted: (_) => _continue(),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: WideButton(
                    text: 'Continue',
                    onPressed: _continue,
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