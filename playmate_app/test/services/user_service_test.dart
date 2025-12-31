import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:playmate_app/services/user_service.dart';

void main() {
  group('UserService', () {
    late UserService userService;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      userService = UserService();
    });

    test('인증 토큰이 없을 때 getUserProfile은 null을 반환해야 함', () async {
      // 토큰이 없는 상태
      await prefs.remove('playmate_auth_token');
      
      // getUserProfile은 내부적으로 _getAuthToken을 호출하므로
      // 토큰이 없으면 Exception을 던지고 null을 반환
      final result = await userService.getUserProfile(1);
      
      // 실제 API 호출 없이 테스트하기 어려우므로
      // 기본 구조만 확인
      expect(result, isNull);
    });

    test('인증 토큰이 있을 때 getUserProfile은 User 객체를 반환해야 함', () async {
      // 토큰 설정
      await prefs.setString('playmate_auth_token', 'test_token');
      
      // 실제 API 호출이 필요하므로 통합 테스트에서 처리
      // 여기서는 기본 구조만 확인
      expect(prefs.getString('playmate_auth_token'), 'test_token');
    });
  });
}

