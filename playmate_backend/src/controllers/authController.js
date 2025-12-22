const asyncHandler = require('express-async-handler');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const userStore = require('../stores/userStore');

// 사용자 데이터는 server.js에서 통합 관리

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
  
  // 이메일 중복 확인
  if (userStore.isEmailExists(email)) {
    res.status(400);
    throw new Error('User already exists');
  }
  
  // 비밀번호 해시화
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);
  
  // 사용자 수 제한 확인
  if (userStore.getUserCount() >= userStore.maxUsers) {
    res.status(503);
    throw new Error('서버 용량 초과: 최대 사용자 수에 도달했습니다.');
  }
  
  // 고유 ID 생성 (6자리 숫자)
  const userId = userStore.generateUniqueUserId();
  if (!userId) {
    res.status(503);
    throw new Error('사용자 ID 생성 실패: 사용 가능한 ID가 없습니다.');
  }
  
  const newUser = {
    id: userId,                    // 고유 사용자 ID (6자리)
    email: email,                  // 이메일 (중복 불가)
    password: hashedPassword,
    nickname: nickname,
    profileImage: null,
    bio: '',
    birthYear: birthYear,
    gender: gender,
    location: '',
    isVerified: false,
    createdAt: new Date(),
    updatedAt: new Date()
  };
  
  console.log(`🔍 새 사용자 생성 - ID: ${userId}, 이메일: ${email}, 닉네임: ${nickname}`);
  
  // 통합 저장소에 저장
  userStore.addUser(newUser);
  
  // 파일에 저장 (비동기)
  userStore.saveUsersToFile().catch(console.error);
  
  // JWT 토큰 생성
    const token = jwt.sign({ 
      id: newUser.id,
      email: newUser.email,
      nickname: newUser.nickname
    }, process.env.JWT_SECRET);
  
  res.status(201).json({
    success: true,
    message: 'User registered successfully',
    data: {
      id: newUser.id,
      email: newUser.email,
      nickname: newUser.nickname,
      profileImage: newUser.profileImage,
      bio: newUser.bio,
      birthYear: newUser.birthYear,
      gender: newUser.gender,
      location: newUser.location,
      isVerified: newUser.isVerified,
      token: token
    }
  });
});

// @desc    Authenticate user
// @route   POST /api/auth/login
// @access  Public
const loginUser = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  
  console.log(`🔍 로그인 시도: ${email}`);
  console.log(`📊 통합 저장소 상태: 사용자 ${userStore.getUserCount()}명`);
  
  // 통합 저장소에서 사용자 찾기
  const user = userStore.getUserByEmail(email);
  console.log(`👤 사용자 찾기 결과: ${user ? '찾음' : '없음'}`);
  
  if (user && (await bcrypt.compare(password, user.password))) {
    // JWT 토큰 생성
  const token = jwt.sign({ 
    id: user.id,
    email: user.email,
    nickname: user.nickname
  }, process.env.JWT_SECRET);
    
    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        profileImage: user.profileImage,
        bio: user.bio,
        birthYear: user.birthYear,
        gender: user.gender,
        location: user.location,
        isVerified: user.isVerified,
        token: token
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

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
const getCurrentUser = asyncHandler(async (req, res) => {
  // 실제 사용자 데이터를 메모리 스토어에서 가져오기
  const userStore = require('../stores/userStore');
  const user = userStore.getUserById(req.user.id);
  
  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }
  
  // 비밀번호 제외하고 반환
  const { password, ...userWithoutPassword } = user;
  
  // null 값들을 기본값으로 처리
  const safeUser = {
    ...userWithoutPassword,
    // 숫자 필드들 안전 처리
    birthYear: userWithoutPassword.birthYear ? parseInt(userWithoutPassword.birthYear) : 1990,
    skillLevel: userWithoutPassword.skillLevel ? parseInt(userWithoutPassword.skillLevel) : 1,
    reviewCount: userWithoutPassword.reviewCount ? parseInt(userWithoutPassword.reviewCount) : 0,
    mannerScore: userWithoutPassword.mannerScore ? parseFloat(userWithoutPassword.mannerScore) : 5.0,
    ntrpScore: userWithoutPassword.ntrpScore ? parseFloat(userWithoutPassword.ntrpScore) : 3.0,
    // 배열 필드들 안전 처리
    followingIds: Array.isArray(userWithoutPassword.followingIds) ? userWithoutPassword.followingIds : [],
    followerIds: Array.isArray(userWithoutPassword.followerIds) ? userWithoutPassword.followerIds : [],
    preferredTime: Array.isArray(userWithoutPassword.preferredTime) ? userWithoutPassword.preferredTime : [],
    // 문자열 필드들 안전 처리
    startYearMonth: userWithoutPassword.startYearMonth || "2020-01",
    preferredCourt: userWithoutPassword.preferredCourt || "",
    playStyle: userWithoutPassword.playStyle || "",
    preferredGameType: userWithoutPassword.preferredGameType || "mixed",
    bio: userWithoutPassword.bio || "",
    location: userWithoutPassword.location || "",
    // 불린 필드들 안전 처리
    hasLesson: userWithoutPassword.hasLesson === true,
    isVerified: userWithoutPassword.isVerified === true,
  };
  
  res.json({
    success: true,
    data: safeUser
  });
});

