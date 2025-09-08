const asyncHandler = require('express-async-handler');
const ChatRoom = require('../models/ChatRoom');
const ChatMessage = require('../models/ChatMessage');

// @desc    Get user's chat rooms
// @route   GET /api/chat/rooms
// @access  Private
const getChatRooms = asyncHandler(async (req, res) => {
  const chatRooms = await ChatRoom.find({
    'participants.user': req.user.id,
    isActive: true
  })
    .populate('participants.user', 'nickname profileImage')
    .populate('lastMessage.sender', 'nickname')
    .sort({ 'lastMessage.sentAt': -1 });
  
  res.json({
    success: true,
    data: chatRooms
  });
});

// @desc    Create or get direct chat room
// @route   POST /api/chat/rooms/direct
// @access  Private
const createDirectChatRoom = asyncHandler(async (req, res) => {
  const { targetUserId } = req.body;
  
  if (!targetUserId) {
    res.status(400);
    throw new Error('Target user ID is required');
  }
  
  if (targetUserId === req.user.id) {
    res.status(400);
    throw new Error('Cannot create chat room with yourself');
  }
  
  // 기존 다이렉트 채팅방이 있는지 확인
  let chatRoom = await ChatRoom.findOne({
    type: 'direct',
    'participants.user': { $all: [req.user.id, targetUserId] },
    isActive: true
  }).populate('participants.user', 'nickname profileImage');
  
  if (!chatRoom) {
    // 새 채팅방 생성
    chatRoom = await ChatRoom.create({
      type: 'direct',
      participants: [
        { user: req.user.id },
        { user: targetUserId }
      ]
    });
    
    chatRoom = await ChatRoom.findById(chatRoom._id)
      .populate('participants.user', 'nickname profileImage');
  }
  
  res.json({
    success: true,
    data: chatRoom
  });
});

// @desc    Get chat messages
// @route   GET /api/chat/rooms/:roomId/messages
// @access  Private
const getChatMessages = asyncHandler(async (req, res) => {
  const { roomId } = req.params;
  const { page = 1, limit = 50 } = req.query;
  
  // 채팅방 참여자 확인
  const chatRoom = await ChatRoom.findOne({
    _id: roomId,
    'participants.user': req.user.id,
    isActive: true
  });
  
  if (!chatRoom) {
    res.status(404);
    throw new Error('Chat room not found or access denied');
  }
  
  const messages = await ChatMessage.find({ room: roomId })
    .populate('sender', 'nickname profileImage')
    .populate('readBy.user', 'nickname')
    .sort({ createdAt: -1 })
    .limit(limit * 1)
    .skip((page - 1) * limit);
  
  res.json({
    success: true,
    data: messages.reverse() // 최신 메시지가 아래로 오도록
  });
});

// @desc    Send message
// @route   POST /api/chat/rooms/:roomId/messages
// @access  Private
const sendMessage = asyncHandler(async (req, res) => {
  const { roomId } = req.params;
  const { content, type = 'text', attachments } = req.body;
  
  if (!content && (!attachments || attachments.length === 0)) {
    res.status(400);
    throw new Error('Message content or attachments is required');
  }
  
  // 채팅방 참여자 확인
  const chatRoom = await ChatRoom.findOne({
    _id: roomId,
    'participants.user': req.user.id,
    isActive: true
  });
  
  if (!chatRoom) {
    res.status(404);
    throw new Error('Chat room not found or access denied');
  }
  
  // 메시지 생성
  const message = await ChatMessage.create({
    room: roomId,
    sender: req.user.id,
    content,
    type,
    attachments
  });
  
  // 채팅방의 마지막 메시지 업데이트
  chatRoom.lastMessage = {
    content,
    sender: req.user.id,
    sentAt: message.createdAt
  };
  
  await chatRoom.save();
  
  const populatedMessage = await ChatMessage.findById(message._id)
    .populate('sender', 'nickname profileImage');
  
  res.status(201).json({
    success: true,
    data: populatedMessage
  });
});

// @desc    Mark messages as read
// @route   PUT /api/chat/rooms/:roomId/read
// @access  Private
const markMessagesAsRead = asyncHandler(async (req, res) => {
  const { roomId } = req.params;
  
  // 채팅방 참여자 확인
  const chatRoom = await ChatRoom.findOne({
    _id: roomId,
    'participants.user': req.user.id,
    isActive: true
  });
  
  if (!chatRoom) {
    res.status(404);
    throw new Error('Chat room not found or access denied');
  }
  
  // 해당 사용자의 마지막 읽은 시간 업데이트
  const participant = chatRoom.participants.find(
    p => p.user.toString() === req.user.id
  );
  
  if (participant) {
    participant.lastReadAt = new Date();
    await chatRoom.save();
  }
  
  res.json({
    success: true,
    message: 'Messages marked as read'
  });
});

// @desc    Leave chat room
// @route   DELETE /api/chat/rooms/:roomId/leave
// @access  Private
const leaveChatRoom = asyncHandler(async (req, res) => {
  const { roomId } = req.params;
  
  const chatRoom = await ChatRoom.findOne({
    _id: roomId,
    'participants.user': req.user.id,
    isActive: true
  });
  
  if (!chatRoom) {
    res.status(404);
    throw new Error('Chat room not found or access denied');
  }
  
  // 참여자 목록에서 제거
  chatRoom.participants = chatRoom.participants.filter(
    p => p.user.toString() !== req.user.id
  );
  
  // 참여자가 없으면 채팅방 비활성화
  if (chatRoom.participants.length === 0) {
    chatRoom.isActive = false;
  }
  
  await chatRoom.save();
  
  res.json({
    success: true,
    message: 'Successfully left chat room'
  });
});

module.exports = {
  getChatRooms,
  createDirectChatRoom,
  getChatMessages,
  sendMessage,
  markMessagesAsRead,
  leaveChatRoom
};