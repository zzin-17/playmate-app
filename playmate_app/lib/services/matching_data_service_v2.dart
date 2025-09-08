import '../models/matching.dart';
import '../models/user.dart';
import 'api_service.dart';

class MatchingDataServiceV2 {
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
        print('매칭 목록 조회 오류 (시도 $retryCount/$maxRetries): $e');
        
        if (retryCount >= maxRetries) {
          print('최대 재시도 횟수 초과, Mock 데이터 사용');
          // API 실패 시 Mock 데이터 반환 (오프라인 모드)
          return _createMockMatchings();
        }
        
        // 재시도 전 대기
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    return _createMockMatchings();
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

  // 매칭 수정
  static Future<Matching?> updateMatching(int matchingId, Map<String, dynamic> matchingData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      return await ApiService.updateMatching(matchingId, matchingData, token);
    } catch (e) {
      print('매칭 수정 오류: $e');
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

  // 인증 토큰 가져오기
  static Future<String?> _getAuthToken() async {
    try {
      // 임시로 개발용 토큰 사용 (백엔드에서 temp_jwt_token을 허용하도록 설정됨)
      return 'temp_jwt_token';
      
      // 실제 운영환경에서는 아래 코드 사용
      /*
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) return null;
      
      // 토큰 만료 체크
      final expiresAt = prefs.getString('token_expires_at');
      if (expiresAt != null) {
        final expiryDate = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiryDate)) {
          // 토큰이 만료된 경우 제거
          await prefs.remove('auth_token');
          await prefs.remove('token_expires_at');
          return null;
        }
      }
      
      return token;
      */
    } catch (e) {
      print('토큰 가져오기 오류: $e');
      return null;
    }
  }

  // Mock 데이터 생성 (오프라인 모드용)
  static List<Matching> _createMockMatchings() {
    final now = DateTime.now();
    final List<Matching> matchings = [];

    // 다양한 매칭 데이터 생성
    for (int i = 1; i <= 10; i++) {
      final matching = _createMockMatching(
        id: i,
        courtName: '테니스 코트 $i',
        date: now.add(Duration(days: i % 7)),
        gameType: ['mixed', 'male_doubles', 'female_doubles', 'singles'][i % 4],
        status: ['recruiting', 'confirmed', 'completed', 'cancelled'][i % 4],
      );
      matchings.add(matching);
    }

    return matchings;
  }

  // 개별 Mock 매칭 생성
  static Matching _createMockMatching({
    required int id,
    required String courtName,
    required DateTime date,
    String gameType = 'mixed',
    String status = 'recruiting',
    int maleRecruitCount = 2,
    int femaleRecruitCount = 2,
    int minLevel = 1,
    int maxLevel = 5,
    int? minAge,
    int? maxAge,
    bool isFollowersOnly = false,
  }) {
    final host = User(
      id: id + 1000,
      email: 'host$id@example.com',
      nickname: '호스트$id',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Matching(
      id: id,
      type: 'host',
      courtName: courtName,
      courtLat: 37.5665 + (id * 0.001),
      courtLng: 126.9780 + (id * 0.001),
      date: date,
      timeSlot: '10:00~12:00',
      minLevel: minLevel,
      maxLevel: maxLevel,
      minAge: minAge,
      maxAge: maxAge,
      gameType: gameType,
      maleRecruitCount: maleRecruitCount,
      femaleRecruitCount: femaleRecruitCount,
      status: status,
      isFollowersOnly: isFollowersOnly,
      host: host,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recoveryCount: 0,
    );
  }
}