const updateProfile = asyncHandler(async (req, res) => {
  const { nickname, bio, location, profileImage } = req.body;
  const userId = req.user.id;
  
  // 통합 저장소에서 사용자 찾기
  const user = userStore.getUserById(userId);
  
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  
  // 프로필 업데이트
  if (nickname) user.nickname = nickname;
  if (bio !== undefined) user.bio = bio;
  if (location !== undefined) user.location = location;
  if (profileImage !== undefined) user.profileImage = profileImage;
  user.updatedAt = new Date();
  
  // 파일에 저장 (비동기)
  userStore.saveUsersToFile().catch(console.error);
  
  console.log(`🔍 프로필 업데이트 - ID: ${userId}, 닉네임: ${nickname || user.nickname}`);
  
  res.json({
    success: true,
    message: 'Profile updated successfully',
    data: {
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      profileImage: user.profileImage,
      bio: user.bio,
      birthYear: user.birthYear,
      gender: user.gender,
      location: user.location,
      isVerified: user.isVerified,
      updatedAt: user.updatedAt
    }
  });
});

// @desc    Kakao Sign In
// @route   POST /api/auth/kakao
// @access  Public
const loginWithKakao = asyncHandler(async (req, res) => {
  const { kakaoId, email, nickname, profileImage } = req.body;
  
  // 필수 필드 검증
  if (!kakaoId) {
    res.status(400);
    throw new Error('Kakao ID is required');
  }
  
  // Kakao ID로 기존 사용자 찾기
  let user = null;
  
  // Kakao ID로 사용자 찾기 (임시로 email로 검색, 실제로는 Kakao ID 저장 필요)
  if (email) {
    user = userStore.getUserByEmail(email);
  }
  
  // Kakao ID로 직접 찾기 (User 모델에 kakaoId 필드가 있다고 가정)
  // user = userStore.getUserByKakaoId(kakaoId);
  
  if (user) {
    // 기존 사용자 로그인
    const token = jwt.sign({ 
      id: user.id,
      email: user.email,
      nickname: user.nickname
    }, process.env.JWT_SECRET);
    
    res.json({
      success: true,
      message: 'Kakao login successful',
      data: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        profileImage: user.profileImage,
        bio: user.bio,
        birthYear: user.birthYear,
        gender: user.gender,
        location: user.location,
        isVerified: user.isVerified,
        token: token
      }
    });
  } else {
    // 신규 사용자 등록
    if (!email) {
      res.status(400);
      throw new Error('Email is required for new user registration');
    }
    
    // 사용자 수 제한 확인
    if (userStore.getUserCount() >= userStore.maxUsers) {
      res.status(503);
      throw new Error('서버 용량 초과: 최대 사용자 수에 도달했습니다.');
    }
    
    // 고유 ID 생성
    const userId = userStore.generateUniqueUserId();
    if (!userId) {
      res.status(503);
      throw new Error('사용자 ID 생성 실패: 사용 가능한 ID가 없습니다.');
    }
    
    // 닉네임 생성
    const finalNickname = nickname || email.split('@')[0] || `User${userId}`;
    
    const newUser = {
      id: userId,
      email: email,
      password: null, // Kakao 로그인은 비밀번호 없음
      nickname: finalNickname,
      profileImage: profileImage || null,
      bio: '',
      birthYear: 1990, // 기본값, 나중에 프로필 설정에서 수정 가능
      gender: 'male', // 기본값, 나중에 프로필 설정에서 수정 가능
      location: '',
      isVerified: true, // Kakao 로그인은 이메일 인증됨
      kakaoId: kakaoId, // Kakao ID 저장
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    console.log(`🔍 Kakao 로그인으로 새 사용자 생성 - ID: ${userId}, 이메일: ${email}, 닉네임: ${finalNickname}`);
    
    // 통합 저장소에 저장
    userStore.addUser(newUser);
    
    // 파일에 저장 (비동기)
    userStore.saveUsersToFile().catch(console.error);
    
    // JWT 토큰 생성
    const token = jwt.sign({ 
      id: newUser.id,
      email: newUser.email,
      nickname: newUser.nickname
    }, process.env.JWT_SECRET);
    
    res.status(201).json({
      success: true,
      message: 'Kakao registration successful',
      data: {
        id: newUser.id,
        email: newUser.email,
        nickname: newUser.nickname,
        profileImage: newUser.profileImage,
        bio: newUser.bio,
        birthYear: newUser.birthYear,
        gender: newUser.gender,
        location: newUser.location,
        isVerified: newUser.isVerified,
        token: token
      }
    });
  }
});

