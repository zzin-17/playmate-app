import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class ConnectionMonitorService {
  static final ConnectionMonitorService _instance = ConnectionMonitorService._internal();
  factory ConnectionMonitorService() => _instance;
  ConnectionMonitorService._internal();

  Timer? _monitorTimer;
  bool _isConnected = true;
  DateTime? _lastSuccessfulConnection;
  int _consecutiveFailures = 0;
  
  // 연결 상태 스트림
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  
  // 연결 상태 getter
  bool get isConnected => _isConnected;
  DateTime? get lastSuccessfulConnection => _lastSuccessfulConnection;
  int get consecutiveFailures => _consecutiveFailures;

  // 연결 모니터링 시작
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_monitorTimer?.isActive == true) return;
    
    print('🔍 연결 상태 모니터링 시작 (${interval.inSeconds}초 간격)');
    
    _monitorTimer = Timer.periodic(interval, (_) {
      _checkConnection();
    });
    
    // 즉시 한 번 체크
    _checkConnection();
  }

  // 연결 모니터링 중지
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    print('🛑 연결 상태 모니터링 중지');
  }

  // 연결 상태 체크
  Future<void> _checkConnection() async {
    try {
      // 간단한 헬스체크 요청
      final response = await ApiService.get('/health').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('헬스체크 타임아웃', const Duration(seconds: 10));
        },
      );
      
      if (response.statusCode == 200) {
        _onConnectionSuccess();
      } else {
        _onConnectionFailure('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      _onConnectionFailure('연결 실패: $e');
    }
  }

  // 연결 성공 처리
  void _onConnectionSuccess() {
    if (!_isConnected) {
      print('✅ 서버 연결 복구됨');
      _isConnected = true;
      _connectionStatusController.add(true);
    }
    
    _lastSuccessfulConnection = DateTime.now();
    _consecutiveFailures = 0;
  }

  // 연결 실패 처리
  void _onConnectionFailure(String reason) {
    _consecutiveFailures++;
    
    if (_isConnected) {
      print('❌ 서버 연결 실패: $reason (연속 실패: $_consecutiveFailures회)');
      _isConnected = false;
      _connectionStatusController.add(false);
    } else {
      print('❌ 서버 연결 지속 실패: $reason (연속 실패: $_consecutiveFailures회)');
    }
  }

  // 수동 연결 테스트
  Future<bool> testConnection() async {
    try {
      await _checkConnection();
      return _isConnected;
    } catch (e) {
      print('❌ 수동 연결 테스트 실패: $e');
      return false;
    }
  }

  // 연결 상태 정보 가져오기
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'lastSuccessfulConnection': _lastSuccessfulConnection?.toIso8601String(),
      'consecutiveFailures': _consecutiveFailures,
      'isMonitoring': _monitorTimer?.isActive ?? false,
    };
  }

  // 리소스 정리
  void dispose() {
    stopMonitoring();
    _connectionStatusController.close();
  }
}

// 연결 상태 위젯에서 사용할 수 있는 헬퍼 클래스
class ConnectionStatusWidget extends StatefulWidget {
  final Widget child;
  final Widget? disconnectedWidget;
  final VoidCallback? onConnectionRestored;

  const ConnectionStatusWidget({
    super.key,
    required this.child,
    this.disconnectedWidget,
    this.onConnectionRestored,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  late StreamSubscription<bool> _connectionSubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _connectionSubscription = ConnectionMonitorService().connectionStatus.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
        
        if (isConnected && widget.onConnectionRestored != null) {
          widget.onConnectionRestored!();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected && widget.disconnectedWidget != null) {
      return widget.disconnectedWidget!;
    }
    
    return widget.child;
  }
}
