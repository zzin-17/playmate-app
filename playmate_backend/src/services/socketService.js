const socketIo = require('socket.io');

let io;

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

      // 메시지 전송
      socket.on('send_message', (data) => {
        const { roomId, message, sender } = data;
        socket.to(`room_${roomId}`).emit('receive_message', {
          roomId,
          message,
          sender,
          timestamp: new Date()
        });
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