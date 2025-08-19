// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  nickname: json['nickname'] as String,
  gender: json['gender'] as String?,
  birthYear: (json['birthYear'] as num?)?.toInt(),
  region: json['region'] as String?,
  skillLevel: (json['skillLevel'] as num?)?.toInt(),
  startYearMonth: json['startYearMonth'] as String?,
  preferredCourt: json['preferredCourt'] as String?,
  preferredTime: (json['preferredTime'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  playStyle: json['playStyle'] as String?,
  hasLesson: json['hasLesson'] as bool?,
  mannerScore: (json['mannerScore'] as num?)?.toDouble(),
  profileImage: json['profileImage'] as String?,
  followingIds: (json['followingIds'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  followerIds: (json['followerIds'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  bio: json['bio'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'nickname': instance.nickname,
  'gender': instance.gender,
  'birthYear': instance.birthYear,
  'region': instance.region,
  'skillLevel': instance.skillLevel,
  'startYearMonth': instance.startYearMonth,
  'preferredCourt': instance.preferredCourt,
  'preferredTime': instance.preferredTime,
  'playStyle': instance.playStyle,
  'hasLesson': instance.hasLesson,
  'mannerScore': instance.mannerScore,
  'profileImage': instance.profileImage,
  'followingIds': instance.followingIds,
  'followerIds': instance.followerIds,
  'bio': instance.bio,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
