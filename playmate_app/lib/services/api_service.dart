import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/matching.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'https://api.playmate.com'; // 실제 API URL로 변경 필요
  static const Duration timeout = Duration(seconds: 30);
  
  // HTTP 헤더
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // 인증 헤더 (토큰이 있는 경우)
  static Map<String, String> getAuthHeaders(String? token) {
    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  // 매칭 목록 조회
  static Future<List<Matching>> getMatchings({
    String? searchQuery,
    List<String>? gameTypes,
    String? skillLevel,
    String? endSkillLevel,
    String? minAge,
    String? maxAge,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? cityId,
    List<String>? districtIds,
    bool? showOnlyRecruiting,
    bool? showOnlyFollowing,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (gameTypes != null && gameTypes.isNotEmpty) {
        queryParams['game_types'] = gameTypes.join(',');
      }
      if (skillLevel != null) {
        queryParams['skill_level'] = skillLevel;
      }
      if (endSkillLevel != null) {
        queryParams['end_skill_level'] = endSkillLevel;
      }
      if (minAge != null) {
        queryParams['min_age'] = minAge;
      }
      if (maxAge != null) {
        queryParams['max_age'] = maxAge;
      }
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      if (startTime != null) {
        queryParams['start_time'] = startTime;
      }
      if (endTime != null) {
        queryParams['end_time'] = endTime;
      }
      if (cityId != null) {
        queryParams['city_id'] = cityId;
      }
      if (districtIds != null && districtIds.isNotEmpty) {
        queryParams['district_ids'] = districtIds.join(',');
      }
      if (showOnlyRecruiting != null) {
        queryParams['show_only_recruiting'] = showOnlyRecruiting.toString();
      }
      if (showOnlyFollowing != null) {
        queryParams['show_only_following'] = showOnlyFollowing.toString();
      }
      
      final uri = Uri.parse('$baseUrl/api/matchings').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Matching.fromJson(json)).toList();
      } else {
        throw ApiException('매칭 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 매칭 상세 조회
  static Future<Matching> getMatchingDetail(int matchingId, String? token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/matchings/$matchingId');
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Matching.fromJson(data);
      } else {
        throw ApiException('매칭 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 매칭 생성
  static Future<Matching> createMatching(Map<String, dynamic> matchingData, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/matchings');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode(matchingData),
      ).timeout(timeout);
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Matching.fromJson(data);
      } else {
        throw ApiException('매칭 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 매칭 수정
  static Future<Matching> updateMatching(int matchingId, Map<String, dynamic> matchingData, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/matchings/$matchingId');
      
      final response = await http.put(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode(matchingData),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Matching.fromJson(data);
      } else {
        throw ApiException('매칭 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 매칭 상태 변경
  static Future<Matching> updateMatchingStatus(int matchingId, String status, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/matchings/$matchingId/status');
      
      final response = await http.patch(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode({'status': status}),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Matching.fromJson(data);
      } else {
        throw ApiException('매칭 상태 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 사용자 정보 조회
  static Future<User> getUserProfile(String? token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/user/profile');
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw ApiException('사용자 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 위치 정보 조회
  static Future<List<dynamic>> getLocations() async {
    try {
      final uri = Uri.parse('$baseUrl/api/locations');
      
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('위치 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // ===== 인증 관련 API =====
  
  // 로그인
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('로그인 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nickname,
    String? gender,
    int? birthYear,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/register');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'nickname': nickname,
          'gender': gender,
          'birth_year': birthYear,
        }),
      ).timeout(timeout);
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException('회원가입 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 현재 사용자 정보 조회
  static Future<User> getCurrentUser(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/me');
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw ApiException('사용자 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 프로필 업데이트
  static Future<User> updateProfile(Map<String, dynamic> profileData, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/profile');
      
      final response = await http.put(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode(profileData),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw ApiException('프로필 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 비밀번호 재설정 요청
  static Future<void> requestPasswordReset(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/password/reset-request');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({'email': email}),
      ).timeout(timeout);
      
      if (response.statusCode != 200) {
        throw ApiException('비밀번호 재설정 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 비밀번호 재설정
  static Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/password/reset');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'code': code,
          'password': newPassword,
        }),
      ).timeout(timeout);
      
      if (response.statusCode != 200) {
        throw ApiException('비밀번호 재설정 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // ===== 채팅 관련 API =====
  
  // 내 채팅방 목록 조회
  static Future<List<dynamic>> getMyChatRooms(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat/rooms/my');
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('채팅방 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 채팅방 생성
  static Future<void> createChatRoom({
    required int matchingId,
    required int hostId,
    required int guestId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat/rooms');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode({
          'matching_id': matchingId,
          'host_id': hostId,
          'guest_id': guestId,
        }),
      ).timeout(timeout);
      
      if (response.statusCode != 201) {
        throw ApiException('채팅방 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // ===== 매칭 관련 API =====
  
  // 내 매칭 목록 조회
  static Future<List<Matching>> getMyMatchings(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/matchings/my');
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Matching.fromJson(json)).toList();
      } else {
        throw ApiException('내 매칭 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 매칭 요청
  static Future<void> requestMatching(int matchingId, String message, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/matchings/$matchingId/request');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode({'message': message}),
      ).timeout(timeout);
      
      if (response.statusCode != 200) {
        throw ApiException('매칭 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 매칭 응답
  static Future<void> respondToMatching({
    required int matchingId,
    required int requestUserId,
    required String action,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/matchings/$matchingId/respond');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode({
          'request_user_id': requestUserId,
          'action': action,
        }),
      ).timeout(timeout);
      
      if (response.statusCode != 200) {
        throw ApiException('매칭 응답 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
}

// API 예외 클래스
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
} 