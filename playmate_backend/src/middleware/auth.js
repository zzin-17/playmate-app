const jwt = require('jsonwebtoken');
const User = require('../models/User');
const asyncHandler = require('express-async-handler');

const protect = asyncHandler(async (req, res, next) => {
  let token;
  
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // 토큰 추출
      token = req.headers.authorization.split(' ')[1];
      
      // 임시로 MongoDB 없이 작동하도록 수정
      if (token === 'temp_jwt_token') {
        req.user = {
          id: 'temp_id_123',
          email: 'test@example.com',
          nickname: 'testuser'
        };
        next();
        return;
      }
      
      // 실제 JWT 토큰 검증 (MongoDB 연결 시 사용)
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // 사용자 정보 가져오기
      req.user = await User.findById(decoded.id).select('-password');
      
      if (!req.user) {
        res.status(401);
        throw new Error('Not authorized, user not found');
      }
      
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