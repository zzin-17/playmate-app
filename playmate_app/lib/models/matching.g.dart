// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Matching _$MatchingFromJson(Map<String, dynamic> json) => Matching(
  id: (json['id'] as num).toInt(),
  type: json['type'] as String,
  courtName: json['courtName'] as String,
  courtLat: (json['courtLat'] as num).toDouble(),
  courtLng: (json['courtLng'] as num).toDouble(),
  date: DateTime.parse(json['date'] as String),
  timeSlot: json['timeSlot'] as String,
  minLevel: (json['minLevel'] as num?)?.toInt(),
  maxLevel: (json['maxLevel'] as num?)?.toInt(),
  genderPreference: json['genderPreference'] as String?,
  gameType: json['gameType'] as String,
  maleRecruitCount: (json['maleRecruitCount'] as num).toInt(),
  femaleRecruitCount: (json['femaleRecruitCount'] as num).toInt(),
  status: json['status'] as String,
  message: json['message'] as String?,
  guestCost: (json['guestCost'] as num?)?.toInt(),
  host: User.fromJson(json['host'] as Map<String, dynamic>),
  guests: (json['guests'] as List<dynamic>?)
      ?.map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$MatchingToJson(Matching instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'courtName': instance.courtName,
  'courtLat': instance.courtLat,
  'courtLng': instance.courtLng,
  'date': instance.date.toIso8601String(),
  'timeSlot': instance.timeSlot,
  'minLevel': instance.minLevel,
  'maxLevel': instance.maxLevel,
  'genderPreference': instance.genderPreference,
  'gameType': instance.gameType,
  'maleRecruitCount': instance.maleRecruitCount,
  'femaleRecruitCount': instance.femaleRecruitCount,
  'status': instance.status,
  'message': instance.message,
  'guestCost': instance.guestCost,
  'host': instance.host,
  'guests': instance.guests,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
