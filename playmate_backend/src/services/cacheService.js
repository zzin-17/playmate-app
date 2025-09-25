const NodeCache = require('node-cache');

// 대용량 데이터 처리를 위한 캐시 서비스

class CacheService {
  constructor() {
    // 다양한 캐시 인스턴스 생성 (용도별 최적화)
    this.caches = {
      // 사용자 데이터 캐시 (5분 TTL)
      users: new NodeCache({ 
        stdTTL: 300, 
        checkperiod: 60,
        maxKeys: 10000,
        useClones: false // 메모리 효율성
      }),
      
      // 매칭 데이터 캐시 (2분 TTL)
      matchings: new NodeCache({ 
        stdTTL: 120, 
        checkperiod: 30,
        maxKeys: 50000,
        useClones: false
      }),
      
      // 게시글 데이터 캐시 (3분 TTL)
      posts: new NodeCache({ 
        stdTTL: 180, 
        checkperiod: 45,
        maxKeys: 100000,
        useClones: false
      }),
      
      // 인기 콘텐츠 캐시 (10분 TTL)
      popular: new NodeCache({ 
        stdTTL: 600, 
        checkperiod: 120,
        maxKeys: 1000,
        useClones: false
      }),
      
      // 검색 결과 캐시 (1분 TTL)
      search: new NodeCache({ 
        stdTTL: 60, 
        checkperiod: 15,
        maxKeys: 5000,
        useClones: false
      })
    };
    
    // 캐시 통계
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0
    };
    
