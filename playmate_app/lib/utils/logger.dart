import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  
  // 파일 저장 관련
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB
  static const int _maxLogFiles = 5; // 최대 5개 파일 유지
  static const String _logFileName = 'app_logs.txt';
  static Directory? _logDirectory;
  static File? _currentLogFile;
  static final List<String> _logBuffer = [];
  static Timer? _flushTimer;
  static const Duration _flushInterval = Duration(seconds: 5);
  
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }
  
  // 로그 디렉토리 초기화
  static Future<void> _initializeLogDirectory() async {
    if (_logDirectory != null) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logDirectory = Directory('${directory.path}/logs');
      
      if (!await _logDirectory!.exists()) {
        await _logDirectory!.create(recursive: true);
      }
      
      // 현재 로그 파일 설정
      _currentLogFile = File('${_logDirectory!.path}/$_logFileName');
      
      // 기존 로그 파일 정리
      await _cleanupOldLogs();
      
      // 주기적으로 버퍼 플러시
      _flushTimer = Timer.periodic(_flushInterval, (_) => _flushLogBuffer());
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로그 디렉토리 초기화 실패: $e');
      }
    }
  }
  
  // 오래된 로그 파일 정리
  static Future<void> _cleanupOldLogs() async {
    if (_logDirectory == null) return;
    
    try {
      final files = _logDirectory!.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('app_logs'))
          .toList();
      
      // 파일명으로 정렬 (오래된 것부터)
      files.sort((a, b) => a.path.compareTo(b.path));
      
      // 최대 개수 초과 시 오래된 파일 삭제
      if (files.length >= _maxLogFiles) {
        for (int i = 0; i < files.length - _maxLogFiles + 1; i++) {
          await files[i].delete();
        }
      }
      
      // 현재 로그 파일 크기 확인
      if (_currentLogFile != null && await _currentLogFile!.exists()) {
        final size = await _currentLogFile!.length();
        if (size > _maxLogFileSize) {
          // 파일 크기가 초과하면 새 파일로 로테이션
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newFileName = 'app_logs_$timestamp.txt';
          await _currentLogFile!.copy('${_logDirectory!.path}/$newFileName');
          await _currentLogFile!.delete();
          _currentLogFile = File('${_logDirectory!.path}/$_logFileName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로그 파일 정리 실패: $e');
      }
    }
  }
  
  // 로그 버퍼를 파일에 플러시
  static Future<void> _flushLogBuffer() async {
    if (_logBuffer.isEmpty || _currentLogFile == null) return;
    
    try {
      final logsToWrite = List<String>.from(_logBuffer);
      _logBuffer.clear();
      
      await _currentLogFile!.writeAsString(
        logsToWrite.join('\n') + '\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로그 파일 쓰기 실패: $e');
      }
    }
  }
  
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void _log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (level.index < _minLevel.index) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    final tagStr = tag != null ? '[$tag]' : '';
    final errorStr = error != null ? ' | Error: $error' : '';
    final stackStr = stackTrace != null ? ' | Stack: $stackTrace' : '';
    
    final logMessage = '[$timestamp] [$levelName] $tagStr $message$errorStr$stackStr';
    
    if (kDebugMode) {
      switch (level) {
        case LogLevel.debug:
          print('🐛 $logMessage');
          break;
        case LogLevel.info:
          print('ℹ️ $logMessage');
          break;
        case LogLevel.warning:
          print('⚠️ $logMessage');
          break;
        case LogLevel.error:
          print('❌ $logMessage');
          break;
        case LogLevel.fatal:
          print('💀 $logMessage');
          break;
      }
    }
    
    // 프로덕션에서는 에러 레벨 이상의 로그를 파일에 저장
    if (!kDebugMode && level.index >= LogLevel.error.index) {
      _saveToFile(logMessage);
    }
    
    // 디버그 모드에서도 에러 로그는 파일에 저장
    if (kDebugMode && level.index >= LogLevel.error.index) {
      _saveToFile(logMessage);
    }
  }
  
  static Future<void> _saveToFile(String message) async {
    try {
      await _initializeLogDirectory();
      
      if (_currentLogFile == null) return;
      
      // 버퍼에 추가 (주기적으로 플러시)
      _logBuffer.add(message);
      
      // 버퍼가 너무 크면 즉시 플러시
      if (_logBuffer.length >= 10) {
        await _flushLogBuffer();
      }
    } catch (e) {
      // 파일 저장 실패해도 앱은 계속 실행
      if (kDebugMode) {
        print('❌ 로그 파일 저장 실패: $e');
      }
    }
  }
  
  // 로그 파일 읽기 (디버깅용)
  static Future<String?> getLogFileContent() async {
    try {
      await _initializeLogDirectory();
      
      if (_currentLogFile == null || !await _currentLogFile!.exists()) {
        return null;
      }
      
      return await _currentLogFile!.readAsString();
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로그 파일 읽기 실패: $e');
      }
      return null;
    }
  }
  
  // 로그 파일 삭제
  static Future<void> clearLogs() async {
    try {
      await _initializeLogDirectory();
      
      if (_logDirectory == null) return;
      
      final files = _logDirectory!.listSync()
          .whereType<File>()
          .where((f) => f.path.contains('app_logs'))
          .toList();
      
      for (final file in files) {
        await file.delete();
      }
      
      _logBuffer.clear();
      _currentLogFile = File('${_logDirectory!.path}/$_logFileName');
    } catch (e) {
      if (kDebugMode) {
        print('❌ 로그 파일 삭제 실패: $e');
      }
    }
  }
  
  // 앱 종료 시 버퍼 플러시
  static Future<void> dispose() async {
    _flushTimer?.cancel();
    await _flushLogBuffer();
  }
  
  // API 호출 로깅
  static void apiRequest(String method, String url, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    debug('API Request: $method $url', tag: 'API');
    if (body != null) {
      debug('Request Body: $body', tag: 'API');
    }
    if (headers != null) {
      debug('Request Headers: $headers', tag: 'API');
    }
  }
  
  static void apiResponse(String method, String url, int statusCode, {String? body, Duration? duration}) {
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    
    if (statusCode >= 200 && statusCode < 300) {
      info('API Response: $method $url -> $statusCode$durationStr', tag: 'API');
    } else {
      error('API Response: $method $url -> $statusCode$durationStr', tag: 'API');
      if (body != null) {
        error('Response Body: $body', tag: 'API');
      }
    }
  }
  
  // 사용자 액션 로깅
  static void userAction(String action, {Map<String, dynamic>? data}) {
    info('User Action: $action', tag: 'USER');
    if (data != null) {
      debug('Action Data: $data', tag: 'USER');
    }
  }
  
  // 성능 측정
  static void performance(String operation, Duration duration) {
    if (duration.inMilliseconds > 1000) {
      warning('Slow Operation: $operation took ${duration.inMilliseconds}ms', tag: 'PERF');
    } else {
      debug('Operation: $operation took ${duration.inMilliseconds}ms', tag: 'PERF');
    }
  }
  
  // 네트워크 상태 로깅
  static void networkStatus(String status, {String? details}) {
    info('Network Status: $status', tag: 'NETWORK');
    if (details != null) {
      debug('Network Details: $details', tag: 'NETWORK');
    }
  }
  
  // 데이터베이스 로깅
  static void database(String operation, {String? table, int? recordCount}) {
    debug('DB Operation: $operation${table != null ? ' on $table' : ''}${recordCount != null ? ' ($recordCount records)' : ''}', tag: 'DB');
  }
  
  // 캐시 로깅
  static void cache(String operation, {String? key, bool? hit}) {
    final hitStr = hit != null ? (hit ? 'HIT' : 'MISS') : '';
    debug('Cache $operation: $key $hitStr', tag: 'CACHE');
  }
  
  // WebSocket 로깅
  static void websocket(String event, {String? data, bool? connected}) {
    if (connected != null) {
      info('WebSocket ${connected ? 'Connected' : 'Disconnected'}', tag: 'WS');
    } else {
      debug('WebSocket Event: $event${data != null ? ' - $data' : ''}', tag: 'WS');
    }
  }
  
  // 알림 로깅
  static void notification(String type, {String? title, String? body}) {
    info('Notification: $type', tag: 'NOTIFICATION');
    if (title != null) {
      debug('Title: $title', tag: 'NOTIFICATION');
    }
    if (body != null) {
      debug('Body: $body', tag: 'NOTIFICATION');
    }
  }
}
