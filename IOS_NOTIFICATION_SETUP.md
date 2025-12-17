# iOS 알림 설정 가이드

## iOS 설정에서 알림이 보이지 않는 이유

### 문제 원인

1. **Info.plist 설정 부족**
   - `NSUserNotificationsUsageDescription`가 비어 있거나 없음
   - `UIBackgroundModes`에 `remote-notification`이 없음

2. **앱이 알림 권한을 요청하지 않음**
   - iOS 설정에 알림 항목이 나타나려면 최소한 한 번은 권한을 요청해야 함
   - 앱 시작 시 조용히 확인만 하면 설정에 나타나지 않을 수 있음

### 해결 방법

#### 1. Info.plist 수정 (완료 ✅)

```xml
<!-- 알림 권한 사용 설명 -->
<key>NSUserNotificationsUsageDescription</key>
<string>매칭 요청, 채팅 메시지, 커뮤니티 활동 등 중요한 알림을 받기 위해 알림 권한이 필요합니다.</string>

<!-- 백그라운드 알림 모드 (FCM 푸시 알림 수신) -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### 2. 앱에서 알림 권한 요청

앱 내 알림 설정 화면에서 "알림 권한 요청" 버튼을 클릭하면:
- iOS 권한 팝업이 표시됨
- 허용/거부 선택
- iOS 설정 앱에 알림 항목이 나타남

## 테스트 방법

### 1단계: 앱 재빌드
```bash
cd playmate_app
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios
```

### 2단계: 앱 실행 및 권한 요청
1. 앱 실행
2. 마이페이지 > 톱니바퀴 (또는 알림 설정)
3. "알림 권한 요청" 버튼 클릭
4. iOS 권한 팝업에서 "허용" 선택

### 3단계: iOS 설정 확인
1. iOS 설정 앱 열기
2. 아래로 스크롤하여 "Playmate App" 찾기
3. "알림" 항목이 나타나는지 확인

## 참고사항

### iOS 제한사항
- iOS에서는 특정 설정 페이지(예: 알림)로 직접 이동할 수 없음
- `openAppSettings()`는 앱의 전체 설정 화면으로만 이동
- 이는 iOS의 보안 정책 때문

### 알림 설정이 나타나는 조건
1. ✅ Info.plist에 알림 사용 설명이 있음
2. ✅ UIBackgroundModes에 remote-notification이 있음
3. ✅ 앱이 최소한 한 번은 알림 권한을 요청함

### 현재 상태
- ✅ Info.plist 수정 완료
- ✅ 앱 내 알림 권한 요청 기능 구현 완료
- ⚠️ 사용자가 앱 내에서 "알림 권한 요청" 버튼을 클릭해야 iOS 설정에 나타남


