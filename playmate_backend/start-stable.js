#!/usr/bin/env node

/**
 * 안정적인 서버 시작 스크립트
 * - 환경변수 충돌 방지
 * - 포트 고정 보장
 * - 에러 복구 로직
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// 로그 디렉토리 생성
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// 환경변수 고정 설정
const env = {
  ...process.env,
  NODE_ENV: 'development',
  PORT: '3000',
  HOST: '0.0.0.0'
};

// 기존 서버 프로세스 종료
console.log('🔄 기존 서버 프로세스 정리 중...');

function killExistingProcesses() {
  return new Promise((resolve) => {
    const killProcess = spawn('pkill', ['-f', 'node src/server.js'], { stdio: 'ignore' });
    killProcess.on('close', () => {
      setTimeout(resolve, 2000); // 2초 대기
    });
  });
}

function startServer() {
  console.log('🚀 안정적인 서버 시작 중...');
  console.log(`📍 포트: ${env.PORT}`);
  console.log(`🌍 환경: ${env.NODE_ENV}`);
  
  const server = spawn('node', ['src/server.js'], {
    env,
    cwd: __dirname,
    stdio: ['pipe', 'pipe', 'pipe']
  });

  // 출력 로그
  server.stdout.on('data', (data) => {
    const message = data.toString().trim();
    console.log(message);
    
    // 로그 파일에 저장
    const logEntry = `[${new Date().toISOString()}] ${message}\n`;
    fs.appendFileSync(path.join(logsDir, 'server.log'), logEntry);
  });

  // 에러 로그
  server.stderr.on('data', (data) => {
    const error = data.toString().trim();
    console.error('❌ 서버 에러:', error);
    
    // 에러 로그 파일에 저장
    const logEntry = `[${new Date().toISOString()}] ERROR: ${error}\n`;
    fs.appendFileSync(path.join(logsDir, 'error.log'), logEntry);
  });

  // 서버 종료 처리
  server.on('close', (code) => {
    console.log(`⚠️ 서버가 종료되었습니다 (코드: ${code})`);
    
    if (code !== 0) {
      console.log('🔄 5초 후 서버 재시작...');
      setTimeout(() => {
        startServer();
      }, 5000);
    }
  });

  // 프로세스 종료 시 서버도 종료
  process.on('SIGINT', () => {
    console.log('\n🛑 서버 종료 중...');
    server.kill('SIGTERM');
    process.exit(0);
  });

  process.on('SIGTERM', () => {
    console.log('\n🛑 서버 종료 중...');
    server.kill('SIGTERM');
    process.exit(0);
  });

  return server;
}

// 메인 실행
async function main() {
  try {
    await killExistingProcesses();
    startServer();
  } catch (error) {
    console.error('❌ 서버 시작 실패:', error);
    process.exit(1);
  }
}

main();
