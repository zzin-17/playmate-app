import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

/// 사용자 관련 API 서비스
/// 팔로우, 프로필 관리, 사용자 검색 등의 기능을 제공
class UserService {
  
  /// 인증 토큰 가져오기
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      return null;
    }
  }

  /// 사용자 프로필 조회
  Future<User?> getUserProfile(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/users/$userId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('사용자 프로필 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 프로필 조회 오류: $e');
      return null;
    }
  }

  /// 내 프로필 조회
  Future<User?> getMyProfile() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/users/me',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('내 프로필 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('내 프로필 조회 오류: $e');
      return null;
    }
  }

  /// 프로필 업데이트
  Future<User?> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.put(
        '/users/me',
        body: json.encode(profileData),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('프로필 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('프로필 업데이트 오류: $e');
      return null;
    }
  }

  /// 사용자 검색
  Future<List<User>> searchUsers(String query) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/users/search?q=${Uri.encodeComponent(query)}',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('사용자 검색 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 검색 오류: $e');
      return [];
    }
  }

  /// 팔로우하기
  Future<bool> followUser(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.post(
        '/users/$userId/follow',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('팔로우 오류: $e');
      return false;
    }
  }

  /// 언팔로우하기
  Future<bool> unfollowUser(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.delete(
        '/users/$userId/follow',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('언팔로우 오류: $e');
      return false;
    }
  }

  /// 팔로잉 목록 조회
  Future<List<User>> getFollowingList(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/users/$userId/following',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('팔로잉 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('팔로잉 목록 조회 오류: $e');
      return [];
    }
  }

  /// 팔로워 목록 조회
  Future<List<User>> getFollowerList(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/users/$userId/followers',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('팔로워 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('팔로워 목록 조회 오류: $e');
      return [];
    }
  }

  /// 팔로우 상태 확인
  Future<bool> isFollowing(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/users/$userId/follow-status',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFollowing'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('팔로우 상태 확인 오류: $e');
      return false;
    }
  }

  /// 프로필 이미지 업로드
  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      // 실제 구현에서는 multipart/form-data로 이미지 업로드
      // 여기서는 임시로 성공 응답 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));
      return 'https://example.com/profile-images/uploaded-image.jpg';
    } catch (e) {
      print('프로필 이미지 업로드 오류: $e');
      return null;
    }
  }

  /// 계정 삭제
  Future<bool> deleteAccount() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.delete(
        '/users/me',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('계정 삭제 오류: $e');
      return false;
    }
  }
}
