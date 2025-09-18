import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android 설정
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS 설정
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 초기화 설정
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      print('알림 서비스 초기화 완료');
    } catch (e) {
      print('알림 서비스 초기화 실패: $e');
    }
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: 알림 탭 시 해당 화면으로 이동
    print('알림 탭됨: ${response.payload}');
  }

  /// 댓글 알림
  Future<void> showCommentNotification({
    required String postTitle,
    required String commenterName,
    required String comment,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '새로운 댓글',
      body: '$commenterName님이 "$postTitle"에 댓글을 남겼습니다: $comment',
      payload: 'comment',
    );
  }

  /// 좋아요 알림
  Future<void> showLikeNotification({
    required String postTitle,
    required String likerName,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '좋아요',
      body: '$likerName님이 "$postTitle"을 좋아합니다',
      payload: 'like',
    );
  }

  /// 팔로우 알림
  Future<void> showFollowNotification({
    required String followerName,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '새로운 팔로워',
      body: '$followerName님이 회원님을 팔로우하기 시작했습니다',
      payload: 'follow',
    );
  }

  /// 공유 알림
  Future<void> showShareNotification({
    required String postTitle,
    required String sharerName,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '게시글 공유',
      body: '$sharerName님이 "$postTitle"을 공유했습니다',
      payload: 'share',
    );
  }

  /// 매칭 확정 알림
  Future<void> showMatchingConfirmedNotification({
    required String hostName,
    required String courtName,
    required String date,
    required int matchingId,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '매칭이 확정되었습니다',
      body: '$hostName님의 $courtName $date 매칭이 확정되었습니다',
      payload: 'matching_confirmed',
    );
  }

  /// 일반 알림 표시
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Android 알림 설정
      const androidDetails = AndroidNotificationDetails(
        'community_channel',
        '커뮤니티 알림',
        channelDescription: '커뮤니티 활동 관련 알림',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      // iOS 알림 설정
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // 알림 상세 설정
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 알림 표시
      await _notifications.show(id, title, body, details, payload: payload);
      
      // 알림 히스토리에 저장
      await _saveNotificationHistory(title, body, payload);
      
    } catch (e) {
      print('알림 표시 실패: $e');
    }
  }

  /// 알림 히스토리 저장
  Future<void> _saveNotificationHistory(String title, String body, String? payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('notification_history') ?? [];
      
      final notification = {
        'title': title,
        'body': body,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      history.insert(0, notification.toString());
      
      // 최근 50개만 유지
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }
      
      await prefs.setStringList('notification_history', history);
    } catch (e) {
      print('알림 히스토리 저장 실패: $e');
    }
  }

  /// 알림 히스토리 가져오기
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('notification_history') ?? [];
      
      return history.map((item) {
        // 간단한 파싱 (실제로는 JSON 사용 권장)
        final cleanItem = item.replaceAll('{', '').replaceAll('}', '');
        final parts = cleanItem.split(', ');
        
        final Map<String, dynamic> notification = {};
        for (final part in parts) {
          final keyValue = part.split(': ');
          if (keyValue.length == 2) {
            final key = keyValue[0].replaceAll("'", '');
            final value = keyValue[1].replaceAll("'", '');
            notification[key] = value;
          }
        }
        
        return notification;
      }).toList();
    } catch (e) {
      print('알림 히스토리 가져오기 실패: $e');
      return [];
    }
  }

  /// 알림 히스토리 삭제
  Future<void> clearNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_history');
    } catch (e) {
      print('알림 히스토리 삭제 실패: $e');
    }
  }

  /// 알림 권한 요청
  Future<bool> requestPermissions() async {
    try {
      // iOS 권한 요청
      final iosGranted = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      
      // Android는 권한이 필요하지 않음 (로컬 알림), iOS만 체크
      return iosGranted ?? true;
    } catch (e) {
      print('알림 권한 요청 실패: $e');
      return false;
    }
  }

  /// 알림 설정 가져오기
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'comments': prefs.getBool('notify_comments') ?? true,
        'likes': prefs.getBool('notify_likes') ?? true,
        'follows': prefs.getBool('notify_follows') ?? true,
        'shares': prefs.getBool('notify_shares') ?? true,
      };
    } catch (e) {
      print('알림 설정 가져오기 실패: $e');
      return {
        'comments': true,
        'likes': true,
        'follows': true,
        'shares': true,
      };
    }
  }

  /// 알림 설정 저장
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in settings.entries) {
        await prefs.setBool('notify_${entry.key}', entry.value);
      }
    } catch (e) {
      print('알림 설정 저장 실패: $e');
    }
  }
}
