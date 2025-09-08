import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/matching.dart';
import '../models/user.dart';
import 'api_service.dart';

class MatchingDataService {
  
  // 매칭 목록 가져오기
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
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final queryParams = <String, String>{};
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      
      if (gameTypes != null && gameTypes.isNotEmpty) {
        queryParams['game_types'] = gameTypes.join(',');
      }
      
      if (skillLevel != null) {
        queryParams['min_skill_level'] = skillLevel;
      }
      
      if (endSkillLevel != null) {
        queryParams['max_skill_level'] = endSkillLevel;
      }
      
      if (ageRanges != null && ageRanges.isNotEmpty) {
        queryParams['age_ranges'] = ageRanges.join(',');
      }
      
      if (noAgeRestriction == true) {
        queryParams['no_age_restriction'] = 'true';
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
      
      if (showOnlyRecruiting == true) {
        queryParams['recruiting_only'] = 'true';
      }
      
      if (showOnlyFollowing == true) {
        queryParams['following_only'] = 'true';
      }

      final uri = Uri.parse('${ApiService.baseUrl}/matchings').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMatchingsFromJson(data);
      } else {
        throw Exception('매칭 데이터를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      print('매칭 데이터 가져오기 오류: $e');
      // 오류 발생 시 빈 리스트 반환 (또는 캐시된 데이터 반환)
      return [];
    }
  }

  // 매칭 상세 정보 가져오기
  static Future<Matching?> getMatchingById(int id) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/matchings/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMatchingFromJson(data);
      } else {
        throw Exception('매칭 상세 정보를 가져오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      print('매칭 상세 정보 가져오기 오류: $e');
      return null;
    }
  }

  // 매칭 생성
  static Future<Matching?> createMatching({
    required String courtName,
    required double courtLat,
    required double courtLng,
    required DateTime date,
    required String timeSlot,
    required int minLevel,
    required int maxLevel,
    int? minAge,
    int? maxAge,
    required String gameType,
    required int maleRecruitCount,
    required int femaleRecruitCount,
    bool isFollowersOnly = false,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final body = {
        'court_name': courtName,
        'court_lat': courtLat,
        'court_lng': courtLng,
        'date': date.toIso8601String(),
        'time_slot': timeSlot,
        'min_level': minLevel,
        'max_level': maxLevel,
        'min_age': minAge,
        'max_age': maxAge,
        'game_type': gameType,
        'male_recruit_count': maleRecruitCount,
        'female_recruit_count': femaleRecruitCount,
        'is_followers_only': isFollowersOnly,
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/matchings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return _parseMatchingFromJson(data);
      } else {
        throw Exception('매칭 생성에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      print('매칭 생성 오류: $e');
      return null;
    }
  }

  // 매칭 참여 요청
  static Future<bool> requestMatching(int matchingId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/matchings/$matchingId/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('매칭 참여 요청 오류: $e');
      return false;
    }
  }

  // 매칭 응답 (수락/거절)
  static Future<bool> respondToMatching(int matchingId, String response) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final body = {'response': response};

      final httpResponse = await http.post(
        Uri.parse('${ApiService.baseUrl}/matchings/$matchingId/respond'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      return httpResponse.statusCode == 200;
    } catch (e) {
      print('매칭 응답 오류: $e');
      return false;
    }
  }

  // JSON 데이터를 Matching 객체로 변환
  static List<Matching> _parseMatchingsFromJson(dynamic data) {
    if (data is Map && data.containsKey('matchings')) {
      final matchings = data['matchings'] as List;
      return matchings.map((json) => _parseMatchingFromJson(json)).toList();
    }
    return [];
  }

  static Matching _parseMatchingFromJson(Map<String, dynamic> json) {
    return Matching(
      id: json['id'],
      type: json['type'] ?? 'host',
      courtName: json['court_name'],
      courtLat: json['court_lat']?.toDouble() ?? 0.0,
      courtLng: json['court_lng']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
      timeSlot: json['time_slot'],
      minLevel: json['min_level'],
      maxLevel: json['max_level'],
      minAge: json['min_age'],
      maxAge: json['max_age'],
      gameType: json['game_type'],
      maleRecruitCount: json['male_recruit_count'],
      femaleRecruitCount: json['female_recruit_count'],
      status: json['status'],
      isFollowersOnly: json['is_followers_only'] ?? false,
      host: User.fromJson(json['host']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      recoveryCount: json['recovery_count'] ?? 0,
    );
  }

  // 인증 토큰 가져오기
  static Future<String?> _getAuthToken() async {
    try {
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
    } catch (e) {
      print('토큰 가져오기 오류: $e');
      return null;
    }
  }
}
