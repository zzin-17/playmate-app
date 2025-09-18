/**
 * 표준화된 API 응답 헬퍼 함수들
 * 모든 컨트롤러에서 일관된 응답 형식을 사용하기 위함
 */

/**
 * 성공 응답 (단일 데이터)
 * @param {Object} res - Express response 객체
 * @param {*} data - 응답 데이터
 * @param {string} message - 성공 메시지 (선택사항)
 * @param {number} statusCode - HTTP 상태 코드 (기본값: 200)
 */
const sendSuccessResponse = (res, data, message = null, statusCode = 200) => {
  const response = {
    success: true,
    data,
    timestamp: new Date().toISOString()
  };
  
  if (message) {
    response.message = message;
  }
  
  res.status(statusCode).json(response);
};

/**
 * 성공 응답 (페이지네이션 포함)
 * @param {Object} res - Express response 객체
 * @param {Array} data - 응답 데이터 배열
 * @param {Object} pagination - 페이지네이션 정보
 * @param {string} message - 성공 메시지 (선택사항)
 */
const sendPaginatedResponse = (res, data, pagination, message = null) => {
  const response = {
    success: true,
    data,
    pagination: {
      page: parseInt(pagination.page) || 1,
      limit: parseInt(pagination.limit) || 20,
      total: pagination.total || 0,
      totalPages: Math.ceil((pagination.total || 0) / (parseInt(pagination.limit) || 20))
    },
    timestamp: new Date().toISOString()
  };
  
  if (message) {
    response.message = message;
  }
  
  res.status(200).json(response);
};

/**
 * 생성 성공 응답
 * @param {Object} res - Express response 객체
 * @param {*} data - 생성된 데이터
 * @param {string} message - 성공 메시지 (선택사항)
 */
const sendCreatedResponse = (res, data, message = null) => {
  sendSuccessResponse(res, data, message, 201);
};

/**
 * 오류 응답
 * @param {Object} res - Express response 객체
 * @param {string} message - 오류 메시지
 * @param {number} statusCode - HTTP 상태 코드
 * @param {*} error - 상세 오류 정보 (선택사항, 개발 환경에서만)
 */
const sendErrorResponse = (res, message, statusCode = 500, error = null) => {
  const response = {
    success: false,
    message,
    timestamp: new Date().toISOString()
  };
  
  // 개발 환경에서만 상세 오류 정보 포함
  if (process.env.NODE_ENV === 'development' && error) {
    response.error = error.message || error;
    response.stack = error.stack;
  }
  
  res.status(statusCode).json(response);
};

/**
 * 404 Not Found 응답
 * @param {Object} res - Express response 객체
 * @param {string} resource - 찾을 수 없는 리소스명
 */
const sendNotFoundResponse = (res, resource = '리소스') => {
  sendErrorResponse(res, `${resource}를 찾을 수 없습니다.`, 404);
};

/**
 * 400 Bad Request 응답
 * @param {Object} res - Express response 객체
 * @param {string} message - 오류 메시지
 */
const sendBadRequestResponse = (res, message = '잘못된 요청입니다.') => {
  sendErrorResponse(res, message, 400);
};

/**
 * 401 Unauthorized 응답
 * @param {Object} res - Express response 객체
 * @param {string} message - 오류 메시지
 */
const sendUnauthorizedResponse = (res, message = '인증이 필요합니다.') => {
  sendErrorResponse(res, message, 401);
};

/**
 * 403 Forbidden 응답
 * @param {Object} res - Express response 객체
 * @param {string} message - 오류 메시지
 */
const sendForbiddenResponse = (res, message = '권한이 없습니다.') => {
  sendErrorResponse(res, message, 403);
};

/**
 * 422 Validation Error 응답
 * @param {Object} res - Express response 객체
 * @param {Object} validationErrors - 유효성 검사 오류 목록
 */
const sendValidationErrorResponse = (res, validationErrors) => {
  const response = {
    success: false,
    message: '입력 데이터 검증에 실패했습니다.',
    validationErrors,
    timestamp: new Date().toISOString()
  };
  
  res.status(422).json(response);
};

module.exports = {
  sendSuccessResponse,
  sendPaginatedResponse,
  sendCreatedResponse,
  sendErrorResponse,
  sendNotFoundResponse,
  sendBadRequestResponse,
  sendUnauthorizedResponse,
  sendForbiddenResponse,
  sendValidationErrorResponse
};
