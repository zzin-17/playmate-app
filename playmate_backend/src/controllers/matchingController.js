const asyncHandler = require('express-async-handler');
const Matching = require('../models/Matching');
const fs = require('fs');
const path = require('path');

// 파일 기반 저장소 (앱 재시작 시에도 유지)
const STORAGE_FILE = path.join(__dirname, '../../data/matchings.json');

// 저장소 초기화
let memoryStore = [];

// 파일에서 데이터 로드
function loadFromFile() {
  try {
    if (fs.existsSync(STORAGE_FILE)) {
      const data = fs.readFileSync(STORAGE_FILE, 'utf8');
      memoryStore = JSON.parse(data);
      console.log(`📁 파일에서 ${memoryStore.length}개 매칭 로드됨`);
    } else {
      // 디렉토리 생성
      const dir = path.dirname(STORAGE_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      memoryStore = [];
      console.log('📁 새로운 저장소 파일 생성됨');
    }
  } catch (error) {
    console.error('📁 파일 로드 오류:', error);
    memoryStore = [];
  }
}

// 파일에 데이터 저장
function saveToFile() {
  try {
    const dir = path.dirname(STORAGE_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(STORAGE_FILE, JSON.stringify(memoryStore, null, 2));
    console.log(`💾 ${memoryStore.length}개 매칭을 파일에 저장됨`);
  } catch (error) {
    console.error('💾 파일 저장 오류:', error);
  }
}

// 서버 시작 시 데이터 로드
loadFromFile();

// @desc    Get all matchings
// @route   GET /api/matchings
// @access  Private
const getMatchings = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, gameType, status } = req.query;
  
  // 임시로 MongoDB 없이 작동하도록 수정 - Flutter 모델과 호환
  const mockMatchings = [
    {
      id: 1,
      type: 'host',
      courtName: '테스트 체육관',
      courtLat: 37.5665,
      courtLng: 126.9780,
      date: new Date('2024-01-15').toISOString(),
      timeSlot: '19:00~21:00',
      minLevel: 1,
      maxLevel: 5,
      minAge: 20,
      maxAge: 40,
      gameType: 'mixed',
      maleRecruitCount: 2,
      femaleRecruitCount: 2,
      status: 'recruiting',
      message: 'API 테스트용 매칭입니다',
      guestCost: 0,
      isFollowersOnly: false,
      host: {
        id: 123,
        nickname: 'testuser',
        email: 'test@example.com',
        profileImage: null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      guests: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      recoveryCount: 0,
      appliedUserIds: [],
      confirmedUserIds: [],
      completedAt: null,
      cancelledAt: null
    }
  ];
  
  // 메모리 저장소의 데이터와 기본 데이터를 합침
  const allMatchings = [...mockMatchings, ...memoryStore];
  
  res.json({
    success: true,
    data: allMatchings,
    pagination: {
      current: parseInt(page),
      pages: 1,
      total: allMatchings.length
    }
  });
});

// @desc    Get single matching
// @route   GET /api/matchings/:id
// @access  Private
const getMatching = asyncHandler(async (req, res) => {
  const matching = await Matching.findById(req.params.id)
    .populate('host', 'nickname profileImage bio')
    .populate('guests.user', 'nickname profileImage bio');
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  res.json({
    success: true,
    data: matching
  });
});

