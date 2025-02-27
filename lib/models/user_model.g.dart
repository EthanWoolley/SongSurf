// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastRecommendationTime: json['last_recommendation_time'] == null
          ? null
          : DateTime.parse(json['last_recommendation_time'] as String),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'created_at': instance.createdAt.toIso8601String(),
      'last_recommendation_time':
          instance.lastRecommendationTime?.toIso8601String(),
    };
