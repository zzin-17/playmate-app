const fs = require('fs');
const path = require('path');

// 대용량 데이터 처리를 위한 성능 모니터링 서비스

class PerformanceMonitor {
  constructor() {
    this.metrics = {
      requests: {
        total: 0,
        successful: 0,
        failed: 0,
        averageResponseTime: 0
      },
      database: {
        queries: 0,
        slowQueries: 0,
        averageQueryTime: 0
      },
      cache: {
        hits: 0,
        misses: 0,
        hitRate: 0
      },
      memory: {
        peakUsage: 0,
        currentUsage: 0,
        garbageCollections: 0
      }
    };

    this.responseTimes = [];
    this.queryTimes = [];
    this.slowQueryThreshold = 1000; // 1초 이상을 느린 쿼리로 간주
    
    this.startTime = Date.now();
    this.lastResetTime = Date.now();
    
    // 성능 로그 디렉토리 생성
    this.logDir = path.join(__dirname, '../../logs/performance');
    if (!fs.existsSync(this.logDir)) {
      fs.mkdirSync(this.logDir, { recursive: true });
    }
    
    console.log('✅ 성능 모니터링 서비스 시작');
  }

  /**
   * API 요청 시작 시간 기록
   * @param {string} endpoint - API 엔드포인트
   * @param {string} method - HTTP 메서드
   * @returns {number} 요청 ID
   */
  startRequest(endpoint, method) {
    const requestId = Date.now() + Math.random();
    const startTime = process.hrtime.bigint();
    
    // 요청 정보 저장
    this[`request_${requestId}`] = {
      endpoint,
      method,
      startTime,
      timestamp: new Date().toISOString()
    };
    
    return requestId;
  }

  /**
   * API 요청 완료 시간 기록
   * @param {number} requestId - 요청 ID
   * @param {number} statusCode - HTTP 상태 코드
   * @param {Error} error - 에러 객체 (선택사항)
   */
  endRequest(requestId, statusCode, error = null) {
    const requestInfo = this[`request_${requestId}`];
    if (!requestInfo) return;

    const endTime = process.hrtime.bigint();
    const duration = Number(endTime - requestInfo.startTime) / 1000000; // 밀리초로 변환

    // 응답 시간 기록
    this.responseTimes.push(duration);
    if (this.responseTimes.length > 1000) {
      this.responseTimes.shift(); // 최대 1000개까지만 유지
    }

    // 통계 업데이트
    this.metrics.requests.total++;
    if (statusCode >= 200 && statusCode < 400) {
      this.metrics.requests.successful++;
    } else {
      this.metrics.requests.failed++;
    }

    // 평균 응답 시간 계산
    this.metrics.requests.averageResponseTime = 
      this.responseTimes.reduce((a, b) => a + b, 0) / this.responseTimes.length;

    // 느린 요청 로깅
    if (duration > 2000) { // 2초 이상
      console.warn(`🐌 느린 API 요청: ${requestInfo.method} ${requestInfo.endpoint} - ${duration.toFixed(2)}ms`);
      this.logSlowRequest(requestInfo, duration, statusCode, error);
    }

    // 요청 정보 삭제
    delete this[`request_${requestId}`];
  }

  /**
   * 데이터베이스 쿼리 시작 시간 기록
   * @param {string} collection - 컬렉션명
   * @param {string} operation - 작업 유형
   * @returns {number} 쿼리 ID
   */
  startQuery(collection, operation) {
    const queryId = Date.now() + Math.random();
    const startTime = process.hrtime.bigint();
    
    this[`query_${queryId}`] = {
      collection,
      operation,
      startTime,
      timestamp: new Date().toISOString()
    };
    
    return queryId;
  }

