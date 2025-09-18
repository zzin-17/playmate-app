/**
 * 대량 데이터 처리를 위한 성능 설정
 * 십만 건 이상의 데이터를 안정적으로 처리하기 위한 설정
 */

const performanceConfig = {
  // 페이지네이션 설정
  pagination: {
    maxLimit: parseInt(process.env.MAX_POSTS_PER_PAGE) || 50,
    defaultLimit: 20,
    maxOffset: 10000, // 무한 스크롤 제한
  },

  // 캐시 설정
  cache: {
    ttl: parseInt(process.env.CACHE_TTL) || 300, // 5분
    maxSize: 1000, // 최대 캐시 항목 수
    enableInMemoryCache: process.env.NODE_ENV !== 'production',
  },

  // 데이터베이스 최적화
  database: {
    maxConnections: process.env.NODE_ENV === 'production' ? 100 : 10,
    connectionTimeout: 30000,
    queryTimeout: 15000,
    enableIndexes: true,
  },

  // 메모리 관리
  memory: {
    maxMemoryUsage: process.env.MEMORY_LIMIT || '512MB',
    gcInterval: 60000, // 1분마다 가비지 컬렉션 체크
    enableMemoryMonitoring: process.env.NODE_ENV !== 'production',
  },

  // API 제한
  rateLimit: {
    windowMs: (parseInt(process.env.RATE_LIMIT_WINDOW) || 15) * 60 * 1000, // 15분
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    enableInDevelopment: false,
  },

  // 로깅 설정
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    enableApiLogging: process.env.ENABLE_API_LOGGING === 'true',
    enablePerformanceLogging: process.env.ENABLE_PERFORMANCE_LOGGING === 'true',
    enableQueryLogging: process.env.NODE_ENV === 'development',
  },

  // 압축 설정
  compression: {
    enable: process.env.ENABLE_COMPRESSION === 'true',
    threshold: 1024, // 1KB 이상일 때 압축
    level: 6, // 압축 레벨 (1-9)
  },

  // 보안 설정
  security: {
    enableHelmet: process.env.ENABLE_HELMET === 'true',
    enableCors: true,
    enableXss: true,
    enableRateLimit: process.env.NODE_ENV === 'production',
  }
};

module.exports = performanceConfig;
