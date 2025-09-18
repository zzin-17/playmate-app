const fs = require('fs');
const path = require('path');

// 채팅 데이터 파일 경로
const CHAT_ROOMS_FILE = path.join(__dirname, '../data/chat_rooms.json');
const CHAT_MESSAGES_FILE = path.join(__dirname, '../data/chat_messages.json');

// 메모리 스토어 (대량 데이터 처리 최적화)
let chatRooms = [];
let chatMessages = [];
let nextRoomId = 1;
let nextMessageId = 1;

// 성능 최적화를 위한 인덱스 (수만 개 채팅방 대응)
let userRoomsIndex = new Map(); // userId -> roomIds[]
let matchingRoomsIndex = new Map(); // matchingId -> roomIds[]

// 인덱스 업데이트 함수 (성능 최적화)
function updateIndexes() {
  userRoomsIndex.clear();
  matchingRoomsIndex.clear();
  
  for (const room of chatRooms) {
    // 사용자별 인덱스
    for (const participant of room.participants) {
      const userId = participant.userId;
      if (!userRoomsIndex.has(userId)) {
        userRoomsIndex.set(userId, []);
      }
      userRoomsIndex.get(userId).push(room.id);
    }
    
    // 매칭별 인덱스
    if (room.matchingId) {
      if (!matchingRoomsIndex.has(room.matchingId)) {
        matchingRoomsIndex.set(room.matchingId, []);
      }
      matchingRoomsIndex.get(room.matchingId).push(room.id);
    }
  }
  
  console.log(`📊 인덱스 업데이트 완료: 사용자 ${userRoomsIndex.size}명, 매칭 ${matchingRoomsIndex.size}개`);
}

// 파일에서 데이터 로드
function loadFromFile() {
  try {
    // 채팅방 데이터 로드
    if (fs.existsSync(CHAT_ROOMS_FILE)) {
      const roomsData = fs.readFileSync(CHAT_ROOMS_FILE, 'utf8');
      chatRooms = JSON.parse(roomsData);
      console.log(`채팅방 데이터 로드 완료: ${chatRooms.length}개`);
      
      // 인덱스 구축
      updateIndexes();
    } else {
      chatRooms = [];
      console.log('채팅방 데이터 파일이 없습니다. 빈 배열로 시작합니다.');
    }

    // 메시지 데이터 로드
    if (fs.existsSync(CHAT_MESSAGES_FILE)) {
      const messagesData = fs.readFileSync(CHAT_MESSAGES_FILE, 'utf8');
      chatMessages = JSON.parse(messagesData);
      console.log(`채팅 메시지 데이터 로드 완료: ${chatMessages.length}개`);
    } else {
      chatMessages = [];
      console.log('채팅 메시지 데이터 파일이 없습니다. 빈 배열로 시작합니다.');
    }

    // ID 카운터 설정
    if (chatRooms.length > 0) {
      nextRoomId = Math.max(...chatRooms.map(r => r.id)) + 1;
    }
    if (chatMessages.length > 0) {
      nextMessageId = Math.max(...chatMessages.map(m => m.id)) + 1;
    }
  } catch (error) {
    console.error('채팅 데이터 로드 실패:', error);
    chatRooms = [];
    chatMessages = [];
    nextRoomId = 1;
    nextMessageId = 1;
  }
}

// 파일에 데이터 저장
function saveToFile() {
  try {
    // 채팅방 데이터 저장
    const roomsData = JSON.stringify(chatRooms, null, 2);
    fs.writeFileSync(CHAT_ROOMS_FILE, roomsData, 'utf8');

    // 메시지 데이터 저장
    const messagesData = JSON.stringify(chatMessages, null, 2);
    fs.writeFileSync(CHAT_MESSAGES_FILE, messagesData, 'utf8');

    console.log('채팅 데이터 저장 완료');
  } catch (error) {
    console.error('채팅 데이터 저장 실패:', error);
  }
}

