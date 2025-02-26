import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  bool _isInitialized = false;

  factory SpotifyService() {
    return _instance;
  }

  SpotifyService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: dotenv.env['SPOTIFY_CLIENT_ID']!,
        redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Spotify: $e');
    }
  }

  Future<void> authenticate() async {
    final clientId = dotenv.env['SPOTIFY_CLIENT_ID']!;
    final redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL']!;
    
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
    } catch (e) {
      throw Exception('Failed to authenticate with Spotify: $e');
    }
  }

  Future<bool> checkConnection() async {
    try {
      return await SpotifySdk.isSpotifyAppActive;
    } catch (e) {
      return false;
    }
  }

  Future<void> playSong(String spotifyUri) async {
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
    } catch (e) {
      throw Exception('Failed to play song: $e');
    }
  }

  Future<void> pausePlayback() async {
    try {
      await SpotifySdk.pause();
    } catch (e) {
      throw Exception('Failed to pause playback: $e');
    }
  }

  Future<void> resumePlayback() async {
    try {
      await SpotifySdk.resume();
    } catch (e) {
      throw Exception('Failed to resume playback: $e');
    }
  }

  Future<void> openSpotifyTrack(String trackId) async {
    final uri = Uri.parse('spotify:track:$trackId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch Spotify');
    }
  }

  Future<Map<String, dynamic>> getCurrentTrack() async {
    try {
      final playerState = await SpotifySdk.getPlayerState();
      if (playerState?.track == null) {
        throw Exception('No track is currently playing');
      }

      return {
        'id': playerState!.track!.uri.split(':').last,
        'name': playerState.track!.name,
        'artist': playerState.track!.artist.name,
        'uri': playerState.track!.uri,
      };
    } catch (e) {
      throw Exception('Failed to get current track: $e');
    }
  }
} 