    console.log('✅ 캐시 서비스 초기화 완료');
  }

  /**
   * 캐시에서 데이터 가져오기
   * @param {string} type - 캐시 타입
   * @param {string} key - 캐시 키
   * @returns {any} 캐시된 데이터 또는 null
   */
  get(type, key) {
    try {
      const cache = this.caches[type];
      if (!cache) {
        console.warn(`⚠️ 알 수 없는 캐시 타입: ${type}`);
        return null;
      }
      
      const value = cache.get(key);
      if (value !== undefined) {
        this.stats.hits++;
        return value;
      } else {
        this.stats.misses++;
        return null;
      }
    } catch (error) {
      console.error('❌ 캐시 조회 오류:', error);
      this.stats.misses++;
      return null;
    }
  }

  /**
   * 캐시에 데이터 저장
   * @param {string} type - 캐시 타입
   * @param {string} key - 캐시 키
   * @param {any} value - 저장할 데이터
   * @param {number} ttl - TTL (초, 선택사항)
   * @returns {boolean} 저장 성공 여부
   */
  set(type, key, value, ttl = null) {
    try {
      const cache = this.caches[type];
      if (!cache) {
        console.warn(`⚠️ 알 수 없는 캐시 타입: ${type}`);
        return false;
      }
      
      const success = cache.set(key, value, ttl);
      if (success) {
        this.stats.sets++;
      }
      return success;
    } catch (error) {
      console.error('❌ 캐시 저장 오류:', error);
      return false;
    }
  }

  /**
   * 캐시에서 데이터 삭제
   * @param {string} type - 캐시 타입
   * @param {string} key - 캐시 키
   * @returns {boolean} 삭제 성공 여부
   */
  del(type, key) {
    try {
      const cache = this.caches[type];
      if (!cache) {
        console.warn(`⚠️ 알 수 없는 캐시 타입: ${type}`);
        return false;
      }
      
      const deleted = cache.del(key);
      if (deleted > 0) {
        this.stats.deletes++;
      }
      return deleted > 0;
    } catch (error) {
      console.error('❌ 캐시 삭제 오류:', error);
      return false;
    }
  }

  /**
   * 패턴으로 캐시 삭제
   * @param {string} type - 캐시 타입
   * @param {string} pattern - 삭제할 패턴
   * @returns {number} 삭제된 항목 수
   */
  delPattern(type, pattern) {
    try {
      const cache = this.caches[type];
      if (!cache) {
        console.warn(`⚠️ 알 수 없는 캐시 타입: ${type}`);
        return 0;
      }
      
      const keys = cache.keys();
      const regex = new RegExp(pattern);
      let deletedCount = 0;
      
      keys.forEach(key => {
        if (regex.test(key)) {
          if (cache.del(key) > 0) {
            deletedCount++;
            this.stats.deletes++;
          }
        }
      });
      
      return deletedCount;
    } catch (error) {
      console.error('❌ 패턴 캐시 삭제 오류:', error);
      return 0;
    }
  }

  /**
   * 캐시 전체 삭제
   * @param {string} type - 캐시 타입
   */
  flush(type) {
    try {
      const cache = this.caches[type];
      if (!cache) {
        console.warn(`⚠️ 알 수 없는 캐시 타입: ${type}`);
        return;
      }
      
      cache.flushAll();
      console.log(`🗑️ ${type} 캐시 전체 삭제 완료`);
    } catch (error) {
      console.error('❌ 캐시 전체 삭제 오류:', error);
    }
  }

  /**
   * 캐시 통계 조회
   * @returns {Object} 캐시 통계
   */
  getStats() {
    const totalRequests = this.stats.hits + this.stats.misses;
    const hitRate = totalRequests > 0 ? (this.stats.hits / totalRequests * 100).toFixed(2) : 0;
    
    const cacheStats = {};
    Object.keys(this.caches).forEach(type => {
      const cache = this.caches[type];
      cacheStats[type] = {
        keys: cache.keys().length,
        stats: cache.getStats()
      };
    });
    
    return {
      global: {
        hits: this.stats.hits,
        misses: this.stats.misses,
        sets: this.stats.sets,
        deletes: this.stats.deletes,
        hitRate: `${hitRate}%`
      },
      caches: cacheStats
    };
  }

  /**
   * 캐시 키 생성 (일관성 보장)
   * @param {string} prefix - 접두사
   * @param {...any} parts - 키 구성 요소들
   * @returns {string} 생성된 캐시 키
   */
  static generateKey(prefix, ...parts) {
    return `${prefix}:${parts.join(':')}`;
  }

  /**
   * 사용자 관련 캐시 키 생성
   * @param {number} userId - 사용자 ID
   * @param {string} suffix - 접미사
   * @returns {string} 캐시 키
   */
  static userKey(userId, suffix = '') {
    return this.generateKey('user', userId, suffix);
  }

  /**
   * 매칭 관련 캐시 키 생성
   * @param {number} matchingId - 매칭 ID
   * @param {string} suffix - 접미사
   * @returns {string} 캐시 키
   */
  static matchingKey(matchingId, suffix = '') {
    return this.generateKey('matching', matchingId, suffix);
  }

  /**
   * 게시글 관련 캐시 키 생성
   * @param {number} postId - 게시글 ID
   * @param {string} suffix - 접미사
   * @returns {string} 캐시 키
   */
  static postKey(postId, suffix = '') {
    return this.generateKey('post', postId, suffix);
  }

  /**
   * 페이지네이션 캐시 키 생성
   * @param {string} type - 데이터 타입
   * @param {Object} params - 페이지네이션 파라미터
   * @returns {string} 캐시 키
   */
  static paginationKey(type, params) {
    const keyParts = [type, 'page'];
    
    // 정렬 파라미터 추가
    if (params.sort) {
      keyParts.push('sort', JSON.stringify(params.sort));
    }
    
    // 필터 파라미터 추가
    if (params.filters) {
      keyParts.push('filters', JSON.stringify(params.filters));
    }
    
    // 페이지 정보 추가
    if (params.page) keyParts.push('p', params.page);
    if (params.limit) keyParts.push('l', params.limit);
    if (params.cursor) keyParts.push('c', params.cursor);
    
    return this.generateKey(...keyParts);
  }
}

// 싱글톤 인스턴스 생성
const cacheService = new CacheService();

module.exports = cacheService;
