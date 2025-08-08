import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _locationPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final permissions = await PermissionUtils.checkPermissions();
    setState(() {
      _locationPermissionGranted = permissions[Permission.location]?.isGranted ?? false;
      _notificationPermissionGranted = permissions[Permission.notification]?.isGranted ?? false;
    });
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);
    final granted = await PermissionUtils.requestLocationPermission(context);
    setState(() {
      _locationPermissionGranted = granted;
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);
    final granted = await PermissionUtils.requestNotificationPermission(context);
    setState(() {
      _notificationPermissionGranted = granted;
      _isLoading = false;
    });
  }

  void _continueToApp() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // 타이틀
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.sports_tennis,
                      color: AppColors.surface,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '권한 설정',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '더 나은 서비스를 위해\n권한을 허용해주세요',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // 위치 권한
              _buildPermissionCard(
                icon: Icons.location_on,
                title: '위치 권한',
                description: '근처의 테니스 코트와 사용자를 찾기 위해 필요합니다.',
                isGranted: _locationPermissionGranted,
                onRequest: _requestLocationPermission,
              ),
              
              const SizedBox(height: 16),
              
              // 알림 권한
              _buildPermissionCard(
                icon: Icons.notifications,
                title: '알림 권한',
                description: '매칭 요청과 중요한 알림을 받기 위해 필요합니다.',
                isGranted: _notificationPermissionGranted,
                onRequest: _requestNotificationPermission,
              ),
              
              const SizedBox(height: 32),
              
              // 계속하기 버튼
              AppButton(
                text: '계속하기',
                onPressed: _continueToApp,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 16),
              
              // 나중에 설정하기
              TextButton(
                onPressed: _continueToApp,
                child: Text(
                  '나중에 설정하기',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? AppColors.success : AppColors.cardBorder,
          width: isGranted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGranted ? AppColors.success : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isGranted ? AppColors.surface : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '허용됨',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            AppButton(
              text: '허용',
              type: ButtonType.secondary,
              onPressed: onRequest,
              width: 80,
              height: 36,
            ),
        ],
      ),
    );
  }
} 