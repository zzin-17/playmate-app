# 🔥 Firebase 설정 가이드 (상세 버전)

## 📋 목차
1. [현재 상태 확인](#현재-상태-확인)
2. [Firebase 프로젝트 생성](#firebase-프로젝트-생성)
3. [Android 설정](#android-설정)
4. [iOS 설정](#ios-설정)
5. [FCM 푸시 알림 설정](#fcm-푸시-알림-설정)
6. [설정 확인 및 테스트](#설정-확인-및-테스트)
7. [문제 해결](#문제-해결)
8. [추가 설정 (선택사항)](#추가-설정-선택사항)

---

## 현재 상태 확인

### 현재 설정 상태
- ✅ Firebase 패키지 설치됨 (`firebase_core`, `firebase_messaging`)
- ✅ Android Gradle 설정 완료 (`com.google.gms.google-services` 플러그인)
- ⚠️ 샘플 `google-services.json` 파일 사용 중
- ⚠️ iOS `GoogleService-Info.plist` 파일 없음 (iOS 지원 시 필요)

### 필요한 정보
- **Android 패키지 이름**: `com.example.playmate_app`
- **iOS Bundle ID**: 확인 필요 (Info.plist에서 확인)
- **프로젝트 경로**: `/Users/zzin/playmate/playmate_app`

---

## Firebase 프로젝트 생성

### 1단계: Firebase Console 접속
1. https://console.firebase.google.com 접속
2. Google 계정으로 로그인
3. 기존 프로젝트가 있으면 선택, 없으면 새로 생성

### 2단계: 새 프로젝트 생성
1. **"프로젝트 추가"** 또는 **"프로젝트 만들기"** 클릭
2. **프로젝트 이름** 입력: `PlayMate` (또는 원하는 이름)
3. **Google Analytics 설정** (선택사항)
   - Analytics 사용 여부 선택
   - Analytics 계정 선택 또는 새로 만들기
4. **"프로젝트 만들기"** 클릭
5. 프로젝트 생성 완료 대기 (약 1-2분)

### 3단계: 프로젝트 설정 확인
1. 프로젝트 대시보드로 이동
2. 프로젝트 설정 아이콘(⚙️) 클릭
3. **일반** 탭에서 프로젝트 정보 확인

---

## Android 설정

### 1단계: Android 앱 등록
1. Firebase Console에서 **"Android 앱 추가"** 또는 **"앱 추가" > "Android"** 클릭
2. **Android 앱 등록** 화면에서:
   - **Android 패키지 이름**: `com.example.playmate_app` 입력
   - **앱 닉네임**: `PlayMate` (선택사항)
   - **디버그 서명 인증서 SHA-1**: (선택사항, 나중에 추가 가능)
3. **"앱 등록"** 클릭

### 2단계: google-services.json 다운로드
1. **"google-services.json 다운로드"** 버튼 클릭
2. 다운로드한 파일을 다음 경로에 저장:
   ```
   playmate_app/android/app/google-services.json
   ```
3. **기존 샘플 파일 덮어쓰기** 확인

### 3단계: 파일 내용 확인
다운로드한 `google-services.json` 파일을 열어서 다음 내용이 포함되어 있는지 확인:
```json
{
  "project_info": {
    "project_number": "실제 프로젝트 번호",
    "project_id": "실제 프로젝트 ID",
    "storage_bucket": "실제 스토리지 버킷"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "실제 앱 ID",
        "android_client_info": {
          "package_name": "com.example.playmate_app"
        }
      },
      ...
    }
  ]
}
```

⚠️ **주의**: 샘플 값(`123456789012`, `playmate-app-sample` 등)이 아닌 실제 값이어야 합니다.

### 4단계: Android 빌드 설정 확인
`playmate_app/android/app/build.gradle.kts` 파일에 다음이 포함되어 있는지 확인:
```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
}
```

✅ 이미 설정되어 있음

### 5단계: 프로젝트 레벨 build.gradle 확인
`playmate_app/android/build.gradle.kts` 파일에 다음이 포함되어 있는지 확인:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

---

## iOS 설정

### 1단계: Bundle ID 확인
1. Xcode에서 프로젝트 열기:
   ```bash
   open playmate_app/ios/Runner.xcworkspace
   ```
2. **Runner** 프로젝트 선택
3. **TARGETS > Runner** 선택
4. **General** 탭에서 **Bundle Identifier** 확인
   - 예: `com.example.playmateApp` 또는 다른 값

### 2단계: iOS 앱 등록
1. Firebase Console에서 **"iOS 앱 추가"** 또는 **"앱 추가" > "iOS"** 클릭
2. **iOS 앱 등록** 화면에서:
   - **iOS 번들 ID**: Xcode에서 확인한 Bundle Identifier 입력
   - **앱 닉네임**: `PlayMate` (선택사항)
   - **App Store ID**: (선택사항, 나중에 추가 가능)
3. **"앱 등록"** 클릭

### 3단계: GoogleService-Info.plist 다운로드
1. **"GoogleService-Info.plist 다운로드"** 버튼 클릭
2. 다운로드한 파일을 다음 경로에 저장:
   ```
   playmate_app/ios/Runner/GoogleService-Info.plist
   ```

### 4단계: Xcode에서 파일 추가
1. Xcode에서 `Runner` 프로젝트 열기
2. **Runner** 폴더를 우클릭
3. **"Add Files to Runner..."** 선택
4. 다운로드한 `GoogleService-Info.plist` 파일 선택
5. **"Copy items if needed"** 체크
6. **"Add"** 클릭

### 5단계: iOS Capabilities 설정
1. Xcode에서 **Runner** 프로젝트 선택
2. **TARGETS > Runner** 선택
3. **Signing & Capabilities** 탭 선택
4. **Push Notifications** capability 추가 (없는 경우)
5. **Background Modes** capability 추가 및 다음 옵션 체크:
   - ✅ Remote notifications

### 6단계: Info.plist 설정 확인
`playmate_app/ios/Runner/Info.plist` 파일에 다음이 포함되어 있는지 확인:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

또는 Firebase App Delegate를 사용하는 경우:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<true/>
```

---

## FCM 푸시 알림 설정

### 1단계: Cloud Messaging 활성화
1. Firebase Console에서 **프로젝트 설정** (⚙️) 클릭
2. **Cloud Messaging** 탭 선택
3. **Cloud Messaging API (V1)** 활성화 확인

### 2단계: 서버 키 확인 (백엔드용)
1. **Cloud Messaging** 탭에서 **서버 키** 확인
2. 백엔드에서 FCM 푸시 알림을 보낼 때 사용
3. **참고**: 서버 키는 안전하게 보관해야 함

### 3단계: 앱에서 FCM 토큰 확인
앱 실행 후 다음 로그에서 FCM 토큰 확인:
```
FCM 서비스 초기화 완료 (토큰: [FCM 토큰])
```

### 4단계: 테스트 알림 전송
1. Firebase Console > **Cloud Messaging** > **새 알림 작성**
2. 알림 제목과 내용 입력
3. **테스트 메시지** 탭에서 FCM 토큰 입력
4. **테스트** 버튼 클릭

---

## 설정 확인 및 테스트

### 1단계: 프로젝트 정리 및 재빌드
```bash
cd playmate_app
flutter clean
flutter pub get
```

### 2단계: Android 빌드 및 실행
```bash
flutter run
```

또는 특정 디바이스에서:
```bash
flutter run -d <device-id>
```

### 3단계: 확인 사항
앱 실행 후 다음을 확인:

1. **Firebase 초기화 확인**
   - 콘솔에 "FCM 서비스 초기화 완료" 메시지 확인
   - 오류 메시지가 없는지 확인

2. **FCM 토큰 확인**
   - 콘솔에 FCM 토큰이 출력되는지 확인
   - 토큰이 `null`이 아닌지 확인

3. **푸시 알림 테스트**
   - Firebase Console에서 테스트 알림 전송
   - 앱이 포그라운드/백그라운드에서 알림 수신 확인

### 4단계: iOS 빌드 및 실행 (iOS 지원 시)
```bash
flutter run -d <ios-device-id>
```

또는 Xcode에서 직접 실행:
```bash
open playmate_app/ios/Runner.xcworkspace
```

---

## 문제 해결

### 오류 1: "Please set a valid API key"
**원인**: `google-services.json` 파일이 없거나 잘못된 파일 사용

**해결 방법**:
1. `playmate_app/android/app/google-services.json` 파일 확인
2. 파일이 실제 Firebase 프로젝트에서 다운로드한 것인지 확인
3. 파일 내용에 샘플 값이 아닌 실제 값이 있는지 확인
4. `flutter clean` 후 재빌드

### 오류 2: "Package name mismatch"
**원인**: `google-services.json`의 패키지 이름과 앱의 패키지 이름이 일치하지 않음

**해결 방법**:
1. `google-services.json` 파일에서 `package_name` 확인:
   ```json
   "package_name": "com.example.playmate_app"
   ```
2. `android/app/build.gradle.kts`에서 `applicationId` 확인:
   ```kotlin
   applicationId = "com.example.playmate_app"
   ```
3. 두 값이 일치하는지 확인
4. 일치하지 않으면 Firebase Console에서 올바른 패키지 이름으로 앱 재등록

### 오류 3: "FirebaseApp not initialized"
**원인**: Firebase 초기화가 제대로 되지 않음

**해결 방법**:
1. `main.dart`에서 `Firebase.initializeApp()` 호출 확인
2. `google-services.json` 파일이 올바른 위치에 있는지 확인
3. `flutter clean` 후 재빌드

### 오류 4: iOS에서 알림이 작동하지 않음
**원인**: iOS 권한 또는 설정 문제

**해결 방법**:
1. Xcode에서 **Push Notifications** capability 추가 확인
2. **Background Modes > Remote notifications** 활성화 확인
3. `Info.plist`에서 알림 권한 관련 설정 확인
4. 실제 디바이스에서 테스트 (시뮬레이터에서는 푸시 알림 제한적)

### 오류 5: FCM 토큰이 null
**원인**: Firebase 초기화 실패 또는 권한 문제

**해결 방법**:
1. Firebase 초기화 오류 로그 확인
2. 알림 권한이 허용되었는지 확인
3. `google-services.json` 파일 확인
4. Android의 경우 Google Play Services가 설치되어 있는지 확인

---

## 추가 설정 (선택사항)

### 1. Firebase Authentication 설정
이메일/비밀번호 로그인을 Firebase로 처리하려는 경우:

1. Firebase Console > **Authentication** > **시작하기**
2. **Sign-in method** 탭에서 원하는 인증 방법 활성화:
   - 이메일/비밀번호
   - Google
   - Apple (iOS)
   - 기타

### 2. Firebase Analytics 설정
사용자 행동 분석을 위한 Analytics:

1. Firebase Console > **Analytics** > **시작하기**
2. Analytics 이벤트 자동 수집 확인
3. 커스텀 이벤트 추가 (필요시)

### 3. Firebase Crashlytics 설정
앱 크래시 모니터링:

1. Firebase Console > **Crashlytics** > **시작하기**
2. `pubspec.yaml`에 `firebase_crashlytics` 추가
3. `main.dart`에서 Crashlytics 초기화

### 4. Firebase Remote Config 설정
원격 설정 관리:

1. Firebase Console > **Remote Config** > **시작하기**
2. `pubspec.yaml`에 `firebase_remote_config` 추가
3. 앱에서 Remote Config 값 읽기 구현

---

## 보안 고려사항

### 1. API 키 보호
- `google-services.json`과 `GoogleService-Info.plist`는 공개 저장소에 커밋하지 않기
- `.gitignore`에 추가:
  ```
  android/app/google-services.json
  ios/Runner/GoogleService-Info.plist
  ```

### 2. 서버 키 보호
- FCM 서버 키는 백엔드 서버에서만 사용
- 클라이언트 앱에 포함하지 않기
- 환경 변수로 관리

### 3. 프로덕션/개발 환경 분리
- 개발용과 프로덕션용 Firebase 프로젝트 분리 권장
- 빌드 타입에 따라 다른 설정 파일 사용

---

## 체크리스트

### Android 설정 체크리스트
- [ ] Firebase 프로젝트 생성 완료
- [ ] Android 앱 등록 완료
- [ ] `google-services.json` 다운로드 및 저장 완료
- [ ] `build.gradle.kts`에 Google Services 플러그인 추가 확인
- [ ] Firebase 의존성 추가 확인
- [ ] 앱 빌드 및 실행 성공
- [ ] FCM 토큰 정상 발급 확인
- [ ] 테스트 푸시 알림 수신 확인

### iOS 설정 체크리스트 (iOS 지원 시)
- [ ] Bundle ID 확인 완료
- [ ] iOS 앱 등록 완료
- [ ] `GoogleService-Info.plist` 다운로드 및 저장 완료
- [ ] Xcode에서 파일 추가 완료
- [ ] Push Notifications capability 추가 완료
- [ ] Background Modes > Remote notifications 활성화 완료
- [ ] 앱 빌드 및 실행 성공
- [ ] FCM 토큰 정상 발급 확인
- [ ] 테스트 푸시 알림 수신 확인

---

## 참고 자료

### 공식 문서
- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [FCM 설정 가이드](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Android 설정 가이드](https://firebase.google.com/docs/android/setup)
- [iOS 설정 가이드](https://firebase.google.com/docs/ios/setup)

### 유용한 링크
- [Firebase Console](https://console.firebase.google.com)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
- [FCM 테스트 도구](https://console.firebase.google.com/project/_/notification)

---

## 다음 단계

Firebase 설정이 완료되면:

1. **백엔드 FCM 연동**
   - 서버 키를 사용하여 백엔드에서 푸시 알림 전송 구현
   - 사용자별 FCM 토큰 저장 및 관리

2. **알림 기능 확장**
   - 알림 타입별 처리 로직 구현
   - 알림 데이터 페이로드 설계
   - 알림 클릭 시 화면 이동 로직 구현

3. **모니터링 설정**
   - Firebase Analytics 이벤트 추가
   - Crashlytics 설정 (선택사항)
   - 성능 모니터링 설정 (선택사항)

---

**최종 업데이트**: 2025-01-XX  
**작성자**: AI Assistant

**참고**: 개발 단계에서는 Firebase 없이도 앱이 작동합니다. 
푸시 알림이 필요할 때 Firebase 프로젝트를 설정하면 됩니다.