// @desc    Apple Sign In
// @route   POST /api/auth/apple
// @access  Public
const loginWithApple = asyncHandler(async (req, res) => {
  const { identityToken, authorizationCode, userIdentifier, email, fullName } = req.body;
  
  // 필수 필드 검증
  if (!identityToken && !userIdentifier) {
    res.status(400);
    throw new Error('Apple authentication token is required');
  }
  
  // userIdentifier를 사용하여 기존 사용자 찾기
  const appleId = userIdentifier || identityToken;
  let user = null;
  
  // Apple ID로 기존 사용자 찾기 (임시로 email로 검색, 실제로는 Apple ID 저장 필요)
  if (email) {
    user = userStore.getUserByEmail(email);
  }
  
  if (user) {
    // 기존 사용자 로그인
    const token = jwt.sign({ 
      id: user.id,
      email: user.email,
      nickname: user.nickname
    }, process.env.JWT_SECRET);
    
    res.json({
      success: true,
      message: 'Apple login successful',
      data: {
        id: user.id,
        email: user.email,
        nickname: user.nickname,
        profileImage: user.profileImage,
        bio: user.bio,
        birthYear: user.birthYear,
        gender: user.gender,
        location: user.location,
        isVerified: user.isVerified,
        token: token
      }
    });
  } else {
    // 신규 사용자 등록
    if (!email) {
      res.status(400);
      throw new Error('Email is required for new user registration');
    }
    
    // 사용자 수 제한 확인
    if (userStore.getUserCount() >= userStore.maxUsers) {
      res.status(503);
      throw new Error('서버 용량 초과: 최대 사용자 수에 도달했습니다.');
    }
    
    // 고유 ID 생성
    const userId = userStore.generateUniqueUserId();
    if (!userId) {
      res.status(503);
      throw new Error('사용자 ID 생성 실패: 사용 가능한 ID가 없습니다.');
    }
    
    // 닉네임 생성 (fullName이 있으면 사용, 없으면 email 기반)
    const nickname = fullName || email.split('@')[0] || `User${userId}`;
    
    const newUser = {
      id: userId,
      email: email,
      password: null, // Apple 로그인은 비밀번호 없음
      nickname: nickname,
      profileImage: null,
      bio: '',
      birthYear: 1990, // 기본값, 나중에 프로필 설정에서 수정 가능
      gender: 'male', // 기본값, 나중에 프로필 설정에서 수정 가능
      location: '',
      isVerified: true, // Apple 로그인은 이메일 인증됨
      appleId: appleId, // Apple ID 저장
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    console.log(`🔍 Apple 로그인으로 새 사용자 생성 - ID: ${userId}, 이메일: ${email}, 닉네임: ${nickname}`);
    
    // 통합 저장소에 저장
    userStore.addUser(newUser);
    
    // 파일에 저장 (비동기)
    userStore.saveUsersToFile().catch(console.error);
    
    // JWT 토큰 생성
    const token = jwt.sign({ 
      id: newUser.id,
      email: newUser.email,
      nickname: newUser.nickname
    }, process.env.JWT_SECRET);
    
    res.status(201).json({
      success: true,
      message: 'Apple registration successful',
      data: {
        id: newUser.id,
        email: newUser.email,
        nickname: newUser.nickname,
        profileImage: newUser.profileImage,
        bio: newUser.bio,
        birthYear: newUser.birthYear,
        gender: newUser.gender,
        location: newUser.location,
        isVerified: newUser.isVerified,
        token: token
      }
    });
  }
});

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET);
};

module.exports = { registerUser, loginUser, getCurrentUser, getMe, updateProfile, loginWithApple, loginWithKakao };