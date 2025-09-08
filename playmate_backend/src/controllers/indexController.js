const asyncHandler = require('express-async-handler');

// @desc    API status
// @route   GET /api
// @access  Public
const getApiStatus = asyncHandler(async (req, res) => {
  res.json({
    success: true,
    message: 'Playmate API Server is running',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      matchings: '/api/matchings',
      community: '/api/community',
      chat: '/api/chat',
      reviews: '/api/reviews',
      notifications: '/api/notifications',
      upload: '/api/upload',
      health: '/api/health'
    }
  });
});

module.exports = {
  getApiStatus
};