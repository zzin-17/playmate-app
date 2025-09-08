const asyncHandler = require('express-async-handler');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// @desc    Register new user
// @route   POST /api/auth/register
// @access  Public
const registerUser = asyncHandler(async (req, res) => {
  const { email, password, nickname, birthYear, gender } = req.body;
  
  // 필수 필드 검증
  if (!email || !password || !nickname || !birthYear || !gender) {
    res.status(400);
    throw new Error('Please add all required fields');
  }
  
  // 임시로 MongoDB 없이 작동하도록 수정
  res.status(201).json({
    success: true,
    message: 'User registration endpoint is working (MongoDB not connected)',
    data: {
      id: 'temp_id_123',
      email: email,
      nickname: nickname,
      profileImage: null,
      bio: '',
      birthYear: birthYear,
      gender: gender,
      location: '',
      isVerified: false,
      token: 'temp_jwt_token'
    }
  });
});

// @desc    Authenticate user
// @route   POST /api/auth/login
// @access  Public
const loginUser = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  
  // 사용자 확인
  const user = await User.findOne({ email });
  
  if (user && (await bcrypt.compare(password, user.password))) {
    res.json({
      success: true,
      data: {
        id: user._id,
        email: user.email,
        nickname: user.nickname,
        profileImage: user.profileImage,
        bio: user.bio,
        birthYear: user.birthYear,
        gender: user.gender,
        location: user.location,
        isVerified: user.isVerified,
        token: generateToken(user._id)
      }
    });
  } else {
    res.status(401);
    throw new Error('Invalid credentials');
  }
});

// @desc    Get user data
// @route   GET /api/auth/me
// @access  Private
const getMe = asyncHandler(async (req, res) => {
  res.json({
    success: true,
    data: {
      id: req.user._id,
      email: req.user.email,
      nickname: req.user.nickname,
      profileImage: req.user.profileImage,
      bio: req.user.bio,
      birthYear: req.user.birthYear,
      gender: req.user.gender,
      location: req.user.location,
      isVerified: req.user.isVerified,
      createdAt: req.user.createdAt
    }
  });
});

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
  });
};

module.exports = { registerUser, loginUser, getMe };