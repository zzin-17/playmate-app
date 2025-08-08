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
  final String? preferredCourt;
  final List<String>? preferredTime;
  final String? playStyle;
  final bool? hasLesson;
  final double? mannerScore;
  final String? profileImage;
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
    this.preferredCourt,
    this.preferredTime,
    this.playStyle,
    this.hasLesson,
    this.mannerScore,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // 스킬 레벨 텍스트 변환
  String get skillLevelText {
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
} 