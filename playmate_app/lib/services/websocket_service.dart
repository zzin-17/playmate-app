import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_message.dart';
import 'chat_event_bus.dart';
import 'chat_local_store.dart';

class WebSocketService {
  static WebSocketService? _instance;
  IO.Socket? _socket;
  StreamController<ChatMessage>? _messageController;
  StreamController<String>? _statusController;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  
  // 연결 상태
  bool _isConnected = false;
  String _currentMatchingId = '';
  String _currentUserId = '';
  
  // 싱글톤 패턴
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }
  
  WebSocketService._();
  final ChatLocalStore _localStore = ChatLocalStore();
  
  // 메시지 스트림
  Stream<ChatMessage> get messageStream => _messageController?.stream ?? const Stream.empty();
  
  // 상태 스트림
  Stream<String> get statusStream => _statusController?.stream ?? const Stream.empty();
  
  // 연결 상태
  bool get isConnected => _isConnected;
  
  // 플메 Socket.io 연결 (항상 대상 매칭으로 연결)
  Future<void> connect(String matchingId, String userId) async {
    // 같은 매칭이 아니면 강제로 재연결
    if (_isConnected && _currentMatchingId == matchingId) {
      // 이미 동일 매칭이면 상태만 OK
    } else {
      await disconnect();
    }
    
    // 연결 정보 저장 (재연결용)
    _currentMatchingId = matchingId;
    _currentUserId = userId;
    
    try {
      // 플메 Socket.io 서버 URL (Android 에뮬레이터용)
      final serverUrl = 'http://10.0.2.2:8080';
      
      // Socket.io 클라이언트 생성
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionDelay': 2000,
        'reconnectionAttempts': 10,
        'timeout': 20000,
        'forceNew': true,
      });
      
      print('플메 Socket.io 클라이언트 생성: $serverUrl');
      
      // 연결 정보는 이미 위에서 저장됨
      
      // 메시지 컨트롤러 초기화
      _messageController = StreamController<ChatMessage>.broadcast();
      _statusController = StreamController<String>.broadcast();
      
      // Socket.io 이벤트 리스너 설정
      _setupSocketListeners();
      
      // 수동 연결
      _socket!.connect();
      print('플메 Socket.io 연결 시도...');
      
      // 연결 대기
      await _waitForConnection();
      
      // 플메 채팅방 입장
      _sendJoinMatching(matchingId, userId);
      
      // 핑 타이머 시작 (연결 유지)
      _startPingTimer();
      
      print('플메 Socket.io 연결 성공: $matchingId');
      
    } catch (e) {
      print('플메 Socket.io 연결 실패: $e');
      _handleError();
    }
  }

  // Socket.io 이벤트 리스너 설정
  void _setupSocketListeners() {
    if (_socket == null) return;
    
    // 연결 성공
    _socket!.onConnect((_) {
      print('플메 Socket.io 연결됨');
      _isConnected = true;
      _statusController?.add('connected');
    });
    
    // 연결 해제
    _socket!.onDisconnect((_) {
      print('플메 Socket.io 연결 해제됨');
      _isConnected = false;
      _statusController?.add('disconnected');
    });
    
    // 연결 오류
    _socket!.onConnectError((error) {
      print('플메 Socket.io 연결 오류: $error');
      _isConnected = false;
      _statusController?.add('error');
    });
    
    // 메시지 수신
    _socket!.on('receive_message', (data) {
      try {
        final message = ChatMessage.fromSocketJson(Map<String, dynamic>.from(data));
        // 자신이 방금 보낸 메시지를 서버가 에코할 경우 중복 방지: 동일 id면 무시
        // (id가 없으면 timestamp/내용 기준으로 로컬 저장에서 필터)
        _messageController?.add(message);
        // 로컬 저장
        _localStore.appendMessage(message);
        // 채팅 리스트 갱신 이벤트 발행
        ChatEventBus.instance.emit(ChatMessageArrived(
          matchingId: message.matchingId,
          timestamp: message.createdAt,
        ));
      } catch (e) {
        print('플메 메시지 파싱 오류: $e');
      }
    });

    // 읽음 확인 수신
    _socket!.on('read_receipt', (data) {
      try {
        final readData = Map<String, dynamic>.from(data);
        final matchingId = readData['matchingId'] as int;
        final userId = readData['userId'] as int;
        final timestamp = DateTime.parse(readData['timestamp'] as String);
        
        print('플메 읽음 확인 수신: 사용자 $userId, 매칭 $matchingId, 시간 $timestamp');
        
        // 읽음 확인 이벤트 발행
        ChatEventBus.instance.emit(ChatMessageRead(
          matchingId: matchingId,
          userId: userId,
          timestamp: timestamp,
        ));
      } catch (e) {
        print('플메 읽음 확인 파싱 오류: $e');
      }
    });
    
    // 메시지 히스토리 수신
    _socket!.on('message_history', (data) {
      try {
        final messages = (data as List)
            .map((msg) => ChatMessage.fromSocketJson(Map<String, dynamic>.from(msg)))
            .toList();
        for (final message in messages) {
          _messageController?.add(message);
          _localStore.appendMessage(message);
        }
      } catch (e) {
        print('플메 메시지 히스토리 파싱 오류: $e');
      }
    });
    
    // 사용자 입장
    _socket!.on('user_joined', (data) {
      print('플메 사용자 입장: ${data['nickname']}');
    });
    
    // 사용자 탈퇴
    _socket!.on('user_left', (data) {
      print('플메 사용자 탈퇴: ${data['nickname']}');
    });
    
    // 핑/퐁
    _socket!.on('pong', (data) {
      print('플메 핑/퐁 응답: ${data['timestamp']}');
    });
  }

  // 연결 대기
  Future<void> _waitForConnection() async {
    if (_socket == null) return;
    
    // 이미 연결된 경우
    if (_socket!.connected) {
      _isConnected = true;
      _statusController?.add('connected');
      return;
    }
    
    // 연결 대기 (최대 30초)
    int attempts = 0;
    while (!_socket!.connected && attempts < 300) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      
      // 연결 상태 로깅
      if (attempts % 50 == 0) {
        print('플메 Socket.io 연결 대기 중... (${attempts * 100}ms)');
      }
    }
    
    if (!_socket!.connected) {
      print('플메 Socket.io 연결 시간 초과 (30초)');
      throw Exception('Socket.io 연결 시간 초과');
    }
  }

  // 플메 채팅방 입장
  void _sendJoinMatching(String matchingId, String userId) {
    if (_socket != null && _socket!.connected) {
      final joinData = {
        'matchingId': int.parse(matchingId),
        'userId': int.parse(userId),
        'userNickname': '테스트유저', // TODO: 실제 사용자 정보 사용
        'isHost': true // TODO: 실제 호스트 여부 확인
      };
      
      _socket!.emit('join_matching', joinData);
      print('플메 채팅방 입장 요청: $matchingId');
    }
  }

  // 메시지 전송
  Future<void> sendMessage(ChatMessage message) async {
    if (!_isConnected || _socket == null || !_socket!.connected) {
      throw Exception('Socket.io가 연결되지 않았습니다.');
    }
    
    try {
      final messageData = {
        'content': message.message,
        'type': message.messageType,
        'imageUrl': message.imageUrl,
        'latitude': message.latitude,
        'longitude': message.longitude,
        'locationName': message.locationName,
      };
      
      _socket!.emit('send_message', messageData);
      print('플메 메시지 전송: ${message.message}');
      
      // 메시지 전송 성공시 채팅 리스트 갱신 이벤트 발행
      ChatEventBus.instance.emit(ChatMessageArrived(
        matchingId: message.matchingId,
        timestamp: message.createdAt,
      ));
      
    } catch (e) {
      print('플메 메시지 전송 실패: $e');
      rethrow;
    }
  }

  // 읽음 확인 전송
  Future<void> sendReadReceipt({
    required int matchingId,
    required int userId,
    required DateTime timestamp,
  }) async {
    if (!_isConnected || _socket == null || !_socket!.connected) {
      throw Exception('Socket.io가 연결되지 않았습니다.');
    }

    try {
      final readReceiptData = {
        'matchingId': matchingId,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
      };

      _socket!.emit('read_receipt', readReceiptData);
      print('플메 읽음 확인 전송: 사용자 $userId, 매칭 $matchingId');
    } catch (e) {
      print('플메 읽음 확인 전송 오류: $e');
      rethrow;
    }
  }

  // 연결 해제 (재연결 가능)
  Future<void> disconnect() async {
    _stopPingTimer();
    _stopReconnectTimer();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _isConnected = false;
    // 연결 정보는 유지 (재연결용)
    
    await _messageController?.close();
    await _statusController?.close();
    
    _messageController = null;
    _statusController = null;
    
    print('플메 Socket.io 연결 해제 완료');
  }

  // 완전 연결 해제 (재연결 안함)
  Future<void> disconnectCompletely() async {
    _stopPingTimer();
    _stopReconnectTimer();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _isConnected = false;
    _currentMatchingId = '';
    _currentUserId = '';
    
    await _messageController?.close();
    await _statusController?.close();
    
    _messageController = null;
    _statusController = null;
    
    print('플메 Socket.io 완전 연결 해제 완료');
  }

  // 핑 타이머 시작
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('ping');
      }
    });
  }

  // 핑 타이머 중지
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // 재연결 타이머 시작
  void _startReconnectTimer() {
    _stopReconnectTimer();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected && _currentMatchingId.isNotEmpty && _currentUserId.isNotEmpty) {
        print('플메 Socket.io 재연결 시도...');
        connect(_currentMatchingId, _currentUserId);
      }
    });
  }

  // 재연결 타이머 중지
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // 오류 처리
  void _handleError() {
    _isConnected = false;
    _statusController?.add('error');
    _startReconnectTimer();
  }

  // 연결 해제 처리
  void _handleDisconnection() {
    _isConnected = false;
    _statusController?.add('disconnected');
    _startReconnectTimer();
  }
}
