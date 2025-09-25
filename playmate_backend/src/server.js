// 환경별 설정 파일 로드
const environment = process.env.NODE_ENV || 'development';
const configPath = `./config.${environment}.env`;

require('dotenv').config({ 
  path: require('fs').existsSync(configPath) ? configPath : './config.env' 
});
const http = require('http');
const app = require('./app');
const { initSocket } = require('./services/socketService');
const userStore = require('./stores/userStore');
const { connectDB, createIndexes } = require('./config/database');
const cacheService = require('./services/cacheService');
const performanceMonitor = require('./services/performanceMonitor');
const memoryOptimizer = require('./utils/memoryOptimizer');

// 데이터베이스 연결 (임시로 비활성화)
// connectDB();

// 사용 가능한 포트 찾기 함수 (개선된 버전)
const findAvailablePort = (startPort = 3000, maxPort = 3010) => {
  return new Promise((resolve, reject) => {
    const tryPort = (port) => {
      if (port > maxPort) {
        reject(new Error(`포트 ${startPort}-${maxPort} 범위에서 사용 가능한 포트를 찾을 수 없습니다.`));
        return;
      }
      
      const testServer = http.createServer();
      testServer.listen(port, '0.0.0.0', () => {
        testServer.close(() => {
          console.log(`✅ 포트 ${port} 사용 가능`);
          resolve(port);
        });
      });
      
      testServer.on('error', (error) => {
        if (error.code === 'EADDRINUSE') {
          console.log(`❌ 포트 ${port} 사용 중, 다음 포트 시도...`);
          tryPort(port + 1);
        } else {
          console.log(`❌ 포트 ${port} 오류: ${error.message}`);
          tryPort(port + 1);
        }
      });
    };
    
    tryPort(startPort);
  });
};

// 서버 시작 시간 측정
const startTime = Date.now();

// 서버 시작 함수
const startServer = async () => {
  try {
    // 1. 대용량 데이터 처리를 위한 서비스 초기화
    console.log('🔄 대용량 데이터 처리 서비스 초기화 중...');
    
    // 데이터베이스 연결 (MongoDB 사용 시)
    // await connectDB();
    // await createIndexes();
    
    // 캐시 서비스 초기화
    global.cacheService = cacheService;
    
    // 성능 모니터링 시작
    global.performanceMonitor = performanceMonitor;
    
    // 메모리 최적화 서비스 시작
    global.memoryOptimizer = memoryOptimizer;
    
    // 2. 데이터 초기화
    console.log('🔄 데이터 초기화 중...');
    await userStore.loadUsersFromFile();
    console.log('✅ 모든 데이터 초기화 완료');
    
    // 2. 사용 가능한 포트 찾기
    const preferredPort = parseInt(process.env.PORT) || 3000;
    const PORT = await findAvailablePort(preferredPort, preferredPort + 10);
    console.log(`🔧 서버 포트: ${PORT} (선호 포트: ${preferredPort})`);
    
    // 3. 환경 변수 업데이트 (다른 포트를 사용하는 경우)
    if (PORT !== preferredPort) {
      process.env.PORT = PORT.toString();
      console.log(`🔄 환경 변수 PORT를 ${PORT}로 업데이트`);
    }
    
    const server = http.createServer(app);
    
    // 3. Socket.IO 초기화
    initSocket(server);
    
    // 4. 서버 시작
    server.listen(PORT, '0.0.0.0', () => {
      const loadTime = Date.now() - startTime;
      console.log(`🚀 Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
      console.log(`📱 API Base URL: http://localhost:${PORT}/api`);
      console.log(`📱 API Base URL (Android): http://10.0.2.2:${PORT}/api`);
      console.log(`📱 API Base URL (Network): http://192.168.6.100:${PORT}/api`);
      console.log(`🔗 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`⏱️  서버 시작 시간: ${loadTime}ms`);
      console.log(`🔧 프로세스 ID: ${process.pid}`);
      console.log(`💾 메모리 사용량: ${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB`);
    });
    
    // 서버 오류 처리 (포트 충돌은 이미 해결됨)
    server.on('error', (error) => {
      console.error('❌ 서버 오류:', error);
      console.error('❌ 복구 불가능한 서버 오류로 인해 종료합니다.');
      process.exit(1);
    });

    // 프로세스 종료 시그널 처리
    process.on('SIGTERM', () => {
      console.log('🛑 SIGTERM 수신, 서버 정상 종료 중...');
      server.close(() => {
        console.log('✅ 서버 정상 종료 완료');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      console.log('🛑 SIGINT 수신 (Ctrl+C), 서버 정상 종료 중...');
      server.close(() => {
        console.log('✅ 서버 정상 종료 완료');
        process.exit(0);
      });
    });

    // 처리되지 않은 예외 처리
    process.on('uncaughtException', (error) => {
      console.error('❌ 처리되지 않은 예외:', error);
      console.log('🔄 서버를 재시작합니다...');
      process.exit(1);
    });

    process.on('unhandledRejection', (reason, promise) => {
      console.error('❌ 처리되지 않은 Promise 거부:', reason);
      console.log('🔄 서버를 재시작합니다...');
      process.exit(1);
    });
    
  } catch (error) {
    console.error('❌ 서버 시작 실패:', error.message);
    process.exit(1);
  }
};

// 서버 시작
startServer();

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  console.error(`Error: ${err.message}`);
  // Close server & exit process
  server.close(() => process.exit(1));
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});