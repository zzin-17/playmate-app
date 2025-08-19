import 'user.dart';
import 'matching.dart';

class Review {
  final int id;
  final int matchingId;
  final int reviewerId; // 리뷰 작성자 ID
  final int reviewedUserId; // 리뷰 대상자 ID
  final double ntrpScore; // NTRP 점수 (1.0 ~ 7.0)
  final double mannerScore; // 매너 점수 (1.0 ~ 5.0)
  final String comment; // 리뷰 텍스트
  final DateTime createdAt;
  final DateTime updatedAt;

  // 관계 데이터 (JSON 직렬화 시 제외)
  final User? reviewer;
  
  final User? reviewedUser;
  
  final Matching? matching;

  Review({
    required this.id,
    required this.matchingId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.ntrpScore,
    required this.mannerScore,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.reviewer,
    this.reviewedUser,
    this.matching,
  });

  // JSON 직렬화 메서드 (필요시 구현)
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      matchingId: json['matchingId'] as int,
      reviewerId: json['reviewerId'] as int,
      reviewedUserId: json['reviewedUserId'] as int,
      ntrpScore: (json['ntrpScore'] as num).toDouble(),
      mannerScore: (json['mannerScore'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchingId': matchingId,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'ntrpScore': ntrpScore,
      'mannerScore': mannerScore,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // NTRP 점수 표시
  String get ntrpScoreText {
    return ntrpScore.toStringAsFixed(1);
  }

  // NTRP 점수 레벨 텍스트
  String get ntrpLevelText {
    if (ntrpScore < 1.5) return '초보자 (1.0-1.5)';
    if (ntrpScore < 2.5) return '입문자 (1.5-2.5)';
    if (ntrpScore < 3.5) return '초급자 (2.5-3.5)';
    if (ntrpScore < 4.5) return '중급자 (3.5-4.5)';
    if (ntrpScore < 5.5) return '고급자 (4.5-5.5)';
    if (ntrpScore < 6.5) return '전문가 (5.5-6.5)';
    return '엘리트 (6.5+)';
  }

  // 매너 점수 표시
  String get mannerScoreText {
    return mannerScore.toStringAsFixed(1);
  }

  // 매너 점수 레벨 텍스트
  String get mannerLevelText {
    if (mannerScore < 2.0) return '매우 나쁨';
    if (mannerScore < 3.0) return '나쁨';
    if (mannerScore < 4.0) return '보통';
    if (mannerScore < 4.5) return '좋음';
    return '매우 좋음';
  }

  // 매너 점수 색상
  String get mannerScoreColor {
    if (mannerScore < 2.0) return '#FF4444'; // 빨강
    if (mannerScore < 3.0) return '#FF8800'; // 주황
    if (mannerScore < 4.0) return '#FFCC00'; // 노랑
    if (mannerScore < 4.5) return '#88CC00'; // 연두
    return '#44CC44'; // 초록
  }

  // 복사 및 수정 메서드
  Review copyWith({
    int? id,
    int? matchingId,
    int? reviewerId,
    int? reviewedUserId,
    double? ntrpScore,
    double? mannerScore,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? reviewer,
    User? reviewedUser,
    Matching? matching,
  }) {
    return Review(
      id: id ?? this.id,
      matchingId: matchingId ?? this.matchingId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewedUserId: reviewedUserId ?? this.reviewedUserId,
      ntrpScore: ntrpScore ?? this.ntrpScore,
      mannerScore: mannerScore ?? this.mannerScore,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewer: reviewer ?? this.reviewer,
      reviewedUser: reviewedUser ?? this.reviewedUser,
      matching: matching ?? this.matching,
    );
  }
}
