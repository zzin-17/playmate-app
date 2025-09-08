const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification,
  getNotificationCount
} = require('../controllers/notificationController');

// 알림 관련 라우트
router.route('/')
  .get(protect, getNotifications);

router.route('/count')
  .get(protect, getNotificationCount);

router.route('/read-all')
  .put(protect, markAllNotificationsAsRead);

router.route('/:id/read')
  .put(protect, markNotificationAsRead);

router.route('/:id')
  .delete(protect, deleteNotification);

module.exports = router;