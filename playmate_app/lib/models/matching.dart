import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'matching.g.dart';

enum MatchingType { host, guest }
enum MatchingStatus { recruiting, confirmed, completed, cancelled }

@JsonSerializable()
class Matching {
  final int id;
  final String type; // 'host' or 'guest'
  final String courtName;
  final double courtLat;
  final double courtLng;
  final DateTime date;
  final String timeSlot;
  final int? minLevel;
  final int? maxLevel;

  final String gameType; // 'mixed', 'male_doubles', 'female_doubles', 'singles', 'rally'
  final int maleRecruitCount;
  final int femaleRecruitCount;
  final String status;
  final String? message;
  final int? guestCost;
  final bool isFollowersOnly; // 팔로워 전용 공개 여부
  final User host;
  final List<User>? guests;
  final DateTime createdAt;
  final DateTime updatedAt;

  Matching({
    required this.id,
    required this.type,
    required this.courtName,
    required this.courtLat,
    required this.courtLng,
    required this.date,
    required this.timeSlot,
    this.minLevel,
    this.maxLevel,

    required this.gameType,
    required this.maleRecruitCount,
    required this.femaleRecruitCount,
    required this.status,
    this.message,
    this.guestCost,
    this.isFollowersOnly = false,
    required this.host,
    this.guests,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Matching.fromJson(Map<String, dynamic> json) => _$MatchingFromJson(json);
  Map<String, dynamic> toJson() => _$MatchingToJson(this);

  // 구력 범위 텍스트
  String get skillRangeText {
    if (minLevel == null && maxLevel == null) return '제한없음';
    if (minLevel == null) return '~$maxLevel년';
    if (maxLevel == null) return '$minLevel년~';
    if (minLevel == maxLevel) return '$minLevel년';
    return '$minLevel년-$maxLevel년';
  }

  // 게임 유형 텍스트
  String get gameTypeText {
    switch (gameType) {
      case 'mixed':
        return '혼복';
      case 'male_doubles':
        return '남복';
      case 'female_doubles':
        return '여복';
      case 'singles':
        return '단식';
      case 'rally':
        return '랠리';
      default:
        return '알 수 없음';
    }
  }



  // 상태 텍스트
  String get statusText {
    switch (status) {
      case 'recruiting':
        return '모집중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return '알 수 없음';
    }
  }

  // 날짜 포맷팅
  String get formattedDate {
    return '${date.month}월 ${date.day}일';
  }

  // 시간대 포맷팅
  String get formattedTime {
    return timeSlot;
  }

  // 모집인원 텍스트 (성별 구분)
  String get recruitCountText {
    final total = maleRecruitCount + femaleRecruitCount;
    if (maleRecruitCount > 0 && femaleRecruitCount > 0) {
      return '${total}명 (남$maleRecruitCount, 여$femaleRecruitCount)';
    } else if (maleRecruitCount > 0) {
      return '${total}명 (남$maleRecruitCount)';
    } else if (femaleRecruitCount > 0) {
      return '${total}명 (여$femaleRecruitCount)';
    } else {
      return '${total}명';
    }
  }
} 