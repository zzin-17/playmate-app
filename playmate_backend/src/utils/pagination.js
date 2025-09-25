// 대용량 데이터 처리를 위한 페이지네이션 유틸리티

/**
 * 페이지네이션 옵션 생성
 * @param {Object} query - 쿼리 파라미터
 * @returns {Object} 페이지네이션 옵션
 */
const createPaginationOptions = (query) => {
  const page = Math.max(1, parseInt(query.page) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit) || 20)); // 최대 100개로 제한
  const skip = (page - 1) * limit;
  
  return {
    page,
    limit,
    skip,
    sort: query.sort || { createdAt: -1 } // 기본 정렬: 최신순
  };
};

/**
 * 페이지네이션 메타데이터 생성
 * @param {number} total - 전체 데이터 수
 * @param {number} page - 현재 페이지
 * @param {number} limit - 페이지당 항목 수
 * @returns {Object} 페이지네이션 메타데이터
 */
const createPaginationMeta = (total, page, limit) => {
  const totalPages = Math.ceil(total / limit);
  const hasNextPage = page < totalPages;
  const hasPrevPage = page > 1;
  
  return {
    currentPage: page,
    totalPages,
    totalItems: total,
    itemsPerPage: limit,
    hasNextPage,
    hasPrevPage,
    nextPage: hasNextPage ? page + 1 : null,
    prevPage: hasPrevPage ? page - 1 : null
  };
};

/**
 * 커서 기반 페이지네이션 (무한 스크롤용)
 * @param {Object} query - 쿼리 파라미터
 * @returns {Object} 커서 페이지네이션 옵션
 */
const createCursorPaginationOptions = (query) => {
  const limit = Math.min(50, Math.max(1, parseInt(query.limit) || 20)); // 최대 50개로 제한
  const cursor = query.cursor || null;
  const sort = query.sort || { createdAt: -1 };
  
  return {
    limit,
    cursor,
    sort,
    direction: query.direction || 'next' // 'next' 또는 'prev'
  };
};

/**
 * 커서 기반 페이지네이션 쿼리 생성
 * @param {Object} paginationOptions - 페이지네이션 옵션
 * @param {Object} baseQuery - 기본 쿼리
 * @returns {Object} MongoDB 쿼리 객체
 */
const createCursorQuery = (paginationOptions, baseQuery = {}) => {
  const { cursor, sort, direction } = paginationOptions;
  
  if (!cursor) {
    return baseQuery;
  }
  
  const cursorQuery = { ...baseQuery };
  
  // 정렬 필드에 따른 커서 조건 생성
  const sortField = Object.keys(sort)[0];
  const sortValue = sort[sortField];
  
  if (direction === 'next') {
    if (sortValue === -1) {
      // 내림차순: cursor보다 작은 값
      cursorQuery[sortField] = { $lt: cursor };
    } else {
      // 오름차순: cursor보다 큰 값
      cursorQuery[sortField] = { $gt: cursor };
    }
  } else {
    if (sortValue === -1) {
      // 내림차순: cursor보다 큰 값
      cursorQuery[sortField] = { $gt: cursor };
    } else {
      // 오름차순: cursor보다 작은 값
      cursorQuery[sortField] = { $lt: cursor };
    }
  }
  
  return cursorQuery;
};

/**
 * 커서 기반 페이지네이션 응답 생성
 * @param {Array} items - 데이터 배열
 * @param {Object} paginationOptions - 페이지네이션 옵션
 * @returns {Object} 페이지네이션 응답
 */
const createCursorResponse = (items, paginationOptions) => {
  const { limit, sort } = paginationOptions;
  const sortField = Object.keys(sort)[0];
  
  let nextCursor = null;
  let prevCursor = null;
  
  if (items.length > 0) {
    // 다음 커서 생성
    if (items.length === limit) {
      nextCursor = items[items.length - 1][sortField];
    }
    
    // 이전 커서 생성
    if (items.length > 0) {
      prevCursor = items[0][sortField];
    }
  }
  
  return {
    items,
    pagination: {
      hasNextPage: nextCursor !== null,
      hasPrevPage: prevCursor !== null,
      nextCursor,
      prevCursor,
      limit,
      count: items.length
    }
  };
};

/**
 * 대용량 데이터 처리를 위한 집계 파이프라인 생성
 * @param {Object} filters - 필터 조건
 * @param {Object} paginationOptions - 페이지네이션 옵션
 * @param {Array} additionalStages - 추가 집계 단계
 * @returns {Array} MongoDB 집계 파이프라인
 */
const createAggregationPipeline = (filters, paginationOptions, additionalStages = []) => {
  const pipeline = [];
  
  // 1. 매치 단계 (필터링)
  if (Object.keys(filters).length > 0) {
    pipeline.push({ $match: filters });
  }
  
  // 2. 추가 집계 단계
  additionalStages.forEach(stage => {
    pipeline.push(stage);
  });
  
  // 3. 정렬 단계
  pipeline.push({ $sort: paginationOptions.sort });
  
  // 4. 페이지네이션 단계
  if (paginationOptions.skip !== undefined) {
    pipeline.push({ $skip: paginationOptions.skip });
  }
  pipeline.push({ $limit: paginationOptions.limit });
  
  return pipeline;
};

/**
 * 성능 최적화를 위한 쿼리 힌트 생성
 * @param {Object} sort - 정렬 조건
 * @param {Object} filters - 필터 조건
 * @returns {Object} 쿼리 힌트
 */
const createQueryHint = (sort, filters) => {
  // 정렬 필드에 맞는 인덱스 힌트 생성
  const sortField = Object.keys(sort)[0];
  
  // 필터 조건에 따라 최적의 인덱스 선택
  if (filters.status && sortField === 'gameDate') {
    return { status: 1, gameDate: -1 };
  } else if (filters.authorId && sortField === 'createdAt') {
    return { authorId: 1, createdAt: -1 };
  } else if (sortField === 'createdAt') {
    return { createdAt: -1 };
  } else if (sortField === 'gameDate') {
    return { gameDate: -1 };
  }
  
  return null;
};

/**
 * 대용량 데이터 검색 최적화
 * @param {string} searchTerm - 검색어
 * @param {Array} fields - 검색할 필드들
 * @returns {Object} 검색 쿼리
 */
const createSearchQuery = (searchTerm, fields) => {
  if (!searchTerm || !fields || fields.length === 0) {
    return {};
  }
  
  // 텍스트 인덱스를 사용한 검색
  return {
    $text: {
      $search: searchTerm,
      $caseSensitive: false,
      $diacriticSensitive: false
    }
  };
};

module.exports = {
  createPaginationOptions,
  createPaginationMeta,
  createCursorPaginationOptions,
  createCursorQuery,
  createCursorResponse,
  createAggregationPipeline,
  createQueryHint,
  createSearchQuery
};
