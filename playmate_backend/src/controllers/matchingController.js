const asyncHandler = require('express-async-handler');
const Matching = require('../models/Matching');
const fs = require('fs');
const path = require('path');
const { createPaginationOptions, createPaginationMeta, createAggregationPipeline, createQueryHint } = require('../utils/pagination');
const cacheService = require('../services/cacheService');
const performanceMonitor = require('../services/performanceMonitor');
const memoryOptimizer = require('../utils/memoryOptimizer');

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
  
  // 모든 매칭 데이터를 안전하게 처리
  const safeMatchings = allMatchings.map(matching => ({
    ...matching,
    // 숫자 필드들 null 안전성 보장
    minLevel: matching.minLevel ?? 1,
    maxLevel: matching.maxLevel ?? 5,
    minAge: matching.minAge ?? 20,
    maxAge: matching.maxAge ?? 60,
    maleRecruitCount: matching.maleRecruitCount ?? 0,
    femaleRecruitCount: matching.femaleRecruitCount ?? 0,
    guestCost: matching.guestCost ?? 0,
    recoveryCount: matching.recoveryCount ?? 0,
    
    // 배열 필드들 null 안전성 보장
    appliedUserIds: matching.appliedUserIds ?? [],
    confirmedUserIds: matching.confirmedUserIds ?? [],
    guests: matching.guests ?? [],
    
    // DateTime 필드들 null 안전성 보장
    completedAt: matching.completedAt || null,
    cancelledAt: matching.cancelledAt || null,
    
    // Boolean 필드들 null 안전성 보장
    isFollowersOnly: matching.isFollowersOnly ?? false,
    
    // String 필드들 기본값 보장
    type: matching.type || 'host',
    courtName: matching.courtName || '테니스장',
    timeSlot: matching.timeSlot || '18:00~20:00',
    gameType: matching.gameType || 'mixed',
    status: matching.status || 'recruiting',
    message: matching.message || '',
    
    // Double 필드들 기본값 보장
    courtLat: matching.courtLat ?? 37.5665,
    courtLng: matching.courtLng ?? 126.978,
    
    // Host 객체 안전성 보장
    host: {
      ...matching.host,
      id: matching.host?.id ?? 0,
      nickname: matching.host?.nickname || 'Unknown',
      email: matching.host?.email || 'unknown@example.com',
      profileImage: matching.host?.profileImage || null,
      createdAt: matching.host?.createdAt || new Date().toISOString(),
      updatedAt: matching.host?.updatedAt || new Date().toISOString(),
    }
  }));
  
  console.log(`📊 총 ${safeMatchings.length}개 안전한 매칭 데이터 반환`);
  
  res.json({
    success: true,
    data: safeMatchings,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: safeMatchings.length,
      totalPages: Math.ceil(safeMatchings.length / parseInt(limit))
    }
  });
});

// @desc    Get single matching
// @route   GET /api/matchings/:id
// @access  Private
const getMatching = asyncHandler(async (req, res) => {
  const matchingId = parseInt(req.params.id);
  let matching = memoryStore.matchings.get(matchingId);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }

  // null 값들을 안전하게 처리하여 Flutter에서 파싱 오류 방지
  const safeMatching = {
    ...matching,
    // 숫자 필드들 null 안전성 보장
    minLevel: matching.minLevel ?? 1,
    maxLevel: matching.maxLevel ?? 5,
    minAge: matching.minAge ?? 20,
    maxAge: matching.maxAge ?? 60,
    maleRecruitCount: matching.maleRecruitCount ?? 0,
    femaleRecruitCount: matching.femaleRecruitCount ?? 0,
    guestCost: matching.guestCost ?? 0,
    recoveryCount: matching.recoveryCount ?? 0,
    
    // 배열 필드들 null 안전성 보장
    appliedUserIds: matching.appliedUserIds ?? [],
    confirmedUserIds: matching.confirmedUserIds ?? [],
    guests: matching.guests ?? [],
    
    // DateTime 필드들 null 안전성 보장
    completedAt: matching.completedAt || null,
    cancelledAt: matching.cancelledAt || null,
    
    // Boolean 필드들 null 안전성 보장
    isFollowersOnly: matching.isFollowersOnly ?? false,
    
    // String 필드들 기본값 보장
    type: matching.type || 'host',
    courtName: matching.courtName || '테니스장',
    timeSlot: matching.timeSlot || '18:00~20:00',
    gameType: matching.gameType || 'mixed',
    status: matching.status || 'recruiting',
    message: matching.message || '',
    
    // Double 필드들 기본값 보장
    courtLat: matching.courtLat ?? 37.5665,
    courtLng: matching.courtLng ?? 126.978,
    
    // Host 객체 안전성 보장
    host: {
      ...matching.host,
      id: matching.host?.id ?? 0,
      nickname: matching.host?.nickname || 'Unknown',
      email: matching.host?.email || 'unknown@example.com',
      profileImage: matching.host?.profileImage || null,
      createdAt: matching.host?.createdAt || new Date().toISOString(),
      updatedAt: matching.host?.updatedAt || new Date().toISOString(),
    }
  };

  console.log(`✅ 안전한 매칭 데이터 반환: ${safeMatching.courtName} (ID: ${safeMatching.id})`);

  res.json({
    success: true,
    data: safeMatching
  });
});

