require('dotenv').config({ path: './config.env' });
const http = require('http');
const app = require('./app');
const connectDB = require('./config/database');
const { initSocket } = require('./services/socketService');

// 데이터베이스 연결 (임시로 비활성화)
// connectDB();

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

// 서버 시작 시간 측정
const startTime = Date.now();

// Socket.IO 초기화 (비동기)
const initializeServer = async () => {
  try {
    console.log('🔄 서버 초기화 중...');
    
    // Socket.IO 초기화
    initSocket(server);
    
    // 서버 시작
    server.listen(PORT, '0.0.0.0', () => {
      const loadTime = Date.now() - startTime;
      console.log(`🚀 Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
      console.log(`📱 API Base URL: http://localhost:${PORT}/api`);
      console.log(`📱 API Base URL (Android): http://10.0.2.2:${PORT}/api`);
      console.log(`🔗 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`⏱️  서버 시작 시간: ${loadTime}ms`);
    });
  } catch (error) {
    console.error('❌ 서버 초기화 실패:', error);
    process.exit(1);
  }
};

// 서버 초기화 시작
initializeServer();

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