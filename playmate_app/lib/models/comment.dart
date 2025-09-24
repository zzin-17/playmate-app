import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  final int id;
  final int postId;
  final int authorId;
  final String authorNickname;
  final String? authorProfileImage;
  final String content;
  final int? parentCommentId; // 답글인 경우 부모 댓글 ID
  final List<Comment> replies; // 답글 목록
  final int likeCount;
  @JsonKey(name: 'isLiked') // 백엔드에서 isLiked로 보내므로 매핑
  final bool isLikedByCurrentUser;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorNickname,
    this.authorProfileImage,
    required this.content,
    this.parentCommentId,
    this.replies = const [],
    required this.likeCount,
    required this.isLikedByCurrentUser,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  // 답글인지 확인
  bool get isReply => parentCommentId != null;

  // 시간 경과 텍스트
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

  // 댓글 복사본 생성 (좋아요 상태 변경용)
  Comment copyWith({
    int? id,
    int? postId,
    int? authorId,
    String? authorNickname,
    String? authorProfileImage,
    String? content,
    int? parentCommentId,
    List<Comment>? replies,
    int? likeCount,
    bool? isLikedByCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      authorProfileImage: authorProfileImage ?? this.authorProfileImage,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
      likeCount: likeCount ?? this.likeCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
