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
    };
