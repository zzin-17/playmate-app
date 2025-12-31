// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  id: (json['id'] as num).toInt(),
  authorId: (json['authorId'] as num).toInt(),
  authorNickname: json['authorNickname'] as String,
  authorProfileImage: json['authorProfileImage'] as String?,
  content: json['content'] as String,
  images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
  videoUrl: json['videoUrl'] as String?,
  hashtags: (json['hashtags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  location: json['location'] as String?,
  category: json['category'] as String,
  likeCount: (json['likeCount'] as num).toInt(),
  commentCount: (json['commentCount'] as num).toInt(),
  shareCount: (json['shareCount'] as num).toInt(),
  isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool,
  isBookmarkedByCurrentUser: json['isBookmarkedByCurrentUser'] as bool,
  isSharedByCurrentUser: json['isSharedByCurrentUser'] as bool? ?? false,
  comments: (json['comments'] as List<dynamic>?)
      ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'id': instance.id,
  'authorId': instance.authorId,
  'authorNickname': instance.authorNickname,
  'authorProfileImage': instance.authorProfileImage,
  'content': instance.content,
  'images': instance.images,
  'videoUrl': instance.videoUrl,
  'hashtags': instance.hashtags,
  'location': instance.location,
  'category': instance.category,
  'likeCount': instance.likeCount,
  'commentCount': instance.commentCount,
  'shareCount': instance.shareCount,
  'isLikedByCurrentUser': instance.isLikedByCurrentUser,
  'isBookmarkedByCurrentUser': instance.isBookmarkedByCurrentUser,
  'isSharedByCurrentUser': instance.isSharedByCurrentUser,
  'comments': instance.comments,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
