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
      
      // temp_jwt_token 처리 (개발용)
      if (token === 'temp_jwt_token') {
        req.user = {
          id: 1,
          email: 'dev@playmate.com',
          nickname: 'dev',
        };
        return next();
      }
      
      // JWT 토큰 검증
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // 메모리 스토어에서 사용자 정보 조회
      const user = memoryStore.users.get(decoded.id);
      
      if (!user) {
        res.status(401);
        throw new Error('Not authorized, user not found');
      }
      
      // 비밀번호 제외하고 사용자 정보 설정
      req.user = {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        profileImage: user.profileImage,
        bio: user.bio,
        birthYear: user.birthYear,
        gender: user.gender,
        location: user.location,
        isVerified: user.isVerified
      };
      
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