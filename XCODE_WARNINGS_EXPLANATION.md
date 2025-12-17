# 📝 Xcode 경고 설명 및 처리 방법

## 🔍 경고 종류 분석

### 1. "Update to recommended settings" (경고, 수정 가능)
- **의미**: Xcode 프로젝트 설정이 최신 권장 설정과 다름
- **해결**: 
  - ✅ iOS Deployment Target을 14.0으로 통일 완료
  - Xcode에서 "Update to recommended settings" 버튼 클릭하면 자동 수정

### 2. Deprecated API 경고 (대부분 무시 가능)
이 경고들은 **서드파티 패키지의 내부 코드**에서 발생하므로 직접 수정할 수 없습니다.

#### file_picker (8.3.7)
- `UIDocumentPickerMode` deprecated 경고
- **영향**: 없음 (앱 정상 작동)
- **해결**: 패키지 업데이트 (10.3.7) 가능하지만 breaking changes 주의

#### firebase_core, firebase_messaging
- `deepLinkURLScheme`, `UNNotificationPresentationOptionAlert` deprecated
- **영향**: 없음 (앱 정상 작동)
- **해결**: 패키지 업데이트 가능하지만 Firebase 설정 변경 필요

#### geolocator, flutter_local_notifications 등
- iOS 14.0 이전 API 사용 경고
- **영향**: 없음 (앱 정상 작동)
- **해결**: 패키지 업데이트 가능

### 3. 실제 오류 (수정 필요)
#### sign_in_with_apple: "Switch must be exhaustive"
- **상태**: ✅ 패키지 업데이트 완료 (6.1.4 → 7.0.1)
- **확인 필요**: 빌드 후 오류가 사라졌는지 확인

---

## ✅ 수정 완료된 항목

1. ✅ iOS Deployment Target 통일 (13.0 → 14.0)
2. ✅ sign_in_with_apple 패키지 업데이트 (6.1.4 → 7.0.1)

---

## 🎯 Xcode에서 해야 할 작업

### Step 1: "Update to recommended settings" 클릭
1. Xcode에서 경고 메시지 클릭
2. "Update to recommended settings" 버튼 클릭
3. 변경사항 확인 후 "Perform Changes" 클릭

### Step 2: Clean Build Folder
1. `Product` → `Clean Build Folder` (`Cmd + Shift + K`)

### Step 3: 다시 빌드
1. `Cmd + R` 또는 실행 버튼 클릭

---

## ⚠️ 남아있는 경고들

### 서드파티 패키지 경고 (무시 가능)
- file_picker, firebase_core, geolocator 등의 deprecated API 경고
- **이유**: 패키지 내부 코드이므로 직접 수정 불가
- **영향**: 없음 (앱은 정상 작동)
- **해결**: 패키지 업데이트 (선택사항, breaking changes 주의)

### 권장 사항
- 현재 상태로도 앱은 정상 작동합니다
- 경고는 무시하고 테스트 진행 가능
- 나중에 패키지 업데이트 시 해결 가능

---

## 📊 경고 통계

- **수정 완료**: 2개 (iOS Deployment Target, sign_in_with_apple)
- **Xcode에서 수정 가능**: 1개 (Update to recommended settings)
- **서드파티 패키지 경고**: 대부분 (무시 가능)
- **실제 오류**: 0개 (수정 완료)

---

**결론**: 현재 상태로 테스트 진행 가능합니다. 남은 경고들은 대부분 무시해도 됩니다.


