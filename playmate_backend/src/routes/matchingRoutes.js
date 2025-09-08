const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getMatchings,
  getMatching,
  createMatching,
  updateMatching,
  deleteMatching,
  joinMatching,
  leaveMatching
} = require('../controllers/matchingController');

// 매칭 관련 라우트
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

module.exports = router;