/**
 * 사용자 ID 일관성 검증 유틸리티
 * 모든 API에서 사용자 ID가 일관되게 사용되는지 확인
 */

/**
 * 사용자 ID 유효성 검증 (대규모 사용자 대응)
 * @param {number} userId - 검증할 사용자 ID
 * @param {string} email - 검증할 이메일
 * @returns {boolean} - 유효한 사용자 ID인지 여부
 */
const validateUserId = (userId, email) => {
  // ID 타입 및 범위 검증
  if (!userId || typeof userId !== 'number') {
    console.error('❌ 잘못된 사용자 ID 타입:', userId);
    return false;
  }
  
  // ID 범위 검증 (1 ~ 999999) - 기존 사용자 ID 1-4도 허용
  if (userId < 1 || userId > 999999) {
    console.error('❌ 사용자 ID 범위 초과:', userId);
    return false;
  }
  
  // 이메일 형식 검증
  if (!email || typeof email !== 'string') {
    console.error('❌ 잘못된 이메일:', email);
    return false;
  }
  
  // 이메일 형식 검증 (간단한 정규식)
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    console.error('❌ 잘못된 이메일 형식:', email);
    return false;
  }
  
  return true;
};

/**
 * 사용자 ID와 이메일 일치성 검증
 * @param {number} userId - 사용자 ID
 * @param {string} email - 이메일
 * @param {Object} user - 사용자 객체
 * @returns {boolean} - ID와 이메일이 일치하는지 여부
 */
const validateUserConsistency = (userId, email, user) => {
  if (!user) {
    console.error('❌ 사용자 정보가 없습니다');
    return false;
  }
  
  if (user.id !== userId) {
    console.error('❌ 사용자 ID 불일치:', { expected: userId, actual: user.id });
    return false;
  }
  
  if (user.email !== email) {
    console.error('❌ 사용자 이메일 불일치:', { expected: email, actual: user.email });
    return false;
  }
  
  return true;
};

/**
 * API 요청에서 사용자 정보 로깅
 * @param {Object} req - Express 요청 객체
 * @param {string} operation - 수행 중인 작업명
 */
const logUserOperation = (req, operation) => {
  const userId = req.user?.id;
  const email = req.user?.email;
  const nickname = req.user?.nickname;
  
  console.log(`🔍 ${operation} - 사용자 ID: ${userId}, 이메일: ${email}, 닉네임: ${nickname}`);
};

module.exports = {
  validateUserId,
  validateUserConsistency,
  logUserOperation
};
