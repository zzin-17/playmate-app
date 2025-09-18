#!/bin/bash

echo "🔍 PlayMate 시스템 상태 점검 시작..."
echo "=================================="

# 1. 백엔드 서버 확인
echo "1️⃣ 백엔드 서버 확인..."
if pgrep -f "node src/server.js" > /dev/null; then
    echo "✅ 백엔드 서버 실행 중"
    PORT_PID=$(lsof -ti:3000)
    if [ ! -z "$PORT_PID" ]; then
        echo "✅ 포트 3000 정상 바인딩 (PID: $PORT_PID)"
    else
        echo "❌ 포트 3000 바인딩 실패"
        exit 1
    fi
else
    echo "❌ 백엔드 서버 실행되지 않음"
    echo "🔄 백엔드 서버 시작 중..."
    cd /Users/zzin/playmate/playmate_backend && node src/server.js &
    sleep 5
fi

# 2. API Health Check
echo ""
echo "2️⃣ API Health Check..."
HEALTH_RESPONSE=$(curl -s http://192.168.6.100:3000/api/health)
if echo "$HEALTH_RESPONSE" | grep -q '"success":true'; then
    echo "✅ API Health Check 통과"
else
    echo "❌ API Health Check 실패"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi

# 3. Flutter 앱 확인
echo ""
echo "3️⃣ Flutter 앱 확인..."
if pgrep -f "flutter run" > /dev/null; then
    echo "✅ Flutter 앱 실행 중"
else
    echo "❌ Flutter 앱 실행되지 않음"
    echo "🔄 Flutter 앱 시작 중..."
    cd /Users/zzin/playmate/playmate_app && flutter run &
fi

echo ""
echo "=================================="
echo "🎉 시스템 점검 완료!"
echo "📱 백엔드: http://192.168.6.100:3000"
echo "🔗 Health Check: http://192.168.6.100:3000/api/health"