// @desc    Create new matching
// @route   POST /api/matchings
// @access  Private
const createMatching = asyncHandler(async (req, res) => {
  console.log('🔍 백엔드에서 받은 요청 데이터:', JSON.stringify(req.body, null, 2));
  
  const {
    courtName,
    description,
    gameType,
    date,
    startTime,
    endTime,
    location,
    maxParticipants,
    maleRecruitCount,
    femaleRecruitCount,
    guestCost,
    message,
    minLevel,
    maxLevel,
    minAge,
    maxAge,
    isFollowersOnly
  } = req.body;
  
  console.log('🔍 추출된 isFollowersOnly 값:', isFollowersOnly);
  
  // Flutter 모델과 호환되는 데이터 구조로 변환
  const newMatching = {
    id: Date.now(), // Flutter는 숫자 ID를 기대
    type: 'host',
    courtName: courtName || '테스트 코트',
    courtLat: location?.lat || 37.5665, // 기본값: 서울시청
    courtLng: location?.lng || 126.9780,
    date: new Date(date).toISOString(),
    timeSlot: `${startTime || '18:00'}~${endTime || '20:00'}`,
    minLevel: minLevel || 1,
    maxLevel: maxLevel || 5,
    minAge: minAge,
    maxAge: maxAge,
    gameType: gameType || 'singles',
    maleRecruitCount: maleRecruitCount || 2,
    femaleRecruitCount: femaleRecruitCount || 2,
    status: 'recruiting',
    message: message || description || '',
    guestCost: guestCost || 0,
    isFollowersOnly: isFollowersOnly || false,
    host: {
      id: parseInt(req.user.id.replace('temp_id_', '')),
      nickname: req.user.nickname,
      email: req.user.email,
      profileImage: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    guests: [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    recoveryCount: 0,
    appliedUserIds: [],
    confirmedUserIds: [],
    completedAt: null,
    cancelledAt: null
  };
  
  // 메모리 저장소에 새 매칭 저장
  memoryStore.push(newMatching);
  console.log(`💾 새 매칭이 메모리 저장소에 저장됨: ${newMatching.courtName} (ID: ${newMatching.id})`);
  console.log(`📊 현재 메모리 저장소 매칭 개수: ${memoryStore.length}`);
  
  // 파일에 저장
  saveToFile();
  
  res.status(201).json({
    success: true,
    message: 'Matching created successfully (MongoDB not connected)',
    data: newMatching
  });
});

// @desc    Update matching
// @route   PUT /api/matchings/:id
// @access  Private
const updateMatching = asyncHandler(async (req, res) => {
  const matching = await Matching.findById(req.params.id);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  // 호스트만 수정 가능
  if (matching.host.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to update this matching');
  }
  
  const updatedMatching = await Matching.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true, runValidators: true }
  ).populate('host', 'nickname profileImage');
  
  res.json({
    success: true,
    data: updatedMatching
  });
});

// @desc    Delete matching
// @route   DELETE /api/matchings/:id
// @access  Private
const deleteMatching = asyncHandler(async (req, res) => {
  const matching = await Matching.findById(req.params.id);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  // 호스트만 삭제 가능
  if (matching.host.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to delete this matching');
  }
  
  await matching.deleteOne();
  
  res.json({
    success: true,
    message: 'Matching deleted successfully'
  });
});

// @desc    Join matching
// @route   POST /api/matchings/:id/join
// @access  Private
const joinMatching = asyncHandler(async (req, res) => {
  const matching = await Matching.findById(req.params.id);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  // 이미 참여한 사용자인지 확인
  const existingGuest = matching.guests.find(
    guest => guest.user.toString() === req.user.id
  );
  
  if (existingGuest) {
    res.status(400);
    throw new Error('Already joined this matching');
  }
  
  // 최대 참여자 수 확인
  if (matching.currentParticipants >= matching.maxParticipants) {
    res.status(400);
    throw new Error('Matching is full');
  }
  
  matching.guests.push({
    user: req.user.id,
    status: 'pending'
  });
  
  matching.currentParticipants += 1;
  
  await matching.save();
  
  res.json({
    success: true,
    message: 'Successfully requested to join matching'
  });
});

// @desc    Leave matching
// @route   POST /api/matchings/:id/leave
// @access  Private
const leaveMatching = asyncHandler(async (req, res) => {
  const matching = await Matching.findById(req.params.id);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  const guestIndex = matching.guests.findIndex(
    guest => guest.user.toString() === req.user.id
  );
  
  if (guestIndex === -1) {
    res.status(400);
    throw new Error('Not a participant of this matching');
  }
  
  matching.guests.splice(guestIndex, 1);
  matching.currentParticipants -= 1;
  
  await matching.save();
  
  res.json({
    success: true,
    message: 'Successfully left matching'
  });
});

module.exports = {
  getMatchings,
  getMatching,
  createMatching,
  updateMatching,
  deleteMatching,
  joinMatching,
  leaveMatching
};