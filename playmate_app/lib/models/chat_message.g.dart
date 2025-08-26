// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: (json['id'] as num).toInt(),
  matchingId: (json['matchingId'] as num).toInt(),
  senderId: (json['senderId'] as num).toInt(),
  senderName: json['senderName'] as String,
  message: json['message'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  messageType: json['messageType'] as String? ?? 'text',
  status: json['status'] as String? ?? 'sent',
  deliveredAt: json['deliveredAt'] == null
      ? null
      : DateTime.parse(json['deliveredAt'] as String),
  readAt: json['readAt'] == null
      ? null
      : DateTime.parse(json['readAt'] as String),
  imageUrl: json['imageUrl'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  locationName: json['locationName'] as String?,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matchingId': instance.matchingId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
      'messageType': instance.messageType,
      'status': instance.status,
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'locationName': instance.locationName,
    };
