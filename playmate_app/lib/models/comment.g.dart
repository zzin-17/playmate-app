// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: (json['id'] as num).toInt(),
  postId: (json['postId'] as num).toInt(),
  authorId: (json['authorId'] as num).toInt(),
  authorNickname: json['authorNickname'] as String,
  authorProfileImage: json['authorProfileImage'] as String?,
  content: json['content'] as String,
  parentCommentId: (json['parentCommentId'] as num?)?.toInt(),
  replies:
      (json['replies'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  likeCount: (json['likeCount'] as num).toInt(),
  isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'authorId': instance.authorId,
  'authorNickname': instance.authorNickname,
  'authorProfileImage': instance.authorProfileImage,
  'content': instance.content,
  'parentCommentId': instance.parentCommentId,
  'replies': instance.replies,
  'likeCount': instance.likeCount,
  'isLikedByCurrentUser': instance.isLikedByCurrentUser,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