  /**
   * 데이터베이스 쿼리 완료 시간 기록
   * @param {number} queryId - 쿼리 ID
   * @param {number} resultCount - 결과 수
   * @param {Error} error - 에러 객체 (선택사항)
   */
  endQuery(queryId, resultCount = 0, error = null) {
    const queryInfo = this[`query_${queryId}`];
    if (!queryInfo) return;

    const endTime = process.hrtime.bigint();
    const duration = Number(endTime - queryInfo.startTime) / 1000000; // 밀리초로 변환

    // 쿼리 시간 기록
    this.queryTimes.push(duration);
    if (this.queryTimes.length > 1000) {
      this.queryTimes.shift();
    }

    // 통계 업데이트
    this.metrics.database.queries++;
    if (duration > this.slowQueryThreshold) {
      this.metrics.database.slowQueries++;
      console.warn(`🐌 느린 데이터베이스 쿼리: ${queryInfo.collection}.${queryInfo.operation} - ${duration.toFixed(2)}ms`);
      this.logSlowQuery(queryInfo, duration, resultCount, error);
    }

    // 평균 쿼리 시간 계산
    this.metrics.database.averageQueryTime = 
      this.queryTimes.reduce((a, b) => a + b, 0) / this.queryTimes.length;

    // 쿼리 정보 삭제
    delete this[`query_${queryId}`];
  }

  /**
   * 캐시 통계 업데이트
   * @param {number} hits - 캐시 히트 수
   * @param {number} misses - 캐시 미스 수
   */
  updateCacheStats(hits, misses) {
    this.metrics.cache.hits += hits;
    this.metrics.cache.misses += misses;
    
    const total = this.metrics.cache.hits + this.metrics.cache.misses;
    this.metrics.cache.hitRate = total > 0 ? (this.metrics.cache.hits / total * 100) : 0;
  }

  /**
   * 메모리 사용량 업데이트
   * @param {number} currentUsage - 현재 메모리 사용량 (MB)
   * @param {number} peakUsage - 최대 메모리 사용량 (MB)
   */
  updateMemoryStats(currentUsage, peakUsage) {
    this.metrics.memory.currentUsage = currentUsage;
    this.metrics.memory.peakUsage = Math.max(this.metrics.memory.peakUsage, peakUsage);
  }

  /**
   * 가비지 컬렉션 카운트 업데이트
   */
  incrementGarbageCollections() {
    this.metrics.memory.garbageCollections++;
  }

  /**
   * 느린 요청 로깅
   */
  logSlowRequest(requestInfo, duration, statusCode, error) {
    const logEntry = {
      type: 'slow_request',
      timestamp: new Date().toISOString(),
      endpoint: requestInfo.endpoint,
      method: requestInfo.method,
      duration: duration,
      statusCode: statusCode,
      error: error?.message || null
    };

    this.writeLogFile('slow_requests.log', logEntry);
  }

  /**
   * 느린 쿼리 로깅
   */
  logSlowQuery(queryInfo, duration, resultCount, error) {
    const logEntry = {
      type: 'slow_query',
      timestamp: new Date().toISOString(),
      collection: queryInfo.collection,
      operation: queryInfo.operation,
      duration: duration,
      resultCount: resultCount,
      error: error?.message || null
    };

    this.writeLogFile('slow_queries.log', logEntry);
  }

  /**
   * 로그 파일에 기록
   */
  writeLogFile(filename, data) {
    try {
      const logPath = path.join(this.logDir, filename);
      const logLine = JSON.stringify(data) + '\n';
      fs.appendFileSync(logPath, logLine);
    } catch (error) {
      console.error('❌ 로그 파일 쓰기 실패:', error);
    }
  }

  /**
   * 성능 통계 조회
   * @returns {Object} 성능 통계
   */
  getMetrics() {
    const uptime = Date.now() - this.startTime;
    const uptimeHours = Math.round(uptime / (1000 * 60 * 60) * 100) / 100;

    return {
      uptime: {
        total: uptime,
        hours: uptimeHours
      },
      requests: {
        ...this.metrics.requests,
        requestsPerHour: this.metrics.requests.total / Math.max(uptimeHours, 0.01)
      },
      database: {
        ...this.metrics.database,
        slowQueryRate: this.metrics.database.queries > 0 
          ? (this.metrics.database.slowQueries / this.metrics.database.queries * 100).toFixed(2) + '%'
          : '0%'
      },
      cache: {
        ...this.metrics.cache,
        hitRate: this.metrics.cache.hitRate.toFixed(2) + '%'
      },
      memory: this.metrics.memory
    };
  }

