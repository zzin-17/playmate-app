import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/matching.dart';
import '../models/chat_room.dart';

class ApiService {
  static const String baseUrl = 'https://api.playmate.app/v1/';
  late Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 인터셉터 추가
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 토큰 추가 로직
        if (_authToken != null && _authToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ' + _authToken!;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // API Error logging
        handler.next(error);
      },
    ));
  }

  // ===== 채팅 관련 API =====
  Future<List<ChatRoom>> getMyChatRooms() async {
    try {
      final response = await _dio.get('/chat/rooms/my');
      final List<dynamic> data = response.data;
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    } catch (e) {
      throw Exception('채팅방 목록 조회 실패: $e');
    }
  }

  Future<void> createChatRoom({required int matchingId, required int hostId, required int guestId}) async {
    try {
      await _dio.post('/chat/rooms', data: {
        'matching_id': matchingId,
        'host_id': hostId,
        'guest_id': guestId,
      });
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    }
  }

  Future<Matching> getMatchingById(int matchingId) async {
    try {
      final response = await _dio.get('/matchings/' + matchingId.toString());
      return Matching.fromJson(response.data);
    } catch (e) {
      throw Exception('매칭 조회 실패: $e');
    }
  }

  // 외부에서 인증 토큰을 설정/해제할 수 있는 메서드
  void setAuthToken(String? token) {
    _authToken = token;
  }

  // 인증 관련 API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      // 서버가 토큰을 헤더로도 내려줄 수 있으므로, 응답에 토큰이 있으면 내부 필드에 설정
      final token = (response.data is Map<String, dynamic>) ? response.data['token'] as String? : null;
      if (token != null) {
        setAuthToken(token);
      }
      return response.data;
    } catch (e) {
      throw Exception('로그인 실패: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nickname,
    String? gender,
    int? birthYear,
  }) async {
    try {
      final response = await _dio.post('/users/register', data: {
        'email': email,
        'password': password,
        'nickname': nickname,
        'gender': gender,
        'birth_year': birthYear,
      });
      final token = (response.data is Map<String, dynamic>) ? response.data['token'] as String? : null;
      if (token != null) {
        setAuthToken(token);
      }
      return response.data;
    } catch (e) {
      throw Exception('회원가입 실패: $e');
    }
  }

  // 사용자 관련 API
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('사용자 정보 조회 실패: $e');
    }
  }

  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.put('/users/me', data: profileData);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('프로필 업데이트 실패: $e');
    }
  }

  // 매칭 관련 API
  Future<List<Matching>> getMatchings({
    String? region,
    int? level,
    String? gender,
    String? date,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (region != null) queryParameters['region'] = region;
      if (level != null) queryParameters['level'] = level;
      if (gender != null) queryParameters['gender'] = gender;
      if (date != null) queryParameters['date'] = date;

      final response = await _dio.get('/matchings', queryParameters: queryParameters);
      final List<dynamic> data = response.data;
      return data.map((json) => Matching.fromJson(json)).toList();
    } catch (e) {
      throw Exception('매칭 목록 조회 실패: $e');
    }
  }

  Future<Matching> createMatching(Map<String, dynamic> matchingData) async {
    try {
      final response = await _dio.post('/matchings', data: matchingData);
      return Matching.fromJson(response.data);
    } catch (e) {
      throw Exception('매칭 생성 실패: $e');
    }
  }

  Future<void> requestMatching(int matchingId, String message) async {
    try {
      await _dio.post('/matchings/$matchingId/request', data: {
        'message': message,
      });
    } catch (e) {
      throw Exception('매칭 요청 실패: $e');
    }
  }

  Future<void> respondToMatching(int matchingId, int requestUserId, String action) async {
    try {
      await _dio.post('/matchings/$matchingId/respond', data: {
        'request_user_id': requestUserId,
        'action': action,
      });
    } catch (e) {
      throw Exception('매칭 응답 실패: $e');
    }
  }

  Future<List<Matching>> getMyMatchings() async {
    try {
      final response = await _dio.get('/matchings/my');
      final List<dynamic> data = response.data;
      return data.map((json) => Matching.fromJson(json)).toList();
    } catch (e) {
      throw Exception('내 매칭 조회 실패: $e');
    }
  }

  // 비밀번호 재설정: 이메일 요청
  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post('/auth/password/reset-request', data: {
        'email': email,
      });
    } catch (e) {
      throw Exception('비밀번호 재설정 요청 실패: $e');
    }
  }

  // 비밀번호 재설정: 코드로 변경
  Future<void> resetPassword({required String code, required String newPassword}) async {
    try {
      await _dio.post('/auth/password/reset', data: {
        'code': code,
        'password': newPassword,
      });
    } catch (e) {
      throw Exception('비밀번호 재설정 실패: $e');
    }
  }
} 