// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Matching _$MatchingFromJson(Map<String, dynamic> json) => Matching(
  id: (json['id'] as num?)?.toInt() ?? 0,
  type: json['type'] as String? ?? 'host',
  courtName: json['courtName'] as String? ?? '',
  courtLat: (json['courtLat'] as num?)?.toDouble() ?? 37.5665,
  courtLng: (json['courtLng'] as num?)?.toDouble() ?? 126.9780,
  date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
  timeSlot: json['timeSlot'] as String? ?? '18:00~20:00',
  minLevel: (json['minLevel'] as num?)?.toInt(),
  maxLevel: (json['maxLevel'] as num?)?.toInt(),
  minAge: (() {
    final value = (json['minAge'] as num?)?.toInt();
    print('🔍 Matching.fromJson minAge: ${json['minAge']} -> $value');
    return value;
  })(),
  maxAge: (() {
    final value = (json['maxAge'] as num?)?.toInt();
    print('🔍 Matching.fromJson maxAge: ${json['maxAge']} -> $value');
    return value;
  })(),
  gameType: json['gameType'] as String? ?? 'singles',
  maleRecruitCount: (json['maleRecruitCount'] as num?)?.toInt() ?? 2,
  femaleRecruitCount: (json['femaleRecruitCount'] as num?)?.toInt() ?? 2,
  status: json['status'] as String? ?? 'recruiting',
  message: json['message'] as String?,
  guestCost: (json['guestCost'] as num?)?.toInt(),
  isFollowersOnly: json['isFollowersOnly'] as bool? ?? false,
  host: json['host'] != null ? User.fromJson(json['host'] as Map<String, dynamic>) : User(
    id: 0,
    nickname: 'Unknown',
    email: 'unknown@example.com',
    profileImage: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  guests: (json['guests'] as List<dynamic>?)
      ?.map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
  updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
  recoveryCount: (json['recoveryCount'] as num?)?.toInt(),
  appliedUserIds: (json['appliedUserIds'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  confirmedUserIds: (json['confirmedUserIds'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
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
  'minAge': instance.minAge,
  'maxAge': instance.maxAge,
  'gameType': instance.gameType,
  'maleRecruitCount': instance.maleRecruitCount,
  'femaleRecruitCount': instance.femaleRecruitCount,
  'status': instance.status,
  'message': instance.message,
  'guestCost': instance.guestCost,
  'isFollowersOnly': instance.isFollowersOnly,
  'host': instance.host,
  'guests': instance.guests,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'recoveryCount': instance.recoveryCount,
  'appliedUserIds': instance.appliedUserIds,
  'confirmedUserIds': instance.confirmedUserIds,
  'completedAt': instance.completedAt?.toIso8601String(),
  'cancelledAt': instance.cancelledAt?.toIso8601String(),
};
