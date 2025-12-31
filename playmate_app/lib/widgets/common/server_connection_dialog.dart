import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// 서버 연결 실패 시 표시하는 안내 다이얼로그
class ServerConnectionDialog extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const ServerConnectionDialog({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '서버 연결 실패',
        style: AppTextStyles.h3,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '백엔드 서버에 연결할 수 없습니다.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          const Text(
            '서버를 시작하려면:',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const SelectableText(
              'cd playmate_backend\nnpm run dev:stable',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '서버가 실행 중인지 확인:',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const SelectableText(
              'curl http://localhost:3000/api/health',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: const Text('재시도'),
          ),
      ],
    );
  }

  /// 다이얼로그 표시
  static void show(BuildContext context, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ServerConnectionDialog(onRetry: onRetry),
    );
  }
}

