import 'package:flutter/foundation.dart';
import '../models/matching.dart';
import '../models/user.dart';
import 'fcm_service.dart';

class MatchingNotification {
  final int id;
  final String type; // 'matching_confirmed', 'matching_cancelled', 'matching_completed', 'new_chat', 'guest_left', 'review_available'
  final String title;
  final String message;
  final int matchingId;
  final String matchingTitle;
  final int? targetUserId; // 알림을 받을 사용자 ID
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? additionalData; // 추가 데이터 (사용자 정보, 코트 정보 등)

  MatchingNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.matchingId,
    required this.matchingTitle,
    this.targetUserId,
    required this.createdAt,
    this.isRead = false,
    this.additionalData,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'matchingId': matchingId,
      'matchingTitle': matchingTitle,
      'targetUserId': targetUserId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }

  factory MatchingNotification.fromJson(Map<String, dynamic> json) {
    return MatchingNotification(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      matchingId: json['matchingId'],
      matchingTitle: json['matchingTitle'],
      targetUserId: json['targetUserId'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      additionalData: json['additionalData'],
    );
  }

  // 읽음 상태 변경
  MatchingNotification copyWith({bool? isRead}) {
    return MatchingNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      matchingId: matchingId,
      matchingTitle: matchingTitle,
      targetUserId: targetUserId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      additionalData: additionalData,
    );
  }
}

class MatchingNotificationService extends ChangeNotifier {
  static final MatchingNotificationService _instance = MatchingNotificationService._internal();
  factory MatchingNotificationService() => _instance;
  MatchingNotificationService._internal();

  // 알림 목록
  final List<MatchingNotification> _notifications = [];
  
  // 알림 ID 카운터
  int _nextNotificationId = 1;

  // 알림 목록 getter
  List<MatchingNotification> get notifications => List.unmodifiable(_notifications);
  
  // 읽지 않은 알림 개수
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // 리스너들에게 알림
  void _notifyListeners() {
    notifyListeners();
  }

  // 테스트용 알림 생성 (호스트에게만 관련 알림)
  void createTestNotifications() {
    final now = DateTime.now();
    
    // 호스트(테스트유저, ID: 1)에게만 관련 알림 생성
    _createNotification(
      type: 'matching_confirmed',
      title: '매칭이 확정되었습니다!',
      message: '잠실종합운동장 매칭이 확정되었습니다.',
      matchingId: 1,
      matchingTitle: '잠실종합운동장 테니스',
      targetUserId: 1, // 호스트에게만
      createdAt: now.subtract(const Duration(minutes: 5)),
    );

    // 게스트가 받는 매칭 확정 알림 추가 (테스트용)
    _createNotification(
      type: 'matching_confirmed',
      title: '매칭이 확정되었습니다!',
      message: '양재시민의숲 매칭이 확정되었습니다.',
      matchingId: 2,
      matchingTitle: '양재시민의숲 테니스',
      targetUserId: 1, // 테스트유저가 게스트로 참여한 경우
      createdAt: now.subtract(const Duration(minutes: 10)),
    );

    _createNotification(
      type: 'new_chat',
      title: '새로운 채팅이 있습니다',
      message: '테니스초보님이 매칭에 참여했습니다.',
      matchingId: 2,
      matchingTitle: '양재시민의숲 테니스',
      targetUserId: 2, // 양재러버(호스트)에게만
      createdAt: now.subtract(const Duration(hours: 2)),
    );

    _createNotification(
      type: 'matching_completed',
      title: '매칭이 완료되었습니다',
      message: '올림픽공원 테니스장 매칭이 성공적으로 완료되었습니다.',
      matchingId: 3,
      matchingTitle: '올림픽공원 테니스장',
      targetUserId: 5, // 올림픽러버(호스트)에게만
      createdAt: now.subtract(const Duration(days: 1)),
      isRead: true,
    );

    _createNotification(
      type: 'matching_cancelled',
      title: '매칭이 취소되었습니다',
      message: '한강공원 테니스장 매칭이 취소되었습니다.',
      matchingId: 4,
      matchingTitle: '한강공원 테니스장',
      targetUserId: 8, // 한강러버(호스트)에게만
      createdAt: now.subtract(const Duration(days: 2)),
    );

    // 테스트유저가 호스트인 매칭에 대한 알림 추가
    _createNotification(
      type: 'new_chat',
      title: '새로운 채팅이 있습니다',
      message: '테니스러버님이 매칭에 참여했습니다.',
      matchingId: 1,
      matchingTitle: '잠실종합운동장 테니스',
      targetUserId: 1, // 테스트유저(호스트)에게만
      createdAt: now.subtract(const Duration(hours: 1)),
    );

    // 후기 작성 가능 알림 추가 (테스트용)
    _createNotification(
      type: 'review_available',
      title: '후기 작성 가능',
      message: '테니스러버님에 대한 후기를 작성해보세요!',
      matchingId: 1,
      matchingTitle: '잠실종합운동장 테니스',
      targetUserId: 1, // 테스트유저에게
      createdAt: now.subtract(const Duration(days: 1)),
    );

    _createNotification(
      type: 'review_available',
      title: '후기 작성 가능',
      message: '올림픽공원 테니스장 매칭에 대한 후기를 작성해보세요!',
      matchingId: 3,
      matchingTitle: '올림픽공원 테니스장',
      targetUserId: 1, // 테스트유저에게
      createdAt: now.subtract(const Duration(days: 2)),
    );

    _notifyListeners();
  }

