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
    // 포트 고정 (환경변수 또는 기본값 3000)
    const PORT = process.env.PORT || 3000;
    console.log(`🔧 서버 포트 고정: ${PORT}`);
    const server = http.createServer(app);
    
    // Socket.IO 초기화
    initSocket(server);
    
    // 서버 시작
    server.listen(PORT, '0.0.0.0', () => {
      const loadTime = Date.now() - startTime;
      console.log(`🚀 Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
      console.log(`📱 API Base URL: http://localhost:${PORT}/api`);
      console.log(`📱 API Base URL (Android): http://10.0.2.2:${PORT}/api`);
      console.log(`📱 API Base URL (Network): http://192.168.6.100:${PORT}/api`);
      console.log(`🔗 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`⏱️  서버 시작 시간: ${loadTime}ms`);
    });
    
    // 서버 오류 처리
    server.on('error', (error) => {
      console.error('❌ 서버 오류:', error);
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