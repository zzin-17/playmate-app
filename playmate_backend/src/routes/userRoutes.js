const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getUserProfile,
  updateUserProfile,
  deleteUser,
  searchUsers
} = require('../controllers/userController');

// 사용자 관련 라우트
router.route('/search')
  .get(protect, searchUsers);

router.route('/:id')
  .get(protect, getUserProfile)
  .put(protect, updateUserProfile)
  .delete(protect, deleteUser);

module.exports = router;