  // 알림 생성 헬퍼 메서드
  void _createNotification({
    required String type,
    required String title,
    required String message,
    required int matchingId,
    required String matchingTitle,
    required int targetUserId,
    required DateTime createdAt,
    bool isRead = false,
  }) {
    final notification = MatchingNotification(
      id: _nextNotificationId++,
      type: type,
      title: title,
      message: message,
      matchingId: matchingId,
      matchingTitle: matchingTitle,
      targetUserId: targetUserId,
      createdAt: createdAt,
      isRead: isRead,
    );
    
    _notifications.add(notification);
  }

  // 매칭 확정 알림 생성
  void createMatchingConfirmedNotification(Matching matching, User host) {
    // 호스트에게 알림
    final hostNotification = MatchingNotification(
      id: _nextNotificationId++,
      type: 'matching_confirmed',
      title: '매칭 확정 완료',
      message: '${matching.courtName} 매칭이 확정되었습니다!',
      matchingId: matching.id,
      matchingTitle: matching.courtName,
      targetUserId: host.id,
      createdAt: DateTime.now(),
      additionalData: {
        'hostName': host.nickname,
        'courtName': matching.courtName,
        'date': matching.date.toIso8601String(),
        'timeSlot': matching.timeSlot,
      },
    );

    // 게스트들에게 알림
    if (matching.guests != null) {
      for (final guest in matching.guests!) {
        final guestNotification = MatchingNotification(
          id: _nextNotificationId++,
          type: 'matching_confirmed',
          title: '매칭 확정 완료',
          message: '${matching.courtName} 매칭이 확정되었습니다!',
          matchingId: matching.id,
          matchingTitle: matching.courtName,
          targetUserId: guest.id,
          createdAt: DateTime.now(),
          additionalData: {
            'hostName': host.nickname,
            'courtName': matching.courtName,
            'date': matching.date.toIso8601String(),
            'timeSlot': matching.timeSlot,
          },
        );
        _notifications.add(guestNotification);
      }
    }

    _notifications.add(hostNotification);
    _notifyListeners();
    
    if (kDebugMode) {
      print('매칭 확정 알림 생성: ${matching.courtName}');
    }
    
    // FCM 토픽 구독 (매칭 참여자들에게 알림)
    _subscribeToMatchingTopics(matching);
  }