// @desc    Create new matching
// @route   POST /api/matchings
// @access  Private
const createMatching = asyncHandler(async (req, res) => {
  // 클라이언트 데이터에서 host 정보 제거 (보안상 무시)
  const { host, ...safeBody } = req.body;
  console.log('🔍 백엔드에서 받은 요청 데이터 (host 제외):', JSON.stringify(safeBody, null, 2));
  
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
    // host 정보는 클라이언트에서 받지 않고 req.user 사용
  } = safeBody;
  
  console.log('🔍 추출된 값들:');
  console.log('  - maleRecruitCount:', maleRecruitCount);
  console.log('  - femaleRecruitCount:', femaleRecruitCount);
  console.log('  - guestCost:', guestCost);
  console.log('  - isFollowersOnly:', isFollowersOnly);
  
  console.log('🔍 인증된 사용자 정보:');
  console.log('  - ID:', req.user.id);
  console.log('  - 이메일:', req.user.email);
  console.log('  - 닉네임:', req.user.nickname);
  
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
      id: req.user.id, // 6자리 고유 ID 시스템 사용
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
  
  // 메모리 저장소에 새 매칭 저장 (Map 구조 사용)
  memoryStore.matchings.set(newMatching.id, newMatching);
  console.log(`💾 새 매칭이 메모리 저장소에 저장됨: ${newMatching.courtName} (ID: ${newMatching.id})`);
  console.log(`📊 현재 메모리 저장소 매칭 개수: ${memoryStore.matchings.size}`);
  
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
  
  // 메모리 저장소에서 매칭 찾기 (Map 구조 사용)
  const matching = memoryStore.matchings.get(matchingId);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
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
  
  // 메모리 저장소 업데이트 (Map 구조 사용)
  memoryStore.matchings.set(matchingId, updatedMatching);
  
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
  
  // 메모리 저장소에서 매칭 찾기 (Map 구조 사용)
  const matching = memoryStore.matchings.get(matchingId);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  // 호스트만 삭제 가능 (임시로 모든 사용자 허용)
  // if (matching.host.id !== req.user.id) {
  //   res.status(403);
  //   throw new Error('Not authorized to delete this matching');
  // }
  
  // 메모리 저장소에서 매칭 제거 (Map 구조 사용)
  memoryStore.matchings.delete(matchingId);
  
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
  try {
    const matchingId = parseInt(req.params.id);
    const userId = req.user.id;
    
    console.log(`🔍 매칭 참여 요청: 사용자 ${userId} -> 매칭 ${matchingId}`);
    
    // 메모리에서 매칭 찾기
    const matching = memoryStore.matchings.get(matchingId);
    
    if (!matching) {
      console.log(`❌ 매칭을 찾을 수 없음: ${matchingId}`);
      return res.status(404).json({
        success: false,
        message: 'Matching not found'
      });
    }
    
    // 이미 참여한 사용자인지 확인
    const isAlreadyApplied = matching.appliedUserIds && matching.appliedUserIds.includes(userId);
    
    if (isAlreadyApplied) {
      console.log(`⚠️ 이미 신청한 사용자: ${userId}`);
      return res.status(400).json({
        success: false,
        message: 'Already applied to this matching'
      });
    }
    
    // 신청자 목록에 추가
    if (!matching.appliedUserIds) {
      matching.appliedUserIds = [];
    }
    matching.appliedUserIds.push(userId);
    
    // 메모리 업데이트
    memoryStore.matchings.set(matchingId, matching);
    
    // 파일에 저장
    saveToFile();
    
    // 매칭 참여 시 호스트와의 1:1 채팅방 자동 생성
    try {
      const { addChatRoomToMemory, saveToFile: saveChatToFile } = require('./chatControllerMemory');
      
      // 호스트와의 1:1 채팅방 생성 (중복 방지)
      const chatRoomId = `${matchingId}_${matching.host.id}_${userId}`;
      
      // 기존 채팅방 확인
      const existingRoom = chatRooms.find(room => 
        room.matchingId === matchingId && 
        room.participants.some(p => p.userId === userId) &&
        room.participants.some(p => p.userId === matching.host.id)
      );
      
      if (!existingRoom) {
        const newChatRoom = {
          id: chatRoomId,
          type: 'direct',
          name: null,
          participants: [
            {
              userId: userId,
              joinedAt: new Date().toISOString(),
              lastReadAt: new Date().toISOString()
            },
            {
              userId: matching.host.id,
              joinedAt: new Date().toISOString(),
              lastReadAt: new Date().toISOString()
            }
          ],
          lastMessage: null,
          isActive: true,
          matchingId: matchingId,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        
        addChatRoomToMemory(newChatRoom);
        saveChatToFile();
        
        console.log(`💬 채팅방 생성 완료: ${userId} ↔ ${matching.host.id} (매칭: ${matchingId})`);
      } else {
        console.log(`⚠️ 채팅방이 이미 존재함: ${userId} ↔ ${matching.host.id}`);
      }
      
    } catch (chatError) {
      console.error('채팅방 생성 중 오류 발생:', chatError);
      // 채팅방 생성 실패해도 매칭 참여는 성공으로 처리
    }
    
    console.log(`✅ 매칭 참여 완료: 사용자 ${userId} -> 매칭 ${matchingId}`);
    
    res.json({
      success: true,
      message: 'Successfully requested to join matching',
      data: {
        matchingId: matchingId,
        userId: userId,
        appliedUserIds: matching.appliedUserIds
      }
    });
  } catch (error) {
    console.error('❌ 매칭 참여 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to join matching',
      error: error.message
    });
  }
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

// @desc    Get my matchings (hosted + applied)
// @route   GET /api/matchings/my
// @access  Private
const getMyMatchings = asyncHandler(async (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`🔍 내 매칭 목록 조회: 사용자 ${userId}`);
    
    const allMatchings = Array.from(memoryStore.matchings.values());
    const myMatchings = [];
    
    for (const matching of allMatchings) {
      // 내가 호스트인 매칭
      if (matching.host && matching.host.id === userId) {
        myMatchings.push({
          ...matching,
          myRole: 'host'
        });
      }
      // 내가 신청한 매칭
      else if (matching.appliedUserIds && matching.appliedUserIds.includes(userId)) {
        myMatchings.push({
          ...matching,
          myRole: 'guest'
        });
      }
      // 내가 확정된 매칭
      else if (matching.confirmedUserIds && matching.confirmedUserIds.includes(userId)) {
        myMatchings.push({
          ...matching,
          myRole: 'confirmed_guest'
        });
      }
    }
    
    // 최신 순으로 정렬
    myMatchings.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    console.log(`✅ 내 매칭 ${myMatchings.length}개 반환 (호스트/게스트 포함)`);
    
    res.json({
      success: true,
      data: myMatchings,
      count: myMatchings.length
    });
  } catch (error) {
    console.error('❌ 내 매칭 목록 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '내 매칭 목록 조회에 실패했습니다.',
      error: error.message
    });
  }
});

