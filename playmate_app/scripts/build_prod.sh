#!/bin/bash

echo "🚀 프로덕션 환경 빌드 시작..."

# 프로덕션 환경 변수 설정
export FLUTTER_ENV=production

# 의존성 설치
flutter pub get

# 코드 생성
flutter packages pub run build_runner build --delete-conflicting-outputs

# 프로덕션용 빌드 (최적화)
flutter build apk --dart-define=FLUTTER_ENV=production --release --obfuscate --split-debug-info=build/debug-info

echo "✅ 프로덕션 환경 빌드 완료!"
echo "📱 APK 위치: build/app/outputs/flutter-apk/app-release.apk"
echo "🔒 디버그 정보: build/debug-info/ (보안을 위해 별도 보관)"