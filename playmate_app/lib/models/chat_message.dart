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
  final String messageType; // 'text', 'system', 'image', 'location'
  
  // 읽음 상태 관련
  final String status; // 'sent', 'delivered', 'read'
  final DateTime? deliveredAt;
  final DateTime? readAt;
  
  // 이미지 메시지 관련
  final String? imageUrl;
  
  // 위치 메시지 관련
  final double? latitude;
  final double? longitude;
  final String? locationName;

  ChatMessage({
    required this.id,
    required this.matchingId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.messageType = 'text',
    this.status = 'sent',
    this.deliveredAt,
    this.readAt,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.locationName,
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
      status: 'read', // 시스템 메시지는 항상 읽음 상태
    );
  }
  
  // 읽음 상태 업데이트 헬퍼
  ChatMessage copyWith({
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id,
      matchingId: matchingId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      createdAt: createdAt,
      messageType: messageType,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );
  }
} 