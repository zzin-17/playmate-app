#!/bin/bash

# PlayMate 개발 환경 통합 시작 스크립트
# 서버와 앱을 함께 시작합니다

echo "🚀 PlayMate 개발 환경 시작"
echo "=========================="
echo ""

# 프로젝트 루트로 이동
cd "$(dirname "$0")" || exit 1

# 1. 백엔드 서버 시작
echo "1️⃣ 백엔드 서버 시작 중..."
cd playmate_backend || exit 1

# 기존 서버 프로세스 종료
echo "🔄 기존 서버 프로세스 정리 중..."
pkill -f 'node.*server.js' 2>/dev/null || true
pkill -f 'node.*start-stable.js' 2>/dev/null || true
sleep 2

# 포트 3000 사용 확인
if lsof -i :3000 &> /dev/null; then
    echo "⚠️  포트 3000이 사용 중입니다. 프로세스를 종료합니다..."
    lsof -ti :3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# 서버를 백그라운드로 시작
echo "✅ 서버 시작 중..."
npm run dev:stable > ../server.log 2>&1 &
SERVER_PID=$!

# 서버 시작 대기
echo "⏳ 서버 시작 대기 중..."
sleep 5

# 서버 상태 확인
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "✅ 서버가 정상적으로 시작되었습니다 (PID: $SERVER_PID)"
    echo "📡 API: http://localhost:3000/api"
else
    echo "❌ 서버 시작 실패. 로그를 확인하세요: tail -f server.log"
    exit 1
fi

# 2. Flutter 앱 시작
echo ""
echo "2️⃣ Flutter 앱 시작 중..."
cd ../playmate_app || exit 1

# Flutter 의존성 확인
if [ ! -d "build" ]; then
    echo "📦 Flutter 의존성 설치 중..."
    flutter pub get
fi

echo ""
echo "=========================="
echo "✅ 개발 환경 준비 완료!"
echo ""
echo "📱 서버: http://localhost:3000/api"
echo "📱 Android: http://10.0.2.2:3000/api"
echo "📱 iOS: http://localhost:3000/api"
echo ""
echo "💡 서버 로그: tail -f server.log"
echo "💡 서버 종료: kill $SERVER_PID"
echo ""
echo "Flutter 앱을 실행하려면:"
echo "  flutter run"
echo ""

# 사용자에게 선택권 제공
read -p "지금 Flutter 앱을 실행하시겠습니까? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    flutter run
fi

