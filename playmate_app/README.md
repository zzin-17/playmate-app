# 🎾 플메 (PlayMate) - 테니스 동호인 매칭 앱

테니스 동호인들을 위한 지역 기반 매칭 서비스입니다. 게스트를 구하기 어려운 문제를 해결하고, 테니스 동호인들이 쉽게 파트너를 찾을 수 있도록 도와줍니다.

## 📱 주요 기능

### 🔐 인증 시스템
- 이메일/비밀번호 로그인
- SNS 간편 로그인 (카카오, Apple) - 준비 중
- 회원가입 및 프로필 설정

### 🎯 매칭 시스템
- **게스트 찾기**: 호스트가 게스트를 모집
- **호스트 찾기**: 게스트가 호스트를 찾기
- 조건별 필터링 (구력, 성별, 지역, 시간대)
- 매칭 요청/수락 시스템

### 📍 코트 기반 기능
- 위치 기반 코트 탐색
- 인기 코트 및 즐겨찾기
- 코트별 매칭 일정 확인

### ⭐ 후기 시스템
- 경기 완료 후 상호 리뷰
- 별점 및 텍스트 리뷰
- 매너 점수 시스템

### 💬 커뮤니티
- 자유게시판
- 지역 기반 게시판
- 후기 공유 및 정보 교환

### 🛒 중고거래
- 테니스 용품 중고거래
- 라켓, 의류, 볼 등 카테고리별 분류
- 채팅 기능을 통한 거래

## 🛠 기술 스택

- **Frontend**: Flutter 3.8.1
- **State Management**: Provider
- **Network**: Dio
- **Local Storage**: SharedPreferences
- **Maps**: Google Maps Flutter
- **Authentication**: Kakao SDK, Apple Sign In
- **Image**: Cached Network Image, Image Picker

## 🚀 설치 및 실행

### 필수 요구사항
- Flutter SDK 3.8.1 이상
- Dart SDK 3.0.0 이상
- Android Studio / VS Code
- iOS 개발을 위한 Xcode (macOS)

### 설치 방법

1. **저장소 클론**
```bash
git clone [repository-url]
cd playmate_app
```

2. **의존성 설치**
```bash
flutter pub get
```

3. **모델 파일 생성**
```bash
flutter packages pub run build_runner build
```

4. **앱 실행**
```bash
flutter run
```

## 📁 프로젝트 구조

```
lib/
├── constants/          # 앱 상수 (색상, 텍스트 스타일)
├── models/            # 데이터 모델
├── providers/         # 상태 관리
├── screens/           # 화면 UI
│   ├── auth/         # 인증 관련 화면
│   └── home/         # 홈 화면
├── services/          # API 서비스
├── utils/            # 유틸리티 함수
└── widgets/          # 공통 위젯
    └── common/       # 기본 UI 컴포넌트
```

## 🎨 디자인 시스템

### 색상
- **Primary**: #1D9A6C (테니스 코트 그린)
- **Accent**: #F5D547 (테니스볼 옐로우)
- **Background**: #F8F8F8 / #FFFFFF
- **Text**: #333333 / #777777

### 타이포그래피
- **H1**: 20pt Bold (Pretendard)
- **H2**: 16pt Medium (Pretendard)
- **Body**: 14pt Regular (Pretendard)
- **Caption**: 12pt Light (Pretendard)

## 🔧 개발 환경 설정

### API 설정
현재 개발 중인 상태로, 실제 API 서버가 연결되지 않았습니다. 
API 서버가 준비되면 `lib/services/api_service.dart`에서 base URL을 수정하세요.

### 환경 변수
필요한 경우 `.env` 파일을 생성하여 API 키 등을 관리할 수 있습니다.

## 📋 개발 로드맵

### Phase 1 (현재)
- [x] 프로젝트 구조 설정
- [x] 디자인 시스템 구현
- [x] 인증 시스템 (기본)
- [x] 홈 화면 UI
- [ ] 매칭 시스템 구현

### Phase 2
- [ ] 코트 찾기 기능
- [ ] 지도 연동
- [ ] 후기 시스템
- [ ] 프로필 관리

### Phase 3
- [ ] 커뮤니티 기능
- [ ] 중고거래 시스템
- [ ] SNS 로그인 연동
- [ ] 푸시 알림

### Phase 4
- [ ] 성능 최적화
- [ ] 테스트 코드 작성
- [ ] 배포 준비

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성해 주세요.

---

**플메**와 함께 테니스를 더욱 즐겁게! 🎾
