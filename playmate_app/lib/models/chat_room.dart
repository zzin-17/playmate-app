import 'user.dart';

class ChatRoom {
  final int matchingId;
  final String courtName;
  final DateTime date;
  final String timeSlot;
  final String myRole; // 'host' | 'guest'
  final User partner;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String status; // recruiting | confirmed | completed | cancelled

  ChatRoom({
    required this.matchingId,
    required this.courtName,
    required this.date,
    required this.timeSlot,
    required this.myRole,
    required this.partner,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.status,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      matchingId: json['matchingId'] as int,
      courtName: json['courtName'] as String,
      date: DateTime.parse(json['date'] as String),
      timeSlot: json['timeSlot'] as String,
      myRole: json['myRole'] as String,
      partner: User.fromJson(json['partner'] as Map<String, dynamic>),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchingId': matchingId,
      'courtName': courtName,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'myRole': myRole,
      'partner': partner.toJson(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'unreadCount': unreadCount,
      'status': status,
    };
  }
}


