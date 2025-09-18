import 'package:shared_preferences/shared_preferences.dart';
import '../models/matching.dart';
import 'api_service.dart';

class MatchingDataService {
  // 매칭 목록 가져오기 (재시도 로직 포함)
  static Future<List<Matching>> getMatchings({
    String? searchQuery,
    List<String>? gameTypes,
    String? skillLevel,
    String? endSkillLevel,
    List<String>? ageRanges,
    bool? noAgeRestriction,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? cityId,
    List<String>? districtIds,
    bool? showOnlyRecruiting,
    bool? showOnlyFollowing,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final token = await _getAuthToken();
        
        // 실제 API 호출
        return await ApiService.getMatchings(
          searchQuery: searchQuery,
          gameTypes: gameTypes,
          skillLevel: skillLevel,
          endSkillLevel: endSkillLevel,
          minAge: ageRanges?.isNotEmpty == true ? ageRanges!.first : null,
          maxAge: ageRanges?.isNotEmpty == true ? ageRanges!.last : null,
          startDate: startDate,
          endDate: endDate,
          startTime: startTime,
          endTime: endTime,
          cityId: cityId,
          districtIds: districtIds,
          showOnlyRecruiting: showOnlyRecruiting,
          showOnlyFollowing: showOnlyFollowing,
          token: token,
        );
      } catch (e) {
        retryCount++;
        // 매칭 목록 조회 오류 (시도 $retryCount/$maxRetries): $e
        
        if (retryCount >= maxRetries) {
          // 최대 재시도 횟수 초과, 빈 목록 반환
          // API 실패 시 빈 목록 반환
          return [];
        }
        
        // 재시도 전 대기
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    return [];
  }

  // 매칭 상세 조회
  static Future<Matching?> getMatchingDetail(int matchingId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      
      return await ApiService.getMatchingDetail(matchingId, token);
    } catch (e) {
      print('매칭 상세 조회 오류: $e');
      return null;
    }
  }

  // 매칭 생성
  static Future<Matching?> createMatching(Map<String, dynamic> matchingData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      return await ApiService.createMatching(matchingData, token);
    } catch (e) {
      print('매칭 생성 오류: $e');
      return null;
    }
  }


  // 매칭 상태 변경
  static Future<Matching?> updateMatchingStatus(int matchingId, String status) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      return await ApiService.updateMatchingStatus(matchingId, status, token);
    } catch (e) {
      print('매칭 상태 변경 오류: $e');
      return null;
    }
  }

  // 매칭 요청
  static Future<bool> requestMatching(int matchingId, String message) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      await ApiService.requestMatching(matchingId, message, token);
      return true;
    } catch (e) {
      print('매칭 요청 오류: $e');
      return false;
    }
  }

  // 매칭 응답
  static Future<bool> respondToMatching({
    required int matchingId,
    required int requestUserId,
    required String action,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      await ApiService.respondToMatching(
        matchingId: matchingId,
        requestUserId: requestUserId,
        action: action,
        token: token,
      );
      return true;
    } catch (e) {
      print('매칭 응답 오류: $e');
      return false;
    }
  }

  // 내 매칭 목록 조회
  static Future<List<Matching>> getMyMatchings() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];
      
      return await ApiService.getMyMatchings(token);
    } catch (e) {
      print('내 매칭 목록 조회 오류: $e');
      return [];
    }
  }

  // 매칭 수정
  static Future<bool> updateMatching(int matchingId, Map<String, dynamic> matchingData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      await ApiService.updateMatching(matchingId, matchingData, token);
      return true;
    } catch (e) {
      print('매칭 수정 오류: $e');
      return false;
    }
  }

  // 매칭 삭제
  static Future<bool> deleteMatching(int matchingId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      await ApiService.deleteMatching(matchingId, token);
      return true;
    } catch (e) {
      print('매칭 삭제 오류: $e');
      return false;
    }
  }

  // 인증 토큰 가져오기
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('playmate_auth_token');
      
      if (token == null) return null;
      
      return token;
    } catch (e) {
      print('토큰 가져오기 오류: $e');
      return null;
    }
  }

}
