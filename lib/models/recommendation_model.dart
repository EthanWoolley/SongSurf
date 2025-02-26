import 'package:json_annotation/json_annotation.dart';

part 'recommendation_model.g.dart';

enum RecommendationStatus {
  pending,
  matched
}

@JsonSerializable()
class RecommendationModel {
  final String id;
  final String senderId;
  final String? receiverId;
  final String songId;
  final String songName;
  final String artistName;
  final DateTime createdAt;
  @JsonKey(defaultValue: RecommendationStatus.pending)
  final RecommendationStatus status;

  RecommendationModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.songId,
    required this.songName,
    required this.artistName,
    required this.createdAt,
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
    DateTime? createdAt,
    RecommendationStatus? status,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      songId: songId ?? this.songId,
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
} 