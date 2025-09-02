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
  final double? ntrpScore; // NTRP 점수 (1.0 ~ 7.0)
  final String? preferredCourt;
  final List<String>? preferredTime;
  final String? playStyle;
  final bool? hasLesson;
  final double? mannerScore;
  final String? profileImage;
  final String? preferredGameType;
  List<int>? followingIds; // 팔로우하는 사용자 ID 목록
  List<int>? followerIds;  // 팔로워 ID 목록
  final String? bio;             // 자기소개
  final int? reviewCount;        // 받은 후기 개수
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
    this.ntrpScore,
    this.preferredCourt,
    this.preferredTime,
    this.playStyle,
    this.hasLesson,
    this.mannerScore,
    this.profileImage,
    this.preferredGameType,
    this.followingIds,
    this.followerIds,
    this.bio,
    this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // copyWith 메서드
  User copyWith({
    int? id,
    String? email,
    String? nickname,
    String? gender,
    int? birthYear,
    String? region,
    int? skillLevel,
    String? startYearMonth,
    double? ntrpScore,
    String? preferredCourt,
    List<String>? preferredTime,
    String? playStyle,
    bool? hasLesson,
    double? mannerScore,
    String? profileImage,
    String? preferredGameType,
    List<int>? followingIds,
    List<int>? followerIds,
    String? bio,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      region: region ?? this.region,
      skillLevel: skillLevel ?? this.skillLevel,
      startYearMonth: startYearMonth ?? this.startYearMonth,
      ntrpScore: ntrpScore ?? this.ntrpScore,
      preferredCourt: preferredCourt ?? this.preferredCourt,
      preferredTime: preferredTime ?? this.preferredTime,
      playStyle: playStyle ?? this.playStyle,
      hasLesson: hasLesson ?? this.hasLesson,
      mannerScore: mannerScore ?? this.mannerScore,
      profileImage: profileImage ?? this.profileImage,
      preferredGameType: preferredGameType ?? this.preferredGameType,
      followingIds: followingIds ?? this.followingIds,
      followerIds: followerIds ?? this.followerIds,
      bio: bio ?? this.bio,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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

  // NTRP 점수 표시
  String get ntrpScoreText {
    if (ntrpScore == null) return '평가 없음';
    return ntrpScore!.toStringAsFixed(1);
  }

  // NTRP 점수 레벨 텍스트
  String get ntrpLevelText {
    if (ntrpScore == null) return '미평가';
    if (ntrpScore! < 1.5) return '초보자 (1.0-1.5)';
    if (ntrpScore! < 2.5) return '입문자 (1.5-2.5)';
    if (ntrpScore! < 3.5) return '초급자 (2.5-3.5)';
    if (ntrpScore! < 4.5) return '중급자 (3.5-4.5)';
    if (ntrpScore! < 5.5) return '고급자 (4.5-5.5)';
    if (ntrpScore! < 6.5) return '전문가 (5.5-6.5)';
    return '엘리트 (6.5+)';
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