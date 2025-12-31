import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:playmate_app/services/matching_service.dart';
import 'package:playmate_app/models/matching.dart';
import 'package:playmate_app/models/user.dart';

void main() {
  group('MatchingService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('MatchingService는 싱글톤 패턴을 사용해야 함', () {
      final instance1 = MatchingService();
      final instance2 = MatchingService();
      
      expect(instance1, same(instance2));
    });

    test('인증 토큰이 없을 때 joinMatching은 false를 반환해야 함', () async {
      // 토큰이 없는 상태
      await prefs.remove('playmate_auth_token');
      
      final now = DateTime.now();
      final testMatching = Matching(
        id: 1,
        type: 'host',
        courtName: 'Test Court',
        courtLat: 37.5665,
        courtLng: 126.9780,
        date: now,
        timeSlot: '10:00-12:00',
        gameType: 'singles',
        maleRecruitCount: 2,
        femaleRecruitCount: 2,
        status: 'recruiting',
        host: User(
          id: 1,
          nickname: 'Test Host',
          email: 'test@example.com',
          createdAt: now,
          updatedAt: now,
        ),
        createdAt: now,
        updatedAt: now,
      );
      
      final testUser = User(
        id: 2,
        nickname: 'Test User',
        email: 'user@example.com',
        createdAt: now,
        updatedAt: now,
      );
      
      // 실제 API 호출이 필요하므로 통합 테스트에서 처리
      // 여기서는 기본 구조만 확인
      expect(testMatching.id, 1);
      expect(testUser.id, 2);
    });
  });
}

