const asyncHandler = require('express-async-handler');
const fs = require('fs');
const path = require('path');

// @desc    Health check
// @route   GET /api/health
// @access  Public
const healthCheck = asyncHandler(async (req, res) => {
  try {
    // 메모리 사용량 체크
    const memoryUsage = process.memoryUsage();
    const memoryUsageMB = {
      rss: Math.round(memoryUsage.rss / 1024 / 1024),
      heapTotal: Math.round(memoryUsage.heapTotal / 1024 / 1024),
      heapUsed: Math.round(memoryUsage.heapUsed / 1024 / 1024),
      external: Math.round(memoryUsage.external / 1024 / 1024)
    };

    // 디스크 공간 체크 (데이터 파일들)
    const dataDir = path.join(__dirname, '../../data');
    let diskStatus = 'unknown';
    try {
      if (fs.existsSync(dataDir)) {
        const stats = fs.statSync(dataDir);
        diskStatus = 'accessible';
      } else {
        diskStatus = 'not_found';
      }
    } catch (error) {
      diskStatus = 'error';
    }

    // 서버 상태 판단
    const isHealthy = memoryUsageMB.heapUsed < 500; // 500MB 미만이면 정상

    res.status(isHealthy ? 200 : 503).json({
      success: isHealthy,
      message: isHealthy ? 'Server is healthy' : 'Server is under stress',
      timestamp: new Date().toISOString(),
      uptime: Math.round(process.uptime()),
      environment: process.env.NODE_ENV || 'development',
      memory: memoryUsageMB,
      disk: diskStatus,
      pid: process.pid,
      version: '1.0.0'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Health check failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// @desc    Detailed health check
// @route   GET /api/health/detailed
// @access  Public
const detailedHealthCheck = asyncHandler(async (req, res) => {
  try {
    const memoryUsage = process.memoryUsage();
    const cpuUsage = process.cpuUsage();
    
    res.json({
      success: true,
      message: 'Detailed health check',
      timestamp: new Date().toISOString(),
      system: {
        uptime: process.uptime(),
        memory: {
          rss: memoryUsage.rss,
          heapTotal: memoryUsage.heapTotal,
          heapUsed: memoryUsage.heapUsed,
          external: memoryUsage.external
        },
        cpu: {
          user: cpuUsage.user,
          system: cpuUsage.system
        },
        pid: process.pid,
        platform: process.platform,
        arch: process.arch,
        nodeVersion: process.version
      },
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Detailed health check failed',
      error: error.message
    });
  }
});

module.exports = {
  healthCheck,
  detailedHealthCheck
};