import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/matching.dart';
import '../../models/chat_message.dart';
import '../../models/user.dart';
import '../../models/chat_room.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

import '../review/review_list_screen.dart';
import '../../services/notification_service.dart';
import '../../services/websocket_service.dart';
import '../../services/matching_state_service.dart';
import '../../services/matching_notification_service.dart';
import '../../services/chat_service.dart';
import '../../services/chat_local_store.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../services/chat_event_bus.dart';

class ChatScreen extends StatefulWidget {
  final Matching matching;
  final User currentUser;
  final User? chatPartner; // 채팅 상대방 정보 추가

  const ChatScreen({
    super.key,
    required this.matching,
    required this.currentUser,
    this.chatPartner, // 선택적 매개변수
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ChatLocalStore _localStore = ChatLocalStore();
  bool _isLoading = false;
  bool _isHost = false;
  bool _hasApplied = false;
  bool _isMatchingConfirmed = false;
  
  // WebSocket 관련 상태
  bool _isWebSocketConnected = false;
  String _connectionStatus = '연결 중...';

  @override
  void initState() {
    super.initState();
    _isHost = widget.currentUser.id == widget.matching.host.id;
    _loadInitialMessages();
    _checkAndConnectWebSocket();
    
    // 매칭 상태 서비스 초기화 및 리스너 등록
    final stateService = MatchingStateService();
    stateService.initializeMatchingState(widget.matching.id, widget.matching.status);
    stateService.addStateChangeListener(widget.matching.id, _onMatchingStateChanged);
    
    // 채팅 화면 진입시 백엔드에 채팅방 존재 확인/생성 요청
    _ensureChatRoomExists();
    
    // 채팅 화면이 활성화될 때 읽지 않은 메시지들을 읽음 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  // WebSocket 연결 상태 확인 및 연결
  void _checkAndConnectWebSocket() {
    // 현재 화면의 매칭으로 항상 연결 시도 (다른 매칭에 연결돼 있었다면 내부에서 안전하게 재연결)
    _connectWebSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // WebSocket 연결은 유지 (다른 화면에서도 사용)
    super.dispose();
  }

  void _loadInitialMessages() {
    // 로컬 저장된 메시지 우선 로드 (오프라인/서버지연 대비)
    _localStore.loadMessages(widget.matching.id).then((msgs) {
      if (msgs.isNotEmpty && mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(msgs);
        });
      }
    });
  }

  /// 채팅방 존재 확인 및 생성
  Future<void> _ensureChatRoomExists() async {
    try {
      final chatService = ChatService();
      final partner = _isHost 
          ? (widget.chatPartner ?? widget.matching.guests?.first)
          : widget.matching.host;
      
      if (partner != null) {
        // 백엔드에 채팅방 생성 요청 (이미 있으면 무시됨)
        await chatService.createChatRoom(
          widget.matching.id, 
          widget.matching.host, 
          partner
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('채팅방 생성 확인 실패: $e');
      }
    }
  }

  // WebSocket 연결
  void _connectWebSocket() {
    try {
      final wsService = WebSocketService.instance;
      
      print('플메 Socket.io 연결 시작...');
      
      // 연결 상태 리스너
      wsService.statusStream.listen((status) {
        print('플메 연결 상태 변경: $status');
        setState(() {
          switch (status) {
            case 'connected':
              _isWebSocketConnected = true;
              _connectionStatus = '연결됨';
              print('플메 UI 상태 업데이트: 연결됨');
              break;
            case 'disconnected':
              _isWebSocketConnected = false;
              _connectionStatus = '연결 끊김';
              print('플메 UI 상태 업데이트: 연결 끊김');
              break;
            case 'error':
              _isWebSocketConnected = false;
              _connectionStatus = '연결 오류';
              print('플메 UI 상태 업데이트: 연결 오류');
              break;
          }
        });
      });
      
      // 메시지 리스너
      wsService.messageStream.listen((message) {
        print('플메 메시지 수신: ${message.message}');
        setState(() {
          _messages.add(message);
        });
        
        // 스크롤을 맨 아래로
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
      
      // 플메 Socket.io 연결
      wsService.connect(widget.matching.id.toString(), widget.currentUser.id.toString());
      
      // 연결 상태 수동 확인 (3초 후)
      Future.delayed(const Duration(seconds: 3), () {
        if (wsService.isConnected) {
          print('플메 수동 연결 상태 확인: 연결됨');
          setState(() {
            _isWebSocketConnected = true;
            _connectionStatus = '연결됨';
          });
        } else {
          print('플메 수동 연결 상태 확인: 연결 안됨');
          setState(() {
            _isWebSocketConnected = false;
            _connectionStatus = '연결 실패';
          });
        }
      });
      
    } catch (e) {
      print('플메 Socket.io 연결 실패: $e');
      setState(() {
        _isWebSocketConnected = false;
        _connectionStatus = '연결 실패';
      });
    }
  }
  
  // WebSocket 연결 해제
  void _disconnectWebSocket() {
    try {
      WebSocketService.instance.disconnect();
    } catch (e) {
      print('WebSocket 연결 해제 실패: $e');
    }
  }

  // 연결 상태 표시 위젯 (연결이 정상이면 숨김)
  Widget _buildConnectionStatus() {
    // 연결이 정상이면 표시하지 않음
    if (_isWebSocketConnected) {
      return const SizedBox.shrink();
    }
    
    // 연결에 문제가 있을 때만 표시
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            _connectionStatus,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _checkAndConnectWebSocket,
            child: Text(
              '재연결',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// 매칭 확정 알림 전송
  void _sendMatchingConfirmedNotification() {
    try {
      // 게스트들에게 매칭 확정 알림
      if (widget.matching.guests != null) {
        for (final guest in widget.matching.guests!) {
          NotificationService().showMatchingConfirmedNotification(
            hostName: widget.matching.host.nickname,
            courtName: widget.matching.courtName,
            date: _formatDate(widget.matching.date),
            matchingId: widget.matching.id,
          );
        }
      }
      
      // 목업 데이터가 있는 경우에도 알림
      if (widget.matching.guests == null || widget.matching.guests!.isEmpty) {
        NotificationService().showMatchingConfirmedNotification(
          hostName: widget.matching.host.nickname,
          courtName: widget.matching.courtName,
          date: _formatDate(widget.matching.date),
          matchingId: widget.matching.id,
        );
      }
    } catch (e) {
      print('매칭 확정 알림 전송 실패: $e');
    }
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  Future<void> _writeReview() async {
    // 채팅 상대방 찾기
    User? chatPartner;
    
    if (_isHost) {
      // 호스트인 경우: 게스트 중 하나를 채팅 상대방으로 설정
      if (widget.matching.guests != null && widget.matching.guests!.isNotEmpty) {
        chatPartner = widget.matching.guests!.first;
      } else {
        // 목업 데이터 사용
        chatPartner = User(
          id: 999,
          email: 'test@example.com',
          nickname: '테니스러버',
          birthYear: 1990,
          gender: 'male',
          skillLevel: 3,
          region: '서울',
          preferredCourt: '잠실종합운동장',
          preferredTime: ['오후', '저녁'],
          playStyle: '공격적',
          hasLesson: false,
          mannerScore: 4.5,
          startYearMonth: '2020-03',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } else {
      // 게스트인 경우: 호스트를 채팅 상대방으로 설정
      chatPartner = widget.matching.host;
    }
    
    // 후기 목록 화면으로 이동 (채팅 상대방 정보 포함)
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewListScreen(
          targetUser: chatPartner,
          reviews: [], // TODO: 실제 리뷰 데이터 가져오기
        ),
      ),
    );
  }

  List<User> _getParticipants() {
    // 매칭 참여자 목록 반환 (현재 사용자 제외)
    final participants = <User>[];
    
    // 호스트가 현재 사용자가 아닌 경우 호스트 추가
    if (widget.matching.host.id != widget.currentUser.id) {
      participants.add(widget.matching.host);
    }
    
    // 게스트 목록 추가 (null 체크 포함)
    if (widget.matching.guests != null) {
      for (final guest in widget.matching.guests!) {
        if (guest.id != widget.currentUser.id) {
          participants.add(guest);
        }
      }
    }
    
    // 목업 데이터: 실제 게스트가 없을 때 테스트용
    if (participants.isEmpty && widget.matching.host.id != widget.currentUser.id) {
      // 테스트용 더미 게스트 추가
      participants.add(User(
        id: 999,
        email: 'test@example.com',
        nickname: '테니스러버',
        birthYear: 1990,
        gender: 'male',
        skillLevel: 3,
        region: '서울',
        preferredCourt: '잠실종합운동장',
        preferredTime: ['오후', '저녁'],
        playStyle: '공격적',
        hasLesson: false,
        mannerScore: 4.5,
        startYearMonth: '2020-03',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    return participants;
  }

  @override
  Widget build(BuildContext context) {
    // 로그인 가드: currentUser가 없으면 로그인 유도
    if (widget.currentUser.id == 0) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.matching.courtName,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.matching.formattedDate} ${widget.matching.timeSlot}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showMatchingInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // WebSocket 연결 상태 표시
          _buildConnectionStatus(),
          
          // 매칭 상태 표시
          _buildMatchingStatus(),
          
          // 채팅 메시지 목록
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageItem(message);
                    },
                  ),
          ),
          
          // 메시지 입력 영역
          _buildMessageInput(),

        ],
      ),
    );
  }

  Widget _buildMatchingStatus() {
    if (!_isHost) {
      return const SizedBox.shrink();
    }

    // 매칭 상태에 따라 버튼 표시 결정
    final isConfirmed = widget.matching.status == 'confirmed' || _isMatchingConfirmed;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isConfirmed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '현재 매칭진행중입니다. 약속 후 매칭 확정해주세요',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                                  child: ElevatedButton(
                  onPressed: _confirmMatching,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '매칭확정',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ],
            ),
          ] else ...[
            // 확정 취소 버튼을 먼저 표시
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: '확정 취소',
                    icon: Icons.cancel,
                    type: ButtonType.secondary,
                    onPressed: _cancelMatchingConfirmation,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: '후기 작성',
                    icon: Icons.rate_review,
                    type: ButtonType.primary,
                    onPressed: _writeReview,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 확정 완료 메시지를 버튼 아래에 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '매칭이 확정되었습니다!',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 메시지가 없습니다',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 메시지를 보내보세요!',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isMyMessage = message.senderId == widget.currentUser.id;
    final isSystemMessage = message.messageType == 'system';

    if (isSystemMessage) {
      return _buildSystemMessage(message);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: Text(
                message.senderName.substring(0, 1),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMyMessage ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isMyMessage ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isMyMessage ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: !isMyMessage ? Border.all(color: AppColors.cardBorder) : null,
                  ),
                  child: _buildMessageContent(message),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isMyMessage) ...[
                      const SizedBox(width: 8),
                      _buildMessageStatus(message),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                message.senderName.substring(0, 1),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 메시지 내용 표시 (텍스트, 이미지, 위치 등)
  Widget _buildMessageContent(ChatMessage message) {
    switch (message.messageType) {
      case 'image':
        return _buildImageMessage(message);
      case 'location':
        return _buildLocationMessage(message);
      case 'file':
        return _buildFileMessage(message);
      default:
        return Text(
          message.message,
          style: AppTextStyles.body.copyWith(
            color: message.senderId == widget.currentUser.id 
                ? AppColors.surface 
                : AppColors.textPrimary,
          ),
        );
    }
  }

  // 이미지 메시지 표시
  Widget _buildImageMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null)
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(message.imageUrl!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.background,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          message.message,
          style: AppTextStyles.body.copyWith(
            color: message.senderId == widget.currentUser.id 
                ? AppColors.surface 
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // 위치 메시지 표시
  Widget _buildLocationMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: AppColors.background,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.locationName ?? '위치',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (message.latitude != null && message.longitude != null)
                    Text(
                      '${message.latitude!.toStringAsFixed(4)}, ${message.longitude!.toStringAsFixed(4)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message.message,
          style: AppTextStyles.body.copyWith(
            color: message.senderId == widget.currentUser.id 
                ? AppColors.surface 
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // 파일 메시지 표시
  Widget _buildFileMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
            color: AppColors.background,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.attach_file,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.message.replaceAll('를 공유했습니다.', ''),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message.message,
          style: AppTextStyles.body.copyWith(
            color: message.senderId == widget.currentUser.id 
                ? AppColors.surface 
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // 메시지 상태 표시 (읽음 확인)
  Widget _buildMessageStatus(ChatMessage message) {
    switch (message.status) {
      case 'sent':
        return Icon(
          Icons.check,
          size: 12,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        );
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 12,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        );
      case 'read':
        return Icon(
          Icons.done_all,
          size: 12,
          color: AppColors.primary,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // 참여자 온라인 상태 표시 (1:1 채팅에서는 불필요하므로 제거)
  Widget _buildParticipantsStatus() {
    // 1:1 채팅에서는 참여자 목록이 불필요하므로 숨김
    return const SizedBox.shrink();
    
    /*
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참여자',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // 호스트
              _buildParticipantStatus(
                widget.matching.host,
                isOnline: _isWebSocketConnected,
                isHost: true,
              ),
              const SizedBox(width: 16),
              // 게스트들
              if (widget.matching.guests != null)
                ...widget.matching.guests!.map((guest) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildParticipantStatus(
                      guest,
                      isOnline: _isWebSocketConnected,
                      isHost: false,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    */
  }

  // 개별 참여자 상태 표시
  Widget _buildParticipantStatus(User user, {required bool isOnline, required bool isHost}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                user.nickname.substring(0, 1),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 온라인 상태 표시
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.textSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.nickname,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              isHost ? '호스트' : '게스트',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            message.message,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          // 이미지 첨부 버튼
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.image, color: AppColors.textPrimary),
              tooltip: '이미지 첨부',
              onSelected: (value) {
                if (_isLoading) return;
                switch (value) {
                  case 'gallery':
                    _pickImage(ImageSource.gallery);
                    break;
                  case 'camera':
                    _pickImage(ImageSource.camera);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'gallery',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, size: 20),
                      SizedBox(width: 8),
                      Text('갤러리에서 선택'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'camera',
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, size: 20),
                      SizedBox(width: 8),
                      Text('카메라로 촬영'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 위치 공유 버튼
          Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed: _isLoading ? null : _shareLocation,
              tooltip: '위치 공유',
            ),
          ),
          const SizedBox(width: 8),
          // 파일 첨부 버튼
          Container(
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.white),
              onPressed: _isLoading ? null : _pickFile,
              tooltip: '파일 첨부',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppTextField(
              controller: _messageController,
              hint: '메시지를 입력하세요...',
              maxLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // 새 메시지 추가 (초기 상태: sent)
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      matchingId: widget.matching.id,
      senderId: widget.currentUser.id,
      senderName: widget.currentUser.nickname,
      message: message,
      createdAt: DateTime.now(),
      status: 'sent',
    );

    setState(() {
      _messages.add(newMessage);
      _isLoading = false;
    });

    _messageController.clear();
    _scrollToBottom();

    // WebSocket을 통해 메시지 전송
    _sendMessageViaWebSocket(newMessage);
  }

  // WebSocket을 통한 메시지 전송 및 상태 업데이트
  Future<void> _sendMessageViaWebSocket(ChatMessage message) async {
    try {
      // WebSocket으로 메시지 전송
      await WebSocketService.instance.sendMessage(message);
      
      // 전송 성공시 채팅방을 활성 목록에 추가 (실제 메시지가 오간 방으로 등록)
      final partner = _isHost 
          ? (widget.chatPartner ?? User(id: 999, email: 'unknown@example.com', nickname: '상대방', createdAt: DateTime.now(), updatedAt: DateTime.now()))
          : widget.matching.host;
      
      final chatRoom = ChatRoom(
        matchingId: widget.matching.id,
        courtName: widget.matching.courtName,
        date: widget.matching.date,
        timeSlot: widget.matching.timeSlot,
        myRole: _isHost ? 'host' : 'guest',
        partner: partner,
        lastMessageAt: DateTime.now(),
        unreadCount: 0,
        status: widget.matching.status,
      );
      
      ChatService.addActiveChatRoom(chatRoom);
      // 로컬 방 목록/메시지 저장
      await _localStore.upsertRoom(widget.currentUser.id, chatRoom);
      await _localStore.appendMessage(message);
      
      // 전송 성공 시 상태를 'delivered'로 업데이트
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = message.copyWith(
            status: 'delivered',
            deliveredAt: DateTime.now(),
          );
        }
      });
      
    } catch (e) {
      print('WebSocket 메시지 전송 실패: $e');
      // 전송 실패 시 상태를 'sent'로 유지
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 이미지 선택
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        // 이미지 메시지 생성 및 전송
        await _sendImageMessage(image);
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 이미지 메시지 전송
  Future<void> _sendImageMessage(XFile imageFile) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 이미지 메시지 생성
      final imageMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        matchingId: widget.matching.id,
        senderId: widget.currentUser.id,
        senderName: widget.currentUser.nickname,
        message: '이미지를 공유했습니다.',
        messageType: 'image',
        imageUrl: imageFile.path, // 실제로는 서버에 업로드 후 URL 사용
        createdAt: DateTime.now(),
        status: 'sent',
      );

      setState(() {
        _messages.add(imageMessage);
        _isLoading = false;
      });

      _scrollToBottom();

      // WebSocket을 통해 이미지 메시지 전송
      _sendMessageViaWebSocket(imageMessage);

    } catch (e) {
      print('이미지 메시지 생성 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 파일 선택
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        await _sendFileMessage(file);
      }
    } catch (e) {
      print('파일 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('파일 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 파일 메시지 전송
  Future<void> _sendFileMessage(PlatformFile file) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 파일 메시지 생성
      final fileMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        matchingId: widget.matching.id,
        senderId: widget.currentUser.id,
        senderName: widget.currentUser.nickname,
        message: '${file.name}를 공유했습니다.',
        messageType: 'file',
        fileUrl: file.path, // 실제로는 서버에 업로드 후 URL 사용
        createdAt: DateTime.now(),
        status: 'sent',
      );

      setState(() {
        _messages.add(fileMessage);
        _isLoading = false;
      });

      _scrollToBottom();

      // WebSocket을 통해 파일 메시지 전송
      _sendMessageViaWebSocket(fileMessage);

    } catch (e) {
      print('파일 메시지 생성 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 위치 공유
  Future<void> _shareLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 현재 위치 가져오기 (실제로는 geolocator 패키지 사용)
      // 여기서는 임시로 매칭 코트 위치 사용
      final locationMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        matchingId: widget.matching.id,
        senderId: widget.currentUser.id,
        senderName: widget.currentUser.nickname,
        message: '위치를 공유했습니다.',
        messageType: 'location',
        latitude: widget.matching.courtLat,
        longitude: widget.matching.courtLng,
        locationName: widget.matching.courtName,
        createdAt: DateTime.now(),
        status: 'sent',
      );

      setState(() {
        _messages.add(locationMessage);
        _isLoading = false;
      });

      _scrollToBottom();

      // WebSocket을 통해 위치 메시지 전송
      _sendMessageViaWebSocket(locationMessage);

    } catch (e) {
      print('위치 공유 오류: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('위치 공유 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showMatchingInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '매칭 정보',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('코트', widget.matching.courtName),
            _buildInfoRow('날짜', widget.matching.formattedDate),
            _buildInfoRow('시간', widget.matching.timeSlot),
            _buildInfoRow('구력', widget.matching.skillRangeText),
            _buildInfoRow('게임유형', widget.matching.gameTypeText),
            _buildInfoRow('모집인원', widget.matching.recruitCountText),
            if (widget.matching.message != null && widget.matching.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '호스트 메시지',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.matching.message!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  String _getGenderText(String gender) {
    switch (gender) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      case 'any':
        return '성별 무관';
      default:
        return '알 수 없음';
    }
  }

  // 매칭 확정 버튼 위젯
  Widget _buildMatchingConfirmationButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              onPressed: _confirmMatching,
              text: '매칭 확정',
              type: ButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }

  // 매칭 확정 함수
  void _confirmMatching() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('매칭 확정'),
          content: const Text('정말로 이 매칭을 확정하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processMatchingConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('확정'),
            ),
          ],
        );
      },
    );
  }

  // 매칭 확정 처리
  void _processMatchingConfirmation() async {
    final stateService = MatchingStateService();
    final success = await stateService.confirmMatching(widget.matching.id);
    
    if (success) {
      setState(() {
        _isMatchingConfirmed = true;
      });

      // 시스템 메시지 추가
      _messages.add(
        ChatMessage.systemMessage(
          matchingId: widget.matching.id,
          message: '${widget.matching.host.nickname}님이 매칭을 확정했습니다.',
          createdAt: DateTime.now(),
        ),
      );

      // 매칭 확정 알림 생성
      final notificationService = MatchingNotificationService();
      notificationService.createMatchingConfirmedNotification(
        widget.matching,
        widget.matching.host,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매칭이 확정되었습니다!'),
          backgroundColor: AppColors.success,
        ),
      );

      // 스크롤을 맨 아래로
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      if (kDebugMode) {
        print('매칭 확정 완료 및 알림 생성됨');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매칭 확정에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 매칭 상태 변경 리스너
  void _onMatchingStateChanged(String newStatus) {
    setState(() {
      _isMatchingConfirmed = newStatus == 'confirmed';
    });
  }

    // 읽지 않은 메시지들을 읽음 처리
  void _markMessagesAsRead() {
    final now = DateTime.now();
    bool hasChanges = false;

    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];

      // 내가 보낸 메시지가 아니고, 아직 읽지 않은 메시지인 경우
      if (message.senderId != widget.currentUser.id &&
          message.status != 'read' &&
          message.messageType != 'system') {

        _messages[i] = message.copyWith(
          status: 'read',
          readAt: now,
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      setState(() {});

      // WebSocket이 연결된 경우에만 읽음 상태 전송
      if (_isWebSocketConnected) {
        _sendReadReceipt();
      }
    }
  }

  // 읽음 확인 이벤트 핸들러
  void _handleReadReceipt(ChatMessageRead event) {
    // 해당 사용자가 보낸 메시지들을 읽음 상태로 업데이트
    setState(() {
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].senderId == event.userId && 
            _messages[i].status != 'read') {
          _messages[i] = _messages[i].copyWith(
            status: 'read',
            readAt: event.timestamp,
          );
        }
      }
    });
  }

  // 읽음 확인 전송
  void _sendReadReceipt() {
    try {
      WebSocketService.instance.sendReadReceipt(
        matchingId: widget.matching.id,
        userId: widget.currentUser.id,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('읽음 확인 전송 실패: $e');
    }
  }

  // 매칭 확정 취소 함수
  void _cancelMatchingConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('확정 취소'),
          content: const Text('정말로 매칭 확정을 취소하시겠습니까?\n\n확정 취소 후에는 다시 모집 상태로 돌아갑니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('아니오'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processMatchingCancellation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  // 매칭 확정 취소 처리
  void _processMatchingCancellation() {
    setState(() {
      _isMatchingConfirmed = false;
    });

    // 시스템 메시지 추가
    _messages.add(
      ChatMessage.systemMessage(
        matchingId: widget.matching.id,
        message: '${widget.matching.host.nickname}님이 매칭 확정을 취소했습니다.',
        createdAt: DateTime.now(),
      ),
    );

    // TODO: 실제 매칭 상태를 'recruiting'으로 변경하는 로직 구현
    // widget.matching.status = 'recruiting';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('매칭 확정이 취소되었습니다.'),
        backgroundColor: AppColors.warning,
      ),
    );

    // 스크롤을 맨 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
} 