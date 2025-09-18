import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/matching.dart';

import '../../services/matching_notification_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../matching/matching_detail_screen.dart';
import '../chat/chat_screen.dart';
import '../review/write_review_screen.dart';

class NotificationListScreen extends StatefulWidget {
  final User currentUser;

  const NotificationListScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final MatchingNotificationService _notificationService = MatchingNotificationService();
  List<MatchingNotification> _notifications = [];
  
  // 자동 새로고침 타이머
  Timer? _autoRefreshTimer;
  final Duration _refreshInterval = const Duration(minutes: 2); // 2분마다 새로고침

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _startAutoRefreshTimer();
  }
  
  // 자동 새로고침 타이머 시작
  void _startAutoRefreshTimer() {
    print('🔄 알림 자동 새로고침 활성화');
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _refreshNotifications();
      } else {
        timer.cancel();
      }
    });
  }
  
  // 알림 데이터 새로고침 (기존 알림 보존하면서 새 알림 추가)
  void _refreshNotifications() {
    print('🔄 알림 데이터 자동 새로고침 시작');
    
    // 기존 알림은 보존하고 새로운 알림만 추가
    _loadNotifications();
  }

  void _loadNotifications() {
    _notifications = _notificationService.getNotificationsForUser(widget.currentUser.id);
    setState(() {});
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _markAsRead(int notificationId) {
    _notificationService.markAsRead(notificationId);
    _loadNotifications();
  }

  void _markAllAsRead() {
    _notificationService.markAllAsRead(widget.currentUser.id);
    _loadNotifications();
  }

  void _deleteNotification(int notificationId) {
    _notificationService.deleteNotification(notificationId);
    _loadNotifications();
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 알림 삭제'),
        content: const Text('모든 알림을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _notificationService.clearAllNotifications();
              _loadNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _navigateToMatchingDetail(MatchingNotification notification) async {
    try {
      // 임시로 매칭 상세 화면으로 이동 (API 연동은 나중에)
      // TODO: 실제 매칭 데이터를 가져와서 처리
      
      // 임시 매칭 객체 생성
      final matching = Matching(
        id: notification.matchingId,
        type: 'host',
        courtName: '임시 코트',
        courtLat: 37.5665,
        courtLng: 126.9780,
        date: DateTime.now(),
        timeSlot: '10:00~12:00',
        gameType: 'mixed',
        maleRecruitCount: 2,
        femaleRecruitCount: 2,
        status: 'completed',
        host: User(
          id: 1,
          email: 'temp@example.com',
          nickname: '임시 호스트',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (true) { // 임시로 항상 true
        // 알림 타입에 따라 다른 화면으로 이동
        if (notification.type == 'new_chat') {
          // 새로운 채팅 알림인 경우 채팅 화면으로 이동
          final guestId = notification.additionalData?['guestId'] as int?;
          User? chatPartner;
          
          if (guestId != null) {
            // 게스트 정보 찾기
            chatPartner = matching.guests?.firstWhere(
              (guest) => guest.id == guestId,
              orElse: () => matching.host,
            );
          }
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                matching: matching,
                currentUser: widget.currentUser,
                chatPartner: chatPartner,
              ),
            ),
          );
        } else if (notification.type == 'review_available') {
          // 후기 작성 알림인 경우 후기 작성 화면으로 이동
          final targetForReviewId = notification.additionalData?['targetForReviewId'] as int?;
          User? targetForReview;
          
          if (targetForReviewId != null) {
            // 후기 대상 사용자 찾기
            if (matching.host.id == targetForReviewId) {
              targetForReview = matching.host;
            } else {
              targetForReview = matching.guests?.firstWhere(
                (guest) => guest.id == targetForReviewId,
                orElse: () => matching.host,
              );
            }
          }
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WriteReviewScreen(
                matching: matching,
                targetUser: targetForReview ?? matching.host, // null이면 호스트를 기본값으로
              ),
            ),
          );
        } else {
          // 기타 알림은 매칭 상세 화면으로 이동
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MatchingDetailScreen(
                matching: matching,
                currentUser: widget.currentUser,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // 오류 발생 시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('화면 이동 중 오류가 발생했습니다: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'matching_confirmed':
        return '✅';
      case 'matching_cancelled':
        return '❌';
      case 'matching_completed':
        return '🎉';
      case 'new_chat':
        return '💬';
      case 'guest_left':
        return '👋';
      case 'review_available':
        return '⭐';
      default:
        return '📢';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'matching_confirmed':
        return AppColors.success;
      case 'matching_cancelled':
        return AppColors.error;
      case 'matching_completed':
        return AppColors.primary;
      case 'new_chat':
        return AppColors.accent;
      case 'guest_left':
        return AppColors.warning;
      case 'review_available':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: '모두 읽음 처리',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllNotifications,
              tooltip: '모든 알림 삭제',
            ),
          ],
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '매칭 관련 새로운 소식이 있으면\n여기에 표시됩니다',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(MatchingNotification notification) {
    final isUnread = !notification.isRead;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread 
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread 
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.cardBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              _getNotificationIcon(notification.type),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          notification.title,
          style: AppTextStyles.body.copyWith(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
            color: isUnread ? AppColors.textPrimary : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.sports_tennis,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  notification.matchingTitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimeAgo(notification.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'read':
                _markAsRead(notification.id);
                break;
              case 'delete':
                _deleteNotification(notification.id);
                break;
            }
          },
          itemBuilder: (context) => [
            if (isUnread)
              const PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.done, size: 18),
                    SizedBox(width: 8),
                    Text('읽음 처리'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          child: Icon(
            Icons.more_vert,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: () {
          if (isUnread) {
            _markAsRead(notification.id);
          }
          _navigateToMatchingDetail(notification);
        },
      ),
    );
  }
}
