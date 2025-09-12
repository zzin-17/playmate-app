class AppConstants {
  // API 관련 상수
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String websocketUrl = 'http://10.0.2.2:8080';
  static const String apiVersion = '/api';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration websocketTimeout = Duration(seconds: 20);
  
  // 카카오 API 관련 상수
  static const String kakaoApiKey = '4768187af5b0b45f9a6cb1a963f0a51a';
  static const String kakaoBaseUrl = 'https://dapi.kakao.com/v2';
  static const String kakaoLocalSearchUrl = '$kakaoBaseUrl/local/search/keyword.json';
  static const String kakaoCategorySearchUrl = '$kakaoBaseUrl/local/search/category.json';
  
  // 페이지네이션
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // 매칭 관련 상수
  static const List<String> gameTypes = [
    'mixed',
    'male_doubles', 
    'female_doubles',
    'singles',
    'rally'
  ];
  
  static const List<String> gameTypeNames = [
    '혼복',
    '남복',
    '여복', 
    '단식',
    '랠리'
  ];
  
  static const List<int> skillLevels = [1, 2, 3, 4, 5];
  static const List<String> skillLevelNames = [
    '입문자',
    '초급자',
    '중급자',
    '고급자',
    '전문가'
  ];
  
  static const List<String> timeSlots = [
    '06:00~08:00',
    '08:00~10:00',
    '10:00~12:00',
    '12:00~14:00',
    '14:00~16:00',
    '16:00~18:00',
    '18:00~20:00',
    '20:00~22:00',
    '22:00~24:00',
  ];
  
  // 매칭 상태
  static const List<String> matchingStatuses = [
    'recruiting',
    'confirmed',
    'completed',
    'cancelled',
    'deleted'
  ];
  
  static const List<String> matchingStatusNames = [
    '모집중',
    '확정',
    '완료',
    '취소',
    '삭제됨'
  ];
  
  // 지역 관련 상수
  static const List<String> regions = [
    '서울',
    '경기',
    '인천',
    '부산',
    '대구',
    '광주',
    '대전',
    '울산',
    '세종',
    '강원',
    '충북',
    '충남',
    '전북',
    '전남',
    '경북',
    '경남',
    '제주'
  ];
  
  // 서울 구 목록
  static const List<String> seoulDistricts = [
    '강남구',
    '강동구',
    '강북구',
    '강서구',
    '관악구',
    '광진구',
    '구로구',
    '금천구',
    '노원구',
    '도봉구',
    '동대문구',
    '동작구',
    '마포구',
    '서대문구',
    '서초구',
    '성북구',
    '송파구',
    '양천구',
    '영등포구',
    '용산구',
    '은평구',
    '종로구',
    '중구',
    '중랑구'
  ];
  
  // 테니스장 시설
  static const List<String> tennisFacilities = [
    '주차장',
    '샤워실',
    '락커룸',
    '조명시설',
    '매점',
    '휴게실',
    '코치',
    '장비대여',
    '음료자판기',
    'WiFi'
  ];
  
  // 코트 표면 타입
  static const List<String> surfaceTypes = [
    '하드코트',
    '클레이코트',
    '잔디코트',
    '인조잔디',
    '아스팔트',
    '콘크리트'
  ];
  
  // 채팅 관련 상수
  static const int maxMessageLength = 1000;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  
  // 커뮤니티 관련 상수
  static const int maxPostTitleLength = 100;
  static const int maxPostContentLength = 5000;
  static const int maxCommentLength = 1000;
  static const int maxReplyLength = 500;
  
  // 알림 관련 상수
  static const int maxNotificationHistory = 100;
  static const Duration notificationDisplayDuration = Duration(seconds: 3);
  
  // 파일 업로드 관련
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt'
  ];
  
  // 검색 관련
  static const int minSearchLength = 2;
  static const int maxSearchResults = 50;
  static const Duration searchDebounceDelay = Duration(milliseconds: 300);
  
  // UI 관련 상수
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // 애니메이션 관련
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // 네트워크 관련
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // 캐시 관련
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;
  
  // 보안 관련
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int maxNicknameLength = 20;
  static const int minNicknameLength = 2;
  
  // 날짜/시간 관련
  static const List<String> weekdays = [
    '월', '화', '수', '목', '금', '토', '일'
  ];
  
  static const List<String> months = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월'
  ];
  
  // 에러 메시지
  static const String networkErrorMessage = '네트워크 연결을 확인해주세요.';
  static const String serverErrorMessage = '서버 오류가 발생했습니다.';
  static const String unknownErrorMessage = '알 수 없는 오류가 발생했습니다.';
  static const String timeoutErrorMessage = '요청 시간이 초과되었습니다.';
  
  // 성공 메시지
  static const String successMessage = '성공적으로 처리되었습니다.';
  static const String saveSuccessMessage = '저장되었습니다.';
  static const String deleteSuccessMessage = '삭제되었습니다.';
  static const String updateSuccessMessage = '수정되었습니다.';
  
  // 유효성 검사 메시지
  static const String requiredFieldMessage = '필수 입력 항목입니다.';
  static const String invalidEmailMessage = '올바른 이메일 형식이 아닙니다.';
  static const String invalidPhoneMessage = '올바른 전화번호 형식이 아닙니다.';
  static const String passwordMismatchMessage = '비밀번호가 일치하지 않습니다.';
  static const String nicknameTooShortMessage = '닉네임은 2자 이상이어야 합니다.';
  static const String nicknameTooLongMessage = '닉네임은 20자 이하여야 합니다.';
}
