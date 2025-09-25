const os = require('os');
const fs = require('fs');
const path = require('path');

// 대용량 데이터 처리를 위한 메모리 최적화 유틸리티

class MemoryOptimizer {
  constructor() {
    this.memoryThreshold = 0.8; // 80% 메모리 사용 시 경고
    this.cleanupInterval = 60000; // 1분마다 메모리 정리
    this.monitoringInterval = 30000; // 30초마다 메모리 모니터링
    
    this.startMonitoring();
    this.startCleanup();
    
    console.log('✅ 메모리 최적화 서비스 시작');
  }

  /**
   * 메모리 사용량 모니터링 시작
   */
  startMonitoring() {
    setInterval(() => {
      this.checkMemoryUsage();
    }, this.monitoringInterval);
  }

  /**
   * 주기적 메모리 정리 시작
   */
  startCleanup() {
    setInterval(() => {
      this.performMemoryCleanup();
    }, this.cleanupInterval);
  }

  /**
   * 메모리 사용량 체크
   */
  checkMemoryUsage() {
    const memUsage = process.memoryUsage();
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMem = totalMem - freeMem;
    const memUsagePercent = (usedMem / totalMem) * 100;

    // 힙 메모리 사용량 (MB)
    const heapUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
    const heapTotalMB = Math.round(memUsage.heapTotal / 1024 / 1024);
    const heapUsagePercent = (memUsage.heapUsed / memUsage.heapTotal) * 100;

    // 시스템 메모리 사용량 (MB)
    const systemUsedMB = Math.round(usedMem / 1024 / 1024);
    const systemTotalMB = Math.round(totalMem / 1024 / 1024);

    // 메모리 사용량 로깅
    if (heapUsagePercent > 70) {
      console.log(`⚠️ 높은 힙 메모리 사용량: ${heapUsedMB}MB / ${heapTotalMB}MB (${heapUsagePercent.toFixed(1)}%)`);
    }

    if (memUsagePercent > 80) {
      console.warn(`🚨 높은 시스템 메모리 사용량: ${systemUsedMB}MB / ${systemTotalMB}MB (${memUsagePercent.toFixed(1)}%)`);
      this.triggerGarbageCollection();
    }

    // 메모리 통계 저장 (선택사항)
    if (process.env.NODE_ENV === 'development') {
      this.logMemoryStats(memUsage, memUsagePercent);
    }
  }

  /**
   * 가비지 컬렉션 강제 실행
   */
  triggerGarbageCollection() {
    if (global.gc) {
      console.log('🗑️ 가비지 컬렉션 강제 실행');
      global.gc();
      
      // GC 후 메모리 상태 확인
      setTimeout(() => {
        const memUsage = process.memoryUsage();
        const heapUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
        console.log(`✅ GC 완료 후 힙 메모리: ${heapUsedMB}MB`);
      }, 1000);
    } else {
      console.warn('⚠️ 가비지 컬렉션을 사용할 수 없습니다. --expose-gc 플래그를 사용하세요.');
    }
  }

  /**
   * 메모리 정리 작업 수행
   */
  performMemoryCleanup() {
    try {
      // 1. 캐시 정리 (만료된 항목들)
      if (global.cacheService) {
        this.cleanupCaches();
      }

      // 2. 임시 파일 정리
      this.cleanupTempFiles();

      // 3. 메모리 누수 감지
      this.detectMemoryLeaks();

      console.log('🧹 메모리 정리 작업 완료');
    } catch (error) {
      console.error('❌ 메모리 정리 작업 실패:', error);
    }
  }

  /**
   * 캐시 정리
   */
  cleanupCaches() {
    // 캐시 통계 확인 및 정리
    const stats = global.cacheService?.getStats();
    if (stats) {
      Object.keys(stats.caches).forEach(cacheType => {
        const cacheStats = stats.caches[cacheType];
        if (cacheStats.keys > 50000) { // 5만개 이상이면 정리
          console.log(`🧹 ${cacheType} 캐시 정리 중... (${cacheStats.keys}개 항목)`);
          // 오래된 항목들 정리 로직 추가 가능
        }
      });
    }
  }

