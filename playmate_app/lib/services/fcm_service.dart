import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  bool _isInitialized = false;

  // FCM 토큰 getter
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  // FCM 초기화
  Future<void> initialize() async {
    try {
      // Firebase 초기화 확인
      await Firebase.initializeApp();
      
      // 로컬 알림 초기화
      await _initializeLocalNotifications();
      
      // FCM 권한 요청
      await _requestNotificationPermission();
      
      // FCM 토큰 가져오기 (실패해도 계속 진행)
      try {
        await _getFCMToken();
      } catch (e) {
        if (kDebugMode) {
          print('FCM 토큰 가져오기 실패 (계속 진행): $e');
        }
      }
      
      // FCM 핸들러 설정 (토큰이 있을 때만)
      if (_fcmToken != null) {
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      }
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('FCM 서비스 초기화 완료 (토큰: $_fcmToken)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM 서비스 초기화 실패 (앱은 계속 실행): $e');
      }
      // Firebase 초기화 실패해도 앱은 계속 실행
      _isInitialized = true; // 로컬 알림은 사용 가능하도록 설정
    }
  }

  // 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  // 알림 권한 요청
  Future<void> _requestNotificationPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (kDebugMode) {
      print('알림 권한 상태: ${settings.authorizationStatus}');
    }
  }

  // FCM 토큰 가져오기
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      
      // 토큰 갱신 리스너
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) {
          print('FCM 토큰 갱신: $newToken');
        }
        // 서버에 새 토큰 전송 (향후 구현)
      });
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 가져오기 실패: $e');
      }
    }
  }

  // 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('포그라운드 메시지 수신: ${message.messageId}');
      print('제목: ${message.notification?.title}');
      print('내용: ${message.notification?.body}');
      print('데이터: ${message.data}');
    }
    
    // 로컬 알림 표시
    _showLocalNotification(message);
  }

  // 백그라운드 메시지 처리 (static 메서드여야 함)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('백그라운드 메시지 수신: ${message.messageId}');
    }
    
    // 백그라운드에서는 로컬 알림만 표시
    // 백그라운드 작업 수행 (필요시)
  }

  // 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('알림 탭됨: ${message.messageId}');
      print('데이터: ${message.data}');
    }
    
    // 알림 타입에 따라 적절한 화면으로 이동
    _navigateToScreen(message.data);
  }

  // 로컬 알림 탭 처리
  void _onLocalNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('로컬 알림 탭됨: ${response.payload}');
    }
    
    // 페이로드에 따라 적절한 화면으로 이동
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _navigateToScreen(data);
    }
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'matching_notifications',
      '매칭 알림',
      channelDescription: '매칭 관련 알림을 표시합니다',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );
    
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '새로운 알림',
      message.notification?.body ?? '',
      details,
      payload: json.encode(message.data),
    );
  }

  // 알림 데이터에 따른 화면 이동
  void _navigateToScreen(Map<String, dynamic> data) {
    // 네비게이션 솔루션을 사용하여 화면 이동
    // 예: 매칭 상세, 채팅, 프로필 등
    if (kDebugMode) {
      print('화면 이동 데이터: $data');
    }
  }

  // 특정 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('토픽 구독 완료: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('토픽 구독 실패: $e');
      }
    }
  }

  // 특정 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('토픽 구독 해제 완료: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('토픽 구독 해제 실패: $e');
      }
    }
  }

  // 사용자별 토픽 구독
  Future<void> subscribeToUserTopic(int userId) async {
    await subscribeToTopic('user_$userId');
  }

  // 사용자별 토픽 구독 해제
  Future<void> unsubscribeFromUserTopic(int userId) async {
    await unsubscribeFromTopic('user_$userId');
  }

  // 매칭별 토픽 구독
  Future<void> subscribeToMatchingTopic(int matchingId) async {
    await subscribeToTopic('matching_$matchingId');
  }

  // 매칭별 토픽 구독 해제
  Future<void> unsubscribeFromMatchingTopic(int matchingId) async {
    await unsubscribeFromTopic('matching_$matchingId');
  }

  // 서비스 정리
  Future<void> dispose() async {
    try {
      // 모든 토픽 구독 해제
      // 구독 중인 토픽 목록을 추적하여 해제
      
      if (kDebugMode) {
        print('FCM 서비스 정리 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM 서비스 정리 실패: $e');
      }
    }
  }
}

// 백그라운드 메시지 핸들러 (최상위 레벨에 정의)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화
  await Firebase.initializeApp();
  
  if (kDebugMode) {
    print('백그라운드 메시지 핸들러 실행: ${message.messageId}');
  }
}
