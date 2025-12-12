import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

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

  // 인증 토큰 가져오기
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      return null;
    }
  }

  // 매칭 확정
  Future<bool> confirmMatching(int matchingId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print('매칭 확정 실패: 인증 토큰이 없습니다.');
        }
        return false;
      }

      // 실제 API 호출
      final response = await ApiService.confirmMatching(matchingId, token);
      
      if (response['success'] == true) {
        // 상태 변경
        setMatchingStatus(matchingId, 'confirmed');
        
        if (kDebugMode) {
          print('매칭 확정 완료: $matchingId');
        }
        
        return true;
      } else {
        throw Exception(response['message'] ?? '매칭 확정 실패');
      }
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
      final token = await _getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print('매칭 확정 취소 실패: 인증 토큰이 없습니다.');
        }
        return false;
      }

      // 실제 API 호출
      final response = await ApiService.cancelMatchingConfirmation(matchingId, token);
      
      if (response['success'] == true) {
        // 상태 변경
        setMatchingStatus(matchingId, 'recruiting');
        
        if (kDebugMode) {
          print('매칭 확정 취소 완료: $matchingId');
        }
        
        return true;
      } else {
        throw Exception(response['message'] ?? '매칭 확정 취소 실패');
      }
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
      final token = await _getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print('매칭 완료 실패: 인증 토큰이 없습니다.');
        }
        return false;
      }

      // 실제 API 호출
      final response = await ApiService.completeMatching(matchingId, token);
      
      if (response['success'] == true) {
        // 상태 변경
        setMatchingStatus(matchingId, 'completed');
        
        if (kDebugMode) {
          print('매칭 완료: $matchingId');
        }
        
        return true;
      } else {
        throw Exception(response['message'] ?? '매칭 완료 실패');
      }
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
      final token = await _getAuthToken();
      if (token == null) {
        if (kDebugMode) {
          print('매칭 취소 실패: 인증 토큰이 없습니다.');
        }
        return false;
      }

      // 실제 API 호출
      final response = await ApiService.cancelMatching(matchingId, token);
      
      if (response['success'] == true) {
        // 상태 변경
        setMatchingStatus(matchingId, 'cancelled');
        
        if (kDebugMode) {
          print('매칭 취소 완료: $matchingId');
        }
        
        return true;
      } else {
        throw Exception(response['message'] ?? '매칭 취소 실패');
      }
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
