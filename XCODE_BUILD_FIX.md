# 🔧 Xcode 빌드 오류 해결 가이드

## ✅ 해결 완료된 문제

### 1. `Module 'file_picker' not found` 오류
- **원인**: CocoaPods 의존성이 제대로 설치되지 않음
- **해결**: 
  - `flutter clean` 실행
  - `flutter pub get` 실행
  - `pod install` 실행
  - iOS 최소 버전을 14.0으로 업데이트

### 2. iOS 최소 버전 문제
- **원인**: iOS 12.0이 너무 낮아서 일부 패키지가 지원하지 않음
- **해결**: Podfile에서 iOS 14.0으로 업데이트

## 📝 Xcode에서 해야 할 작업

### Step 1: Clean Build Folder
1. Xcode 메뉴에서 `Product` → `Clean Build Folder` (`Cmd + Shift + K`)
2. 또는 `Product` → `Clean` (`Cmd + K`)

### Step 2: Xcode 프로젝트 닫고 다시 열기
1. Xcode에서 프로젝트 닫기 (`Cmd + Q`)
2. `Runner.xcworkspace` 파일을 다시 열기

### Step 3: 빌드 설정 확인
1. `Runner` 프로젝트 선택
2. `TARGETS` → `Runner` 선택
3. `Build Settings` 탭 클릭
4. `iOS Deployment Target`이 `14.0` 이상인지 확인

### Step 4: 다시 빌드
1. 시뮬레이터 선택 (iOS 14.0 이상)
2. `Cmd + R` 또는 실행 버튼 클릭

## 🚀 빠른 해결 방법

터미널에서:
```bash
cd playmate_app
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --no-codesign
```

그 다음 Xcode에서:
1. `Product` → `Clean Build Folder` (`Cmd + Shift + K`)
2. `Cmd + R`로 실행

## ⚠️ 주의사항

- **iOS 14.0 이상** 시뮬레이터/기기만 사용 가능
- **Apple Sign In**은 iOS 13.0 이상에서 작동 (현재 14.0으로 설정되어 있으므로 문제없음)
- Xcode를 닫았다가 다시 열면 빌드 캐시가 초기화되어 도움이 될 수 있습니다

## ✅ 확인 사항

빌드가 성공하면:
- [ ] `file_picker` 모듈 오류가 사라짐
- [ ] 앱이 정상적으로 빌드됨
- [ ] 시뮬레이터에서 앱이 실행됨

---

**마지막 업데이트**: 2025-12-12


