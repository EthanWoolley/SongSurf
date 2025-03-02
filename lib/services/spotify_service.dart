import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class SpotifyService {
  static final SpotifyService _instance = SpotifyService._internal();
  bool _isInitialized = false;
  bool _isSpotifyInstalled = false;
  String? _accessToken;
  bool? _spotifyAppConnectionToken;

  factory SpotifyService() {
    return _instance;
  }

  SpotifyService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID']!;
      final redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL']!;
      
      print('Initializing Spotify service with:');
      print('Client ID: $clientId');
      print('Redirect URL: $redirectUrl');
      
      // Check if Spotify is installed - in v3.0.2, we need to use a different approach
      try {
        // In the new version, we can try to connect and catch the error if Spotify isn't installed
        _isSpotifyInstalled = true; // Assume true initially
        
        // We'll know it's not installed if connection fails with specific error
        print('Checking if Spotify is installed by attempting connection...');
      } catch (e) {
        print('Warning: Failed to check if Spotify is installed: $e');
        _isSpotifyInstalled = true; // Assume it's installed and try anyway
      }
      
      // Try to connect to Spotify remote
      if (_isSpotifyInstalled) {
        try {
          // The new SDK version uses a different connection method
          final connectionResult = await SpotifySdk.connectToSpotifyRemote(
            clientId: clientId,
            redirectUrl: redirectUrl,
          );
          print('Successfully connected to Spotify Remote: $connectionResult');
          _spotifyAppConnectionToken = connectionResult;
        } catch (e) {
          print('Warning: Failed to connect to Spotify remote: $e');
          // If we get a specific error about Spotify not being installed, update our flag
          if (e.toString().contains('Spotify app is not installed') || 
              e.toString().contains('CouldNotFindSpotifyApp')) {
            _isSpotifyInstalled = false;
            print('Spotify app is not installed based on connection error');
          }
          // We can still use the app with URL launching and Web API
        }
      }
      
      // Always authenticate with the Web API as a fallback
      try {
        await authenticate();
        print('Successfully authenticated with Spotify Web API');
      } catch (authError) {
        print('Warning: Failed to authenticate with Spotify Web API: $authError');
      }
      
      _isInitialized = true;
    } catch (e) {
      // If there's an error, we can still use the web API
      print('Warning: Failed to initialize Spotify SDK: $e');
      _isInitialized = true;
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
        throw Exception('Failed to authenticate with Spotify API: ${response.statusCode} - ${response.body}');
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
      // In v3.0.2, we need to use a different approach
      // Try to get the player state, which will throw if not connected
      final playerState = await SpotifySdk.getPlayerState();
      return playerState != null;
    } catch (e) {
      print('Error checking Spotify connection: $e');
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
          // Use the updated play method with more options
          await SpotifySdk.play(spotifyUri: 'spotify:track:$trackId');
          return; // Success!
        } catch (e) {
          print('SDK play failed, falling back to URL: $e');
          // Fall through to URL launching
        }
      } else {
        // Try to reconnect if not connected
        try {
          final clientId = dotenv.env['SPOTIFY_CLIENT_ID']!;
          final redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL']!;
          
          await SpotifySdk.connectToSpotifyRemote(
            clientId: clientId,
            redirectUrl: redirectUrl,
          );
          
          // Try playing again after reconnection
          await SpotifySdk.play(spotifyUri: 'spotify:track:$trackId');
          return; // Success!
        } catch (reconnectError) {
          print('Reconnection failed: $reconnectError');
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
  
  // Test function to verify Spotify connection
  Future<Map<String, dynamic>> testSpotifyConnection() async {
    final result = <String, dynamic>{
      'isSpotifyInstalled': _isSpotifyInstalled,
      'isInitialized': _isInitialized,
      'hasAccessToken': _accessToken != null,
      'hasSpotifyAppConnectionToken': _spotifyAppConnectionToken != null,
      'clientId': dotenv.env['SPOTIFY_CLIENT_ID'],
      'redirectUrl': dotenv.env['SPOTIFY_REDIRECT_URL'],
      'sdkVersion': '3.0.2',
    };
    
    try {
      // Try to check if Spotify app is installed - in v3.0.2, we infer this from connection attempts
      try {
        // We'll try to get player state, which will fail if Spotify isn't installed
        final playerState = await SpotifySdk.getPlayerState();
        result['isSpotifyInstalled'] = playerState != null;
      } catch (e) {
        result['isSpotifyInstalledError'] = e.toString();
        // If we get a specific error about Spotify not being installed, update our result
        if (e.toString().contains('Spotify app is not installed') || 
            e.toString().contains('CouldNotFindSpotifyApp')) {
          result['isSpotifyInstalled'] = false;
        }
      }
      
      // Try to check if Spotify app is connected
      try {
        final playerState = await SpotifySdk.getPlayerState();
        result['isSpotifyAppConnected'] = playerState != null;
        result['playerState'] = playerState.toString();
      } catch (e) {
        result['isSpotifyAppConnectedError'] = e.toString();
      }
      
      // Try to check if we can launch Spotify URLs
      try {
        result['canLaunchSpotifyUri'] = await canLaunchUrl(Uri.parse('spotify:'));
      } catch (e) {
        result['canLaunchSpotifyUriError'] = e.toString();
      }
      
      // Try to connect to Spotify remote
      try {
        final clientId = dotenv.env['SPOTIFY_CLIENT_ID']!;
        final redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URL']!;
        
        final connectionResult = await SpotifySdk.connectToSpotifyRemote(
          clientId: clientId,
          redirectUrl: redirectUrl,
        );
        result['connectedToSpotifyRemote'] = connectionResult != null;
        result['spotifyConnectionToken'] = connectionResult;
      } catch (e) {
        result['connectToSpotifyRemoteError'] = e.toString();
      }
      
      // Try to get an access token
      try {
        await authenticate();
        result['gotAccessToken'] = _accessToken != null;
      } catch (e) {
        result['getAccessTokenError'] = e.toString();
      }
      
      return result;
    } catch (e) {
      return {
        ...result,
        'testError': e.toString(),
      };
    }
  }
} 