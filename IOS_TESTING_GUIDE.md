# 🍎 iOS 테스트 가이드

## ✅ Xcode 테스트 전 확인사항

### 1. 백엔드 서버 실행 확인
```bash
# 서버 상태 확인
curl http://192.168.6.100:3000/api/health

# 서버가 실행되지 않았다면
cd playmate_backend
npm run dev:persistent
```

### 2. iOS 시뮬레이터/기기 준비
- [ ] Xcode가 설치되어 있는지 확인
- [ ] iOS 시뮬레이터 또는 실제 iOS 기기 준비
- [ ] iOS 13.0 이상 (Apple Sign In 지원)

### 3. Apple Sign In Capability 설정 (필수!)

#### Xcode에서 설정:
1. Xcode에서 `playmate_app/ios/Runner.xcworkspace` 열기
2. 프로젝트 네비게이터에서 `Runner` 선택
3. `Signing & Capabilities` 탭 클릭
4. `+ Capability` 버튼 클릭
5. `Sign In with Apple` 추가

#### Apple Developer 계정 설정:
1. [Apple Developer](https://developer.apple.com) 접속
2. Certificates, Identifiers & Profiles > Identifiers
3. 앱의 Bundle ID 선택
4. `Sign In with Apple` Capability 활성화
5. `Configure` 클릭하여 설정 완료

**⚠️ 중요**: Capability 설정 없이는 Apple 로그인이 작동하지 않습니다!

---

## 🧪 테스트 항목

### 1. Apple 로그인 테스트
- [ ] Apple 로그인 버튼이 표시되는지 확인
- [ ] 버튼 클릭 시 Apple 인증 화면이 나타나는지 확인
- [ ] Apple ID로 로그인 성공 시 홈 화면으로 이동하는지 확인
- [ ] 신규 사용자 자동 회원가입이 되는지 확인
- [ ] 기존 사용자 자동 로그인이 되는지 확인

### 2. 일반 로그인 테스트
- [ ] 이메일/비밀번호 로그인이 정상 작동하는지 확인
- [ ] 로그인 실패 시 에러 메시지가 표시되는지 확인

### 3. 프로필 업데이트 테스트
- [ ] 프로필 편집 화면 진입
- [ ] 닉네임 변경 후 저장
- [ ] 변경사항이 서버에 반영되는지 확인

### 4. 매칭 기능 테스트
- [ ] 매칭 목록이 정상적으로 로드되는지 확인
- [ ] 매칭 상세 화면 진입
- [ ] 매칭 확정/취소/완료 버튼 동작 확인

### 5. 에러 처리 테스트
- [ ] 네트워크 오류 시 사용자 친화적 메시지 표시 확인
- [ ] 로딩 인디케이터가 적절히 표시되는지 확인

---

## 🚀 Xcode에서 실행하기

### 방법 1: Xcode에서 직접 실행
1. Xcode에서 `playmate_app/ios/Runner.xcworkspace` 열기
2. 시뮬레이터 또는 기기 선택
3. `Cmd + R` 또는 실행 버튼 클릭

### 방법 2: Flutter 명령어 사용
```bash
cd playmate_app
flutter run -d ios
```

### 방법 3: 특정 시뮬레이터 선택
```bash
# 사용 가능한 디바이스 확인
flutter devices

# 특정 디바이스에서 실행
flutter run -d "iPhone 15 Pro"
```

---

## 🔍 디버깅 팁

### 로그 확인
- Xcode Console에서 Flutter 로그 확인
- `print()` 문으로 디버깅
- `flutter logs` 명령어 사용

### 네트워크 확인
- iOS 시뮬레이터는 `localhost:3000` 사용
- 실제 기기는 `192.168.6.100:3000` 사용
- API 설정 확인: `playmate_app/lib/config/api_config.dart`

### Apple 로그인 문제 해결
1. Capability 설정 확인
2. Bundle ID가 Apple Developer에 등록되어 있는지 확인
3. Sign In with Apple이 활성화되어 있는지 확인
4. Xcode에서 Clean Build (`Cmd + Shift + K`) 후 다시 빌드

---

## ⚠️ 주의사항

### Apple 로그인
- **시뮬레이터**: 기본적으로 작동하지만 제한적
- **실제 기기**: Apple ID로 로그인 테스트 가능
- **Capability 미설정**: 앱이 크래시하거나 버튼이 작동하지 않음

### 네트워크 연결
- iOS 시뮬레이터는 `localhost` 사용
- 실제 기기는 네트워크 IP 사용
- 백엔드 서버가 실행 중이어야 함

### 서버 연결
- 서버가 실행되지 않으면 모든 API 호출 실패
- `npm run dev:persistent`로 서버를 영구 실행 모드로 시작 권장

---

## 📝 테스트 완료 체크리스트

- [ ] 백엔드 서버 실행 확인
- [ ] Apple Sign In Capability 설정 완료
- [ ] Xcode에서 앱 빌드 성공
- [ ] Apple 로그인 버튼 표시 확인
- [ ] Apple 로그인 기능 테스트 완료
- [ ] 일반 로그인 기능 테스트 완료
- [ ] 프로필 업데이트 테스트 완료
- [ ] 매칭 기능 테스트 완료
- [ ] 에러 처리 테스트 완료

---

**마지막 업데이트**: 2025-12-12  
**테스트 환경**: iOS 13.0+, Xcode 14.0+
