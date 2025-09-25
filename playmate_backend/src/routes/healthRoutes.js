const express = require('express');
const router = express.Router();
const { healthCheck, detailedHealthCheck } = require('../controllers/healthController');

// 헬스체크 라우트
router.route('/')
  .get(healthCheck);

// 상세 헬스체크 라우트
router.route('/detailed')
  .get(detailedHealthCheck);

module.exports = router;