import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_recommendation_time')
  final DateTime? lastRecommendationTime;

  UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.lastRecommendationTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  bool canRecommend() {
    if (lastRecommendationTime == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastRecommendationTime!);
    return difference.inHours >= 24;
  }

  UserModel copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    DateTime? lastRecommendationTime,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastRecommendationTime: lastRecommendationTime ?? this.lastRecommendationTime,
    );
  }
} 