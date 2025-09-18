/**
 * 시스템 모니터링 유틸리티
 * 대규모 사용자 시스템의 성능과 상태를 모니터링
 */

/**
 * 시스템 상태 모니터링
 * @param {Object} memoryStore - 메모리 스토어 객체
 * @param {Array} posts - 게시글 배열
 * @param {Object} postIndexes - 게시글 인덱스 객체
 * @returns {Object} - 시스템 상태 정보
 */
const getSystemStatus = (memoryStore, posts, postIndexes) => {
  const now = new Date();
  
  return {
    timestamp: now.toISOString(),
    users: {
      total: memoryStore.users.size,
      max: memoryStore.maxUsers,
      usage: `${((memoryStore.users.size / memoryStore.maxUsers) * 100).toFixed(2)}%`,
      idRange: {
        min: memoryStore.idRange.min,
        max: memoryStore.idRange.max
      }
    },
    posts: {
      total: posts.length,
      indexed: {
        byAuthorId: postIndexes.byAuthorId.size,
        byCategory: postIndexes.byCategory.size,
        byDate: postIndexes.byDate.size
      }
    },
    performance: {
      memoryUsage: process.memoryUsage(),
      uptime: process.uptime()
    }
  };
};

/**
 * 사용자 ID 분포 분석
 * @param {Map} users - 사용자 Map
 * @returns {Object} - ID 분포 정보
 */
const analyzeUserIdDistribution = (users) => {
  const idRanges = {
    '100000-199999': 0,
    '200000-299999': 0,
    '300000-399999': 0,
    '400000-499999': 0,
    '500000-599999': 0,
    '600000-699999': 0,
    '700000-799999': 0,
    '800000-899999': 0,
    '900000-999999': 0
  };
  
  for (const [id, user] of users) {
    const range = Math.floor(id / 100000) * 100000;
    const rangeKey = `${range}-${range + 99999}`;
    if (idRanges[rangeKey] !== undefined) {
      idRanges[rangeKey]++;
    }
  }
  
  return idRanges;
};

/**
 * 시스템 상태 로깅
 * @param {Object} memoryStore - 메모리 스토어 객체
 * @param {Array} posts - 게시글 배열
 * @param {Object} postIndexes - 게시글 인덱스 객체
 */
const logSystemStatus = (memoryStore, posts, postIndexes) => {
  const status = getSystemStatus(memoryStore, posts, postIndexes);
  const idDistribution = analyzeUserIdDistribution(memoryStore.users);
  
  console.log('📊 시스템 상태 모니터링');
  console.log('👥 사용자:', status.users);
  console.log('📝 게시글:', status.posts);
  console.log('🆔 ID 분포:', idDistribution);
  console.log('⚡ 성능:', {
    memory: `${Math.round(status.performance.memoryUsage.heapUsed / 1024 / 1024)}MB`,
    uptime: `${Math.round(status.performance.uptime)}초`
  });
};

module.exports = {
  getSystemStatus,
  analyzeUserIdDistribution,
  logSystemStatus
};
