import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  final int id;
  final int matchingId;
  final int senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;
  final String messageType; // 'text', 'system'

  ChatMessage({
    required this.id,
    required this.matchingId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.messageType = 'text',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  // 시스템 메시지 생성 헬퍼
  static ChatMessage systemMessage({
    required int matchingId,
    required String message,
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      matchingId: matchingId,
      senderId: 0,
      senderName: '시스템',
      message: message,
      createdAt: createdAt,
      messageType: 'system',
    );
  }
} 