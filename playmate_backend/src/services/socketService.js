const socketIo = require('socket.io');

let io;

const initSocket = (httpServer) => {
  io = socketIo(httpServer, {
    cors: {
      origin: process.env.CORS_ORIGIN || "*",
      methods: ["GET", "POST"]
    }
  });

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    // 사용자 ID와 소켓 연결
    socket.on('join', (userId) => {
      socket.join(`user_${userId}`);
      console.log(`User ${userId} joined their room`);
    });

    // 채팅방 참여
    socket.on('join_room', (roomId) => {
      socket.join(`room_${roomId}`);
      console.log(`User ${socket.id} joined room ${roomId}`);
    });

    // 채팅방 떠나기
    socket.on('leave_room', (roomId) => {
      socket.leave(`room_${roomId}`);
      console.log(`User ${socket.id} left room ${roomId}`);
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
      console.log(`User disconnected: ${socket.id}`);
    });
  });

  return io;
};

const getIo = () => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
};

module.exports = { initSocket, getIo };