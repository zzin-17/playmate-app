# 🎾 Playmate Backend API

테니스 매칭 앱을 위한 Node.js 백엔드 서버입니다.

## 🚀 시작하기

### 필수 요구사항
- Node.js (v14 이상)
- npm 또는 yarn

### 설치 및 실행

1. **의존성 설치**
```bash
npm install
```

2. **환경 변수 설정**
```bash
# config.env 파일을 생성하고 필요한 환경 변수를 설정하세요
cp config.env.example config.env
```

3. **개발 서버 실행**
```bash
npm run dev
```

4. **프로덕션 서버 실행**
```bash
npm start
```

## 📡 API 엔드포인트

### 인증 (Authentication)
- `POST /api/v1/auth/register` - 회원가입
- `POST /api/v1/auth/login` - 로그인
- `GET /api/v1/auth/me` - 현재 사용자 정보 조회
- `PUT /api/v1/auth/profile` - 프로필 업데이트

### 사용자 (Users)
- `GET /api/v1/users/search` - 사용자 검색
- `POST /api/v1/users/:id/follow` - 팔로우
- `DELETE /api/v1/users/:id/follow` - 언팔로우
- `GET /api/v1/users/:id/following` - 팔로잉 목록
- `GET /api/v1/users/:id/followers` - 팔로워 목록

### 매칭 (Matchings)
- `GET /api/v1/matchings` - 매칭 목록 조회
- `POST /api/v1/matchings` - 매칭 생성
- `GET /api/v1/matchings/:id` - 매칭 상세 조회
- `PUT /api/v1/matchings/:id` - 매칭 수정
- `POST /api/v1/matchings/:id/request` - 매칭 신청
- `POST /api/v1/matchings/:id/respond` - 매칭 응답

### 커뮤니티 (Community)
- `GET /api/v1/posts` - 게시글 목록 조회
- `POST /api/v1/posts` - 게시글 작성
- `GET /api/v1/posts/:id` - 게시글 상세 조회
- `PUT /api/v1/posts/:id` - 게시글 수정
- `DELETE /api/v1/posts/:id` - 게시글 삭제
- `POST /api/v1/posts/:id/like` - 좋아요 토글
- `POST /api/v1/posts/:id/bookmark` - 북마크 토글

### 채팅 (Chat)
- `GET /api/v1/chat/rooms/my` - 내 채팅방 목록
- `POST /api/v1/chat/rooms` - 채팅방 생성
- `GET /api/v1/chat/rooms/:id/messages` - 메시지 조회
- `POST /api/v1/chat/rooms/:id/messages` - 메시지 전송
- `GET /api/v1/chat/rooms/:id/members` - 참여자 조회
- `POST /api/v1/chat/rooms/:id/leave` - 채팅방 나가기

### 리뷰 (Reviews)
- `GET /api/v1/reviews/my` - 내 리뷰 목록
- `POST /api/v1/reviews` - 리뷰 작성
- `GET /api/v1/reviews/:id` - 리뷰 상세 조회

## 🔌 Socket.IO 이벤트

### 클라이언트 → 서버
- `authenticate` - 사용자 인증
- `join_room` - 채팅방 참여
- `leave_room` - 채팅방 나가기
- `send_message` - 메시지 전송
- `typing_start` - 타이핑 시작
- `typing_stop` - 타이핑 중지

### 서버 → 클라이언트
- `authenticated` - 인증 완료
- `authentication_error` - 인증 실패
- `user_joined` - 사용자 참여
- `user_left` - 사용자 나감
- `new_message` - 새 메시지
- `user_typing` - 사용자 타이핑 상태

## 🛠️ 개발 환경

### 프로젝트 구조
```
src/
├── controllers/     # 컨트롤러
├── middleware/      # 미들웨어
├── models/          # 데이터 모델
├── routes/          # 라우트
├── services/        # 서비스
├── utils/           # 유틸리티
├── app.js           # Express 앱 설정
└── server.js        # 서버 진입점
```

### 환경 변수
- `PORT` - 서버 포트 (기본값: 3000)
- `NODE_ENV` - 환경 (development/production)
- `JWT_SECRET` - JWT 시크릿 키
- `JWT_EXPIRES_IN` - JWT 만료 시간
- `CORS_ORIGIN` - CORS 허용 오리진

## 📝 라이선스

MIT License
