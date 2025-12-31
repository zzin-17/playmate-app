import 'package:flutter_test/flutter_test.dart';
import 'package:playmate_app/services/api_service.dart';

void main() {
  group('ApiService', () {
    setUp(() {
      // 기본적인 테스트 구조만 작성
    });

    test('baseUrl이 올바르게 설정되어 있는지 확인', () {
      expect(ApiService.baseUrl, isNotEmpty);
      expect(ApiService.baseUrl, contains('http'));
    });

    test('timeout이 설정되어 있는지 확인', () {
      expect(ApiService.timeout, isNotNull);
      expect(ApiService.timeout.inSeconds, greaterThan(0));
    });
  });
}

