const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getMatchings,
  getMatching,
  getMyMatchings,
  createMatching,
  updateMatching,
  deleteMatching,
  joinMatching,
  leaveMatching,
  confirmMatching
} = require('../controllers/matchingController');

// 매칭 관련 라우트 (순서 중요: 구체적인 경로를 먼저 정의)

// 내 매칭 목록 조회 (/:id 보다 먼저 정의해야 함)
router.route('/my')
  .get(protect, getMyMatchings);

router.route('/')
  .get(protect, getMatchings)
  .post(protect, createMatching);

router.route('/:id')
  .get(protect, getMatching)
  .put(protect, updateMatching)
  .delete(protect, deleteMatching);

router.route('/:id/join')
  .post(protect, joinMatching);

router.route('/:id/leave')
  .post(protect, leaveMatching);

router.route('/:id/confirm')
  .post(protect, confirmMatching);

module.exports = router;