const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getUserProfile,
  updateUserProfile,
  deleteUser,
  searchUsers,
  testDataStatus,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing
} = require('../controllers/userControllerMemory');

// 사용자 관련 라우트 (임시로 인증 제거)
router.route('/search')
  .get(searchUsers);

router.route('/test')
  .get(testDataStatus);

router.route('/:id')
  .get(protect, getUserProfile)
  .put(protect, updateUserProfile)
  .delete(protect, deleteUser);

router.route('/:id/follow')
  .post(protect, followUser)
  .delete(protect, unfollowUser);

router.route('/:id/followers')
  .get(protect, getFollowers);

router.route('/:id/following')
  .get(protect, getFollowing);

module.exports = router;