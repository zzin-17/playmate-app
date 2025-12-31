# 서버 연결 문제 예방 가이드

## 🛡️ 예방 조치

다음 조치들이 이미 적용되어 서버 연결 문제를 예방합니다:

### 1. ✅ 개선된 에러 메시지

`ErrorHandler`가 서버 미실행 상황을 감지하고 명확한 안내를 제공합니다:

- **Connection refused** 감지 시 서버 시작 방법 안내
- 개발 환경에서 서버 시작 명령어 표시

### 2. ✅ 연결 상태 모니터링

`ConnectionMonitorService`가 30초마다 서버 연결 상태를 체크합니다:

- 연결 실패 시 자동 감지
- 서버 미실행 감지 시 콘솔에 안내 메시지 출력
- 연결 복구 시 자동 감지

### 3. ✅ 서버 연결 안내 다이얼로그

`ServerConnectionDialog` 위젯이 서버 연결 실패 시 안내를 제공합니다:

- 서버 시작 방법 안내
- 서버 상태 확인 명령어 제공
- 재시도 버튼 제공

### 4. ✅ 통합 개발 스크립트

`start_dev.sh` 스크립트로 서버와 앱을 함께 시작할 수 있습니다:

```bash
./start_dev.sh
```

이 스크립트는:
- 백엔드 서버를 자동으로 시작
- 서버 상태를 확인
- Flutter 앱 실행 옵션 제공

## 📋 사용 방법

### 방법 1: 통합 스크립트 사용 (권장)

```bash
cd /Users/zzin/playmate
./start_dev.sh
```

이 스크립트가 자동으로:
1. 기존 서버 프로세스 정리
2. 백엔드 서버 시작
3. 서버 상태 확인
4. Flutter 앱 실행 옵션 제공

### 방법 2: 수동 시작

#### 1단계: 서버 시작
```bash
cd /Users/zzin/playmate/playmate_backend
npm run dev:stable
```

#### 2단계: 서버 확인
```bash
curl http://localhost:3000/api/health
```

#### 3단계: 앱 실행
```bash
cd /Users/zzin/playmate/playmate_app
flutter run
```

## 🔍 문제 감지

### 앱에서 자동 감지

앱이 시작되면 `ConnectionMonitorService`가 자동으로:
- 서버 연결 상태를 체크
- 연결 실패 시 콘솔에 안내 메시지 출력
- 개발 환경에서 서버 시작 방법 안내

### 에러 메시지

서버 연결 실패 시:
- **개발 환경**: 서버 시작 방법 안내 포함
- **프로덕션 환경**: 일반적인 네트워크 오류 메시지

## 🚨 여전히 문제가 발생하는 경우

### 체크리스트

1. **서버가 실행 중인가?**
   ```bash
   lsof -i :3000
   curl http://localhost:3000/api/health
   ```

2. **포트가 사용 가능한가?**
   ```bash
   lsof -i :3000
   # 사용 중이면: kill -9 <PID>
   ```

3. **의존성이 설치되어 있는가?**
   ```bash
   cd playmate_backend
   npm install
   ```

4. **Node.js 버전이 올바른가?**
   ```bash
   node --version
   # Node.js 16 이상 필요
   ```

## 📝 추가 개선 사항

### 향후 개선 가능한 기능

1. **자동 서버 시작** (선택사항)
   - 앱에서 서버 시작 스크립트 실행
   - 보안상 권장하지 않음

2. **서버 상태 위젯**
   - 앱 내에서 서버 연결 상태 표시
   - 연결 실패 시 안내 다이얼로그 자동 표시

3. **개발 환경 자동 감지**
   - 개발/프로덕션 환경 자동 구분
   - 개발 환경에서만 상세 안내 제공

## 💡 팁

### 서버를 백그라운드로 실행

```bash
cd /Users/zzin/playmate/playmate_backend
nohup npm run dev:stable > ../server.log 2>&1 &
```

### 서버 로그 확인

```bash
tail -f /Users/zzin/playmate/server.log
```

### 서버 종료

```bash
cd /Users/zzin/playmate/playmate_backend
npm run kill
```

또는

```bash
pkill -f 'node.*server.js'
```

## 📚 관련 문서

- `QUICK_START_SERVER.md` - 서버 빠른 시작 가이드
- `SERVER_CONNECTION_TROUBLESHOOTING.md` - 서버 연결 문제 해결
- `start_dev.sh` - 통합 개발 스크립트

