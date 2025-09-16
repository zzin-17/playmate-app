const asyncHandler = require('express-async-handler');
const Matching = require('../models/Matching');
const fs = require('fs');
const path = require('path');

// 파일 기반 저장소 (앱 재시작 시에도 유지)
const STORAGE_FILE = path.join(__dirname, '../../data/matchings.json');

// 저장소 초기화
let memoryStore = {
  matchings: new Map(),
  nextId: 1
};

// 파일에서 데이터 로드
function loadFromFile() {
  try {
    if (fs.existsSync(STORAGE_FILE)) {
      const data = fs.readFileSync(STORAGE_FILE, 'utf8');
      const loadedData = JSON.parse(data);
      
      // Map 구조로 변환
      memoryStore.matchings = new Map();
      if (Array.isArray(loadedData)) {
        loadedData.forEach(matching => {
          memoryStore.matchings.set(matching.id, matching);
        });
        memoryStore.nextId = Math.max(...loadedData.map(m => m.id), 0) + 1;
      } else if (loadedData.matchings) {
        Object.entries(loadedData.matchings).forEach(([id, matching]) => {
          memoryStore.matchings.set(parseInt(id), matching);
        });
        memoryStore.nextId = loadedData.nextId || 1;
      }
      
      console.log(`📁 파일에서 ${memoryStore.matchings.size}개 매칭 로드됨`);
      
      // 디버깅: 887887 매칭 상태 확인
      const matching887887 = memoryStore.matchings.get(1757407253725);
      if (matching887887) {
        console.log(`🔍 파일에서 로드된 887887 매칭 상태: ${matching887887.status}`);
      } else {
        console.log('🔍 파일에서 887887 매칭을 찾을 수 없음');
      }
    } else {
      // 디렉토리 생성
      const dir = path.dirname(STORAGE_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      memoryStore = {
        matchings: new Map(),
        nextId: 1
      };
      console.log('📁 새로운 저장소 파일 생성됨');
    }
  } catch (error) {
    console.error('📁 파일 로드 오류:', error);
    memoryStore = {
      matchings: new Map(),
      nextId: 1
    };
  }
}

// 파일에 데이터 저장
function saveToFile() {
  try {
    const dir = path.dirname(STORAGE_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    // Map을 일반 객체로 변환하여 저장
    const dataToSave = {
      matchings: Object.fromEntries(memoryStore.matchings),
      nextId: memoryStore.nextId
    };
    
    fs.writeFileSync(STORAGE_FILE, JSON.stringify(dataToSave, null, 2));
    console.log(`💾 ${memoryStore.matchings.size}개 매칭을 파일에 저장됨`);
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
  
  // 메모리 저장소의 데이터만 사용 (하드코딩된 데이터 제거)
  const allMatchings = Array.from(memoryStore.matchings.values());
  
  // 디버깅: 887887 매칭 상태 확인
  const matching887887 = allMatchings.find(m => m.id === 1757407253725);
  if (matching887887) {
    console.log(`🔍 887887 매칭 상태: ${matching887887.status}`);
  } else {
    console.log('🔍 887887 매칭을 찾을 수 없음');
  }
  
  console.log(`📊 총 ${allMatchings.length}개 매칭 반환`);
  
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
  const matchingId = parseInt(req.params.id);
  const matching = memoryStore.matchings.get(matchingId);
  
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
  
  console.log('🔍 추출된 값들:');
  console.log('  - maleRecruitCount:', maleRecruitCount);
  console.log('  - femaleRecruitCount:', femaleRecruitCount);
  console.log('  - guestCost:', guestCost);
  console.log('  - isFollowersOnly:', isFollowersOnly);
  
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
    maleRecruitCount: maleRecruitCount ?? 2,
    femaleRecruitCount: femaleRecruitCount ?? 2,
    status: 'recruiting',
    message: message || description || '',
    guestCost: guestCost ?? 0,
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
  console.log('🔍 매칭 수정 요청:', req.params.id, JSON.stringify(req.body, null, 2));
  
  const matchingId = parseInt(req.params.id);
  
  // 메모리 저장소에서 매칭 찾기
  const matchingIndex = memoryStore.findIndex(m => m.id === matchingId);
  
  if (matchingIndex === -1) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  const matching = memoryStore[matchingIndex];
  
  // 호스트만 수정 가능 (임시로 모든 사용자 허용)
  // if (matching.host.id !== parseInt(req.user.id.replace('temp_id_', ''))) {
  //   res.status(403);
  //   throw new Error('Not authorized to update this matching');
  // }
  
  // 매칭 데이터 업데이트
  const updatedMatching = {
    ...matching,
    ...req.body,
    id: matchingId, // ID는 변경하지 않음
    updatedAt: new Date().toISOString()
  };
  
  // 메모리 저장소 업데이트
  memoryStore[matchingIndex] = updatedMatching;
  
  // 파일에 저장
  saveToFile();
  
  console.log(`💾 매칭 수정 완료: ${updatedMatching.courtName} (ID: ${updatedMatching.id})`);
  
  res.json({
    success: true,
    data: updatedMatching
  });
});

// @desc    Delete matching
// @route   DELETE /api/matchings/:id
// @access  Private
const deleteMatching = asyncHandler(async (req, res) => {
  console.log('🔍 매칭 삭제 요청:', req.params.id);
  
  const matchingId = parseInt(req.params.id);
  
  // 메모리 저장소에서 매칭 찾기
  const matchingIndex = memoryStore.findIndex(m => m.id === matchingId);
  
  if (matchingIndex === -1) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  const matching = memoryStore[matchingIndex];
  
  // 호스트만 삭제 가능 (임시로 모든 사용자 허용)
  // if (matching.host.id !== parseInt(req.user.id.replace('temp_id_', ''))) {
  //   res.status(403);
  //   throw new Error('Not authorized to delete this matching');
  // }
  
  // 메모리 저장소에서 매칭 제거
  memoryStore.splice(matchingIndex, 1);
  
  // 파일에 저장
  saveToFile();
  
  console.log(`💾 매칭 삭제 완료: ${matching.courtName} (ID: ${matching.id})`);
  
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