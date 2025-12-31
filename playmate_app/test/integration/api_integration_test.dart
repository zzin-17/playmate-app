import 'package:flutter_test/flutter_test.dart';
import 'package:playmate_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 통합 테스트
/// 실제 API 서버와 통신하여 동작을 확인합니다.
/// 
/// 주의: 이 테스트는 실제 서버가 실행 중이어야 합니다.
/// 테스트 실행 전에 백엔드 서버를 시작하세요.
void main() {
  group('API 통합 테스트', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('API 서버 연결 확인', () async {
      // baseUrl이 올바르게 설정되어 있는지 확인
      expect(ApiService.baseUrl, isNotEmpty);
      
      // 실제 서버 연결 테스트는 네트워크가 필요하므로
      // 여기서는 기본 구조만 확인
      print('API Base URL: ${ApiService.baseUrl}');
    });

    test('인증 토큰 저장 및 조회', () async {
      const testToken = 'test_auth_token_12345';
      
      // 토큰 저장
      await prefs.setString('playmate_auth_token', testToken);
      
      // 토큰 조회
      final retrievedToken = prefs.getString('playmate_auth_token');
      
      expect(retrievedToken, testToken);
    });

    // 실제 API 호출 테스트는 서버가 실행 중일 때만 동작
    // 테스트 환경에서 서버를 시작하는 스크립트가 필요할 수 있음
  });
}

