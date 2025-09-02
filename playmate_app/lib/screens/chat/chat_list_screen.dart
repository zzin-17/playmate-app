import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/chat_room.dart';
import '../../models/matching.dart';
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

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<AuthProvider>().currentUser!;
    _loadChatRooms();
    _chatEventSub = ChatEventBus.instance.stream.listen((event) {
      if (event is ChatRoomCreated || event is ChatMessageArrived) {
        _loadChatRooms();
      }
    });
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

  void _openChat(ChatRoom r) async {
    final matching = await _chatService.getMatchingForRoom(r.matchingId);
    if (matching == null) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matching: matching,
          currentUser: _currentUser,
          chatPartner: _chatPartner(r),
        ),
      ),
    );
  }

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
            onTap: () => _openChat(r),
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
}


