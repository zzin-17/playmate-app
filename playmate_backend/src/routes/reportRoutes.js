const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  createReport,
  getMyReports
} = require('../controllers/reportController');

// 신고 관련 라우트
router.route('/')
  .post(protect, createReport);

router.route('/my')
  .get(protect, getMyReports);

module.exports = router;



