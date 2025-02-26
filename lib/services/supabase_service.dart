import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import '../models/recommendation_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    _client = Supabase.instance.client;
  }

  // User Operations
  Future<UserModel> createUser(String email) async {
    final userData = {
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('users')
        .insert(userData)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel?> getUser(String id) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', id)
        .single();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<void> updateLastRecommendationTime(String userId) async {
    await _client
        .from('users')
        .update({'last_recommendation_time': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  // Recommendation Operations
  Future<RecommendationModel> createRecommendation({
    required String senderId,
    required String songId,
    required String songName,
    required String artistName,
  }) async {
    final recommendationData = {
      'sender_id': senderId,
      'song_id': songId,
      'song_name': songName,
      'artist_name': artistName,
      'created_at': DateTime.now().toIso8601String(),
      'status': RecommendationStatus.pending.name,
    };

    final response = await _client
        .from('recommendations')
        .insert(recommendationData)
        .select()
        .single();

    return RecommendationModel.fromJson(response);
  }

  Future<RecommendationModel?> getRandomPendingRecommendation(String userId) async {
    final response = await _client
        .from('recommendations')
        .select()
        .eq('status', RecommendationStatus.pending.name)
        .neq('sender_id', userId)
        .is_('receiver_id', null)
        .order('created_at')
        .limit(1)
        .single();

    if (response == null) return null;
    return RecommendationModel.fromJson(response);
  }

  Future<void> matchRecommendation(String recommendationId, String receiverId) async {
    await _client
        .from('recommendations')
        .update({
          'receiver_id': receiverId,
          'status': RecommendationStatus.matched.name,
        })
        .eq('id', recommendationId);
  }

  Future<List<RecommendationModel>> getUserRecommendations(String userId) async {
    final response = await _client
        .from('recommendations')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => RecommendationModel.fromJson(json))
        .toList();
  }
} 