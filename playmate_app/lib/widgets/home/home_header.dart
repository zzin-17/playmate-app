import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../common/app_logo.dart';

class HomeHeader extends StatelessWidget {
  final bool isLoading;
  final int unreadNotificationCount;
  final VoidCallback onRefresh;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.isLoading,
    required this.unreadNotificationCount,
    required this.onRefresh,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const AppLogo(height: 31),
      centerTitle: true,
      leading: IconButton(
        icon: isLoading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : const Icon(Icons.refresh),
        onPressed: isLoading ? null : onRefresh,
        tooltip: '새로고침',
      ),
      actions: [
        // 알림 버튼
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              // 읽지 않은 알림 개수 표시 (0개일 때는 숨김)
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onNotificationTap,
          tooltip: '알림',
        ),
      ],
    );
  }
}
