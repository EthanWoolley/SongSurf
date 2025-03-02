import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:songsurf/services/spotify_service.dart';
import 'package:songsurf/services/supabase_service.dart';
import 'package:songsurf/theme/app_theme.dart';
import 'package:songsurf/screens/name_screen.dart';
import 'package:songsurf/screens/spotify_test_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  
  // Initialize services
  await SupabaseService().initialize();
  
  // Initialize Spotify service with retry logic
  bool spotifyInitialized = false;
  int retryCount = 0;
  
  while (!spotifyInitialized && retryCount < 3) {
    try {
      await SpotifyService().initialize();
      spotifyInitialized = true;
      print('Spotify service initialized successfully');
    } catch (e) {
      retryCount++;
      print('Failed to initialize Spotify service (attempt $retryCount): $e');
      await Future.delayed(Duration(seconds: 1));
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _spotifyService = SpotifyService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Configure platform channels for deep linking
    _configureDeepLinking();
    
    // Ensure Spotify is authenticated when app starts
    _authenticateSpotify();
  }
  
  Future<void> _authenticateSpotify() async {
    try {
      await _spotifyService.authenticate();
      print('Spotify authenticated successfully');
    } catch (e) {
      print('Failed to authenticate with Spotify: $e');
      // We'll continue anyway, as the app can still function with web fallbacks
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Handle app lifecycle changes (e.g., when returning from Spotify)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconnect to Spotify when app is resumed
      _authenticateSpotify();
    }
  }
  
  // Configure deep linking
  void _configureDeepLinking() {
    // This would handle any incoming links when the app is already running
    // For a more complete implementation, you might want to use uni_links package
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SongSurf',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeWrapper(),
    );
  }
}

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NameScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SpotifyTestScreen(),
            ),
          );
        },
        child: const Icon(Icons.music_note),
        tooltip: 'Spotify Connection Test',
      ),
    );
  }
}
