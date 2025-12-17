# 🍎 Apple Sign In Capability 설정 가이드 (단계별)

## 📋 준비사항
- [ ] Xcode가 설치되어 있어야 함
- [ ] Apple Developer 계정 (무료 계정도 가능, 하지만 제한적)
- [ ] 프로젝트가 열려 있어야 함

---

## 🔧 방법 1: Xcode에서 직접 설정 (가장 간단)

### Step 1: Xcode에서 프로젝트 열기
1. 터미널 또는 Finder에서 다음 경로로 이동:
   ```
   /Users/zzin/playmate/playmate_app/ios/
   ```
2. **`Runner.xcworkspace`** 파일을 더블클릭하여 Xcode로 열기
   - ⚠️ 주의: `.xcodeproj`가 아닌 `.xcworkspace` 파일을 열어야 합니다!
   - Flutter 프로젝트는 CocoaPods를 사용하므로 workspace 파일을 사용합니다

### Step 2: 프로젝트 설정 열기
1. Xcode 왼쪽 상단의 **프로젝트 네비게이터**에서 **`Runner`** (가장 위에 있는 파란색 아이콘) 클릭
2. 가운데 영역에서 **`TARGETS`** 아래의 **`Runner`** 선택
3. 상단 탭에서 **`Signing & Capabilities`** 탭 클릭

### Step 3: Capability 추가
1. 왼쪽 상단의 **`+ Capability`** 버튼 클릭
2. 검색창에 **`Sign In with Apple`** 입력
3. **`Sign In with Apple`** 선택 후 **`Add`** 클릭

### Step 4: 확인
- `Signing & Capabilities` 탭에 **`Sign In with Apple`**이 추가되었는지 확인
- ✅ 완료!

---

## 🌐 방법 2: Apple Developer 웹사이트에서 설정 (실제 기기 테스트용)

> **참고**: 시뮬레이터만 사용한다면 이 단계는 선택사항입니다.
> 실제 기기에서 테스트하려면 이 설정이 필요합니다.

### Step 1: Apple Developer 계정 로그인
1. [Apple Developer 웹사이트](https://developer.apple.com) 접속
2. Apple ID로 로그인
   - 무료 계정도 가능하지만, 일부 기능이 제한될 수 있습니다

### Step 2: App ID 찾기
1. 왼쪽 메뉴에서 **`Certificates, Identifiers & Profiles`** 클릭
2. **`Identifiers`** 클릭
3. 앱의 **Bundle ID**를 찾습니다
   - Xcode의 `Signing & Capabilities` 탭에서 Bundle Identifier 확인 가능
   - 보통 `com.example.playmate_app` 또는 유사한 형식

### Step 3: Sign In with Apple 활성화
1. 해당 App ID를 클릭하여 상세 페이지로 이동
2. **`Sign In with Apple`** 체크박스 찾기
3. 체크박스 선택
4. **`Configure`** 버튼 클릭 (있는 경우)
5. **`Save`** 버튼 클릭

### Step 4: Xcode에서 프로비저닝 프로파일 갱신
1. Xcode로 돌아가기
2. `Signing & Capabilities` 탭에서
3. **`Automatically manage signing`** 체크박스가 선택되어 있는지 확인
4. 선택되어 있지 않다면 선택
5. Xcode가 자동으로 프로비저닝 프로파일을 갱신합니다

---

## ✅ 설정 완료 확인

### 확인 방법 1: Xcode에서 확인
- `Signing & Capabilities` 탭에 **`Sign In with Apple`**이 표시되어 있으면 성공

### 확인 방법 2: 코드에서 확인
1. Xcode에서 `ios/Runner/Runner.entitlements` 파일 열기
2. 다음 내용이 있는지 확인:
   ```xml
   <key>com.apple.developer.applesignin</key>
   <array>
       <string>Default</string>
   </array>
   ```

### 확인 방법 3: 빌드 테스트
```bash
cd playmate_app
flutter build ios --no-codesign
```
- 빌드가 성공하면 설정이 올바르게 되어 있는 것입니다

---

## 🧪 테스트

### 시뮬레이터에서 테스트
1. Xcode에서 시뮬레이터 선택 (iOS 13.0 이상)
2. `Cmd + R` 또는 실행 버튼 클릭
3. 앱이 실행되면 로그인 화면에서 **Apple 로그인** 버튼 확인
4. 버튼 클릭 시 Apple 인증 화면이 나타나야 합니다

### 실제 기기에서 테스트
1. 실제 iOS 기기를 Mac에 연결
2. Xcode에서 해당 기기 선택
3. `Signing & Capabilities`에서 Team 선택 (Apple Developer 계정 필요)
4. 실행하여 테스트

---

## ⚠️ 문제 해결

### 문제 1: "Sign In with Apple"이 목록에 없어요
- **해결**: Xcode 버전이 11.0 이상인지 확인 (iOS 13+ 지원 필요)
- Xcode 업데이트: `App Store` → `업데이트` 탭

### 문제 2: Capability를 추가했는데 빌드 에러가 발생해요
- **해결 1**: Xcode에서 `Product` → `Clean Build Folder` (`Cmd + Shift + K`)
- **해결 2**: Flutter clean 후 다시 빌드:
  ```bash
  cd playmate_app
  flutter clean
  flutter pub get
  cd ios
  pod install
  cd ..
  flutter build ios
  ```

### 문제 3: Apple Developer 계정이 없어요
- **해결**: 시뮬레이터에서는 무료로 테스트 가능
- 실제 기기 테스트를 위해서는 Apple Developer 계정 필요 (연간 $99)

### 문제 4: "No accounts with App Store Connect access" 에러
- **해결**: 
  1. Xcode → `Preferences` → `Accounts` 탭
  2. Apple ID 추가
  3. Team 선택

### 문제 5: Bundle ID가 등록되어 있지 않아요
- **해결**: 
  1. Apple Developer에서 App ID 생성
  2. 또는 Xcode에서 `Automatically manage signing` 사용 시 자동 생성

---

## 📝 체크리스트

설정 완료 후 확인:
- [ ] Xcode에서 `Sign In with Apple` Capability 추가됨
- [ ] `Runner.entitlements` 파일에 설정이 추가됨
- [ ] 빌드가 성공적으로 완료됨
- [ ] 앱 실행 시 Apple 로그인 버튼이 표시됨
- [ ] Apple 로그인 버튼 클릭 시 인증 화면이 나타남

---

## 🎯 다음 단계

설정이 완료되면:
1. Xcode에서 앱 실행
2. Apple 로그인 버튼 테스트
3. 다른 기능들도 함께 테스트

---

**마지막 업데이트**: 2025-12-12  
**필요한 Xcode 버전**: 11.0 이상  
**필요한 iOS 버전**: 13.0 이상


