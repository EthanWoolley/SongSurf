// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastRecommendationTime: json['lastRecommendationTime'] == null
          ? null
          : DateTime.parse(json['lastRecommendationTime'] as String),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastRecommendationTime':
          instance.lastRecommendationTime?.toIso8601String(),
    };
