# 테스트 가이드

이 디렉토리에는 PlayMate 앱의 테스트 코드가 포함되어 있습니다.

## 테스트 구조

```
test/
├── services/          # 서비스 레이어 단위 테스트
│   ├── api_service_test.dart
│   ├── user_service_test.dart
│   └── matching_service_test.dart
├── widgets/          # 위젯 테스트
│   └── auth_screen_test.dart
├── integration/      # 통합 테스트
│   └── api_integration_test.dart
└── widget_test.dart  # 기본 위젯 테스트
```

## 테스트 실행

### 모든 테스트 실행
```bash
flutter test
```

### 특정 테스트 파일 실행
```bash
flutter test test/services/api_service_test.dart
```

### 특정 테스트 그룹 실행
```bash
flutter test --name "ApiService"
```

### 커버리지 확인
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 테스트 작성 가이드

### 단위 테스트 (Unit Tests)

서비스 레이어의 비즈니스 로직을 테스트합니다.

**예시:**
```dart
test('사용자 프로필 조회 테스트', () async {
  final userService = UserService();
  final user = await userService.getUserProfile(1);
  expect(user, isNotNull);
});
```

### 위젯 테스트 (Widget Tests)

UI 컴포넌트의 렌더링과 상호작용을 테스트합니다.

**예시:**
```dart
testWidgets('로그인 버튼 테스트', (WidgetTester tester) async {
  await tester.pumpWidget(LoginScreen());
  expect(find.text('로그인'), findsOneWidget);
});
```

### 통합 테스트 (Integration Tests)

실제 API 서버와의 통신을 테스트합니다.

**주의:** 통합 테스트는 실제 서버가 실행 중이어야 합니다.

## 테스트 의존성

- `flutter_test`: Flutter 기본 테스트 프레임워크
- `mockito`: Mock 객체 생성
- `mocktail`: 더 간편한 Mock 생성
- `http_mock_adapter`: HTTP 요청 Mock

## 현재 테스트 상태

### 완료된 테스트
- ✅ ApiService 기본 설정 테스트
- ✅ UserService 기본 동작 테스트
- ✅ MatchingService 싱글톤 패턴 테스트

### 추가 예정 테스트
- [ ] ApiService API 호출 테스트 (Mock 사용)
- [ ] UserService 팔로우 기능 테스트
- [ ] MatchingService 매칭 참여/취소 테스트
- [ ] 주요 화면 위젯 테스트
- [ ] 통합 테스트 (실제 API 연동)

## 테스트 작성 시 주의사항

1. **Mock 사용**: 실제 API 호출을 피하기 위해 Mock 객체를 사용합니다.
2. **독립성**: 각 테스트는 독립적으로 실행 가능해야 합니다.
3. **명확한 이름**: 테스트 이름은 무엇을 테스트하는지 명확하게 작성합니다.
4. **AAA 패턴**: Arrange(준비) - Act(실행) - Assert(검증) 패턴을 따릅니다.

## CI/CD 통합

테스트는 CI/CD 파이프라인에서 자동으로 실행됩니다. 모든 테스트가 통과해야 배포가 가능합니다.




