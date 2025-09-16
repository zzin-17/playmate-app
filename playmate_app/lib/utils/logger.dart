import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
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
    
    // TODO: 프로덕션에서는 로그를 파일이나 원격 서버에 저장
    if (!kDebugMode && level.index >= LogLevel.error.index) {
      // 프로덕션에서 에러 로그만 별도 처리
      _saveToFile(logMessage);
    }
  }
  
  static void _saveToFile(String message) {
    // TODO: 파일 저장 로직 구현
    // SharedPreferences나 파일 시스템을 사용하여 로그 저장
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
