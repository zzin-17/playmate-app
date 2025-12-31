const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  batchLoadPosts,
  batchLoadChatRooms,
  batchLoadNotifications,
  batchLoadReviews,
  batchSyncProfiles,
  batchRequest
} = require('../controllers/batchController');

// 배치 API 라우트
router.post('/posts', protect, batchLoadPosts);
router.post('/chat-rooms', protect, batchLoadChatRooms);
router.post('/notifications', protect, batchLoadNotifications);
router.post('/reviews', protect, batchLoadReviews);
router.post('/profiles', protect, batchSyncProfiles);

// 통합 배치 요청
router.post('/request', protect, batchRequest);

module.exports = router;




