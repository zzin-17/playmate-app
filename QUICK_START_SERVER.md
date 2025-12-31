# 🚀 서버 빠른 시작 가이드

## ⚠️ 중요: 서버가 실행되어야 앱이 작동합니다!

Android 에뮬레이터나 iOS 시뮬레이터에서 앱을 실행하기 전에 **반드시 백엔드 서버를 시작**해야 합니다.

## 📋 서버 시작 방법

### 방법 1: 간단한 스크립트 사용 (가장 쉬움)

```bash
cd /Users/zzin/playmate
./start_server.sh
```

### 방법 2: 직접 명령어 실행

**새 터미널 창을 열고** 다음 명령어 실행:

```bash
cd /Users/zzin/playmate/playmate_backend
npm run dev:stable
```

### 방법 3: npm start

```bash
cd /Users/zzin/playmate/playmate_backend
npm start
```

## ✅ 서버가 정상적으로 시작되었는지 확인

서버가 시작되면 다음과 같은 메시지가 표시됩니다:

```
🔄 기존 서버 프로세스 정리 중...
🚀 안정적인 서버 시작 중...
📍 포트: 3000
🌍 환경: development
✅ 포트 3000 사용 가능
🚀 Server running on port 3000 in development mode
📱 API Base URL: http://localhost:3000/api
📱 API Base URL (Android): http://10.0.2.2:3000/api
📱 API Base URL (Network): http://192.168.6.100:3000/api
🔗 Health Check: http://localhost:3000/api/health
```

## 🔍 서버 상태 확인

**다른 터미널 창**에서 다음 명령어로 확인:

```bash
# 서버 실행 확인
lsof -i :3000

# 헬스 체크
curl http://localhost:3000/api/health
```

정상 응답:
```json
{"status":"ok","message":"Server is running"}
```

## ❌ 문제 해결

### 1. "포트 3000이 사용 중" 오류

```bash
# 포트 사용 중인 프로세스 확인
lsof -i :3000

# 프로세스 종료
kill -9 <PID>
```

또는

```bash
cd /Users/zzin/playmate/playmate_backend
npm run kill
```

### 2. "node_modules 없음" 오류

```bash
cd /Users/zzin/playmate/playmate_backend
npm install
```

### 3. "Node.js 버전 오류"

```bash
node --version
# Node.js 16 이상 필요
```

## 📱 앱 실행 순서

1. **먼저 서버 시작** (터미널 1)
   ```bash
   cd /Users/zzin/playmate/playmate_backend
   npm run dev:stable
   ```

2. **서버가 정상 시작되었는지 확인** (터미널 2)
   ```bash
   curl http://localhost:3000/api/health
   ```

3. **Flutter 앱 실행** (터미널 3 또는 IDE)
   ```bash
   cd /Users/zzin/playmate/playmate_app
   flutter run
   ```

## ⚠️ 주의사항

1. **서버는 별도 터미널에서 실행**해야 합니다
2. **서버를 종료하면 앱 연결이 끊어집니다**
3. **서버 종료**: `Ctrl+C` 누르기
4. **서버는 계속 실행 상태로 유지**해야 합니다

## 🔗 연결 정보

- **Android 에뮬레이터**: `http://10.0.2.2:3000/api`
- **iOS 시뮬레이터**: `http://localhost:3000/api`
- **실제 기기**: `http://192.168.6.100:3000/api` (네트워크 IP)

## 📝 체크리스트

앱 실행 전 확인:
- [ ] 백엔드 서버가 실행 중인가?
- [ ] `curl http://localhost:3000/api/health`가 정상 응답하는가?
- [ ] 포트 3000이 사용 가능한가?
- [ ] 서버 로그에 오류가 없는가?

---

**💡 팁**: 서버를 백그라운드로 실행하려면:
```bash
cd /Users/zzin/playmate/playmate_backend
nohup npm run dev:stable > server.log 2>&1 &
```

서버 로그 확인:
```bash
tail -f /Users/zzin/playmate/playmate_backend/server.log
```

