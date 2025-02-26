// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendationModel _$RecommendationModelFromJson(Map<String, dynamic> json) =>
    RecommendationModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String?,
      songId: json['songId'] as String,
      songName: json['songName'] as String,
      artistName: json['artistName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status:
          $enumDecodeNullable(_$RecommendationStatusEnumMap, json['status']) ??
              RecommendationStatus.pending,
    );

Map<String, dynamic> _$RecommendationModelToJson(
        RecommendationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'songId': instance.songId,
      'songName': instance.songName,
      'artistName': instance.artistName,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': _$RecommendationStatusEnumMap[instance.status]!,
    };

const _$RecommendationStatusEnumMap = {
  RecommendationStatus.pending: 'pending',
  RecommendationStatus.matched: 'matched',
};