  /**
   * 임시 파일 정리
   */
  cleanupTempFiles() {
    const tempDir = path.join(__dirname, '../../uploads/temp');
    
    if (fs.existsSync(tempDir)) {
      try {
        const files = fs.readdirSync(tempDir);
        const now = Date.now();
        const maxAge = 24 * 60 * 60 * 1000; // 24시간

        files.forEach(file => {
          const filePath = path.join(tempDir, file);
          const stats = fs.statSync(filePath);
          
          if (now - stats.mtime.getTime() > maxAge) {
            fs.unlinkSync(filePath);
            console.log(`🗑️ 임시 파일 삭제: ${file}`);
          }
        });
      } catch (error) {
        console.error('❌ 임시 파일 정리 실패:', error);
      }
    }
  }

  /**
   * 메모리 누수 감지
   */
  detectMemoryLeaks() {
    const memUsage = process.memoryUsage();
    const heapUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
    
    // 힙 메모리가 1GB를 초과하면 경고
    if (heapUsedMB > 1024) {
      console.warn(`🚨 메모리 누수 가능성: 힙 사용량 ${heapUsedMB}MB`);
      
      // 메모리 사용량이 계속 증가하는지 확인
      if (!this.lastHeapUsage) {
        this.lastHeapUsage = heapUsedMB;
      } else if (heapUsedMB > this.lastHeapUsage * 1.5) {
        console.error('🚨 심각한 메모리 누수 감지!');
        this.triggerGarbageCollection();
      }
      
      this.lastHeapUsage = heapUsedMB;
    }
  }

  /**
   * 메모리 통계 로깅
   */
  logMemoryStats(memUsage, systemMemPercent) {
    const stats = {
      timestamp: new Date().toISOString(),
      heap: {
        used: Math.round(memUsage.heapUsed / 1024 / 1024),
        total: Math.round(memUsage.heapTotal / 1024 / 1024),
        external: Math.round(memUsage.external / 1024 / 1024)
      },
      system: {
        used: Math.round((os.totalmem() - os.freemem()) / 1024 / 1024),
        total: Math.round(os.totalmem() / 1024 / 1024),
        percent: systemMemPercent.toFixed(1)
      }
    };

    // 개발 환경에서만 로깅
    if (process.env.NODE_ENV === 'development') {
      console.log('📊 메모리 통계:', JSON.stringify(stats, null, 2));
    }
  }

  /**
   * 메모리 사용량 최적화를 위한 데이터 처리
   * @param {Array} data - 처리할 데이터
   * @param {Function} processor - 데이터 처리 함수
   * @param {number} batchSize - 배치 크기
   * @returns {Promise<Array>} 처리된 데이터
   */
  async processDataInBatches(data, processor, batchSize = 1000) {
    const results = [];
    
    for (let i = 0; i < data.length; i += batchSize) {
      const batch = data.slice(i, i + batchSize);
      
      try {
        const batchResult = await processor(batch);
        results.push(...batchResult);
        
        // 배치 처리 후 메모리 정리
        if (i % (batchSize * 10) === 0) {
          this.triggerGarbageCollection();
        }
        
        // 진행률 로깅
        const progress = Math.round((i / data.length) * 100);
        console.log(`📊 데이터 처리 진행률: ${progress}%`);
        
      } catch (error) {
        console.error(`❌ 배치 처리 실패 (${i}-${i + batchSize}):`, error);
        throw error;
      }
    }
    
    return results;
  }

  /**
   * 스트리밍 방식으로 대용량 데이터 처리
   * @param {ReadableStream} stream - 데이터 스트림
   * @param {Function} processor - 데이터 처리 함수
   * @returns {Promise<void>}
   */
  async processStream(stream, processor) {
    return new Promise((resolve, reject) => {
      let processedCount = 0;
      
      stream.on('data', async (chunk) => {
        try {
          await processor(chunk);
          processedCount++;
          
          // 1000개마다 메모리 정리
          if (processedCount % 1000 === 0) {
            this.triggerGarbageCollection();
          }
          
        } catch (error) {
          stream.destroy();
          reject(error);
        }
      });
      
      stream.on('end', () => {
        console.log(`✅ 스트림 처리 완료: ${processedCount}개 항목`);
        resolve();
      });
      
      stream.on('error', (error) => {
        reject(error);
      });
    });
  }
}

// 싱글톤 인스턴스 생성
const memoryOptimizer = new MemoryOptimizer();

module.exports = memoryOptimizer;
