const express = require('express');
const router = express.Router();
const { getApiStatus } = require('../controllers/indexController');

// API 상태 확인
router.route('/')
  .get(getApiStatus);

module.exports = router;