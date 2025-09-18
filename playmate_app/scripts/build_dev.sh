#!/bin/bash

echo "🔧 개발 환경 빌드 시작..."

# 개발 환경 변수 설정
export FLUTTER_ENV=development

# 의존성 설치
flutter pub get

# 코드 생성
flutter packages pub run build_runner build --delete-conflicting-outputs

# 개발용 빌드
flutter build apk --dart-define=FLUTTER_ENV=development --debug

echo "✅ 개발 환경 빌드 완료!"
echo "📱 APK 위치: build/app/outputs/flutter-apk/app-debug.apk"