import 'package:flutter/material.dart';
import '../models/matching.dart';
import '../services/matching_data_service.dart';

class MatchingProvider extends ChangeNotifier {
  List<Matching> _matchings = [];
  bool _isLoading = false;
  String? _error;

  List<Matching> get matchings => _matchings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 매칭 목록 로드
  Future<void> loadMatchings({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final matchings = await MatchingDataService.getMatchings();
      _matchings = matchings;
      _error = null;
      print('🔄 Provider: ${_matchings.length}개 매칭 로드 완료');
    } catch (e) {
      _error = e.toString();
      print('❌ Provider: 매칭 로드 실패 - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 새 매칭 추가 (생성 후 즉시 UI 업데이트)
  void addMatching(Matching newMatching) {
    _matchings.insert(0, newMatching); // 최신 매칭을 맨 앞에 추가
    notifyListeners();
    print('✅ Provider: 새 매칭 추가됨 - ${newMatching.courtName}');
  }

  // 매칭 업데이트
  void updateMatching(Matching updatedMatching) {
    final index = _matchings.indexWhere((m) => m.id == updatedMatching.id);
    if (index != -1) {
      _matchings[index] = updatedMatching;
      notifyListeners();
      print('🔄 Provider: 매칭 업데이트됨 - ${updatedMatching.courtName}');
    }
  }

  // 매칭 삭제
  void removeMatching(int matchingId) {
    _matchings.removeWhere((m) => m.id == matchingId);
    notifyListeners();
    print('🗑️ Provider: 매칭 삭제됨 - ID: $matchingId');
  }

  // 매칭 상태 변경
  void updateMatchingStatus(int matchingId, String status) {
    final index = _matchings.indexWhere((m) => m.id == matchingId);
    if (index != -1) {
      final updatedMatching = _matchings[index].copyWith(status: status);
      _matchings[index] = updatedMatching;
      notifyListeners();
      print('🔄 Provider: 매칭 상태 변경됨 - ID: $matchingId, Status: $status');
    }
  }

  // 필터링된 매칭 반환 (deleted 제외)
  List<Matching> getFilteredMatchings() {
    return _matchings.where((matching) => matching.actualStatus != 'deleted').toList();
  }

  // 실시간 새로고침 (WebSocket 이벤트용)
  Future<void> refreshFromServer() async {
    await loadMatchings(forceRefresh: true);
  }
}
