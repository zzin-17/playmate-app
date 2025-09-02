import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';

class ChatLocalStore {
  static const String _roomsKeyPrefix = 'chat_rooms_'; // + userId
  static const String _msgsKeyPrefix = 'chat_msgs_'; // + matchingId

  Future<List<ChatRoom>> loadRooms(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _roomsKeyPrefix + userId.toString();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertRoom(int userId, ChatRoom room) async {
    final rooms = await loadRooms(userId);
    rooms.removeWhere((r) => r.matchingId == room.matchingId && r.partner.id == room.partner.id);
    rooms.add(room);
    rooms.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    final prefs = await SharedPreferences.getInstance();
    final key = _roomsKeyPrefix + userId.toString();
    await prefs.setString(key, jsonEncode(rooms.map((e) => e.toJson()).toList()));
  }

  Future<List<ChatMessage>> loadMessages(int matchingId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _msgsKeyPrefix + matchingId.toString();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> appendMessage(ChatMessage message) async {
    final msgs = await loadMessages(message.matchingId);
    // 중복 방지: 같은 보낸이/내용이고 2초 이내면 같은 메시지로 간주
    final isDup = msgs.any((m) {
      final sameSender = m.senderId == message.senderId;
      final sameText = m.message == message.message;
      final dt = (m.createdAt.difference(message.createdAt)).inMilliseconds.abs();
      return m.id == message.id || (sameSender && sameText && dt < 2000);
    });
    if (!isDup) {
      msgs.add(message);
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _msgsKeyPrefix + message.matchingId.toString();
    await prefs.setString(key, jsonEncode(msgs.map((e) => e.toJson()).toList()));
  }
}


