import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/matching.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.fullBaseUrl;
  static const Duration timeout = ApiConfig.timeout;
  
  // HTTP 헤더
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'PlayMate-Mobile/1.0.0',
  };
  
  // API 로깅
  static void _logRequest(String method, String url, Map<String, String>? headers, String? body) {
    if (ApiConfig.enableApiLogging) {
      print('🌐 API Request: $method $url');
      if (headers != null) {
        print('📋 Headers: $headers');
      }
      if (body != null) {
        print('📦 Body: $body');
      }
    }
  }
  
  static void _logResponse(String method, String url, int statusCode, String? body) {
    if (ApiConfig.enableApiLogging) {
      print('📡 API Response: $method $url -> $statusCode');
      if (body != null) {
        print('📦 Response Body: $body');
      }
    }
  }
  
  // 재시도 로직
  static Future<http.Response> _retryRequest(Future<http.Response> Function() request) async {
    int attempts = 0;
    while (attempts < ApiConfig.maxRetries) {
      try {
        final response = await request();
        if (response.statusCode < 500) {
          return response; // 4xx 오류는 재시도하지 않음
        }
        attempts++;
        if (attempts < ApiConfig.maxRetries) {
          await Future.delayed(ApiConfig.retryDelay * attempts);
        }
      } catch (e) {
        attempts++;
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
        await Future.delayed(ApiConfig.retryDelay * attempts);
      }
    }
    throw ApiException('최대 재시도 횟수 초과');
  }
  
  // 인증 헤더 (토큰이 있는 경우)
  static Map<String, String> getAuthHeaders(String? token) {
    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 인증 헤더 (토큰이 있는 경우) - private 버전
  static Map<String, String> _getAuthHeaders(String token) {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // HTTP 요청 실행
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = headers ?? _headers;
    
    _logRequest(method, uri.toString(), requestHeaders, body);
    
    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _retryRequest(() => http.get(uri, headers: requestHeaders));
        break;
      case 'POST':
        response = await _retryRequest(() => http.post(uri, headers: requestHeaders, body: body));
        break;
      case 'PUT':
        response = await _retryRequest(() => http.put(uri, headers: requestHeaders, body: body));
        break;
      case 'DELETE':
        response = await _retryRequest(() => http.delete(uri, headers: requestHeaders));
        break;
      default:
        throw ApiException('지원하지 않는 HTTP 메서드: $method');
    }
    
    _logResponse(method, uri.toString(), response.statusCode, response.body);
    
    if (response.statusCode >= 400) {
      throw ApiException('HTTP ${response.statusCode}: ${response.body}');
    }
    
    return response;
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
      
      final uri = Uri.parse('$baseUrl/matchings').replace(queryParameters: queryParams);
      
      _logRequest('GET', uri.toString(), getAuthHeaders(token), null);
      
      final response = await _retryRequest(() => http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout));
      
      _logResponse('GET', uri.toString(), response.statusCode, response.body);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // 백엔드 응답 구조에 맞게 데이터 추출
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          return data.map((json) => Matching.fromJson(json)).toList();
        } else {
          throw ApiException('매칭 목록 조회 실패: ${responseData['message'] ?? 'Unknown error'}');
        }
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
      final uri = Uri.parse('$baseUrl/matchings/$matchingId');
      
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
      final uri = Uri.parse('$baseUrl/matchings');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode(matchingData),
      ).timeout(timeout);
      
      if (response.statusCode == 201) {
        final responseBody = response.body;
        print('매칭 생성 API 응답: $responseBody');
        
        final responseData = json.decode(responseBody);
        print('파싱된 응답 데이터: $responseData');
        
        // 백엔드 응답 구조에 맞게 데이터 추출
        if (responseData['success'] == true && responseData['data'] != null) {
          final matchingData = responseData['data'];
          print('매칭 데이터: $matchingData');
          
          try {
            final matching = Matching.fromJson(matchingData);
            print('매칭 객체 생성 성공: ${matching.courtName}');
            return matching;
          } catch (e) {
            print('매칭 객체 생성 실패: $e');
            throw ApiException('매칭 데이터 변환 실패: $e');
          }
        } else {
          throw ApiException('매칭 생성 실패: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw ApiException('매칭 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  
  // 매칭 상태 변경
  static Future<Matching> updateMatchingStatus(int matchingId, String status, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/matchings/$matchingId/status');
      
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
      final uri = Uri.parse('$baseUrl/user/profile');
      
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
      final uri = Uri.parse('$baseUrl/locations');
      
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
      final uri = Uri.parse('$baseUrl/auth/login');
      
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
      final uri = Uri.parse('$baseUrl/auth/register');
      
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
      final uri = Uri.parse('$baseUrl/auth/me');
      
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
      final uri = Uri.parse('$baseUrl/auth/profile');
      
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
      final uri = Uri.parse('$baseUrl/auth/password/reset-request');
      
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
      final uri = Uri.parse('$baseUrl/auth/password/reset');
      
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
  
  // ===== 기본 HTTP 메서드들 =====
  
  // GET 요청
  static Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri, headers: headers).timeout(timeout);
      _logRequest('GET', uri.toString(), headers, null);
      _logResponse('GET', uri.toString(), response.statusCode, response.body);
      return response;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // POST 요청
  static Future<http.Response> post(String endpoint, {
    String? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        body: body,
        headers: headers,
      ).timeout(timeout);
      _logRequest('POST', uri.toString(), headers, body);
      _logResponse('POST', uri.toString(), response.statusCode, response.body);
      return response;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // PUT 요청
  static Future<http.Response> put(String endpoint, {
    String? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        uri,
        body: body,
        headers: headers,
      ).timeout(timeout);
      _logRequest('PUT', uri.toString(), headers, body);
      _logResponse('PUT', uri.toString(), response.statusCode, response.body);
      return response;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // DELETE 요청
  static Future<http.Response> delete(String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(uri, headers: headers).timeout(timeout);
      _logRequest('DELETE', uri.toString(), headers, null);
      _logResponse('DELETE', uri.toString(), response.statusCode, response.body);
      return response;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }

  // ===== 채팅 관련 API =====
  
  // 내 채팅방 목록 조회
  static Future<List<dynamic>> getMyChatRooms(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/rooms/my');
      
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
      final uri = Uri.parse('$baseUrl/chat/rooms');
      
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
  
  // 채팅 메시지 조회
  static Future<List<dynamic>> getChatMessages({
    required int roomId,
    required String token,
    int? lastMessageId,
    int limit = 50,
  }) async {
    try {
      String url = '$baseUrl/chat/rooms/$roomId/messages?limit=$limit';
      if (lastMessageId != null) {
        url += '&last_message_id=$lastMessageId';
      }
      
      final uri = Uri.parse(url);
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('채팅 메시지 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 메시지 전송
  static Future<Map<String, dynamic>> sendMessage({
    required int roomId,
    required String content,
    required String token,
    String? messageType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/rooms/$roomId/messages');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode({
          'content': content,
          'message_type': messageType ?? 'text',
        }),
      ).timeout(timeout);
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw ApiException('메시지 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 채팅방 참여자 조회
  static Future<List<dynamic>> getChatRoomMembers({
    required int roomId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/rooms/$roomId/members');
      
      final response = await http.get(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('채팅방 참여자 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 채팅방 나가기
  static Future<void> leaveChatRoom({
    required int roomId,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/rooms/$roomId/leave');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
      ).timeout(timeout);
      
      if (response.statusCode != 200) {
        throw ApiException('채팅방 나가기 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('네트워크 오류: $e');
    }
  }
  
  // 메시지 읽음 처리
  static Future<void> markMessagesAsRead({
    required int roomId,
    required String token,
    int? lastReadMessageId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/rooms/$roomId/read');
      
      final response = await http.post(
        uri,
        headers: getAuthHeaders(token),
        body: json.encode({
          if (lastReadMessageId != null) 'last_read_message_id': lastReadMessageId,
        }),
      ).timeout(timeout);
      
      if (response.statusCode != 200) {
        throw ApiException('메시지 읽음 처리 실패: ${response.statusCode}');
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
      final uri = Uri.parse('$baseUrl/matchings/my');
      
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
      final uri = Uri.parse('$baseUrl/matchings/$matchingId/request');
      
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
      final uri = Uri.parse('$baseUrl/matchings/$matchingId/respond');
      
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

  // ==================== 후기 관련 API ====================
  
  // 내 후기 목록 조회
  static Future<List<Review>> getMyReviews(String token) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/reviews/my',
        headers: _getAuthHeaders(token),
      );
      
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw ApiException('내 후기 목록 조회 실패: $e');
    }
  }

  // 후기 작성
  static Future<void> createReview(Map<String, dynamic> reviewData, String token) async {
    try {
      await _makeRequest(
        'POST',
        '/reviews',
        headers: _getAuthHeaders(token),
        body: json.encode(reviewData),
      );
    } catch (e) {
      throw ApiException('후기 작성 실패: $e');
    }
  }

  // 후기 수정
  static Future<void> updateReview(int reviewId, Map<String, dynamic> reviewData, String token) async {
    try {
      await _makeRequest(
        'PUT',
        '/reviews/$reviewId',
        headers: _getAuthHeaders(token),
        body: json.encode(reviewData),
      );
    } catch (e) {
      throw ApiException('후기 수정 실패: $e');
    }
  }

  // 후기 삭제
  static Future<void> deleteReview(int reviewId, String token) async {
    try {
      await _makeRequest(
        'DELETE',
        '/reviews/$reviewId',
        headers: _getAuthHeaders(token),
      );
    } catch (e) {
      throw ApiException('후기 삭제 실패: $e');
    }
  }

  // 특정 사용자의 후기 목록 조회
  static Future<List<Review>> getUserReviews(int userId, String token) async {
    try {
      final response = await _makeRequest(
        'GET',
        '/reviews/user/$userId',
        headers: _getAuthHeaders(token),
      );
      
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw ApiException('사용자 후기 목록 조회 실패: $e');
    }
  }

  // ==================== 매칭 수정/삭제 API ====================
  
  // 매칭 수정
  static Future<void> updateMatching(int matchingId, Map<String, dynamic> matchingData, String token) async {
    try {
      await _makeRequest(
        'PUT',
        '/matchings/$matchingId',
        headers: _getAuthHeaders(token),
        body: json.encode(matchingData),
      );
    } catch (e) {
      throw ApiException('매칭 수정 실패: $e');
    }
  }

  // 매칭 삭제
  static Future<void> deleteMatching(int matchingId, String token) async {
    try {
      await _makeRequest(
        'DELETE',
        '/matchings/$matchingId',
        headers: _getAuthHeaders(token),
      );
    } catch (e) {
      throw ApiException('매칭 삭제 실패: $e');
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