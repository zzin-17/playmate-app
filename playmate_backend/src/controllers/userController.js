const asyncHandler = require('express-async-handler');
const User = require('../models/User');

// @desc    Get user profile
// @route   GET /api/users/:id
// @access  Private
const getUserProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id).select('-password');
  
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  
  res.json({
    success: true,
    data: user
  });
});

// @desc    Update user profile
// @route   PUT /api/users/:id
// @access  Private
const updateUserProfile = asyncHandler(async (req, res) => {
  const { nickname, bio, profileImage, location } = req.body;
  
  const user = await User.findById(req.params.id);
  
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  
  // 업데이트할 필드들만 수정
  if (nickname) user.nickname = nickname;
  if (bio !== undefined) user.bio = bio;
  if (profileImage !== undefined) user.profileImage = profileImage;
  if (location !== undefined) user.location = location;
  
  const updatedUser = await user.save();
  
  res.json({
    success: true,
    data: updatedUser
  });
});

// @desc    Delete user account
// @route   DELETE /api/users/:id
// @access  Private
const deleteUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);
  
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  
  // 실제로는 soft delete로 처리하는 것이 좋음
  user.isActive = false;
  await user.save();
  
  res.json({
    success: true,
    message: 'User account deactivated successfully'
  });
});

// @desc    Search users
// @route   GET /api/users/search?q=query
// @access  Private
const searchUsers = asyncHandler(async (req, res) => {
  const { q } = req.query;
  
  if (!q) {
    res.status(400);
    throw new Error('Search query is required');
  }
  
  const users = await User.find({
    $and: [
      { isActive: true },
      {
        $or: [
          { nickname: { $regex: q, $options: 'i' } },
          { email: { $regex: q, $options: 'i' } }
        ]
      }
    ]
  }).select('-password').limit(20);
  
  res.json({
    success: true,
    data: users
  });
});

module.exports = {
  getUserProfile,
  updateUserProfile,
  deleteUser,
  searchUsers
};