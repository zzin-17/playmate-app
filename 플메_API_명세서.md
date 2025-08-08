# 📡 API 명세서 for PlayMate (플메)

## 공통 사항
- Base URL: `https://api.playmate.app/v1/`
- 인증 방식: OAuth 2.0 (Bearer Token)
- 응답 형식: JSON (UTF-8)

---

## 1. 사용자 관련 API

### 🔹 회원가입
- `POST /users/register`
```json
{
  "email": "user@example.com",
  "password": "string",
  "nickname": "홍길동",
  "gender": "male",
  "birth_year": 1990
}
```

### 🔹 로그인
- `POST /auth/login`
```json
{
  "email": "user@example.com",
  "password": "string"
}
```

### 🔹 프로필 업데이트
- `PUT /users/me`
```json
{
  "region": "서울시 강남구",
  "skill_level": 3,
  "preferred_court": "탄천종합운동장",
  "preferred_time": ["주말 오전", "평일 저녁"]
}
```

---

## 2. 매칭 관련 API (핵심)

### 🔹 매칭 등록 (게스트 or 호스트)
- `POST /matchings`
```json
{
  "type": "host",
  "court_name": "잠실종합운동장",
  "court_lat": 37.512,
  "court_lng": 127.102,
  "date": "2025-08-07",
  "time_slot": "18:00~20:00",
  "min_level": 2,
  "max_level": 4,
  "gender_preference": "any",
  "recruit_count": 1
}
```

### 🔹 매칭 목록 조회 (필터 포함)
- `GET /matchings?region=서울&level=3&gender=male&date=2025-08-07`
```json
[
  {
    "id": 3021,
    "host_nickname": "테린이",
    "court_name": "양재시민의숲",
    "time_slot": "18:00~20:00",
    "skill_range": "2~4",
    "gender": "any",
    "status": "모집중"
  }
]
```

### 🔹 매칭 요청 보내기 (게스트 → 호스트)
- `POST /matchings/{matching_id}/request`
```json
{
  "message": "안녕하세요! 참가 신청 드립니다 :)"
}
```

### 🔹 매칭 수락 / 거절
- `POST /matchings/{matching_id}/respond`
```json
{
  "request_user_id": 10023,
  "action": "accept"
}
```

### 🔹 확정된 매칭 조회 (내 일정)
- `GET /matchings/my`

---

## 3. 후기 시스템 API

### 🔹 후기 작성
- `POST /reviews`
```json
{
  "matching_id": 3021,
  "target_user_id": 10023,
  "rating": 5,
  "comment": "매너 좋고 실력도 좋아요 :)"
}
```

### 🔹 후기 조회 (유저 프로필용)
- `GET /users/{user_id}/reviews`