// @desc    Confirm matching
// @route   POST /api/matchings/:id/confirm
// @access  Private (Host only)
const confirmMatching = asyncHandler(async (req, res) => {
  try {
    const matchingId = parseInt(req.params.id);
    const userId = req.user.id;
    
    console.log(`🔍 매칭 확정 요청: 사용자 ${userId} -> 매칭 ${matchingId}`);
    
    // 메모리에서 매칭 찾기
    const matching = memoryStore.matchings.get(matchingId);
    
    if (!matching) {
      console.log(`❌ 매칭을 찾을 수 없음: ${matchingId}`);
      return res.status(404).json({
        success: false,
        message: 'Matching not found'
      });
    }
    
    // 호스트 권한 확인
    if (matching.host.id !== userId) {
      console.log(`❌ 매칭 확정 권한 없음: 사용자 ${userId}, 호스트 ${matching.host.id}`);
      return res.status(403).json({
        success: false,
        message: 'Only host can confirm matching'
      });
    }
    
    // 매칭 상태를 confirmed로 변경
    matching.status = 'confirmed';
    matching.updatedAt = new Date().toISOString();
    
    // 신청자들을 확정자로 이동
    if (matching.appliedUserIds && matching.appliedUserIds.length > 0) {
      if (!matching.confirmedUserIds) {
        matching.confirmedUserIds = [];
      }
      matching.confirmedUserIds.push(...matching.appliedUserIds);
      matching.appliedUserIds = []; // 신청자 목록 초기화
    }
    
    // 메모리 업데이트
    memoryStore.matchings.set(matchingId, matching);
    
    // 파일에 저장
    saveToFile();
    
    console.log(`✅ 매칭 확정 완료: 매칭 ${matchingId}, 확정자 ${matching.confirmedUserIds?.length || 0}명`);
    
    res.json({
      success: true,
      message: 'Matching confirmed successfully',
      data: {
        matchingId: matchingId,
        status: matching.status,
        confirmedUserIds: matching.confirmedUserIds,
        appliedUserIds: matching.appliedUserIds
      }
    });
  } catch (error) {
    console.error('❌ 매칭 확정 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to confirm matching',
      error: error.message
    });
  }
});

