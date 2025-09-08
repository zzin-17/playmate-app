# 🚀 API 연동 가이드

## 📋 완료된 API 연동 작업

### ✅ 1. 사용자 관련 API
- **UserService**: 사용자 프로필, 팔로우/언팔로우, 사용자 검색
- **연동 화면**: FollowListScreen, CommunityScreen (사용자 검색)
- **API 엔드포인트**:
  - `GET /users/me` - 내 프로필 조회
  - `PUT /users/me` - 프로필 업데이트
  - `GET /users/search` - 사용자 검색
  - `POST /users/{id}/follow` - 팔로우
  - `DELETE /users/{id}/follow` - 언팔로우
  - `GET /users/{id}/following` - 팔로잉 목록
  - `GET /users/{id}/followers` - 팔로워 목록

### ✅ 2. 커뮤니티 관련 API
- **CommunityService**: 게시글, 댓글, 좋아요, 북마크
- **연동 화면**: CommunityScreen
- **API 엔드포인트**:
  - `GET /posts` - 게시글 목록 조회
  - `POST /posts` - 게시글 작성
  - `PUT /posts/{id}` - 게시글 수정
  - `DELETE /posts/{id}` - 게시글 삭제
  - `POST /posts/{id}/like` - 좋아요 토글
  - `POST /posts/{id}/bookmark` - 북마크 토글
  - `GET /posts/{id}/comments` - 댓글 목록
  - `POST /posts/{id}/comments` - 댓글 작성
  - `GET /posts/my-posts` - 내 게시글
  - `GET /posts/my-bookmarks` - 내 북마크

### ✅ 3. 채팅 관련 API
- **ChatService**: 채팅방, 메시지, 참여자 관리
- **연동 화면**: ChatListScreen, ChatScreen
- **API 엔드포인트**:
  - `GET /chat/rooms/my` - 내 채팅방 목록
  - `POST /chat/rooms` - 채팅방 생성
  - `GET /chat/rooms/{id}/messages` - 메시지 조회
  - `POST /chat/rooms/{id}/messages` - 메시지 전송
  - `GET /chat/rooms/{id}/members` - 참여자 조회
  - `POST /chat/rooms/{id}/leave` - 채팅방 나가기
  - `POST /chat/rooms/{id}/read` - 읽음 처리

### ✅ 4. 매칭 관련 API
- **MatchingDataServiceV2**: 매칭 CRUD, 상태 관리
- **연동 화면**: HomeScreen, CreateMatchingScreen, MatchingDetailScreen
- **API 엔드포인트**:
  - `GET /matchings` - 매칭 목록 조회
  - `POST /matchings` - 매칭 생성
  - `GET /matchings/{id}` - 매칭 상세 조회
  - `PUT /matchings/{id}` - 매칭 수정
  - `POST /matchings/{id}/request` - 매칭 신청
  - `POST /matchings/{id}/respond` - 매칭 응답

### ✅ 5. 리뷰 관련 API
- **ReviewService**: 리뷰 조회, 작성
- **연동 화면**: MyReviewsScreen, WriteReviewScreen
- **API 엔드포인트**:
  - `GET /reviews/my` - 내 리뷰 목록
  - `POST /reviews` - 리뷰 작성
  - `GET /reviews/{id}` - 리뷰 상세

## 🔧 백엔드 서버 연동 방법

### 1. API 서버 설정
```dart
// lib/config/api_config.dart
class ApiConfig {
  // 실제 백엔드 서버 URL로 변경
  static const String devBaseUrl = 'http://your-backend-server.com';
  // 또는
  static const String devBaseUrl = 'http://192.168.1.100:3000'; // 로컬 네트워크
}
```

### 2. 환경별 설정
```dart
// 개발 환경
static const String _currentEnv = 'dev';

// 스테이징 환경
static const String _currentEnv = 'staging';

// 프로덕션 환경
static const String _currentEnv = 'prod';
```

### 3. 인증 토큰 확인
앱에서 사용하는 인증 토큰이 백엔드 서버와 호환되는지 확인:
- 토큰 형식: JWT, Bearer Token 등
- 토큰 저장: SharedPreferences의 'playmate_auth_token' 키
- 토큰 갱신: 필요시 refresh token 로직 추가

## 🧪 API 테스트 방법

### 1. 네트워크 연결 테스트
```dart
// 앱 실행 후 다음 기능들 테스트:
1. 로그인/회원가입
2. 홈화면 매칭 목록 로드
3. 커뮤니티 게시글 로드
4. 채팅방 목록 로드
5. 사용자 검색
```

### 2. 오류 처리 확인
- API 서버가 다운된 경우 Mock 데이터로 폴백되는지 확인
- 네트워크 오류 시 적절한 에러 메시지 표시되는지 확인
- 로딩 상태가 올바르게 표시되는지 확인

### 3. 로그 확인
```dart
// 개발 환경에서 API 로깅 활성화
static bool get enableApiLogging => true;

// 콘솔에서 다음 로그들 확인:
- API 요청/응답 로그
- 오류 메시지
- 폴백 처리 로그
```

## 🚨 주의사항

### 1. CORS 설정 (웹용)
웹에서 테스트하는 경우 백엔드 서버에서 CORS 설정 필요:
```javascript
// Express.js 예시
app.use(cors({
  origin: ['http://localhost:3000', 'https://your-domain.com'],
  credentials: true
}));
```

### 2. 네트워크 보안
- HTTPS 사용 권장 (프로덕션)
- API 키 보안 관리
- 민감한 데이터 암호화

### 3. 성능 최적화
- API 응답 캐싱
- 이미지 압축
- 무한 스크롤 최적화

## 📱 테스트 시나리오

### 기본 플로우 테스트
1. **회원가입/로그인** → 사용자 API 테스트
2. **매칭 생성** → 매칭 API 테스트
3. **게시글 작성** → 커뮤니티 API 테스트
4. **채팅 시작** → 채팅 API 테스트
5. **리뷰 작성** → 리뷰 API 테스트

### 오류 시나리오 테스트
1. **서버 다운** → Mock 데이터 폴백 확인
2. **네트워크 오류** → 에러 메시지 확인
3. **인증 실패** → 로그인 화면으로 리다이렉트 확인

## 🎯 다음 단계

1. **실제 백엔드 서버 구축**
2. **API 엔드포인트 구현**
3. **데이터베이스 설계**
4. **실시간 통신 (WebSocket) 구현**
5. **푸시 알림 서버 연동**

---

**문서 버전**: v1.0  
**최종 업데이트**: 2024년 12월  
**작성자**: AI Assistant
