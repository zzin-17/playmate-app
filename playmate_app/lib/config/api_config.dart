class ApiConfig {
  // 환경별 API URL 설정 (더 안정적인 localhost 사용)
  static const String devBaseUrl = 'http://10.0.2.2:3000'; // Android 에뮬레이터용 localhost
  static const String devBaseUrlIOS = 'http://localhost:3000'; // iOS 시뮬레이터용
  static const String devBaseUrlNetwork = 'http://192.168.6.100:3000'; // 네트워크용 (백업)
  static const String stagingBaseUrl = 'https://staging-api.playmate.com';
  static const String prodBaseUrl = 'https://api.playmate.com';
  
  // 환경 자동 감지 또는 수동 설정
  static const String _environment = String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');
  
  // 현재 사용할 API URL (플랫폼에 따라 자동 선택)
  static String get baseUrl {
    switch (_environment) {
      case 'production':
        return prodBaseUrl;
      case 'staging':
        return stagingBaseUrl;
      case 'development':
      default:
        // Android 에뮬레이터는 10.0.2.2를 localhost로 사용
        return devBaseUrl; // 기본적으로 Android 에뮬레이터용 사용
    }
  }
  
  // 백업 URL들 (연결 실패 시 시도할 수 있는 URL들)
  static List<String> get fallbackUrls => [
    devBaseUrl,           // 10.0.2.2:3000 (Android 에뮬레이터)
    devBaseUrlIOS,        // localhost:3000 (iOS)
    devBaseUrlNetwork,    // 192.168.6.100:3000 (네트워크)
  ];
  
  // API 타임아웃 설정
  static const Duration timeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // API 버전
  static const String apiVersion = 'v1';
  
  // 전체 API URL (백엔드 API 경로에 맞게 수정)
  static String get fullBaseUrl => '$baseUrl/api';
  
  // 환경별 설정
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';
  
  // 로깅 설정 (십만 건 이상 대응)
  static bool get enableApiLogging => isDevelopment || isStaging;
  static bool get enableDetailedLogging => isDevelopment;
  static bool get enablePerformanceLogging => !isProduction;
  
  // 재시도 설정
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // 포트 고정 설정
  static const int serverPort = 3000;
  static const String androidEmulatorHost = '10.0.2.2';  // Android 에뮬레이터 전용 localhost
  static const String iOSSimulatorHost = 'localhost';     // iOS 시뮬레이터 전용
  static const String networkHost = '192.168.6.100';     // 네트워크 IP (백업용)
  
  // 캐시 설정
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  // 파일 업로드 설정
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedVideoTypes = ['mp4', 'mov', 'avi'];
}