// @desc    Cancel matching
// @route   POST /api/matchings/:id/cancel
// @access  Private (Host only)
const cancelMatching = asyncHandler(async (req, res) => {
  try {
    const matchingId = parseInt(req.params.id);
    const userId = req.user.id;
    
    console.log(`🔍 매칭 취소 요청: 사용자 ${userId} -> 매칭 ${matchingId}`);
    
    // 메모리에서 매칭 찾기
    const matching = memoryStore.matchings.get(matchingId);
    
    if (!matching) {
      console.log(`❌ 매칭을 찾을 수 없음: ${matchingId}`);
      return res.status(404).json({
        success: false,
        message: 'Matching not found'
      });
    }
    
    // 호스트 권한 확인
    if (matching.host.id !== userId) {
      console.log(`❌ 매칭 취소 권한 없음: 사용자 ${userId}, 호스트 ${matching.host.id}`);
      return res.status(403).json({
        success: false,
        message: 'Only host can cancel matching'
      });
    }
    
    // 매칭 상태를 cancelled로 변경
    matching.status = 'cancelled';
    matching.cancelledAt = new Date().toISOString();
    matching.updatedAt = new Date().toISOString();
    
    // 메모리 업데이트
    memoryStore.matchings.set(matchingId, matching);
    
    // 파일에 저장
    saveToFile();
    
    console.log(`✅ 매칭 취소 완료: 매칭 ${matchingId}`);
    
    res.json({
      success: true,
      message: 'Matching cancelled successfully',
      data: {
        matchingId: matchingId,
        status: matching.status,
        cancelledAt: matching.cancelledAt
      }
    });
  } catch (error) {
    console.error('❌ 매칭 취소 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel matching',
      error: error.message
    });
  }
});

