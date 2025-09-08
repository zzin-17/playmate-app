const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getChatRooms,
  createDirectChatRoom,
  getChatMessages,
  sendMessage,
  markMessagesAsRead,
  leaveChatRoom
} = require('../controllers/chatController');

// 채팅 관련 라우트
router.route('/rooms')
  .get(protect, getChatRooms);

router.route('/rooms/direct')
  .post(protect, createDirectChatRoom);

router.route('/rooms/:roomId/messages')
  .get(protect, getChatMessages)
  .post(protect, sendMessage);

router.route('/rooms/:roomId/read')
  .put(protect, markMessagesAsRead);

router.route('/rooms/:roomId/leave')
  .delete(protect, leaveChatRoom);

module.exports = router;