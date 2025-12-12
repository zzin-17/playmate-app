# 🔄 서버 자동 시작 가이드

## 문제점
- `npm run dev:stable`로 시작한 서버는 터미널을 닫으면 종료됨
- 시스템 재시작 시 서버가 자동으로 시작되지 않음
- 개발 중 서버가 종료되면 수동으로 다시 시작해야 함

## 해결 방법

### 방법 1: PM2 사용 (권장) ⭐

PM2는 프로세스 매니저로, 서버를 백그라운드에서 실행하고 자동 재시작을 관리합니다.

#### 1단계: PM2로 서버 시작
```bash
cd playmate_backend
npm run dev:persistent
```

또는 직접 PM2 사용:
```bash
npm run pm2:start
```

#### 2단계: 시스템 재시작 시 자동 시작 설정
```bash
# PM2 startup 스크립트 생성 (한 번만 실행)
pm2 startup

# 현재 실행 중인 프로세스 저장
pm2 save
```

이제 시스템을 재시작해도 서버가 자동으로 시작됩니다!

#### 3단계: 서버 관리 명령어
```bash
# 서버 상태 확인
npm run pm2:status
# 또는
pm2 status

# 로그 확인
npm run pm2:logs
# 또는
pm2 logs playmate-backend

# 서버 재시작
npm run pm2:restart
# 또는
pm2 restart playmate-backend

# 서버 중지
npm run pm2:stop
# 또는
pm2 stop playmate-backend

# 서버 삭제
npm run pm2:delete
# 또는
pm2 delete playmate-backend
```

### 방법 2: nohup 사용 (간단한 방법)

터미널을 닫아도 서버가 계속 실행되도록:
```bash
cd playmate_backend
nohup npm run dev:stable > logs/nohup.log 2>&1 &
```

서버 종료:
```bash
pkill -f "node start-stable.js"
```

### 방법 3: macOS launchd 사용 (시스템 재시작 시 자동 시작)

`~/Library/LaunchAgents/com.playmate.backend.plist` 파일 생성:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.playmate.backend</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>/Users/zzin/playmate/playmate_backend/start-stable.js</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/zzin/playmate/playmate_backend</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/zzin/playmate/playmate_backend/logs/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/zzin/playmate/playmate_backend/logs/launchd-error.log</string>
</dict>
</plist>
```

설정:
```bash
# launchd에 등록
launchctl load ~/Library/LaunchAgents/com.playmate.backend.plist

# 시작
launchctl start com.playmate.backend

# 중지
launchctl stop com.playmate.backend

# 제거
launchctl unload ~/Library/LaunchAgents/com.playmate.backend.plist
```

## 권장 설정

### 개발 환경
```bash
# PM2로 시작 (터미널 종료 후에도 계속 실행)
npm run dev:persistent
```

### 프로덕션 환경
```bash
# PM2로 시작 + 시스템 재시작 시 자동 시작
npm run pm2:start
pm2 startup
pm2 save
```

## 서버 상태 확인

### 현재 실행 중인 서버 확인
```bash
npm run status
```

### 포트 사용 확인
```bash
lsof -i :3000
```

### Health Check
```bash
curl http://localhost:3000/api/health
```

## 문제 해결

### 서버가 시작되지 않을 때
1. 포트 충돌 확인: `lsof -i :3000`
2. 기존 프로세스 종료: `npm run kill`
3. 다시 시작: `npm run dev:persistent`

### PM2 프로세스가 보이지 않을 때
```bash
pm2 list
pm2 status
```

### 로그 확인
```bash
# PM2 로그
pm2 logs playmate-backend

# 일반 로그
tail -f logs/server.log
tail -f logs/error.log
```

## 참고사항

- **PM2 사용 시**: 터미널을 닫아도 서버가 계속 실행됨
- **시스템 재시작 시**: `pm2 startup` + `pm2 save` 설정 필요
- **개발 중**: `npm run dev:stable` 사용 가능 (터미널 열어둔 상태)
- **프로덕션**: 반드시 PM2 사용 권장

