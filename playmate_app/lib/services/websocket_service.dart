import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/chat_message.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocketChannel? _channel;
  StreamController<ChatMessage>? _messageController;
  StreamController<String>? _statusController;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  
  // 연결 상태
  bool _isConnected = false;
  String _currentMatchingId = '';
  
  // 싱글톤 패턴
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }
  
  WebSocketService._();
  
  // 메시지 스트림
  Stream<ChatMessage> get messageStream => _messageController?.stream ?? const Stream.empty();
  
  // 상태 스트림
  Stream<String> get statusStream => _statusController?.stream ?? const Stream.empty();
  
  // 연결 상태
  bool get isConnected => _isConnected;
  
  // WebSocket 연결
  Future<void> connect(String matchingId, String userId) async {
    if (_isConnected && _currentMatchingId == matchingId) {
      return; // 이미 같은 매칭에 연결되어 있음
    }
    
    // 기존 연결 해제
    await disconnect();
    
    try {
      // WebSocket URL (실제 서버 URL로 변경 필요)
      final wsUrl = 'ws://localhost:8080/ws/chat/$matchingId?userId=$userId';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _currentMatchingId = matchingId;
      
      // 메시지 컨트롤러 초기화
      _messageController = StreamController<ChatMessage>.broadcast();
      _statusController = StreamController<String>.broadcast();
      
      // 연결 상태 업데이트
      _isConnected = true;
      _statusController?.add('connected');
      
      // 메시지 수신 리스너
      _channel!.stream.listen(
        (data) {
          try {
            final messageData = jsonDecode(data);
            final message = ChatMessage.fromJson(messageData);
            _messageController?.add(message);
          } catch (e) {
            print('메시지 파싱 오류: $e');
          }
        },
        onError: (error) {
          print('WebSocket 오류: $error');
          _handleError();
        },
        onDone: () {
          print('WebSocket 연결 종료');
          _handleDisconnection();
        },
      );
      
      // 핑 타이머 시작 (연결 유지)
      _startPingTimer();
      
      print('WebSocket 연결 성공: $matchingId');
      
    } catch (e) {
      print('WebSocket 연결 실패: $e');
      _handleError();
    }
  }
  
  // 메시지 전송
  Future<void> sendMessage(ChatMessage message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket이 연결되지 않았습니다.');
    }
    
    try {
      final messageJson = jsonEncode(message.toJson());
      _channel!.sink.add(messageJson);
    } catch (e) {
      print('메시지 전송 오류: $e');
      rethrow;
    }
  }
  
  // 연결 해제
  Future<void> disconnect() async {
    _isConnected = false;
    _currentMatchingId = '';
    
    // 타이머 정리
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    
    // 채널 정리
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    
    // 컨트롤러 정리
    await _messageController?.close();
    await _statusController?.close();
    _messageController = null;
    _statusController = null;
    
    print('WebSocket 연결 해제 완료');
  }
  
  // 핑 타이머 시작
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
        } catch (e) {
          print('핑 전송 오류: $e');
          _handleError();
        }
      }
    });
  }
  
  // 오류 처리
  void _handleError() {
    _isConnected = false;
    _statusController?.add('error');
    
    // 자동 재연결 시도
    _scheduleReconnect();
  }
  
  // 연결 해제 처리
  void _handleDisconnection() {
    _isConnected = false;
    _statusController?.add('disconnected');
    
    // 자동 재연결 시도
    _scheduleReconnect();
  }
  
  // 재연결 스케줄링
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentMatchingId.isNotEmpty) {
        print('WebSocket 재연결 시도...');
        // 재연결 로직 (사용자 ID는 임시로 'reconnect' 사용)
        connect(_currentMatchingId, 'reconnect');
      }
    });
  }
  
  // 연결 상태 확인
  bool isConnectedToMatching(String matchingId) {
    return _isConnected && _currentMatchingId == matchingId;
  }
}
