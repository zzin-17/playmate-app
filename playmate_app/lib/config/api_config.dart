class ApiConfig {
  // 개발 환경 설정 (Android 에뮬레이터용)
  static const String devBaseUrl = 'http://10.0.2.2:3000';
  static const String stagingBaseUrl = 'https://staging-api.playmate.com';
  static const String prodBaseUrl = 'https://api.playmate.com';
  
  // 현재 사용할 API URL (개발 중에는 devBaseUrl 사용)
  static const String baseUrl = devBaseUrl;
  
  // API 타임아웃 설정
  static const Duration timeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // API 버전
  static const String apiVersion = 'v1';
  
  // 전체 API URL (백엔드 API 경로에 맞게 수정)
  static String get fullBaseUrl => '$baseUrl/api';
  
  // 환경별 설정
  static bool get isDevelopment => baseUrl == devBaseUrl;
  static bool get isStaging => baseUrl == stagingBaseUrl;
  static bool get isProduction => baseUrl == prodBaseUrl;
  
  // 로깅 설정
  static bool get enableApiLogging => isDevelopment || isStaging;
  
  // 재시도 설정
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // 캐시 설정
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  // 파일 업로드 설정
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedVideoTypes = ['mp4', 'mov', 'avi'];
}
