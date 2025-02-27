import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  bool _isInitialized = false;
  String? _accessToken;

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
    final clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET']!;
    final credentials = base64.encode(utf8.encode('$clientId:$clientSecret'));
    
    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
      } else {
        throw Exception('Failed to authenticate with Spotify API');
      }

      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
      );
    } catch (e) {
      throw Exception('Failed to authenticate with Spotify: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    if (_accessToken == null) {
      await authenticate();
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(query)}&type=track&limit=10',
        ),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['tracks']['items'] as List).map((track) {
          return {
            'id': track['id'],
            'uri': track['uri'],
            'name': track['name'],
            'artist': track['artists'][0]['name'],
            'albumArt': track['album']['images'][0]['url'],
          };
        }).toList();
      } else if (response.statusCode == 401) {
        // Token expired, refresh and retry
        await authenticate();
        return searchTracks(query);
      } else {
        throw Exception('Failed to search tracks');
      }
    } catch (e) {
      throw Exception('Failed to search tracks: $e');
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