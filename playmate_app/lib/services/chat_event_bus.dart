import 'dart:async';

// 채팅 관련 전역 이벤트 버스
class ChatEventBus {
  ChatEventBus._();
  static final ChatEventBus instance = ChatEventBus._();

  final StreamController<ChatEvent> _controller = StreamController<ChatEvent>.broadcast();

  Stream<ChatEvent> get stream => _controller.stream;

  void emit(ChatEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

abstract class ChatEvent {}

class ChatRoomCreated extends ChatEvent {
  final int matchingId;
  ChatRoomCreated(this.matchingId);
}

class ChatMessageArrived extends ChatEvent {
  final int matchingId;
  final DateTime timestamp;
  ChatMessageArrived({required this.matchingId, required this.timestamp});
}

class ChatMessageRead extends ChatEvent {
  final int matchingId;
  final int userId;
  final DateTime timestamp;
  ChatMessageRead({
    required this.matchingId,
    required this.userId,
    required this.timestamp,
  });
}


