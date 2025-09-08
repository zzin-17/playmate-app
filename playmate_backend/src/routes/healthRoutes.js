const express = require('express');
const router = express.Router();
const { healthCheck } = require('../controllers/healthController');

// 헬스체크 라우트
router.route('/')
  .get(healthCheck);

module.exports = router;