const socketIo = require('socket.io');
const path = require('path');
const fs = require('fs');
const { addChatRoomToMemory } = require('../controllers/chatControllerMemory');

let io;

// 채팅방 데이터 파일 경로
const CHAT_ROOMS_FILE = path.join(__dirname, '../data/chat_rooms.json');

// 채팅방 자동 생성 함수
const ensureChatRoomExists = async (roomId, senderId, targetUserId) => {
  try {
    // 채팅방 데이터 로드
    let chatRooms = [];
    if (fs.existsSync(CHAT_ROOMS_FILE)) {
      const data = fs.readFileSync(CHAT_ROOMS_FILE, 'utf8');
      chatRooms = JSON.parse(data);
    }
    
    // 기존 채팅방 확인
    const existingRoom = chatRooms.find(room => 
      room.id == roomId || 
      (room.participants.some(p => p.userId == senderId) && 
       room.participants.some(p => p.userId == targetUserId))
    );
    
    // 자기 자신과의 채팅 방지 (ID가 같더라도 이메일이 다르면 허용)
    // 실제 사용자 정보를 확인해야 하지만, 현재는 ID만 체크
    console.log(`📧 채팅 참여자: 발신자=${senderId}, 대상자=${targetUserId}`);
    
    if (!existingRoom) {
      // 새 채팅방 생성 (roomId를 matchingId로 사용)
      const newRoom = {
        id: Date.now(), // 고유한 채팅방 ID 생성
        type: 'direct',
        name: null,
        participants: [
          {
            userId: senderId,
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
        matchingId: parseInt(roomId), // roomId가 실제 매칭 ID
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };
      
      chatRooms.push(newRoom);
      
      // 파일에 저장
      const dir = path.dirname(CHAT_ROOMS_FILE);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(CHAT_ROOMS_FILE, JSON.stringify(chatRooms, null, 2));
      
      // 메모리 컨트롤러에도 추가 (API 조회에서 보이도록)
      addChatRoomToMemory(newRoom);
      
      console.log(`🏠 채팅방 자동 생성: ${roomId} (${senderId} ↔ ${targetUserId})`);
    }
  } catch (error) {
    console.error('채팅방 자동 생성 실패:', error);
  }
};

const initSocket = (httpServer) => {
  try {
    console.log('🔄 Socket.IO 초기화 중...');
    
    io = socketIo(httpServer, {
      cors: {
        origin: ['http://localhost:3000', 'http://10.0.2.2:3000', 'http://127.0.0.1:3000', 'http://192.168.6.100:3000'],
        methods: ["GET", "POST"],
        credentials: true
      },
      transports: ['websocket', 'polling'], // 폴링도 지원
      pingTimeout: 60000,
      pingInterval: 25000
    });

    io.on('connection', (socket) => {
      console.log(`🔌 User connected: ${socket.id}`);

      // 사용자 ID와 소켓 연결
      socket.on('join', (userId) => {
        socket.join(`user_${userId}`);
        console.log(`👤 User ${userId} joined their room`);
      });

      // 채팅방 참여
      socket.on('join_room', (roomId) => {
        socket.join(`room_${roomId}`);
        console.log(`🏠 User ${socket.id} joined room ${roomId}`);
      });

      // 채팅방 떠나기
      socket.on('leave_room', (roomId) => {
        socket.leave(`room_${roomId}`);
        console.log(`🚪 User ${socket.id} left room ${roomId}`);
      });

      // 메시지 전송 (채팅방 자동 생성 포함)
      socket.on('send_message', async (data) => {
        try {
          const { roomId, message, sender, targetUserId } = data;
          
          // 채팅방 자동 생성 (없는 경우)
          await ensureChatRoomExists(roomId, sender.id, targetUserId);
          
          // 메시지를 다른 참여자에게 전송
          socket.to(`room_${roomId}`).emit('receive_message', {
            roomId,
            message,
            sender,
            timestamp: new Date()
          });
          
          console.log(`메시지 전송 완료: ${sender.nickname} -> 방 ${roomId}`);
        } catch (error) {
          console.error('메시지 전송 오류:', error);
          socket.emit('message_error', { error: error.message });
        }
      });

      // 연결 해제
      socket.on('disconnect', () => {
        console.log(`🔌 User disconnected: ${socket.id}`);
      });
    });

    console.log('✅ Socket.IO 초기화 완료');
    return io;
  } catch (error) {
    console.error('❌ Socket.IO 초기화 실패:', error);
    throw error;
  }
};

const getIo = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
};

module.exports = { initSocket, getIo };