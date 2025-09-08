import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';

class ReviewService {
  // 내 후기 목록 조회
  static Future<List<Review>> getMyReviews() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];
      
      // TODO: 실제 API 엔드포인트 구현
      // return await ApiService.getMyReviews(token);
      
      // 임시로 빈 리스트 반환
      return [];
    } catch (e) {
      print('내 후기 목록 조회 오류: $e');
      return [];
    }
  }

  // 후기 작성
  static Future<bool> createReview(Review review) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      // TODO: 실제 API 엔드포인트 구현
      // await ApiService.createReview(review.toJson(), token);
      
      return true;
    } catch (e) {
      print('후기 작성 오류: $e');
      return false;
    }
  }

  // 후기 수정
  static Future<bool> updateReview(int reviewId, Review review) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      // TODO: 실제 API 엔드포인트 구현
      // await ApiService.updateReview(reviewId, review.toJson(), token);
      
      return true;
    } catch (e) {
      print('후기 수정 오류: $e');
      return false;
    }
  }

  // 후기 삭제
  static Future<bool> deleteReview(int reviewId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다.');
      
      // TODO: 실제 API 엔드포인트 구현
      // await ApiService.deleteReview(reviewId, token);
      
      return true;
    } catch (e) {
      print('후기 삭제 오류: $e');
      return false;
    }
  }

  // 특정 사용자의 후기 목록 조회
  static Future<List<Review>> getUserReviews(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return [];
      
      // TODO: 실제 API 엔드포인트 구현
      // return await ApiService.getUserReviews(userId, token);
      
      return [];
    } catch (e) {
      print('사용자 후기 목록 조회 오류: $e');
      return [];
    }
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
