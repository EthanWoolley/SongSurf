import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  bool _isInitialized = false;
  bool _isSpotifyInstalled = false;
  String? _accessToken;

  factory SpotifyService() {
    return _instance;
  }

  SpotifyService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // First check if Spotify is installed using a more reliable method
      if (Platform.isIOS) {
        // On iOS, we'll check if we can launch the Spotify URL scheme
        final canLaunch = await canLaunchUrl(Uri.parse('spotify:app'));
        _isSpotifyInstalled = canLaunch;
      } else {
        // For Android, try to check if Spotify is installed
        try {
          // Try to check if Spotify app is active as a proxy for installation
          _isSpotifyInstalled = await SpotifySdk.isSpotifyAppActive;
        } catch (e) {
          // Fallback to checking if we can launch the Spotify URL
          _isSpotifyInstalled = await canLaunchUrl(Uri.parse('spotify:app'));
        }
      }
      
      // Only try to connect if Spotify is installed
      if (_isSpotifyInstalled) {
        try {
          await SpotifySdk.connectToSpotifyRemote(
            clientId: dotenv.env['SPOTIFY_CLIENT_ID']!,
            redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
          );
        } catch (e) {
          // If connection fails, we can still use the app with URL launching
          print('Warning: Failed to connect to Spotify remote: $e');
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      // If there's an error, we can still use the web API
      _isSpotifyInstalled = false;
      _isInitialized = true;
      print('Warning: Failed to initialize Spotify SDK: $e');
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

      // Only try to connect to Spotify remote if the app is installed
      if (_isSpotifyInstalled) {
        try {
          await SpotifySdk.connectToSpotifyRemote(
            clientId: clientId,
            redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
          );
        } catch (e) {
          print('Warning: Failed to connect to Spotify remote: $e');
          // We can continue without remote connection
        }
      }
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
        final items = data['tracks']['items'] as List;
        if (items.isEmpty) {
          return [];
        }
        
        return items.map((track) {
          final images = track['album']['images'] as List;
          final imageUrl = images.isEmpty
              ? 'https://cdn.icon-icons.com/icons2/2024/PNG/512/music_note_icon_123887.png' // Static, reliable default image
              : images[0]['url'];
          
          return {
            'id': track['id'],
            'uri': track['uri'],
            'name': track['name'],
            'artist': track['artists'][0]['name'],
            'albumArt': imageUrl,
          };
        }).toList();
      } else if (response.statusCode == 401) {
        // Token expired, refresh and retry
        await authenticate();
        return searchTracks(query);
      } else {
        print('Failed to search tracks. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to search tracks');
      }
    } catch (e) {
      print('Error searching tracks: $e');
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
    // Extract the track ID if we're given a full URI
    final String trackId = spotifyUri.contains(':') 
        ? spotifyUri.split(':').last 
        : spotifyUri;
    
    // If Spotify SDK is not available or app is not installed, go directly to URL launching
    if (!_isSpotifyInstalled) {
      await openSpotifyTrack(trackId);
      return;
    }

    try {
      // First try using the SDK
      final bool connected = await checkConnection();
      if (connected) {
        try {
          await SpotifySdk.play(spotifyUri: 'spotify:track:$trackId');
          return; // Success!
        } catch (e) {
          print('SDK play failed, falling back to URL: $e');
          // Fall through to URL launching
        }
      }
      
      // If SDK fails or not connected, try URL launching
      await openSpotifyTrack(trackId);
    } catch (e) {
      print('All playback methods failed: $e');
      // Try one last web fallback
      final webUri = Uri.parse('https://open.spotify.com/track/$trackId');
      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
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
    // Try multiple URL formats to ensure compatibility
    final List<Uri> urisToTry = [
      Uri.parse('spotify:track:$trackId'),
      Uri.parse('https://open.spotify.com/track/$trackId'),
    ];
    
    bool launched = false;
    
    for (final uri in urisToTry) {
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) break;
        }
      } catch (e) {
        print('Error launching $uri: $e');
        // Continue to the next URI
      }
    }
    
    if (!launched) {
      // As a last resort, try a web fallback
      final webUri = Uri.parse('https://open.spotify.com/track/$trackId');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri);
      } else {
        throw Exception('Could not launch Spotify');
      }
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

  // Add a method to check if Spotify is installed
  bool get isSpotifyInstalled => _isSpotifyInstalled;
} 