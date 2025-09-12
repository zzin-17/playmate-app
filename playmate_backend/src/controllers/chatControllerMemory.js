const fs = require('fs');
const path = require('path');

// 채팅 데이터 파일 경로
const CHAT_ROOMS_FILE = path.join(__dirname, '../data/chat_rooms.json');
const CHAT_MESSAGES_FILE = path.join(__dirname, '../data/chat_messages.json');

// 메모리 스토어
let chatRooms = [];
let chatMessages = [];
let nextRoomId = 1;
let nextMessageId = 1;

// 파일에서 데이터 로드
function loadFromFile() {
  try {
    // 채팅방 데이터 로드
    if (fs.existsSync(CHAT_ROOMS_FILE)) {
      const roomsData = fs.readFileSync(CHAT_ROOMS_FILE, 'utf8');
      chatRooms = JSON.parse(roomsData);
      console.log(`채팅방 데이터 로드 완료: ${chatRooms.length}개`);
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

// 사용자의 채팅방 목록 조회
const getChatRooms = (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`사용자 ${userId}의 채팅방 목록 조회 요청`);

    // 사용자가 참여한 활성 채팅방 조회
    const userRooms = chatRooms.filter(room => 
      room.isActive && 
      room.participants.some(p => p.userId === userId)
    );

    // 최신 메시지 순으로 정렬
    userRooms.sort((a, b) => {
      const aLastMessage = a.lastMessage?.sentAt || a.createdAt;
      const bLastMessage = b.lastMessage?.sentAt || b.createdAt;
      return new Date(bLastMessage) - new Date(aLastMessage);
    });

    console.log(`사용자 ${userId}의 채팅방 수: ${userRooms.length}개`);

    res.json({
      success: true,
      data: userRooms
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

    console.log(`다이렉트 채팅방 생성 요청: ${userId} -> ${targetUserId}`);

    // 기존 다이렉트 채팅방이 있는지 확인
    let existingRoom = chatRooms.find(room => 
      room.type === 'direct' &&
      room.isActive &&
      room.participants.length === 2 &&
      room.participants.some(p => p.userId === userId) &&
      room.participants.some(p => p.userId === targetUserId)
    );

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
    saveToFile();

    console.log(`새 채팅방 생성 완료: ${newRoom.id}`);

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
  saveToFile
};
