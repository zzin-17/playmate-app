import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 통합 에러 처리 유틸리티
/// 네트워크 오류, 서버 오류 등을 사용자 친화적인 메시지로 변환
class ErrorHandler {
  /// 에러를 사용자 친화적인 메시지로 변환
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) {
      return '알 수 없는 오류가 발생했습니다.';
    }

    final errorString = error.toString().toLowerCase();
    
    // 네트워크 연결 오류
    if (errorString.contains('connection refused') || 
        errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection aborted') ||
        errorString.contains('no internet connection')) {
      return '서버에 연결할 수 없습니다.\n네트워크 상태를 확인해주세요.';
    }
    
    // 타임아웃 오류
    if (errorString.contains('timeout') || 
        errorString.contains('timed out')) {
      return '요청 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.';
    }
    
    // 인증 오류
    if (errorString.contains('unauthorized') || 
        errorString.contains('401') ||
        errorString.contains('token') && errorString.contains('expired')) {
      return '로그인이 필요합니다.\n다시 로그인해주세요.';
    }
    
    // 권한 오류
    if (errorString.contains('forbidden') || 
        errorString.contains('403')) {
      return '접근 권한이 없습니다.';
    }
    
    // 리소스 없음
    if (errorString.contains('not found') || 
        errorString.contains('404')) {
      return '요청한 데이터를 찾을 수 없습니다.';
    }
    
    // 서버 오류
    if (errorString.contains('server error') || 
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return '서버에 일시적인 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.';
    }
    
    // API 예외 처리
    if (errorString.contains('apiexception')) {
      // ApiException의 메시지 추출
      final match = RegExp(r'apiexception:\s*(.+)', caseSensitive: false).firstMatch(errorString);
      if (match != null) {
        return match.group(1) ?? 'API 요청에 실패했습니다.';
      }
    }
    
    // 기본 메시지
    return '오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
  }

  /// 에러 타입 분류
  static ErrorType getErrorType(dynamic error) {
    if (error == null) return ErrorType.unknown;
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('connection refused') || 
        errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no internet connection')) {
      return ErrorType.network;
    }
    
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return ErrorType.timeout;
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return ErrorType.unauthorized;
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return ErrorType.forbidden;
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return ErrorType.notFound;
    }
    
    if (errorString.contains('server error') || 
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503')) {
      return ErrorType.server;
    }
    
    return ErrorType.unknown;
  }

  /// 에러에 따른 액션 버튼 표시 여부
  static bool shouldShowRetry(dynamic error) {
    final type = getErrorType(error);
    return type == ErrorType.network || 
           type == ErrorType.timeout || 
           type == ErrorType.server;
  }

  /// 에러에 따른 색상 반환
  static Color getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return AppColors.warning;
      case ErrorType.unauthorized:
      case ErrorType.forbidden:
        return AppColors.error;
      case ErrorType.server:
        return AppColors.warning;
      case ErrorType.notFound:
        return AppColors.textSecondary;
      case ErrorType.unknown:
        return AppColors.error;
    }
  }

  /// 에러 스낵바 표시
  static void showErrorSnackBar(
    BuildContext context, 
    dynamic error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 3),
  }) {
    final message = getUserFriendlyMessage(error);
    final type = getErrorType(error);
    final color = getErrorColor(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
        action: shouldShowRetry(error) && onRetry != null
            ? SnackBarAction(
                label: '재시도',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// 성공 스낵바 표시
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: duration,
      ),
    );
  }

  /// 정보 스낵바 표시
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: duration,
      ),
    );
  }
}

/// 에러 타입 열거형
enum ErrorType {
  network,      // 네트워크 연결 오류
  timeout,      // 타임아웃
  unauthorized, // 인증 오류
  forbidden,    // 권한 오류
  notFound,     // 리소스 없음
  server,       // 서버 오류
  unknown,       // 알 수 없는 오류
}