  // 매칭 취소 알림 생성
  void createMatchingCancelledNotification(Matching matching, User host, String reason) {
    // 호스트에게 알림
    final hostNotification = MatchingNotification(
      id: _nextNotificationId++,
      type: 'matching_cancelled',
      title: '매칭 취소',
      message: '${matching.courtName} 매칭이 취소되었습니다. 사유: $reason',
      matchingId: matching.id,
      matchingTitle: matching.courtName,
      targetUserId: host.id,
      createdAt: DateTime.now(),
      additionalData: {
        'hostName': host.nickname,
        'courtName': matching.courtName,
        'reason': reason,
      },
    );

    // 게스트들에게 알림
    if (matching.guests != null) {
      for (final guest in matching.guests!) {
        final guestNotification = MatchingNotification(
          id: _nextNotificationId++,
          type: 'matching_cancelled',
          title: '매칭 취소',
          message: '${matching.courtName} 매칭이 취소되었습니다. 사유: $reason',
          matchingId: matching.id,
          matchingTitle: matching.courtName,
          targetUserId: guest.id,
          createdAt: DateTime.now(),
          additionalData: {
            'hostName': host.nickname,
            'courtName': matching.courtName,
            'reason': reason,
          },
        );
        _notifications.add(guestNotification);
      }
    }

    _notifications.add(hostNotification);
    _notifyListeners();
    
    if (kDebugMode) {
      print('매칭 취소 알림 생성: ${matching.courtName}');
    }
  }

  // 매칭 완료 알림 생성
  void createMatchingCompletedNotification(Matching matching, User host) {
    // 호스트에게 알림
    final hostNotification = MatchingNotification(
      id: _nextNotificationId++,
      type: 'matching_completed',
      title: '매칭 완료',
      message: '${matching.courtName} 매칭이 완료되었습니다.',
      matchingId: matching.id,
      matchingTitle: matching.courtName,
      targetUserId: host.id,
      createdAt: DateTime.now(),
      additionalData: {
        'hostName': host.nickname,
        'courtName': matching.courtName,
        'date': matching.date.toIso8601String(),
        'timeSlot': matching.timeSlot,
      },
    );

    // 게스트들에게 알림
    if (matching.guests != null) {
      for (final guest in matching.guests!) {
        final guestNotification = MatchingNotification(
          id: _nextNotificationId++,
          type: 'matching_completed',
          title: '매칭 완료',
          message: '${matching.courtName} 매칭이 완료되었습니다.',
          matchingId: matching.id,
          matchingTitle: matching.courtName,
          targetUserId: guest.id,
          createdAt: DateTime.now(),
          additionalData: {
            'hostName': host.nickname,
            'courtName': matching.courtName,
            'date': matching.date.toIso8601String(),
            'timeSlot': matching.timeSlot,
          },
        );
        _notifications.add(guestNotification);
      }
    }

    _notifications.add(hostNotification);
    _notifyListeners();
    
    if (kDebugMode) {
      print('매칭 완료 알림 생성: ${matching.courtName}');
    }
  }

  // 후기 작성 가능 알림 생성
  void createReviewAvailableNotification(Matching matching, User targetUser, User? targetForReview) {
    final notification = MatchingNotification(
      id: _nextNotificationId++,
      type: 'review_available',
      title: '후기 작성 가능',
      message: targetForReview != null 
          ? '${targetForReview.nickname}님에 대한 후기를 작성해보세요!'
          : '${matching.courtName} 매칭에 대한 후기를 작성해보세요!',
      matchingId: matching.id,
      matchingTitle: matching.courtName,
      targetUserId: targetUser.id,
      createdAt: DateTime.now(),
      additionalData: {
        'hostName': matching.host.nickname,
        'courtName': matching.courtName,
        'date': matching.date.toIso8601String(),
        'timeSlot': matching.timeSlot,
        'targetForReviewId': targetForReview?.id,
        'targetForReviewName': targetForReview?.nickname,
      },
    );

    _notifications.add(notification);
    _notifyListeners();
    
    if (kDebugMode) {
      print('후기 작성 가능 알림 생성: ${targetUser.nickname}');
    }
  }

  // 새로운 채팅 알림 생성
  void createNewChatNotification(Matching matching, User host, User guest) {
    final notification = MatchingNotification(
      id: _nextNotificationId++,
      type: 'new_chat',
      title: '새로운 채팅이 있습니다',
      message: '${guest.nickname}님이 ${matching.courtName} 매칭에 참여했습니다.',
      matchingId: matching.id,
      matchingTitle: matching.courtName,
      targetUserId: host.id,
      createdAt: DateTime.now(),
      additionalData: {
        'hostName': host.nickname,
        'guestName': guest.nickname,
        'courtName': matching.courtName,
        'guestId': guest.id,
      },
    );

    _notifications.add(notification);
    _notifyListeners();
    
    if (kDebugMode) {
      print('새로운 채팅 알림 생성: ${guest.nickname}');
    }
  }

