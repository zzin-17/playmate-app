#!/bin/bash

# PlayMate 백엔드 서버 시작 스크립트
# 포트 충돌 방지 및 자동 재시작

echo "🚀 PlayMate 백엔드 서버 시작 중..."

# 기존 프로세스 종료
echo "🧹 기존 서버 프로세스 정리 중..."
pkill -f "node src/server.js" 2>/dev/null || true
sleep 2

# 백엔드 디렉토리로 이동
cd /Users/zzin/playmate/playmate_backend

# 포트 사용 확인
PORT=3000
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️ 포트 $PORT이 사용 중입니다. 정리 중..."
    lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# 서버 시작
echo "🔄 서버 시작 중... (포트: $PORT)"
PORT=$PORT node src/server.js &

# 서버 시작 확인
sleep 3
if curl -s http://localhost:$PORT/api/health > /dev/null; then
    echo "✅ 서버가 성공적으로 시작되었습니다!"
    echo "📱 API Base URL: http://localhost:$PORT/api"
    echo "📱 Network URL: http://192.168.6.100:$PORT/api"
else
    echo "❌ 서버 시작에 실패했습니다."
    exit 1
fi

echo "🎉 백엔드 서버 준비 완료!"
