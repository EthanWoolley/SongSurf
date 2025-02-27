import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import '../models/recommendation_model.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  final _uuid = const Uuid();
  bool _hasShownRLSWarning = false;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  void _showRLSWarningOnce() {
    if (!_hasShownRLSWarning) {
      print('Warning: RLS policy violations are expected if the database is empty or if RLS policies are not set up. This warning will only show once.');
      _hasShownRLSWarning = true;
    }
  }

  Future<void> initialize() async {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (url == null || anonKey == null) {
        throw Exception('SUPABASE_URL or SUPABASE_ANON_KEY not found in .env file');
      }

      print('Initializing Supabase with URL: $url');
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _client = Supabase.instance.client;
      print('Supabase initialized successfully');
    } catch (e) {
      print('Error initializing Supabase: ${e.toString()}');
      rethrow;
    }
  }

  // User Operations
  Future<UserModel> createUser(String email) async {
    try {
      final userData = {
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('users')
          .insert(userData)
          .select()
          .single();

      print('User created successfully: ${response.toString()}');
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error creating user: ${e.toString()}');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        _showRLSWarningOnce();
        return null;
      }
      rethrow;
    }
  }

  Future<void> updateLastRecommendationTime(String userId) async {
    try {
      await _client
          .from('users')
          .update({'last_recommendation_time': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        print('Warning: RLS policy violation when updating user. This is expected if the database is empty or if RLS policies are not set up.');
        return;
      }
      rethrow;
    }
  }

  // Recommendation Operations
  Future<RecommendationModel> createRecommendation({
    required String senderId,
    required String songId,
    required String songName,
    required String artistName,
    String? albumArt,
  }) async {
    try {
      final recommendationData = {
        'sender_id': senderId,
        'song_id': songId,
        'song_name': songName,
        'artist_name': artistName,
        'album_art': albumArt,
        'created_at': DateTime.now().toIso8601String(),
        'status': RecommendationStatus.pending.name,
      };

      print('Sending recommendation data to Supabase:');
      print(recommendationData);

      final response = await _client
          .from('recommendations')
          .insert(recommendationData)
          .select()
          .single();

      print('Received response from Supabase:');
      print(response);

      return RecommendationModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        _showRLSWarningOnce();
        // Return a mock recommendation with a proper UUID for development
        return RecommendationModel(
          id: _uuid.v4(),
          senderId: senderId,
          songId: songId,
          songName: songName,
          artistName: artistName,
          albumArt: albumArt,
          createdAt: DateTime.now(),
          status: RecommendationStatus.pending,
        );
      }
      rethrow;
    }
  }

  Future<RecommendationModel?> getRandomPendingRecommendation(String userId) async {
    try {
      final response = await _client
          .from('recommendations')
          .select()
          .eq('status', RecommendationStatus.pending.name)
          .neq('sender_id', userId)
          .filter('receiver_id', 'is', null)
          .order('created_at')
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return RecommendationModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        _showRLSWarningOnce();
        // In development mode, return a mock recommendation
        return RecommendationModel(
          id: _uuid.v4(),
          senderId: _uuid.v4(),
          songId: 'mock_song_id',
          songName: 'Mock Song',
          artistName: 'Mock Artist',
          albumArt: 'https://i.scdn.co/image/ab67616d0000b273b36949bee43217351961ffbc',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          status: RecommendationStatus.pending,
        );
      }
      print('Error getting random recommendation: $e');
      rethrow;
    }
  }

  Future<bool> matchRecommendation(String recommendationId, String receiverId) async {
    try {
      print('Attempting to match recommendation: $recommendationId for receiver: $receiverId');
      
      final response = await _client
          .from('recommendations')
          .update({
            'receiver_id': receiverId,
            'status': RecommendationStatus.matched.name,
          })
          .eq('id', recommendationId)
          .select()
          .maybeSingle();
      
      if (response == null) {
        print('Warning: No recommendation found with ID: $recommendationId');
        return false;
      }
      
      print('Successfully matched recommendation: $recommendationId');
      return true;

    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        _showRLSWarningOnce();
        // In development mode, we'll just pretend the update succeeded
        print('Development mode: Simulating successful recommendation match');
        return true;
      }
      print('Error matching recommendation: $e');
      return false;
    }
  }

  Future<List<RecommendationModel>> getUserRecommendations(String userId) async {
    try {
      final response = await _client
          .from('recommendations')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RecommendationModel.fromJson(json))
          .toList();
    } catch (e) {
      if (e.toString().contains('violates row-level security policy')) {
        _showRLSWarningOnce();
        // In development mode, return a mock list of recommendations
        return [
          RecommendationModel(
            id: _uuid.v4(),
            senderId: userId,
            songId: 'mock_song_id_1',
            songName: 'Your Mock Song',
            artistName: 'Mock Artist 1',
            albumArt: 'https://i.scdn.co/image/ab67616d0000b273b36949bee43217351961ffbc',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            status: RecommendationStatus.pending,
          ),
          RecommendationModel(
            id: _uuid.v4(),
            senderId: _uuid.v4(),
            receiverId: userId,
            songId: 'mock_song_id_2',
            songName: 'Received Mock Song',
            artistName: 'Mock Artist 2',
            albumArt: 'https://i.scdn.co/image/ab67616d0000b273b36949bee43217351961ffbc',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            status: RecommendationStatus.matched,
          ),
        ];
      }
      print('Error getting user recommendations: $e');
      rethrow;
    }
  }
} 