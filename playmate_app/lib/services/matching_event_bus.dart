import 'dart:async';
import '../models/matching.dart';

/// 매칭 관련 전역 이벤트 버스
/// 매칭 생성, 업데이트, 삭제 등의 이벤트를 전역적으로 전파
class MatchingEventBus {
  MatchingEventBus._();
  static final MatchingEventBus instance = MatchingEventBus._();

  final StreamController<MatchingEvent> _controller = StreamController<MatchingEvent>.broadcast();

  Stream<MatchingEvent> get stream => _controller.stream;

  void emit(MatchingEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// 매칭 이벤트 기본 클래스
abstract class MatchingEvent {}

/// 매칭 생성 이벤트
class MatchingCreated extends MatchingEvent {
  final Matching matching;
  MatchingCreated(this.matching);
}

/// 매칭 업데이트 이벤트
class MatchingUpdated extends MatchingEvent {
  final Matching matching;
  MatchingUpdated(this.matching);
}

/// 매칭 삭제 이벤트
class MatchingDeleted extends MatchingEvent {
  final int matchingId;
  MatchingDeleted(this.matchingId);
}

/// 매칭 상태 변경 이벤트
class MatchingStatusChanged extends MatchingEvent {
  final int matchingId;
  final String oldStatus;
  final String newStatus;
  MatchingStatusChanged({
    required this.matchingId,
    required this.oldStatus,
    required this.newStatus,
  });
}

/// 매칭 새로고침 요청 이벤트
class MatchingRefreshRequested extends MatchingEvent {
  MatchingRefreshRequested();
}





