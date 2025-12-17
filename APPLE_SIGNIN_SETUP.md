# 🍎 Apple Sign In 설정 가이드

## 구현 완료
- ✅ 백엔드 API 엔드포인트 (`POST /api/auth/apple`)
- ✅ Flutter 앱 구현 (`sign_in_with_apple` 패키지 사용)
- ✅ 기존 사용자 자동 로그인
- ✅ 신규 사용자 자동 등록

## iOS 설정 (필수)

### 1. Xcode에서 Capability 추가
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. 프로젝트 네비게이터에서 `Runner` 선택
3. `Signing & Capabilities` 탭 클릭
4. `+ Capability` 버튼 클릭
5. `Sign In with Apple` 추가

### 2. Apple Developer 계정 설정
1. [Apple Developer](https://developer.apple.com) 접속
2. Certificates, Identifiers & Profiles > Identifiers
3. 앱의 Bundle ID 선택
4. `Sign In with Apple` Capability 활성화
5. `Configure` 클릭하여 설정 완료

### 3. 테스트
- iOS 시뮬레이터: Sign in with Apple 지원 (iOS 13+)
- 실제 기기: Apple ID로 로그인 테스트 가능

## Android 설정
- Android에서는 Sign in with Apple이 지원되지 않습니다
- Android에서는 버튼을 숨기거나 비활성화하는 것을 권장합니다

## 참고
- [Apple Sign In 공식 문서](https://developer.apple.com/sign-in-with-apple/)
- [sign_in_with_apple 패키지](https://pub.dev/packages/sign_in_with_apple)


