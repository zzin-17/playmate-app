const asyncHandler = require('express-async-handler');

// @desc    Health check
// @route   GET /api/health
// @access  Public
const healthCheck = asyncHandler(async (req, res) => {
  res.json({
    success: true,
    message: 'Server is healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

module.exports = {
  healthCheck
};