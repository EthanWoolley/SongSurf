import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:songsurf/services/spotify_service.dart';
import 'package:songsurf/services/supabase_service.dart';
import 'package:songsurf/theme/app_theme.dart';
import 'package:songsurf/screens/name_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load();
  
  // Initialize services
  await SupabaseService().initialize();
  await SpotifyService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SongSurf',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const NameScreen(),
    );
  }
}
