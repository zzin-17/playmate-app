import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../utils/logger.dart';

// 배치 요청 타입
enum BatchRequestType {
  loadPosts,
  loadChatRooms, 
  loadNotifications,
  loadReviews,
  syncProfile,
}

// 배치 요청 데이터
class BatchRequest {
  final BatchRequestType type;
  final Map<String, dynamic> params;
  final Completer<dynamic> completer;
  final DateTime createdAt;

  BatchRequest({
    required this.type,
    required this.params,
    required this.completer,
    required this.createdAt,
  });
}

/**
 * 배치 처리 서비스 (나중을 위한 준비)
 * 십만 건 이상 대량 데이터 환경에서 효율적인 업데이트를 위한 시스템
 */
class BatchUpdateService {
  static final BatchUpdateService _instance = BatchUpdateService._internal();
  factory BatchUpdateService() => _instance;
  BatchUpdateService._internal();

  // 배치 처리 설정
  static const Duration _batchInterval = Duration(seconds: 30); // 30초마다 배치 처리
  static const int _maxBatchSize = 50; // 한 번에 최대 50개 요청
  
  Timer? _batchTimer;
  final List<BatchRequest> _pendingRequests = [];
  bool _isBatchProcessing = false;

  // 배치 처리 시작
  void startBatchProcessing() {
    if (_batchTimer != null) return;
    
    print('🔄 배치 처리 시스템 시작 (30초 주기)');
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      _processBatch();
    });
  }

  // 배치 처리 중지
  void stopBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = null;
    print('🔄 배치 처리 시스템 중지');
  }

  // 배치 요청 추가
  Future<T> addToBatch<T>(BatchRequestType type, Map<String, dynamic> params) async {
    final completer = Completer<T>();
    final request = BatchRequest(
      type: type,
      params: params,
      completer: completer,
      createdAt: DateTime.now(),
    );

    _pendingRequests.add(request);
    
    // 배치가 가득 찬 경우 즉시 처리
    if (_pendingRequests.length >= _maxBatchSize) {
      _processBatch();
    }

    return completer.future;
  }

  // 배치 처리 실행
  Future<void> _processBatch() async {
    if (_isBatchProcessing || _pendingRequests.isEmpty) return;

    _isBatchProcessing = true;
    print('🔄 배치 처리 시작 - ${_pendingRequests.length}개 요청');

    try {
      // 요청 타입별로 그룹화
      final groupedRequests = <BatchRequestType, List<BatchRequest>>{};
      for (final request in _pendingRequests) {
        groupedRequests.putIfAbsent(request.type, () => []).add(request);
      }

      // 각 타입별로 병렬 처리
      final futures = <Future>[];
      
      for (final entry in groupedRequests.entries) {
        futures.add(_processRequestGroup(entry.key, entry.value));
      }

      // 모든 요청 병렬 실행
      await Future.wait(futures);

      // 처리 완료된 요청들 제거
      _pendingRequests.clear();
      
      print('🔄 배치 처리 완료');
    } catch (e) {
      print('배치 처리 오류: $e');
    } finally {
      _isBatchProcessing = false;
    }
  }

  // 요청 그룹별 처리
  Future<void> _processRequestGroup(BatchRequestType type, List<BatchRequest> requests) async {
    try {
      switch (type) {
        case BatchRequestType.loadPosts:
          await _batchLoadPosts(requests);
          break;
        case BatchRequestType.loadChatRooms:
          await _batchLoadChatRooms(requests);
          break;
        case BatchRequestType.loadNotifications:
          await _batchLoadNotifications(requests);
          break;
        case BatchRequestType.loadReviews:
          await _batchLoadReviews(requests);
          break;
        case BatchRequestType.syncProfile:
          await _batchSyncProfiles(requests);
          break;
      }
    } catch (e) {
      // 그룹 처리 실패 시 모든 요청에 오류 전파
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
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

  // 게시글 배치 로드
  Future<void> _batchLoadPosts(List<BatchRequest> requests) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 모든 요청에서 userIds 수집
      final userIds = <int>{};
      for (final request in requests) {
        final userId = request.params['userId'] as int?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      if (userIds.isEmpty) {
        // userIds가 없으면 빈 결과 반환
        for (final request in requests) {
          if (!request.completer.isCompleted) {
            request.completer.complete([]);
          }
        }
        return;
      }

      // 배치 API 호출
      final limit = requests.first.params['limit'] as int? ?? 20;
      final offset = requests.first.params['offset'] as int? ?? 0;
      
      final results = await ApiService.batchLoadPosts(
        userIds: userIds.toList(),
        limit: limit,
        offset: offset,
        token: token,
      );

      // 모든 요청에 동일한 결과 반환 (실제로는 요청별로 필터링 필요)
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          final userId = request.params['userId'] as int?;
          if (userId != null) {
            // 특정 사용자의 게시글만 필터링
            final filteredResults = results.where((post) => 
              post['userId'] == userId
            ).toList();
            request.completer.complete(filteredResults);
          } else {
            request.completer.complete(results);
          }
        }
      }
    } catch (e) {
      Logger.error('배치 게시글 로드 실패', tag: 'BatchUpdateService', error: e);
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    }
  }

  // 채팅방 배치 로드
  Future<void> _batchLoadChatRooms(List<BatchRequest> requests) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 모든 요청에서 userIds 수집
      final userIds = <int>{};
      for (final request in requests) {
        final userId = request.params['userId'] as int?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      if (userIds.isEmpty) {
        for (final request in requests) {
          if (!request.completer.isCompleted) {
            request.completer.complete([]);
          }
        }
        return;
      }

      // 배치 API 호출
      final results = await ApiService.batchLoadChatRooms(
        userIds: userIds.toList(),
        token: token,
      );

      // 각 요청에 해당하는 채팅방 필터링
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          final userId = request.params['userId'] as int?;
          if (userId != null) {
            // 특정 사용자가 참여한 채팅방만 필터링
            final filteredResults = results.where((room) {
              final participants = room['participants'] as List<dynamic>?;
              return participants != null && participants.contains(userId);
            }).toList();
            request.completer.complete(filteredResults);
          } else {
            request.completer.complete(results);
          }
        }
      }
    } catch (e) {
      Logger.error('배치 채팅방 로드 실패', tag: 'BatchUpdateService', error: e);
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    }
  }

  // 알림 배치 로드
  Future<void> _batchLoadNotifications(List<BatchRequest> requests) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 모든 요청에서 userIds 수집
      final userIds = <int>{};
      for (final request in requests) {
        final userId = request.params['userId'] as int?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      if (userIds.isEmpty) {
        for (final request in requests) {
          if (!request.completer.isCompleted) {
            request.completer.complete([]);
          }
        }
        return;
      }

      // 배치 API 호출
      final limit = requests.first.params['limit'] as int? ?? 50;
      final offset = requests.first.params['offset'] as int? ?? 0;
      
      final results = await ApiService.batchLoadNotifications(
        userIds: userIds.toList(),
        limit: limit,
        offset: offset,
        token: token,
      );

      // 모든 요청에 결과 반환
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.complete(results);
        }
      }
    } catch (e) {
      Logger.error('배치 알림 로드 실패', tag: 'BatchUpdateService', error: e);
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    }
  }

  // 후기 배치 로드
  Future<void> _batchLoadReviews(List<BatchRequest> requests) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 모든 요청에서 userIds 수집
      final userIds = <int>{};
      for (final request in requests) {
        final userId = request.params['userId'] as int?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      if (userIds.isEmpty) {
        for (final request in requests) {
          if (!request.completer.isCompleted) {
            request.completer.complete([]);
          }
        }
        return;
      }

      // 배치 API 호출
      final limit = requests.first.params['limit'] as int? ?? 20;
      final offset = requests.first.params['offset'] as int? ?? 0;
      
      final results = await ApiService.batchLoadReviews(
        userIds: userIds.toList(),
        limit: limit,
        offset: offset,
        token: token,
      );

      // 각 요청에 해당하는 후기 필터링
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          final userId = request.params['userId'] as int?;
          if (userId != null) {
            // 특정 사용자에 대한 후기만 필터링
            final filteredResults = results.where((review) => 
              review['targetUserId'] == userId
            ).toList();
            request.completer.complete(filteredResults);
          } else {
            request.completer.complete(results);
          }
        }
      }
    } catch (e) {
      Logger.error('배치 후기 로드 실패', tag: 'BatchUpdateService', error: e);
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    }
  }

  // 프로필 배치 동기화
  Future<void> _batchSyncProfiles(List<BatchRequest> requests) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 모든 요청에서 userIds 수집
      final userIds = <int>{};
      for (final request in requests) {
        final userId = request.params['userId'] as int?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      if (userIds.isEmpty) {
        for (final request in requests) {
          if (!request.completer.isCompleted) {
            request.completer.complete(null);
          }
        }
        return;
      }

      // 배치 API 호출
      final results = await ApiService.batchSyncProfiles(
        userIds: userIds.toList(),
        token: token,
      );

      // 각 요청에 해당하는 프로필 반환
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          final userId = request.params['userId'] as int?;
          if (userId != null) {
            // 특정 사용자의 프로필만 필터링
            final profile = results.firstWhere(
              (profile) => profile['id'] == userId,
              orElse: () => null,
            );
            request.completer.complete(profile);
          } else {
            request.completer.complete(results);
          }
        }
      }
    } catch (e) {
      Logger.error('배치 프로필 동기화 실패', tag: 'BatchUpdateService', error: e);
      for (final request in requests) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    }
  }

  // 배치 처리 통계
  Map<String, dynamic> getBatchStats() {
    return {
      'pendingRequests': _pendingRequests.length,
      'isProcessing': _isBatchProcessing,
      'batchInterval': _batchInterval.inSeconds,
      'maxBatchSize': _maxBatchSize,
    };
  }
}
