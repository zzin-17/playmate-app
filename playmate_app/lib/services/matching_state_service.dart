import 'package:flutter/foundation.dart';
import 'matching_notification_service.dart';

class MatchingStateService extends ChangeNotifier {
  static final MatchingStateService _instance = MatchingStateService._internal();
  factory MatchingStateService() => _instance;
  MatchingStateService._internal();

  // 현재 매칭 상태를 저장하는 Map
  final Map<int, String> _matchingStates = {};
  
  // 매칭 상태 변경 리스너들
  final Map<int, List<Function(String)>> _stateChangeListeners = {};

  // 매칭 상태 가져오기
  String getMatchingStatus(int matchingId) {
    return _matchingStates[matchingId] ?? 'recruiting';
  }

  // 매칭 상태 설정
  void setMatchingStatus(int matchingId, String status) {
    final oldStatus = _matchingStates[matchingId];
    _matchingStates[matchingId] = status;
    
    // 상태가 변경된 경우에만 알림
    if (oldStatus != status) {
      _notifyStateChange(matchingId, status);
      if (kDebugMode) {
        print('매칭 상태 변경: ID $matchingId, $oldStatus → $status');
      }
    }
  }

  // 매칭 상태 변경 리스너 등록
  void addStateChangeListener(int matchingId, Function(String) listener) {
    if (!_stateChangeListeners.containsKey(matchingId)) {
      _stateChangeListeners[matchingId] = [];
    }
    _stateChangeListeners[matchingId]!.add(listener);
  }

  // 매칭 상태 변경 리스너 제거
  void removeStateChangeListener(int matchingId, Function(String) listener) {
    if (_stateChangeListeners.containsKey(matchingId)) {
      _stateChangeListeners[matchingId]!.remove(listener);
    }
  }

  // 상태 변경 알림
  void _notifyStateChange(int matchingId, String newStatus) {
    if (_stateChangeListeners.containsKey(matchingId)) {
      for (final listener in _stateChangeListeners[matchingId]!) {
        try {
          listener(newStatus);
        } catch (e) {
          if (kDebugMode) {
            print('상태 변경 리스너 오류: $e');
          }
        }
      }
    }
  }

  // 매칭 확정
  Future<bool> confirmMatching(int matchingId) async {
    try {
      // TODO: 실제 API 호출로 매칭 확정 처리
      await Future.delayed(const Duration(milliseconds: 500)); // API 호출 시뮬레이션
      
      // 상태 변경
      setMatchingStatus(matchingId, 'confirmed');
      
      // 매칭 확정 알림 생성
      final notificationService = MatchingNotificationService();
      // TODO: 실제 매칭과 호스트 정보를 가져와서 알림 생성
      // 현재는 테스트용으로 임시 알림 생성
      notificationService.createSampleNotifications();
      
      if (kDebugMode) {
        print('매칭 확정 완료 및 알림 생성: $matchingId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('매칭 확정 실패: $e');
      }
      return false;
    }
  }

  // 매칭 확정 취소
  Future<bool> cancelMatchingConfirmation(int matchingId) async {
    try {
      // TODO: 실제 API 호출로 매칭 확정 취소 처리
      await Future.delayed(const Duration(milliseconds: 500)); // API 호출 시뮬레이션
      
      // 상태 변경
      setMatchingStatus(matchingId, 'recruiting');
      
      // 매칭 취소 알림 생성
      final notificationService = MatchingNotificationService();
      // TODO: 실제 매칭과 호스트 정보를 가져와서 알림 생성
      // 현재는 테스트용으로 임시 알림 생성
      notificationService.createSampleNotifications();
      
      if (kDebugMode) {
        print('매칭 확정 취소 완료 및 알림 생성: $matchingId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('매칭 확정 취소 실패: $e');
      }
      return false;
    }
  }

  // 매칭 완료
  Future<bool> completeMatching(int matchingId) async {
    try {
      // TODO: 실제 API 호출로 매칭 완료 처리
      await Future.delayed(const Duration(milliseconds: 500)); // API 호출 시뮬레이션
      
      // 상태 변경
      setMatchingStatus(matchingId, 'completed');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('매칭 완료 실패: $e');
      }
      return false;
    }
  }

  // 매칭 취소
  Future<bool> cancelMatching(int matchingId) async {
    try {
      // TODO: 실제 API 호출로 매칭 취소 처리
      await Future.delayed(const Duration(milliseconds: 500)); // API 호출 시뮬레이션
      
      // 상태 변경
      setMatchingStatus(matchingId, 'cancelled');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('매칭 취소 실패: $e');
      }
      return false;
    }
  }

  // 초기 상태 설정
  void initializeMatchingState(int matchingId, String status) {
    if (!_matchingStates.containsKey(matchingId)) {
      _matchingStates[matchingId] = status;
    }
  }

  // 모든 상태 초기화
  void clearAllStates() {
    _matchingStates.clear();
    _stateChangeListeners.clear();
  }
}
