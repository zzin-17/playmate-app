const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getMe } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

// 인증 관련 라우트
router.route('/register')
  .post(registerUser);

router.route('/login')
  .post(loginUser);

router.route('/me')
  .get(protect, getMe);

module.exports = router;