  /**
   * 성능 리포트 생성
   * @returns {Object} 성능 리포트
   */
  generateReport() {
    const metrics = this.getMetrics();
    const report = {
      timestamp: new Date().toISOString(),
      summary: {
        status: this.getOverallStatus(),
        recommendations: this.getRecommendations()
      },
      metrics: metrics
    };

    // 리포트 파일 저장
    const reportPath = path.join(this.logDir, `performance_report_${Date.now()}.json`);
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));

    return report;
  }

  /**
   * 전체 상태 평가
   * @returns {string} 상태 ('excellent', 'good', 'warning', 'critical')
   */
  getOverallStatus() {
    const metrics = this.metrics;
    
    // 응답 시간 기준
    if (metrics.requests.averageResponseTime > 3000) return 'critical';
    if (metrics.requests.averageResponseTime > 1500) return 'warning';
    
    // 느린 쿼리 비율 기준
    const slowQueryRate = metrics.database.queries > 0 
      ? (metrics.database.slowQueries / metrics.database.queries) * 100 
      : 0;
    if (slowQueryRate > 20) return 'critical';
    if (slowQueryRate > 10) return 'warning';
    
    // 캐시 히트율 기준
    if (metrics.cache.hitRate < 50) return 'warning';
    if (metrics.cache.hitRate < 30) return 'critical';
    
    // 메모리 사용량 기준
    if (metrics.memory.peakUsage > 2048) return 'warning'; // 2GB
    if (metrics.memory.peakUsage > 4096) return 'critical'; // 4GB
    
    return metrics.requests.averageResponseTime < 500 ? 'excellent' : 'good';
  }

  /**
   * 성능 개선 권장사항 생성
   * @returns {Array} 권장사항 배열
   */
  getRecommendations() {
    const recommendations = [];
    const metrics = this.metrics;

    // 응답 시간 개선 권장사항
    if (metrics.requests.averageResponseTime > 1000) {
      recommendations.push('API 응답 시간이 느립니다. 캐싱을 강화하고 데이터베이스 쿼리를 최적화하세요.');
    }

    // 느린 쿼리 개선 권장사항
    const slowQueryRate = metrics.database.queries > 0 
      ? (metrics.database.slowQueries / metrics.database.queries) * 100 
      : 0;
    if (slowQueryRate > 10) {
      recommendations.push('느린 데이터베이스 쿼리가 많습니다. 인덱스를 추가하고 쿼리를 최적화하세요.');
    }

    // 캐시 히트율 개선 권장사항
    if (metrics.cache.hitRate < 60) {
      recommendations.push('캐시 히트율이 낮습니다. 캐시 전략을 재검토하세요.');
    }

    // 메모리 사용량 개선 권장사항
    if (metrics.memory.peakUsage > 1024) {
      recommendations.push('메모리 사용량이 높습니다. 메모리 누수를 확인하고 가비지 컬렉션을 강화하세요.');
    }

    return recommendations;
  }

  /**
   * 통계 초기화
   */
  reset() {
    this.metrics = {
      requests: { total: 0, successful: 0, failed: 0, averageResponseTime: 0 },
      database: { queries: 0, slowQueries: 0, averageQueryTime: 0 },
      cache: { hits: 0, misses: 0, hitRate: 0 },
      memory: { peakUsage: 0, currentUsage: 0, garbageCollections: 0 }
    };
    
    this.responseTimes = [];
    this.queryTimes = [];
    this.lastResetTime = Date.now();
    
    console.log('🔄 성능 통계 초기화 완료');
  }
}

// 싱글톤 인스턴스 생성
const performanceMonitor = new PerformanceMonitor();

module.exports = performanceMonitor;
