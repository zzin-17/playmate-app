# 📱 iOS 테스트 가이드

## ✅ 테스트 전 확인사항

### 1. 백엔드 서버 실행 확인
```bash
# 서버 상태 확인
curl http://192.168.6.100:3000/api/health

# 서버가 실행 중이 아니면 시작
cd playmate_backend
npm run dev:persistent
```

### 2. Xcode 프로젝트 열기
```bash
cd playmate_app
open ios/Runner.xcworkspace
```

⚠️ **중요**: `.xcodeproj`가 아닌 `.xcworkspace`를 열어야 합니다!

### 3. Apple Sign In Capability 설정 (필수)

#### 3-1. Xcode에서 설정
1. Xcode에서 `Runner` 프로젝트 선택
2. `Signing & Capabilities` 탭 클릭
3. `+ Capability` 버튼 클릭
4. `Sign In with Apple` 선택하여 추가

#### 3-2. Apple Developer 계정 설정
- 실제 기기에서 테스트하려면 Apple Developer 계정 필요
- 시뮬레이터에서는 Capability 없이도 테스트 가능 (제한적)

### 4. Bundle Identifier 확인
- Xcode에서 `Runner` → `Signing & Capabilities`에서 Bundle ID 확인
- Apple Developer에서 해당 Bundle ID에 Sign In with Apple 활성화 필요

---

## 🧪 테스트 항목

### ✅ 기본 기능 테스트

#### 1. 앱 실행
- [ ] 앱이 정상적으로 시작되는지 확인
- [ ] 로그인 화면이 표시되는지 확인
- [ ] Apple 로그인 버튼이 표시되는지 확인 (iOS에서만)

#### 2. Apple 로그인 테스트
- [ ] Apple 로그인 버튼 클릭
- [ ] Apple 인증 화면이 나타나는지 확인
- [ ] 로그인 성공 시 홈 화면으로 이동하는지 확인
- [ ] 로그인 취소 시 적절한 메시지가 표시되는지 확인

#### 3. 일반 로그인 테스트
- [ ] 이메일/비밀번호 로그인이 정상 작동하는지 확인
- [ ] 로그인 실패 시 에러 메시지가 표시되는지 확인

#### 4. 프로필 업데이트 테스트
- [ ] 프로필 편집 화면 진입
- [ ] 닉네임 변경 후 저장
- [ ] 변경사항이 서버에 반영되는지 확인

#### 5. 매칭 기능 테스트
- [ ] 매칭 목록이 정상적으로 로드되는지 확인
- [ ] 매칭 상세 화면 진입
- [ ] 매칭 확정/취소 버튼 동작 확인 (호스트 권한)

#### 6. 에러 처리 테스트
- [ ] 네트워크 오류 시 사용자 친화적 메시지 표시
- [ ] 로딩 인디케이터가 적절히 표시되는지 확인

---

## 🐛 문제 해결

### Apple 로그인이 작동하지 않을 때

#### 문제 1: "Sign In with Apple" Capability가 없음
**해결**: Xcode에서 Capability 추가 (위 3-1 참고)

#### 문제 2: "Invalid client" 오류
**해결**: 
1. Apple Developer 계정에서 Bundle ID 확인
2. Sign In with Apple 활성화 확인
3. Xcode에서 Signing 설정 확인

#### 문제 3: 시뮬레이터에서 작동하지 않음
**해결**: 
- iOS 13+ 시뮬레이터 사용
- 실제 기기에서 테스트 권장

### 서버 연결 오류

#### 문제: "Connection refused"
**해결**:
```bash
# 서버 상태 확인
cd playmate_backend
npm run status

# 서버 시작
npm run dev:persistent
```

### 빌드 오류

#### 문제: CocoaPods 오류
**해결**:
```bash
cd playmate_app/ios
pod install
```

#### 문제: Signing 오류
**해결**:
- Xcode에서 `Signing & Capabilities` → `Automatically manage signing` 체크
- Team 선택

---

## 📋 테스트 체크리스트

### 필수 테스트
- [ ] 앱 실행 및 로그인 화면 표시
- [ ] Apple 로그인 버튼 표시 (iOS)
- [ ] 일반 로그인 작동
- [ ] 서버 연결 확인

### 권장 테스트
- [ ] Apple 로그인 전체 플로우
- [ ] 프로필 업데이트
- [ ] 매칭 기능
- [ ] 에러 처리

---

## 🚀 빠른 시작

```bash
# 1. 백엔드 서버 시작
cd playmate_backend
npm run dev:persistent

# 2. Xcode에서 프로젝트 열기
cd ../playmate_app
open ios/Runner.xcworkspace

# 3. Xcode에서 실행
# - 시뮬레이터 선택 (iOS 13+)
# - 또는 실제 기기 연결
# - Run 버튼 클릭 (⌘R)
```

---

## 💡 참고사항

### 시뮬레이터 vs 실제 기기
- **시뮬레이터**: 기본 기능 테스트 가능, Apple 로그인 제한적
- **실제 기기**: 모든 기능 완전 테스트 가능, Apple Developer 계정 필요

### 네트워크 설정
- **시뮬레이터**: `http://localhost:3000/api` 사용
- **실제 기기**: `http://192.168.6.100:3000/api` 사용 (같은 WiFi)

---

**마지막 업데이트**: 2025-12-12

