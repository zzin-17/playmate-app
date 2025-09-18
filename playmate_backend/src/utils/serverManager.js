/**
 * 서버 관리 유틸리티
 * 포트 충돌 방지, 자동 재시작, 안정성 개선
 */

const net = require('net');

/**
 * 포트 사용 가능 여부 확인
 * @param {number} port - 확인할 포트 번호
 * @returns {Promise<boolean>} - 포트 사용 가능 여부
 */
const isPortAvailable = (port) => {
  return new Promise((resolve) => {
    const server = net.createServer();
    
    server.listen(port, () => {
      server.once('close', () => {
        resolve(true);
      });
      server.close();
    });
    
    server.on('error', () => {
      resolve(false);
    });
  });
};

/**
 * 사용 가능한 포트 찾기
 * @param {number} startPort - 시작 포트 번호
 * @param {number} maxAttempts - 최대 시도 횟수
 * @returns {Promise<number>} - 사용 가능한 포트 번호
 */
const findAvailablePort = async (startPort = 3000, maxAttempts = 10) => {
  for (let i = 0; i < maxAttempts; i++) {
    const port = startPort + i;
    const available = await isPortAvailable(port);
    
    if (available) {
      console.log(`✅ 포트 ${port} 사용 가능`);
      return port;
    }
    
    console.log(`❌ 포트 ${port} 사용 중`);
  }
  
  throw new Error(`사용 가능한 포트를 찾을 수 없습니다 (${startPort}-${startPort + maxAttempts - 1})`);
};

/**
 * 기존 프로세스 종료
 * @param {number} port - 종료할 포트 번호
 */
const killProcessOnPort = async (port) => {
  try {
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);
    
    // macOS/Linux에서 포트 사용 프로세스 찾기
    const { stdout } = await execAsync(`lsof -ti:${port}`);
    const pids = stdout.trim().split('\n').filter(pid => pid);
    
    for (const pid of pids) {
      try {
        await execAsync(`kill -9 ${pid}`);
        console.log(`🔪 프로세스 ${pid} 종료됨 (포트 ${port})`);
      } catch (error) {
        console.log(`⚠️ 프로세스 ${pid} 종료 실패: ${error.message}`);
      }
    }
  } catch (error) {
    console.log(`⚠️ 포트 ${port} 프로세스 확인 실패: ${error.message}`);
  }
};

/**
 * 서버 시작 전 정리
 * @param {number} port - 정리할 포트 번호
 */
const cleanupPort = async (port) => {
  console.log(`🧹 포트 ${port} 정리 중...`);
  await killProcessOnPort(port);
  
  // 잠시 대기
  await new Promise(resolve => setTimeout(resolve, 1000));
};

/**
 * 서버 상태 확인
 * @param {number} port - 확인할 포트 번호
 * @returns {Promise<boolean>} - 서버 실행 여부
 */
const isServerRunning = async (port) => {
  return new Promise((resolve) => {
    const socket = net.createConnection(port, 'localhost');
    
    socket.on('connect', () => {
      socket.end();
      resolve(true);
    });
    
    socket.on('error', () => {
      resolve(false);
    });
  });
};

module.exports = {
  isPortAvailable,
  findAvailablePort,
  killProcessOnPort,
  cleanupPort,
  isServerRunning
};
