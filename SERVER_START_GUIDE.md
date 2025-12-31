# 서버 시작 가이드

## 문제 상황
iOS 시뮬레이터에서 서버 연결이 안 되는 경우:
```
Connection refused (OS Error: Connection refused, errno = 61)
```

## 해결 방법

### 1. 백엔드 서버 시작

터미널에서 다음 명령어 실행:

```bash
cd /Users/zzin/playmate/playmate_backend
npm run dev:stable
```

또는

```bash
cd /Users/zzin/playmate/playmate_backend
npm start
```

### 2. 서버 상태 확인

서버가 정상적으로 실행되었는지 확인:

```bash
# 포트 3000에서 실행 중인지 확인
lsof -i :3000

# 또는 curl로 테스트
curl http://localhost:3000/api/health
```

정상 응답 예시:
```json
{"status":"ok","message":"Server is running"}
```

### 3. iOS 시뮬레이터 설정

iOS 시뮬레이터는 자동으로 `localhost:3000`을 사용하도록 설정되어 있습니다.

**중요**: 
- iOS 시뮬레이터: `http://localhost:3000` 사용
- Android 에뮬레이터: `http://10.0.2.2:3000` 사용
- 실제 기기: `http://192.168.6.100:3000` 사용 (네트워크 IP)

### 4. 서버가 시작되지 않는 경우

#### 포트 충돌 확인
```bash
# 포트 3000 사용 중인 프로세스 확인
lsof -i :3000

# 프로세스 종료
kill -9 <PID>
```

#### Node.js 버전 확인
```bash
node --version
# Node.js 16 이상 필요
```

#### 의존성 설치
```bash
cd /Users/zzin/playmate/playmate_backend
npm install
```

### 5. 서버 로그 확인

서버가 실행 중이면 다음과 같은 로그가 표시됩니다:

```
✅ 포트 3000 사용 가능
🚀 서버가 포트 3000에서 실행 중입니다
📡 API 엔드포인트: http://localhost:3000/api
```

### 6. 앱에서 서버 연결 확인

앱 실행 후:
1. 로그인 화면에서 서버 연결 상태 확인
2. 홈 화면에서 매칭 목록이 로드되는지 확인
3. Xcode Console에서 연결 로그 확인

### 7. 문제 해결 체크리스트

- [ ] 백엔드 서버가 실행 중인가?
- [ ] 포트 3000이 사용 가능한가?
- [ ] `curl http://localhost:3000/api/health`가 정상 응답하는가?
- [ ] iOS 시뮬레이터에서 `localhost`를 사용하는가?
- [ ] 방화벽이 포트 3000을 차단하지 않는가?

## 빠른 시작

```bash
# 1. 백엔드 서버 시작
cd /Users/zzin/playmate/playmate_backend
npm run dev:stable

# 2. 새 터미널에서 앱 실행 (Xcode 또는 Flutter)
cd /Users/zzin/playmate/playmate_app
flutter run -d ios
```

## 추가 정보

- 서버 설정: `playmate_backend/src/server.js`
- API 설정: `playmate_app/lib/config/api_config.dart`
- 서버 안정성 가이드: `playmate_backend/SERVER_STABILITY.md`


