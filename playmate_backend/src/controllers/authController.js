const asyncHandler = require('express-async-handler');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const User = require('../models/User');

// 사용자 데이터 파일 경로
const USERS_FILE = path.join(__dirname, '../data/users.json');

// 메모리 저장소 (대규모 사용자 대응)
const memoryStore = {
  users: new Map(), // ID를 키로 사용
  usersByEmail: new Map(), // 이메일을 키로 사용 (중복 체크용)
  nextId: 1,
  maxUsers: 1000000, // 최대 100만 사용자 지원
  idRange: {
    min: 100000, // 6자리 ID 시작 (100000부터)
    max: 999999  // 6자리 ID 끝 (999999까지)
  }
};

// 고유 사용자 ID 생성 함수 (대규모 사용자 대응)
const generateUniqueUserId = () => {
  const maxAttempts = 1000; // 최대 시도 횟수
  let attempts = 0;
  
  while (attempts < maxAttempts) {
    // 6자리 랜덤 ID 생성 (100000 ~ 999999)
    const randomId = Math.floor(Math.random() * (memoryStore.idRange.max - memoryStore.idRange.min + 1)) + memoryStore.idRange.min;
    
    // ID 중복 확인
    if (!memoryStore.users.has(randomId)) {
      return randomId;
    }
    
    attempts++;
  }
  
  // 시퀀셜 ID로 폴백 (100000부터 시작)
  let sequentialId = memoryStore.idRange.min;
  while (sequentialId <= memoryStore.idRange.max) {
    if (!memoryStore.users.has(sequentialId)) {
      return sequentialId;
    }
    sequentialId++;
  }
  
  return null; // 사용 가능한 ID가 없음
};

// 사용자 데이터를 파일에서 로드 (비동기로 변경)
const loadUsersFromFile = async () => {
  try {
    // 디렉토리가 없으면 미리 생성
    const dir = path.dirname(USERS_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    if (fs.existsSync(USERS_FILE)) {
      const data = await fs.promises.readFile(USERS_FILE, 'utf8');
      const usersData = JSON.parse(data);
      
      // Map으로 변환
      memoryStore.users.clear();
      memoryStore.usersByEmail.clear();
      
      // users가 배열인지 확인
      if (Array.isArray(usersData.users)) {
        usersData.users.forEach(user => {
          memoryStore.users.set(user.id, user);
          memoryStore.usersByEmail.set(user.email, user);
        });
      } else {
        console.log('⚠️ 사용자 데이터가 배열이 아닙니다. 빈 배열로 시작합니다.');
      }
      
      // nextId 설정
      memoryStore.nextId = usersData.nextId || 1;
      console.log(`✅ 사용자 데이터 로드 완료: ${memoryStore.users.size}명, 다음 ID: ${memoryStore.nextId}`);
    } else {
      console.log('📝 사용자 데이터 파일이 없습니다. 새로 시작합니다.');
    }
  } catch (error) {
    console.error('❌ 사용자 데이터 로드 실패:', error.message);
    memoryStore.users.clear();
    memoryStore.nextId = 1;
  }
};

// 사용자 데이터를 파일에 저장 (비동기로 변경)
const saveUsersToFile = async () => {
  try {
    const usersData = {
      users: Array.from(memoryStore.users.values()),
      nextId: memoryStore.nextId
    };
    
    // 디렉토리가 없으면 생성
    const dir = path.dirname(USERS_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    await fs.promises.writeFile(USERS_FILE, JSON.stringify(usersData, null, 2));
    console.log(`💾 사용자 데이터 저장 완료: ${memoryStore.users.size}명`);
  } catch (error) {
    console.error('❌ 사용자 데이터 저장 실패:', error.message);
  }
};

// 서버 시작 시 사용자 데이터 로드
loadUsersFromFile();

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
  if (memoryStore.usersByEmail.has(email)) {
    res.status(400);
    throw new Error('User already exists');
  }
  
  // 비밀번호 해시화
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);
  
  // 사용자 수 제한 확인
  if (memoryStore.users.size >= memoryStore.maxUsers) {
    res.status(503);
    throw new Error('서버 용량 초과: 최대 사용자 수에 도달했습니다.');
  }
  
  // 고유 ID 생성 (6자리 숫자)
  const userId = generateUniqueUserId();
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
  
  // 메모리에 저장
  memoryStore.users.set(newUser.id, newUser);
  memoryStore.usersByEmail.set(email, newUser);
  
  // 파일에 저장 (비동기)
  saveUsersToFile().catch(console.error);
  
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
  
  // 메모리에서 사용자 찾기
  const user = memoryStore.usersByEmail.get(email);
  
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
  res.json({
    success: true,
    data: {
      id: req.user.id,
      email: req.user.email,
      nickname: req.user.nickname,
      profileImage: req.user.profileImage,
      bio: req.user.bio,
      birthYear: req.user.birthYear,
      gender: req.user.gender,
      location: req.user.location,
      isVerified: req.user.isVerified
    }
  });
});

const updateProfile = asyncHandler(async (req, res) => {
  const { nickname, bio, location } = req.body;
  const userId = req.user.id;
  
  // 사용자 찾기
  let user = null;
  for (const [email, u] of memoryStore.users) {
    if (u.id === userId) {
      user = u;
      break;
    }
  }
  
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  
  // 프로필 업데이트
  if (nickname) user.nickname = nickname;
  if (bio !== undefined) user.bio = bio;
  if (location !== undefined) user.location = location;
  user.updatedAt = new Date();
  
  // 파일에 저장 (비동기)
  saveUsersToFile().catch(console.error);
  
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

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET);
};

module.exports = { registerUser, loginUser, getCurrentUser, getMe, updateProfile };