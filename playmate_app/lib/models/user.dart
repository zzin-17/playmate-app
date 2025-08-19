import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  final String nickname;
  final String? gender;
  final int? birthYear;
  final String? region;
  final int? skillLevel;
  final String? startYearMonth; // 'YYYY-MM' 형태. 가입/테니스 시작월
  final String? preferredCourt;
  final List<String>? preferredTime;
  final String? playStyle;
  final bool? hasLesson;
  final double? mannerScore;
  final String? profileImage;
  List<int>? followingIds; // 팔로우하는 사용자 ID 목록
  List<int>? followerIds;  // 팔로워 ID 목록
  final String? bio;             // 자기소개
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.gender,
    this.birthYear,
    this.region,
    this.skillLevel,
    this.startYearMonth,
    this.preferredCourt,
    this.preferredTime,
    this.playStyle,
    this.hasLesson,
    this.mannerScore,
    this.profileImage,
    this.followingIds,
    this.followerIds,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // 스킬 레벨 텍스트 변환
  String get skillLevelText {
    // startYearMonth 가 있으면 자동 계산된 구력 표시 우선
    if (startYearMonth != null && RegExp(r'^\d{4}-\d{2}$').hasMatch(startYearMonth!)) {
      return experienceText;
    }
    switch (skillLevel) {
      case 1:
        return '입문자';
      case 2:
        return '초급자';
      case 3:
        return '중급자';
      case 4:
        return '고급자';
      case 5:
        return '전문가';
      default:
        return '미설정';
    }
  }

  // 성별 텍스트 변환
  String get genderText {
    switch (gender) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      default:
        return '미설정';
    }
  }

  // 매너 점수 표시
  String get mannerScoreText {
    if (mannerScore == null) return '평가 없음';
    return '${mannerScore!.toStringAsFixed(1)}점';
  }

  // 시작월 기반 구력 계산 텍스트 (예: 4년 3개월)
  String get experienceText {
    if (startYearMonth == null) return '미설정';
    final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(startYearMonth!);
    if (m == null) return '미설정';
    final startYear = int.parse(m.group(1)!);
    final startMonth = int.parse(m.group(2)!);
    final now = DateTime.now();
    int totalMonths = (now.year - startYear) * 12 + (now.month - startMonth);
    if (totalMonths < 0) totalMonths = 0;
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    if (years == 0) return '${months}개월';
    if (months == 0) return '${years}년';
    return '${years}년 ${months}개월';
  }

  // 연령대 텍스트 (예: 20대, 30대)
  String get ageDecadeText {
    if (birthYear == null) return '미설정';
    final nowYear = DateTime.now().year;
    int age = nowYear - birthYear!;
    if (age < 10) return '10대 미만';
    final decade = (age ~/ 10) * 10;
    return '${decade}대';
  }
} 