// 사용자의 채팅방 목록 조회 (페이지네이션 및 최적화)
const getChatRooms = (req, res) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50; // 기본 50개
    const maxLimit = 100; // 최대 100개로 제한
    const actualLimit = Math.min(limit, maxLimit);
    
    console.log(`사용자 ${userId}의 채팅방 목록 조회 요청 (페이지: ${page}, 제한: ${actualLimit})`);

    // 인덱스 기반 고속 검색 (수만 개 채팅방 대응)
    const userRooms = [];
    const startTime = Date.now();
    
    const userRoomIds = userRoomsIndex.get(userId) || [];
    for (const roomId of userRoomIds) {
      const room = chatRooms.find(r => r.id === roomId);
      if (room && room.isActive) {
        userRooms.push(room);
      }
    }

    // 최신 메시지 순으로 정렬 (성능 최적화)
    userRooms.sort((a, b) => {
      const aTime = a.lastMessage?.sentAt || a.createdAt;
      const bTime = b.lastMessage?.sentAt || b.createdAt;
      return new Date(bTime) - new Date(aTime);
    });

    // 페이지네이션 적용
    const startIndex = (page - 1) * actualLimit;
    const endIndex = startIndex + actualLimit;
    const paginatedRooms = userRooms.slice(startIndex, endIndex);
    
    const processingTime = Date.now() - startTime;
    console.log(`사용자 ${userId}의 채팅방 수: ${userRooms.length}개 (${processingTime}ms, 반환: ${paginatedRooms.length}개)`);

    res.json({
      success: true,
      data: paginatedRooms,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(userRooms.length / actualLimit),
        totalItems: userRooms.length,
        itemsPerPage: actualLimit,
        hasNextPage: endIndex < userRooms.length,
        hasPrevPage: page > 1
      }
    });
  } catch (error) {
    console.error('채팅방 목록 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '채팅방 목록 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 다이렉트 채팅방 생성 또는 조회
const createDirectChatRoom = (req, res) => {
  try {
    const { targetUserId, matchingId } = req.body;
    const userId = req.user.id;

    if (!targetUserId) {
      return res.status(400).json({
        success: false,
        message: '상대방 사용자 ID가 필요합니다.'
      });
    }

    if (targetUserId === userId) {
      return res.status(400).json({
        success: false,
        message: '자신과는 채팅방을 만들 수 없습니다.'
      });
    }

    console.log(`다이렉트 채팅방 생성 요청: ${userId} -> ${targetUserId} (매칭: ${matchingId})`);

    // 기존 다이렉트 채팅방이 있는지 확인 (매칭 ID 포함, 성능 최적화)
    let existingRoom = null;
    const startTime = Date.now();
    
    for (const room of chatRooms) {
      if (room.type === 'direct' &&
          room.isActive &&
          room.participants.length === 2 &&
          room.matchingId === matchingId &&
          room.participants.some(p => p.userId === userId) &&
          room.participants.some(p => p.userId === targetUserId)) {
        existingRoom = room;
        break;
      }
    }
    
    const searchTime = Date.now() - startTime;
    console.log(`🔍 채팅방 검색 완료: ${searchTime}ms (총 ${chatRooms.length}개 검색)`);
    
    // 대량 채팅방 처리를 위한 성능 모니터링
    if (chatRooms.length > 1000) {
      console.log(`⚠️ 대량 채팅방 감지: ${chatRooms.length}개 (검색 시간: ${searchTime}ms)`);
    }

    if (existingRoom) {
      console.log(`기존 채팅방 발견: ${existingRoom.id}`);
      return res.json({
        success: true,
        data: existingRoom
      });
    }

    // 새 채팅방 생성
    const newRoom = {
      id: nextRoomId++,
      type: 'direct',
      name: null,
      participants: [
        {
          userId: userId,
          joinedAt: new Date().toISOString(),
          lastReadAt: new Date().toISOString()
        },
        {
          userId: targetUserId,
          joinedAt: new Date().toISOString(),
          lastReadAt: new Date().toISOString()
        }
      ],
      lastMessage: null,
      isActive: true,
      matchingId: matchingId || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    chatRooms.push(newRoom);
    
    // 인덱스 업데이트 (새 채팅방 추가)
    for (const participant of newRoom.participants) {
      const participantUserId = participant.userId;
      if (!userRoomsIndex.has(participantUserId)) {
        userRoomsIndex.set(participantUserId, []);
      }
      userRoomsIndex.get(participantUserId).push(newRoom.id);
    }
    
    if (newRoom.matchingId) {
      if (!matchingRoomsIndex.has(newRoom.matchingId)) {
        matchingRoomsIndex.set(newRoom.matchingId, []);
      }
      matchingRoomsIndex.get(newRoom.matchingId).push(newRoom.id);
    }
    
    saveToFile();

    console.log(`새 채팅방 생성 완료: ${newRoom.id} (총 ${chatRooms.length}개)`);

    res.status(201).json({
      success: true,
      data: newRoom
    });
  } catch (error) {
    console.error('다이렉트 채팅방 생성 오류:', error);
    res.status(500).json({
      success: false,
      message: '채팅방 생성에 실패했습니다.',
      error: error.message
    });
  }
};

// 채팅 메시지 조회
const getChatMessages = (req, res) => {
  try {
    const { roomId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const userId = req.user.id;

    console.log(`채팅방 ${roomId}의 메시지 조회 요청 (페이지: ${page}, 제한: ${limit})`);

    // 채팅방 참여자 확인
    const chatRoom = chatRooms.find(room => 
      room.id == roomId && 
      room.isActive &&
      room.participants.some(p => p.userId === userId)
    );

    if (!chatRoom) {
      return res.status(404).json({
        success: false,
        message: '채팅방을 찾을 수 없거나 접근 권한이 없습니다.'
      });
    }

    // 해당 채팅방의 메시지 조회
    const roomMessages = chatMessages
      .filter(msg => msg.roomId == roomId)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    // 페이지네이션 적용
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedMessages = roomMessages.slice(startIndex, endIndex).reverse();

    console.log(`채팅방 ${roomId}의 메시지 수: ${paginatedMessages.length}개`);

    res.json({
      success: true,
      data: paginatedMessages,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: roomMessages.length,
        totalPages: Math.ceil(roomMessages.length / limit)
      }
    });
  } catch (error) {
    console.error('채팅 메시지 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '채팅 메시지 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 메시지 전송
const sendMessage = (req, res) => {
  try {
    const { roomId } = req.params;
    const { content, type = 'text', attachments } = req.body;
    const userId = req.user.id;

    if (!content && (!attachments || attachments.length === 0)) {
      return res.status(400).json({
        success: false,
        message: '메시지 내용 또는 첨부파일이 필요합니다.'
      });
    }

    console.log(`채팅방 ${roomId}에 메시지 전송 요청: ${content}`);

    // 채팅방 참여자 확인
    const chatRoom = chatRooms.find(room => 
      room.id == roomId && 
      room.isActive &&
      room.participants.some(p => p.userId === userId)
    );

    if (!chatRoom) {
      return res.status(404).json({
        success: false,
        message: '채팅방을 찾을 수 없거나 접근 권한이 없습니다.'
      });
    }

    // 새 메시지 생성
    const newMessage = {
      id: nextMessageId++,
      roomId: parseInt(roomId),
      senderId: userId,
      content: content,
      type: type,
      attachments: attachments || [],
      readBy: [{
        userId: userId,
        readAt: new Date().toISOString()
      }],
      isEdited: false,
      editedAt: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    chatMessages.push(newMessage);

    // 채팅방의 마지막 메시지 업데이트
    chatRoom.lastMessage = {
      content: content,
      senderId: userId,
      sentAt: new Date().toISOString()
    };
    chatRoom.updatedAt = new Date().toISOString();

    saveToFile();

    console.log(`메시지 전송 완료: ID ${newMessage.id}`);

    res.status(201).json({
      success: true,
      data: newMessage
    });
  } catch (error) {
    console.error('메시지 전송 오류:', error);
    res.status(500).json({
      success: false,
      message: '메시지 전송에 실패했습니다.',
      error: error.message
    });
  }
};

// 메시지 읽음 처리
const markMessagesAsRead = (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user.id;

    console.log(`채팅방 ${roomId}의 메시지 읽음 처리 요청`);

    // 채팅방 참여자 확인
    const chatRoom = chatRooms.find(room => 
      room.id == roomId && 
      room.isActive &&
      room.participants.some(p => p.userId === userId)
    );

    if (!chatRoom) {
      return res.status(404).json({
        success: false,
        message: '채팅방을 찾을 수 없거나 접근 권한이 없습니다.'
      });
    }

    // 참여자의 마지막 읽은 시간 업데이트
    const participant = chatRoom.participants.find(p => p.userId === userId);
    if (participant) {
      participant.lastReadAt = new Date().toISOString();
      chatRoom.updatedAt = new Date().toISOString();
      saveToFile();
    }

    console.log(`메시지 읽음 처리 완료: 사용자 ${userId}`);

    res.json({
      success: true,
      message: '메시지가 읽음으로 표시되었습니다.'
    });
  } catch (error) {
    console.error('메시지 읽음 처리 오류:', error);
    res.status(500).json({
      success: false,
      message: '메시지 읽음 처리에 실패했습니다.',
      error: error.message
    });
  }
};

// 채팅방 나가기
const leaveChatRoom = (req, res) => {
  try {
    const { roomId } = req.params;
    const userId = req.user.id;

    console.log(`채팅방 ${roomId} 나가기 요청`);

    const chatRoom = chatRooms.find(room => 
      room.id == roomId && 
      room.isActive &&
      room.participants.some(p => p.userId === userId)
    );

    if (!chatRoom) {
      return res.status(404).json({
        success: false,
        message: '채팅방을 찾을 수 없거나 접근 권한이 없습니다.'
      });
    }

    // 참여자 목록에서 제거
    chatRoom.participants = chatRoom.participants.filter(p => p.userId !== userId);

    // 참여자가 없으면 채팅방 비활성화
    if (chatRoom.participants.length === 0) {
      chatRoom.isActive = false;
    }

    chatRoom.updatedAt = new Date().toISOString();
    saveToFile();

    console.log(`채팅방 나가기 완료: 사용자 ${userId}`);

    res.json({
      success: true,
      message: '채팅방에서 나갔습니다.'
    });
  } catch (error) {
    console.error('채팅방 나가기 오류:', error);
    res.status(500).json({
      success: false,
      message: '채팅방 나가기에 실패했습니다.',
      error: error.message
    });
  }
};

// Socket.IO에서 채팅방 추가 (외부에서 호출)
const addChatRoomToMemory = (roomData) => {
  try {
    // 기존 채팅방 확인
    const existingRoom = chatRooms.find(room => room.id === roomData.id);
    if (existingRoom) {
      console.log(`기존 채팅방 발견: ${roomData.id}`);
      return existingRoom;
    }
    
    // 새 채팅방 추가
    chatRooms.push(roomData);
    saveToFile();
    
    console.log(`💾 메모리에 채팅방 추가: ${roomData.id} (${roomData.participants.map(p => p.userId).join(' ↔ ')})`);
    return roomData;
  } catch (error) {
    console.error('메모리에 채팅방 추가 실패:', error);
    return null;
  }
};

// 서버 시작 시 데이터 로드
loadFromFile();

module.exports = {
  getChatRooms,
  createDirectChatRoom,
  getChatMessages,
  sendMessage,
  markMessagesAsRead,
  leaveChatRoom,
  loadFromFile,
  saveToFile,
  addChatRoomToMemory
};
