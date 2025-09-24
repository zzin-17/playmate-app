// 환경별 설정 파일 로드
const environment = process.env.NODE_ENV || 'development';
const configPath = `./config.${environment}.env`;

require('dotenv').config({ 
  path: require('fs').existsSync(configPath) ? configPath : './config.env' 
});
const http = require('http');
const app = require('./app');
const connectDB = require('./config/database');
const { initSocket } = require('./services/socketService');
const userStore = require('./stores/userStore');

// 데이터베이스 연결 (임시로 비활성화)
// connectDB();

// 사용 가능한 포트 찾기 함수
const findAvailablePort = (startPort = 3000) => {
  return new Promise((resolve, reject) => {
    const tryPort = (port) => {
      if (port > 3010) {
        reject(new Error('사용 가능한 포트를 찾을 수 없습니다.'));
        return;
      }
      
      const testServer = http.createServer();
      testServer.listen(port, '0.0.0.0', () => {
        testServer.close(() => {
          console.log(`✅ 포트 ${port} 사용 가능`);
          resolve(port);
        });
      });
      
      testServer.on('error', () => {
        console.log(`❌ 포트 ${port} 사용 중`);
        tryPort(port + 1);
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
    // 1. 먼저 모든 데이터 초기화
    console.log('🔄 데이터 초기화 중...');
    await userStore.loadUsersFromFile();
    console.log('✅ 모든 데이터 초기화 완료');
    
    // 2. 포트 설정
    const PORT = process.env.PORT || 3000;
    console.log(`🔧 서버 포트 고정: ${PORT}`);
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
    
    // 서버 오류 처리
    server.on('error', (error) => {
      console.error('❌ 서버 오류:', error);
      if (error.code === 'EADDRINUSE') {
        console.error(`포트 ${PORT}가 이미 사용 중입니다.`);
      }
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