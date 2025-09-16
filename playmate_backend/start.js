#!/usr/bin/env node

// 빠른 서버 시작 스크립트
const { spawn } = require('child_process');
const path = require('path');

console.log('🚀 PlayMate Backend 빠른 시작...');

// 환경 변수 설정
process.env.NODE_ENV = 'development';
process.env.PORT = '3000';

// 서버 시작
const server = spawn('node', ['src/server.js'], {
  cwd: __dirname,
  stdio: 'inherit',
  env: { ...process.env }
});

// 서버 종료 처리
process.on('SIGINT', () => {
  console.log('\n🛑 서버 종료 중...');
  server.kill('SIGINT');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 서버 종료 중...');
  server.kill('SIGTERM');
  process.exit(0);
});

server.on('close', (code) => {
  console.log(`서버가 종료되었습니다. 코드: ${code}`);
  process.exit(code);
});

server.on('error', (err) => {
  console.error('서버 시작 실패:', err);
  process.exit(1);
});
