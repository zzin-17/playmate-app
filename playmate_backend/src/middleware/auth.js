const jwt = require('jsonwebtoken');
const asyncHandler = require('express-async-handler');

// 메모리 스토어에서 사용자 조회
const { memoryStore } = require('../controllers/authController');

const protect = asyncHandler(async (req, res, next) => {
  let token;
  
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // 토큰 추출
      token = req.headers.authorization.split(' ')[1];
      
      // temp_jwt_token은 더 이상 사용하지 않음
      
      // JWT 토큰 검증
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // JWT에서 사용자 정보 직접 사용 (토큰에 포함된 정보)
      req.user = {
        id: decoded.id,
        email: decoded.email,
        nickname: decoded.nickname,
      };
      
      console.log(`🔍 인증된 사용자 - ID: ${req.user.id}, 이메일: ${req.user.email}, 닉네임: ${req.user.nickname}`);
      
      next();
    } catch (error) {
      console.error('Token verification error:', error);
      res.status(401);
      throw new Error('Not authorized, token failed');
    }
  }
  
  if (!token) {
    res.status(401);
    throw new Error('Not authorized, no token');
  }
});

module.exports = { protect };