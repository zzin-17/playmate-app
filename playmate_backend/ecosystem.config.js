module.exports = {
  apps: [
    {
      name: 'playmate-backend',
      script: 'src/server.js',
      cwd: '/Users/zzin/playmate/playmate_backend',
      
      // 환경 설정
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      
      // 프로세스 관리
      instances: 1,
      exec_mode: 'fork',
      
      // 자동 재시작 설정
      autorestart: true,
      watch: false,  // 개발 중에는 false로 설정
      max_memory_restart: '1G',  // 1GB 메모리 사용 시 재시작
      
      // 재시작 정책
      restart_delay: 2000,  // 재시작 간격 2초
      max_restarts: 10,     // 최대 10번 재시작
      min_uptime: '10s',    // 최소 10초 실행되어야 정상으로 간주
      
      // 로그 관리
      log_file: './logs/pm2-combined.log',
      out_file: './logs/pm2-out.log',
      error_file: './logs/pm2-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      
      // 성능 최적화
      node_args: [
        '--max-old-space-size=512',  // 최대 힙 메모리 512MB
        '--gc-interval=100'          // 가비지 컬렉션 간격
      ],
      
      // 종료 시그널 처리
      kill_timeout: 5000,  // 5초 후 강제 종료
      
      // 모니터링
      monitoring: false,  // 기본 모니터링 비활성화 (성능상)
      
      // 에러 처리
      ignore_watch: ['node_modules', 'logs'],
      
      // 개발 환경 전용 설정
      env_development: {
        NODE_ENV: 'development',
        PORT: 3000,
        DEBUG: 'playmate:*'
      }
    }
  ]
};