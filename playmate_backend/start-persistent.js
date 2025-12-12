#!/usr/bin/env node

/**
 * 영구적인 서버 시작 스크립트 (PM2 사용)
 * - 터미널 종료 후에도 계속 실행
 * - 시스템 재시작 시 자동 시작 (PM2 startup 설정 필요)
 * - 자동 재시작 및 모니터링
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🚀 영구적인 서버 시작 중 (PM2 사용)...');

// PM2 설치 확인
try {
  execSync('pm2 --version', { stdio: 'ignore' });
} catch (e) {
  console.error('❌ PM2가 설치되지 않았습니다.');
  console.log('📦 PM2 설치 중...');
  try {
    execSync('npm install -g pm2', { stdio: 'inherit' });
    console.log('✅ PM2 설치 완료');
  } catch (installError) {
    console.error('❌ PM2 설치 실패. 다음 명령어로 수동 설치하세요:');
    console.log('   npm install -g pm2');
    process.exit(1);
  }
}

// PM2로 서버 시작
try {
  // 기존 프로세스가 있으면 삭제
  try {
    execSync('pm2 delete playmate-backend 2>/dev/null', { stdio: 'ignore' });
  } catch (e) {
    // 프로세스가 없으면 무시
  }

  // PM2로 시작
  console.log('🔄 PM2로 서버 시작 중...');
  execSync('pm2 start ecosystem.config.js', { 
    stdio: 'inherit',
    cwd: __dirname 
  });

  console.log('✅ 서버가 PM2로 시작되었습니다.');
  console.log('');
  console.log('📋 유용한 명령어:');
  console.log('   pm2 status              - 서버 상태 확인');
  console.log('   pm2 logs playmate-backend - 로그 확인');
  console.log('   pm2 restart playmate-backend - 서버 재시작');
  console.log('   pm2 stop playmate-backend - 서버 중지');
  console.log('   pm2 delete playmate-backend - 서버 삭제');
  console.log('');
  console.log('💡 시스템 재시작 시 자동 시작 설정:');
  console.log('   pm2 startup');
  console.log('   pm2 save');
  
  // PM2 상태 표시
  execSync('pm2 status', { stdio: 'inherit' });
  
} catch (error) {
  console.error('❌ PM2로 서버 시작 실패:', error.message);
  console.log('');
  console.log('🔄 일반 모드로 시작 시도...');
  
  // PM2 실패 시 일반 모드로 시작
  const { spawn } = require('child_process');
  const server = spawn('node', ['start-stable.js'], {
    cwd: __dirname,
    stdio: 'inherit',
    detached: true
  });
  
  server.unref();
  console.log('✅ 서버가 백그라운드에서 시작되었습니다.');
  console.log('⚠️  터미널을 닫으면 서버가 종료될 수 있습니다.');
}