  // 게스트 탈퇴 알림 생성
  void createGuestLeftNotification(Matching matching, User host, User guest) {
    final notification = MatchingNotification(
      id: _nextNotificationId++,
      type: 'guest_left',
      title: '참여자 탈퇴',
      message: '${guest.nickname}님이 ${matching.courtName} 매칭에서 탈퇴했습니다.',
      matchingId: matching.id,
      matchingTitle: matching.courtName,
      targetUserId: host.id,
      createdAt: DateTime.now(),
      additionalData: {
        'hostName': host.nickname,
        'guestName': guest.nickname,
        'courtName': matching.courtName,
      },
    );

    _notifications.add(notification);
    _notifyListeners();
    
    if (kDebugMode) {
      print('게스트 탈퇴 알림 생성: ${guest.nickname}');
    }
  }

  // 특정 사용자의 알림 가져오기
  List<MatchingNotification> getNotificationsForUser(int userId) {
    return _notifications
        .where((n) => n.targetUserId == null || n.targetUserId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순 정렬
  }

  // 알림 읽음 처리
  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifyListeners();
    }
  }

  // 모든 알림 읽음 처리
  void markAllAsRead(int userId) {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].targetUserId == userId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _notifyListeners();
  }

  // 알림 삭제
  void deleteNotification(int notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  // 모든 알림 삭제
  void clearAllNotifications() {
    _notifications.clear();
    _notifyListeners();
  }

  // 알림 필터링
  List<MatchingNotification> filterNotifications({
    String? type,
    bool? isRead,
    int? matchingId,
  }) {
    return _notifications.where((n) {
      if (type != null && n.type != type) return false;
      if (isRead != null && n.isRead != isRead) return false;
      if (matchingId != null && n.matchingId != matchingId) return false;
      return true;
    }).toList();
  }

  // 테스트용 샘플 알림 생성
  void createSampleNotifications() {
    final sampleMatching = Matching(
      id: 1,
      type: 'host',
      courtName: '잠실종합운동장',
      courtLat: 37.5665,
      courtLng: 127.0018,
      date: DateTime.now().add(const Duration(days: 1)),
      timeSlot: '14:00~16:00',
      gameType: 'mixed',
      maleRecruitCount: 2,
      femaleRecruitCount: 2,
      status: 'recruiting',
      host: User(
        id: 1,
        email: 'host@example.com',
        nickname: '테린이',
        birthYear: 1990,
        gender: 'male',
        skillLevel: 3,
        region: '서울',
        preferredCourt: '잠실종합운동장',
        preferredTime: ['오후'],
        playStyle: '공격적',
        hasLesson: false,
        mannerScore: 4.5,
        startYearMonth: '2020-03',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    createMatchingConfirmedNotification(sampleMatching, sampleMatching.host);
  }

  // FCM 토픽 구독 메서드
  void _subscribeToMatchingTopics(Matching matching) {
    try {
      final fcmService = FCMService();
      
      if (fcmService.isInitialized && fcmService.fcmToken != null) {
        // 매칭별 토픽 구독
        fcmService.subscribeToMatchingTopic(matching.id);
        
        // 호스트에게 알림
        fcmService.subscribeToUserTopic(matching.host.id);
        
        // 게스트들에게 알림
        if (matching.guests != null) {
          for (final guest in matching.guests!) {
            fcmService.subscribeToUserTopic(guest.id);
          }
        }
        
        if (kDebugMode) {
          print('FCM 토픽 구독 완료: 매칭 ${matching.id}');
        }
      } else {
        if (kDebugMode) {
          print('FCM 서비스 미사용 (토큰 없음) - 로컬 알림만 사용');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토픽 구독 실패: $e');
      }
    }
  }
}
