# 서버 연결 문제 해결 가이드

## 🔍 문제 진단

### 현재 상황
- **Android 에뮬레이터**: `10.0.2.2:3000` 연결 시도 → `Connection refused`
- **iOS 시뮬레이터**: `localhost:3000` 연결 시도 → `Connection refused`
- **원인**: 백엔드 서버가 실행되지 않음

### 확인 방법

```bash
# 1. 서버 실행 상태 확인
lsof -i :3000

# 2. 서버 헬스 체크
curl http://localhost:3000/api/health

# 3. 백엔드 디렉토리 확인
cd /Users/zzin/playmate/playmate_backend && ls -la
```

## ✅ 해결 방법

### 1단계: 백엔드 서버 시작

터미널에서 다음 명령어 실행:

```bash
cd /Users/zzin/playmate/playmate_backend
npm run dev:stable
```

**예상 출력:**
```
✅ 포트 3000 사용 가능
🚀 서버가 포트 3000에서 실행 중입니다
📡 API 엔드포인트: http://localhost:3000/api
```

### 2단계: 서버 상태 확인

새 터미널에서:

```bash
# 서버가 실행 중인지 확인
curl http://localhost:3000/api/health
```

**정상 응답:**
```json
{"status":"ok","message":"Server is running"}
```

### 3단계: 앱 재시작

서버가 실행된 후:
1. Flutter 앱을 Hot Restart (R 키) 또는 완전 재시작
2. 연결 로그 확인

## 📱 플랫폼별 연결 설정

### Android 에뮬레이터
- **호스트 주소**: `10.0.2.2` (호스트의 `localhost`를 가리킴)
- **포트**: `3000`
- **전체 URL**: `http://10.0.2.2:3000/api`

**중요**: Android 에뮬레이터는 `10.0.2.2`를 사용해야 합니다.
- `localhost` → 에뮬레이터 자체를 가리킴 (작동 안 함)
- `127.0.0.1` → 에뮬레이터 자체를 가리킴 (작동 안 함)
- `10.0.2.2` → 호스트 머신의 `localhost`를 가리킴 (정상 작동)

### iOS 시뮬레이터
- **호스트 주소**: `localhost` 또는 `127.0.0.1`
- **포트**: `3000`
- **전체 URL**: `http://localhost:3000/api`

### 실제 기기 (Wi-Fi)
- **호스트 주소**: 네트워크 IP (예: `192.168.6.100`)
- **포트**: `3000`
- **전체 URL**: `http://192.168.6.100:3000/api`

**중요**: 실제 기기와 개발 머신이 같은 Wi-Fi 네트워크에 연결되어 있어야 합니다.

## 🔧 문제 해결 체크리스트

### 서버 관련
- [ ] 백엔드 서버가 실행 중인가?
- [ ] 포트 3000이 사용 가능한가?
- [ ] `curl http://localhost:3000/api/health`가 정상 응답하는가?
- [ ] Node.js 버전이 16 이상인가? (`node --version`)

### 네트워크 관련
- [ ] Android 에뮬레이터: `10.0.2.2:3000` 사용 중인가?
- [ ] iOS 시뮬레이터: `localhost:3000` 사용 중인가?
- [ ] 실제 기기: 네트워크 IP가 올바른가?
- [ ] 방화벽이 포트 3000을 차단하지 않는가?

### 앱 관련
- [ ] 앱이 최신 코드로 빌드되었는가?
- [ ] Hot Restart를 시도했는가?
- [ ] 앱 로그에서 연결 시도 메시지가 보이는가?

## 🚨 자주 발생하는 오류

### 1. Connection refused (errno = 111)
**원인**: 서버가 실행되지 않음
**해결**: 백엔드 서버 시작

### 2. Connection refused (errno = 61)
**원인**: 서버가 실행되지 않거나 잘못된 주소 사용
**해결**: 
- 서버 실행 확인
- 플랫폼에 맞는 주소 사용 확인

### 3. Timeout
**원인**: 네트워크 문제 또는 서버 응답 지연
**해결**:
- 서버 로그 확인
- 네트워크 연결 확인
- 타임아웃 설정 확인

### 4. Firebase API Key 오류
**원인**: Firebase 설정이 완료되지 않음
**해결**: 
- `google-services.json` (Android) 확인
- `GoogleService-Info.plist` (iOS) 확인
- Firebase 프로젝트 설정 확인

## 📝 빠른 시작 명령어

```bash
# 서버 시작
cd /Users/zzin/playmate/playmate_backend && npm run dev:stable

# 서버 상태 확인 (새 터미널)
curl http://localhost:3000/api/health

# 서버 종료
cd /Users/zzin/playmate/playmate_backend && npm run kill

# 서버 재시작
cd /Users/zzin/playmate/playmate_backend && npm run restart
```

## 🔍 디버깅 팁

### 서버 로그 확인
```bash
cd /Users/zzin/playmate/playmate_backend
tail -f logs/server.log
```

### 앱 로그 확인
- Android: `flutter logs` 또는 Android Studio Logcat
- iOS: Xcode Console 또는 `flutter logs`

### 네트워크 연결 테스트
```bash
# Android 에뮬레이터에서 테스트 (에뮬레이터 내부에서)
adb shell
curl http://10.0.2.2:3000/api/health

# iOS 시뮬레이터는 호스트와 동일한 네트워크 사용
curl http://localhost:3000/api/health
```

## 📚 관련 문서

- `SERVER_START_GUIDE.md` - 서버 시작 가이드
- `playmate_backend/SERVER_STABILITY.md` - 서버 안정성 가이드
- `playmate_app/lib/config/api_config.dart` - API 설정 파일

