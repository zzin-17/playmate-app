import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/chat_room.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/chat_event_bus.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final User _currentUser;
  final ChatService _chatService = ChatService();
  final List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  StreamSubscription? _chatEventSub;
  
  // 자동 새로고침 타이머
  Timer? _autoRefreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 10); // 실시간 (10초마다)

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<AuthProvider>().currentUser!;
    _loadChatRooms();
    _startAutoRefreshTimer();
    _chatEventSub = ChatEventBus.instance.stream.listen((event) {
      if (event is ChatRoomCreated || event is ChatMessageArrived) {
        _loadChatRooms();
      }
    });
  }
  
  // 실시간 새로고침 타이머 시작
  void _startAutoRefreshTimer() {
    print('🔄 채팅 목록 실시간 새로고침 활성화 (10초 주기)');
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _refreshChatRooms();
      } else {
        timer.cancel();
      }
    });
  }
  
  // 채팅방 목록 새로고침 (기존 채팅방 보존하면서 새 채팅방 추가)
  void _refreshChatRooms() {
    print('🔄 채팅방 목록 자동 새로고침 시작');
    
    // 기존 채팅방 보존하면서 새로운 채팅방만 추가
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() => _isLoading = true);
    try {
      final rooms = await _chatService.getMyChatRooms(_currentUser);
      setState(() {
        _chatRooms
          ..clear()
          ..addAll(rooms);
      });
    } catch (e) {
      // 실패 시 빈 화면 안내
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방을 불러오지 못했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _roleColor(ChatRoom r) {
    final isHost = r.myRole == 'host';
    return isHost ? AppColors.primary : AppColors.buttonChat;
  }

  String _roleText(ChatRoom r) {
    final isHost = r.myRole == 'host';
    return isHost ? '호스트' : '게스트';
  }

  User _chatPartner(ChatRoom r) => r.partner;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? Center(
                  child: Text(
                    '표시할 채팅방이 없습니다.\n매칭을 생성하거나 참여해 보세요.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                )
              : ListView.separated(
        itemCount: _chatRooms.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final r = _chatRooms[index];
          final partner = _chatPartner(r);
          final roleColor = _roleColor(r);

          return ListTile(
            onTap: () {
              print('🔍 채팅방 클릭: ${r.courtName} (매칭 ID: ${r.matchingId})');
              _openChatRoom(r);
            },
            leading: CircleAvatar(
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Icon(
                Icons.forum,
                color: roleColor,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    r.courtName,
                    style: AppTextStyles.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _roleText(r),
                    style: AppTextStyles.caption.copyWith(color: roleColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${r.date.month}월 ${r.date.day}일 · ${r.timeSlot}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  '상대: ${partner.nickname}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  '마지막 채팅: ${_formatLastMessageTime(r.lastMessageAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _chatEventSub?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  String _formatLastMessageTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays >= 1) {
      return '${dt.month}/${dt.day}';
    }
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // 채팅방 열기 (강화된 매칭 정보 로딩)
  void _openChatRoom(ChatRoom room) async {
    try {
      print('🔍 채팅방 열기 시도: ${room.courtName} (매칭 ID: ${room.matchingId})');
      
      // 로딩 상태 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // ChatService를 통해 안전한 매칭 정보 로딩
      final matching = await _chatService.getMatchingForRoom(
        room.matchingId,
        courtName: room.courtName.split(' - ')[0], // "한남테니스장 - 개발자님" → "한남테니스장"
        timeSlot: room.timeSlot,
        date: room.date,
        host: room.partner,
      );
      
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();
      
      print('✅ 매칭 정보 로딩 완료: ${matching.courtName} (ID: ${matching.id})');
      
      // 채팅 화면으로 이동
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              matching: matching,
              currentUser: _currentUser,
              chatPartner: room.partner,
            ),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) Navigator.of(context).pop();
      
      print('❌ 채팅방 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅방을 열 수 없습니다: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '재시도',
              textColor: Colors.white,
              onPressed: () => _openChatRoom(room),
            ),
          ),
        );
      }
    }
  }
}


