# 🔥 Firebase 설정 가이드

## 현재 상태
- 샘플 `google-services.json` 파일 사용 중
- Firebase 프로젝트 미설정
- FCM 푸시 알림 미사용 (로컬 알림만 사용 가능)

## Firebase 프로젝트 생성 방법

### 1단계: Firebase Console 접속
1. https://console.firebase.google.com 접속
2. Google 계정으로 로그인

### 2단계: 프로젝트 생성
1. "프로젝트 추가" 클릭
2. 프로젝트 이름 입력: `PlayMate` (또는 원하는 이름)
3. Google Analytics 설정 (선택사항)
4. "프로젝트 만들기" 클릭

### 3단계: Android 앱 추가
1. 프로젝트 대시보드에서 "Android 앱 추가" 클릭
2. **패키지 이름**: `com.example.playmate_app` 입력
3. 앱 닉네임: `PlayMate` (선택사항)
4. "앱 등록" 클릭

### 4단계: google-services.json 다운로드
1. "google-services.json 다운로드" 클릭
2. 다운로드한 파일을 다음 경로에 저장:
   ```
   /Users/zzin/playmate/playmate_app/android/app/google-services.json
   ```

### 5단계: Firebase 서비스 활성화
1. **Cloud Messaging (FCM)** 활성화:
   - 프로젝트 설정 > Cloud Messaging 탭
   - 서버 키 확인 (필요시)

2. **Authentication** (선택사항):
   - Authentication > 시작하기
   - 이메일/비밀번호, Google 등 활성화

### 6단계: iOS 설정 (선택사항)
iOS도 지원하는 경우:
1. "iOS 앱 추가" 클릭
2. Bundle ID 입력
3. `GoogleService-Info.plist` 다운로드
4. `ios/Runner/` 폴더에 저장

## 설정 확인

### Android
```bash
cd playmate_app
flutter clean
flutter pub get
flutter run
```

### 확인 사항
- Firebase 초기화 오류가 사라졌는지 확인
- FCM 토큰이 정상적으로 발급되는지 확인
- 푸시 알림이 작동하는지 테스트

## 문제 해결

### 오류: "Please set a valid API key"
- `google-services.json` 파일이 올바른 위치에 있는지 확인
- 파일 내용이 실제 Firebase 프로젝트의 것인지 확인
- `flutter clean` 후 재빌드

### 오류: "Package name mismatch"
- `google-services.json`의 `package_name`이 `com.example.playmate_app`인지 확인
- `android/app/build.gradle.kts`의 `applicationId` 확인

## 참고 자료
- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [FCM 설정 가이드](https://firebase.google.com/docs/cloud-messaging/flutter/client)

---

**참고**: 개발 단계에서는 Firebase 없이도 앱이 작동합니다. 
푸시 알림이 필요할 때 Firebase 프로젝트를 설정하면 됩니다.


