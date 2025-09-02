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
  final String? fileUrl;
  
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
    this.fileUrl,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  // Socket.io에서 오는 유연한 타입(JSON 문자열 숫자 등)을 안전하게 파싱
  static ChatMessage fromSocketJson(Map<String, dynamic> json) {
    int _toInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    DateTime _toDateTime(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return ChatMessage(
      id: _toInt(json['id'], fallback: DateTime.now().millisecondsSinceEpoch),
      matchingId: _toInt(json['matchingId']),
      senderId: _toInt(json['senderId']),
      senderName: (json['senderName'] ?? '') as String,
      message: (json['message'] ?? json['content'] ?? '') as String,
      createdAt: _toDateTime(json['createdAt'] ?? json['timestamp']),
      messageType: (json['messageType'] ?? json['type'] ?? 'text') as String,
      status: (json['status'] ?? 'sent') as String,
      imageUrl: json['imageUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      latitude: json['latitude'] is String
          ? double.tryParse(json['latitude'])
          : (json['latitude'] as num?)?.toDouble(),
      longitude: json['longitude'] is String
          ? double.tryParse(json['longitude'])
          : (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'] as String?,
    );
  }

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
    int? id,
    int? matchingId,
    int? senderId,
    String? senderName,
    String? message,
    DateTime? createdAt,
    String? messageType,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? imageUrl,
    String? fileUrl,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      matchingId: matchingId ?? this.matchingId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }
} 