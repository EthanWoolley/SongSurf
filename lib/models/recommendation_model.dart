import 'package:json_annotation/json_annotation.dart';

part 'recommendation_model.g.dart';

enum RecommendationStatus {
  pending,
  matched
}

@JsonSerializable()
class RecommendationModel {
  final String id;
  @JsonKey(name: 'sender_id')
  final String senderId;
  @JsonKey(name: 'receiver_id')
  final String? receiverId;
  @JsonKey(name: 'song_id')
  final String songId;
  @JsonKey(name: 'song_name')
  final String songName;
  @JsonKey(name: 'artist_name')
  final String artistName;
  @JsonKey(name: 'album_art')
  final String? albumArt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'matched_at')
  final DateTime? matchedAt;
  @JsonKey(name: 'status', defaultValue: RecommendationStatus.pending)
  final RecommendationStatus status;

  RecommendationModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.songId,
    required this.songName,
    required this.artistName,
    this.albumArt,
    required this.createdAt,
    this.matchedAt,
    this.status = RecommendationStatus.pending,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) => 
      _$RecommendationModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$RecommendationModelToJson(this);

  RecommendationModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? songId,
    String? songName,
    String? artistName,
    String? albumArt,
    DateTime? createdAt,
    DateTime? matchedAt,
    RecommendationStatus? status,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      songId: songId ?? this.songId,
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
      albumArt: albumArt ?? this.albumArt,
      createdAt: createdAt ?? this.createdAt,
      matchedAt: matchedAt ?? this.matchedAt,
      status: status ?? this.status,
    );
  }
} 