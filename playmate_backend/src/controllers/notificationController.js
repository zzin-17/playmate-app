const asyncHandler = require('express-async-handler');
const Notification = require('../models/Notification');

// @desc    Get user's notifications
// @route   GET /api/notifications
// @access  Private
const getNotifications = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20, unreadOnly = false } = req.query;
  
  const query = { recipient: req.user.id };
  if (unreadOnly === 'true') {
    query.isRead = false;
  }
  
  const notifications = await Notification.find(query)
    .populate('sender', 'nickname profileImage')
    .sort({ createdAt: -1 })
    .limit(limit * 1)
    .skip((page - 1) * limit);
  
  const total = await Notification.countDocuments(query);
  const unreadCount = await Notification.countDocuments({
    recipient: req.user.id,
    isRead: false
  });
  
  res.json({
    success: true,
    data: notifications,
    unreadCount,
    pagination: {
      current: parseInt(page),
      pages: Math.ceil(total / limit),
      total
    }
  });
});

// @desc    Mark notification as read
// @route   PUT /api/notifications/:id/read
// @access  Private
const markNotificationAsRead = asyncHandler(async (req, res) => {
  const notification = await Notification.findById(req.params.id);
  
  if (!notification) {
    res.status(404);
    throw new Error('Notification not found');
  }
  
  // 수신자만 읽음 처리 가능
  if (notification.recipient.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to mark this notification as read');
  }
  
  notification.isRead = true;
  notification.readAt = new Date();
  await notification.save();
  
  res.json({
    success: true,
    message: 'Notification marked as read'
  });
});

// @desc    Mark all notifications as read
// @route   PUT /api/notifications/read-all
// @access  Private
const markAllNotificationsAsRead = asyncHandler(async (req, res) => {
  await Notification.updateMany(
    { recipient: req.user.id, isRead: false },
    { isRead: true, readAt: new Date() }
  );
  
  res.json({
    success: true,
    message: 'All notifications marked as read'
  });
});

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
const deleteNotification = asyncHandler(async (req, res) => {
  const notification = await Notification.findById(req.params.id);
  
  if (!notification) {
    res.status(404);
    throw new Error('Notification not found');
  }
  
  // 수신자만 삭제 가능
  if (notification.recipient.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to delete this notification');
  }
  
  await notification.deleteOne();
  
  res.json({
    success: true,
    message: 'Notification deleted successfully'
  });
});

// @desc    Get notification count
// @route   GET /api/notifications/count
// @access  Private
const getNotificationCount = asyncHandler(async (req, res) => {
  const unreadCount = await Notification.countDocuments({
    recipient: req.user.id,
    isRead: false
  });
  
  res.json({
    success: true,
    data: { unreadCount }
  });
});

module.exports = {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification,
  getNotificationCount
};