// @desc    Complete matching
// @route   POST /api/matchings/:id/complete
// @access  Private (Host only)
const completeMatching = asyncHandler(async (req, res) => {
  try {
    const matchingId = parseInt(req.params.id);
    const userId = req.user.id;
    
    console.log(`🔍 매칭 완료 요청: 사용자 ${userId} -> 매칭 ${matchingId}`);
    
    // 메모리에서 매칭 찾기
    const matching = memoryStore.matchings.get(matchingId);
    
    if (!matching) {
      console.log(`❌ 매칭을 찾을 수 없음: ${matchingId}`);
      return res.status(404).json({
        success: false,
        message: 'Matching not found'
      });
    }
    
    // 호스트 권한 확인
    if (matching.host.id !== userId) {
      console.log(`❌ 매칭 완료 권한 없음: 사용자 ${userId}, 호스트 ${matching.host.id}`);
      return res.status(403).json({
        success: false,
        message: 'Only host can complete matching'
      });
    }
    
    // 매칭 상태를 completed로 변경
    matching.status = 'completed';
    matching.completedAt = new Date().toISOString();
    matching.updatedAt = new Date().toISOString();
    
    // 메모리 업데이트
    memoryStore.matchings.set(matchingId, matching);
    
    // 파일에 저장
    saveToFile();
    
    console.log(`✅ 매칭 완료: 매칭 ${matchingId}`);
    
    res.json({
      success: true,
      message: 'Matching completed successfully',
      data: {
        matchingId: matchingId,
        status: matching.status,
        completedAt: matching.completedAt
      }
    });
  } catch (error) {
    console.error('❌ 매칭 완료 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to complete matching',
      error: error.message
    });
  }
});

// @desc    Cancel matching confirmation (확정 취소)
// @route   POST /api/matchings/:id/cancel-confirmation
// @access  Private (Host only)
const cancelMatchingConfirmation = asyncHandler(async (req, res) => {
  try {
    const matchingId = parseInt(req.params.id);
    const userId = req.user.id;
    
    console.log(`🔍 매칭 확정 취소 요청: 사용자 ${userId} -> 매칭 ${matchingId}`);
    
    // 메모리에서 매칭 찾기
    const matching = memoryStore.matchings.get(matchingId);
    
    if (!matching) {
      console.log(`❌ 매칭을 찾을 수 없음: ${matchingId}`);
      return res.status(404).json({
        success: false,
        message: 'Matching not found'
      });
    }
    
    // 호스트 권한 확인
    if (matching.host.id !== userId) {
      console.log(`❌ 매칭 확정 취소 권한 없음: 사용자 ${userId}, 호스트 ${matching.host.id}`);
      return res.status(403).json({
        success: false,
        message: 'Only host can cancel matching confirmation'
      });
    }
    
    // 매칭 상태를 recruiting으로 변경 (확정 취소)
    matching.status = 'recruiting';
    matching.updatedAt = new Date().toISOString();
    
    // 확정자들을 다시 신청자로 이동
    if (matching.confirmedUserIds && matching.confirmedUserIds.length > 0) {
      if (!matching.appliedUserIds) {
        matching.appliedUserIds = [];
      }
      matching.appliedUserIds.push(...matching.confirmedUserIds);
      matching.confirmedUserIds = []; // 확정자 목록 초기화
    }
    
    // 메모리 업데이트
    memoryStore.matchings.set(matchingId, matching);
    
    // 파일에 저장
    saveToFile();
    
    console.log(`✅ 매칭 확정 취소 완료: 매칭 ${matchingId}`);
    
    res.json({
      success: true,
      message: 'Matching confirmation cancelled successfully',
      data: {
        matchingId: matchingId,
        status: matching.status,
        appliedUserIds: matching.appliedUserIds,
        confirmedUserIds: matching.confirmedUserIds
      }
    });
  } catch (error) {
    console.error('❌ 매칭 확정 취소 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cancel matching confirmation',
      error: error.message
    });
  }
});

module.exports = {
  getMatchings,
  getMatching,
  getMyMatchings,
  createMatching,
  updateMatching,
  deleteMatching,
  joinMatching,
  leaveMatching,
  confirmMatching,
  cancelMatching,
  completeMatching,
  cancelMatchingConfirmation
};