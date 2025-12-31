#!/bin/bash

# PlayMate 백엔드 서버 시작 스크립트

echo "🚀 PlayMate 백엔드 서버 시작 중..."
echo ""

# 백엔드 디렉토리로 이동
cd "$(dirname "$0")/playmate_backend" || exit 1

# Node.js 설치 확인
if ! command -v node &> /dev/null; then
    echo "❌ Node.js가 설치되어 있지 않습니다."
    echo "   Node.js 16 이상을 설치해주세요."
    exit 1
fi

# npm 설치 확인
if ! command -v npm &> /dev/null; then
    echo "❌ npm이 설치되어 있지 않습니다."
    exit 1
fi

# 의존성 설치 확인
if [ ! -d "node_modules" ]; then
    echo "📦 의존성 설치 중..."
    npm install
fi

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

# 서버 시작
echo "✅ 서버 시작 중..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  서버 로그 (Ctrl+C로 종료)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

npm run dev:stable
