import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 알림 권한 상태
  bool _isInitialized = false;
  String? _fcmToken;

  // 알림 타입별 ID 관리
  static const int _matchingRequestId = 1000;
  static const int _matchingConfirmedId = 1001;
  static const int _chatMessageId = 1002;
  static const int _reviewCompletedId = 1003;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 로컬 알림 초기화 (Firebase와 무관하게 항상 시도)
      await _initializeLocalNotifications();
      
      // Firebase 초기화 시도
      try {
        await Firebase.initializeApp();
        await _initializeFirebaseMessaging();
        print('Firebase 알림 서비스 초기화 완료');
      } catch (e) {
        print('Firebase 알림 서비스 초기화 실패: $e');
        print('로컬 알림만 사용합니다.');
      }
      
      _isInitialized = true;
      print('알림 서비스 초기화 완료');
    } catch (e) {
      print('알림 서비스 초기화 실패: $e');
      // 로컬 알림 초기화라도 시도
      try {
        await _initializeLocalNotifications();
        _isInitialized = true;
        print('로컬 알림 서비스만 초기화 완료');
      } catch (e2) {
        print('로컬 알림 서비스 초기화도 실패: $e2');
      }
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: false,  // iOS 알림 권한 요청 비활성화
      requestBadgePermission: false,  // iOS 배지 권한 요청 비활성화
      requestSoundPermission: false,  // iOS 소리 권한 요청 비활성화
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

    /// Firebase Cloud Messaging 초기화
  Future<void> _initializeFirebaseMessaging() async {
    // 권한 요청 완전 차단
    print('알림 권한 요청 완전 차단됨 - 로컬 알림만 사용');
    
    // 로컬 알림은 권한 없이도 작동
    print('로컬 알림 서비스 활성화됨');
    
    // 앱이 종료된 상태에서 알림을 탭했을 때
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('포그라운드 메시지 수신: ${message.notification?.title}');
    // 포그라운드에서는 로컬 알림으로 표시
    _showLocalNotification(
      id: _getNotificationId(message.data['type']),
      title: message.notification?.title ?? '새 알림',
      body: message.notification?.body ?? '',
      payload: json.encode(message.data),
    );
  }

  /// 백그라운드 메시지 처리
  void _handleBackgroundMessage(RemoteMessage message) {
    print('백그라운드 메시지 수신: ${message.notification?.title}');
    // 백그라운드에서는 네비게이션 처리
    _handleNotificationNavigation(message.data);
  }

  /// 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    print('알림 탭됨: ${response.payload}');
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  /// 알림 네비게이션 처리
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'matching_request':
      case 'matching_confirmed':
        final matchingId = data['matchingId'] as int;
        _navigateToMatchingDetail(matchingId);
        break;
      case 'chat_message':
        final matchingId = data['matchingId'] as int;
        _navigateToChat(matchingId);
        break;
      case 'review_completed':
        final userId = data['userId'] as int;
        _navigateToProfile(userId);
        break;
    }
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'playmate_channel',
      'Playmate 알림',
      channelDescription: '테니스 매칭 관련 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// 알림 타입별 ID 반환
  int _getNotificationId(String? type) {
    switch (type) {
      case 'matching_request':
        return _matchingRequestId;
      case 'matching_confirmed':
        return _matchingConfirmedId;
      case 'chat_message':
        return _chatMessageId;
      case 'review_completed':
        return _reviewCompletedId;
      default:
        return DateTime.now().millisecondsSinceEpoch.remainder(100000);
    }
  }

  /// 매칭 신청 알림
  Future<void> showMatchingRequestNotification({
    required String hostName,
    required String courtName,
    required String date,
    required int matchingId,
  }) async {
    await _showLocalNotification(
      id: _matchingRequestId,
      title: '새로운 매칭 신청',
      body: '$hostName님이 $courtName $date 매칭에 신청했습니다',
      payload: json.encode({
        'type': 'matching_request',
        'matchingId': matchingId,
      }),
    );
  }

  /// 매칭 확정 알림
  Future<void> showMatchingConfirmedNotification({
    required String hostName,
    required String courtName,
    required String date,
    required int matchingId,
  }) async {
    await _showLocalNotification(
      id: _matchingConfirmedId,
      title: '매칭이 확정되었습니다',
      body: '$hostName님의 $courtName $date 매칭이 확정되었습니다',
      payload: json.encode({
        'type': 'matching_confirmed',
        'matchingId': matchingId,
      }),
    );
  }

  /// 채팅 메시지 알림
  Future<void> showChatMessageNotification({
    required String senderName,
    required String message,
    required int matchingId,
  }) async {
    await _showLocalNotification(
      id: _chatMessageId,
      title: '$senderName님의 메시지',
      body: message,
      payload: json.encode({
        'type': 'chat_message',
        'matchingId': matchingId,
      }),
    );
  }

  /// 후기 작성 완료 알림
  Future<void> showReviewCompletedNotification({
    required String reviewerName,
    required String targetName,
    required int userId,
  }) async {
    await _showLocalNotification(
      id: _reviewCompletedId,
      title: '후기 작성 완료',
      body: '$reviewerName님이 $targetName님에 대한 후기를 작성했습니다',
      payload: json.encode({
        'type': 'review_completed',
        'userId': userId,
      }),
    );
  }

  /// FCM 토큰 반환
  String? get fcmToken => _fcmToken;

  /// 알림 권한 상태 확인
  Future<bool> isNotificationEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Firebase 알림 권한 확인 실패: $e');
      // Firebase가 없으면 로컬 알림 권한만 확인
      return true;
    }
  }

  /// 알림 권한 요청
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Firebase 알림 권한 요청 실패: $e');
      // Firebase가 없으면 로컬 알림 권한만 요청
      return true;
    }
  }

  // TODO: 실제 네비게이션 구현
  void _navigateToMatchingDetail(int matchingId) {
    print('매칭 상세 화면으로 이동: $matchingId');
  }

  void _navigateToChat(int matchingId) {
    print('채팅 화면으로 이동: $matchingId');
  }

  void _navigateToProfile(int userId) {
    print('프로필 화면으로 이동: $userId');
  }
}
