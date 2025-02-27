// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecommendationModel _$RecommendationModelFromJson(Map<String, dynamic> json) =>
    RecommendationModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String?,
      songId: json['song_id'] as String,
      songName: json['song_name'] as String,
      artistName: json['artist_name'] as String,
      albumArt: json['album_art'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      matchedAt: json['matched_at'] == null
          ? null
          : DateTime.parse(json['matched_at'] as String),
      status:
          $enumDecodeNullable(_$RecommendationStatusEnumMap, json['status']) ??
              RecommendationStatus.pending,
    );

Map<String, dynamic> _$RecommendationModelToJson(
        RecommendationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_id': instance.senderId,
      'receiver_id': instance.receiverId,
      'song_id': instance.songId,
      'song_name': instance.songName,
      'artist_name': instance.artistName,
      'album_art': instance.albumArt,
      'created_at': instance.createdAt.toIso8601String(),
      'matched_at': instance.matchedAt?.toIso8601String(),
      'status': _$RecommendationStatusEnumMap[instance.status]!,
    };

const _$RecommendationStatusEnumMap = {
  RecommendationStatus.pending: 'pending',
  RecommendationStatus.matched: 'matched',
};
