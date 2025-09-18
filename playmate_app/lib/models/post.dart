import 'package:json_annotation/json_annotation.dart';
import 'comment.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  final int id;
  final int authorId;
  final String authorNickname;
  final String? authorProfileImage;
  final String content;
  final List<String>? images;
  final String? videoUrl;
  final List<String>? hashtags;
  final String? location;
  final String category; // 'general', 'tennis_tip', 'court_review', 'matching'
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLikedByCurrentUser;
  final bool isBookmarkedByCurrentUser;
  final bool isSharedByCurrentUser; // 현재 사용자가 공유했는지
  final List<Comment>? comments; // 댓글 목록
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    this.authorProfileImage,
    required this.content,
    this.images,
    this.videoUrl,
    this.hashtags,
    this.location,
    required this.category,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isLikedByCurrentUser,
    required this.isBookmarkedByCurrentUser,
    this.isSharedByCurrentUser = false,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  // 카테고리 텍스트 변환
  String get categoryText {
    switch (category) {
      case 'general':
        return '일반';
      case 'tennis_tip':
        return '테니스팁';
      case 'court_review':
        return '코트리뷰';
      case 'matching':
        return '매칭';
      default:
        return '기타';
    }
  }

  // 시간 경과 텍스트 (예: 2시간 전, 1일 전)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  // 해시태그 텍스트 변환
  String get hashtagText {
    if (hashtags == null || hashtags!.isEmpty) return '';
    return hashtags!.map((tag) => '#$tag').join(' ');
  }

  // 이미지 개수에 따른 표시 텍스트
  String get imageCountText {
    if (images == null || images!.isEmpty) return '';
    if (images!.length == 1) return '';
    return '+${images!.length - 1}';
  }
}
