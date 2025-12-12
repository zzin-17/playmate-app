import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../utils/permission_handler.dart' as permission_utils;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  bool? _notificationEnabled;
  bool? _matchingNotificationsEnabled;
  bool? _chatNotificationsEnabled;
  bool? _communityNotificationsEnabled;
  AuthorizationStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissionStatus();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationEnabled = prefs.getBool('notification_enabled') ?? true;
        _matchingNotificationsEnabled = prefs.getBool('matching_notifications_enabled') ?? true;
        _chatNotificationsEnabled = prefs.getBool('chat_notifications_enabled') ?? true;
        _communityNotificationsEnabled = prefs.getBool('community_notifications_enabled') ?? true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정을 불러오는데 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      setState(() {
        _permissionStatus = settings.authorizationStatus;
      });
    } catch (e) {
      // Firebase가 초기화되지 않은 경우
      final status = await Permission.notification.status;
      setState(() {
        _permissionStatus = status.isGranted 
            ? AuthorizationStatus.authorized 
            : AuthorizationStatus.denied;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    
    try {
      // FCM 권한 요청
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      setState(() {
        _permissionStatus = settings.authorizationStatus;
      });

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림 권한이 허용되었습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('임시 알림 권한이 허용되었습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      // Firebase가 초기화되지 않은 경우 permission_handler 사용
      if (mounted) {
        final granted = await permission_utils.PermissionUtils.requestNotificationPermission(context);
        if (granted && mounted) {
          await _checkPermissionStatus();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPermissionDeniedDialog() {
    final isIOS = !kIsWeb && Platform.isIOS;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알림 권한이 필요합니다'),
          content: Text(
            isIOS
                ? '매칭 요청, 채팅 메시지, 커뮤니티 활동 등 중요한 알림을 받기 위해 알림 권한이 필요합니다.\n\n'
                    '설정 앱에서:\n'
                    '1. "Playmate App"을 찾아주세요\n'
                    '2. "알림"을 선택해주세요\n'
                    '3. 알림을 허용해주세요'
                : '매칭 요청, 채팅 메시지, 커뮤니티 활동 등 중요한 알림을 받기 위해 알림 권한이 필요합니다.\n\n'
                    '설정에서 알림 권한을 허용해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(isIOS ? '설정 앱 열기' : '설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 저장에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 권한 상태 카드
                  _buildPermissionStatusCard(),
                  
                  const SizedBox(height: 24),
                  
                  // 알림 설정
                  if (_permissionStatus == AuthorizationStatus.authorized ||
                      _permissionStatus == AuthorizationStatus.provisional) ...[
                    _buildSectionTitle('알림 설정'),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: '알림 받기',
                      subtitle: '모든 알림을 받습니다',
                      value: _notificationEnabled ?? true,
                      onChanged: (value) {
                        setState(() => _notificationEnabled = value);
                        _saveSetting('notification_enabled', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: '매칭 알림',
                      subtitle: '매칭 요청, 확정, 취소 알림',
                      value: _matchingNotificationsEnabled ?? true,
                      enabled: _notificationEnabled ?? true,
                      onChanged: (value) {
                        setState(() => _matchingNotificationsEnabled = value);
                        _saveSetting('matching_notifications_enabled', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: '채팅 알림',
                      subtitle: '새로운 메시지 알림',
                      value: _chatNotificationsEnabled ?? true,
                      enabled: _notificationEnabled ?? true,
                      onChanged: (value) {
                        setState(() => _chatNotificationsEnabled = value);
                        _saveSetting('chat_notifications_enabled', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: '커뮤니티 알림',
                      subtitle: '댓글, 좋아요, 팔로우 알림',
                      value: _communityNotificationsEnabled ?? true,
                      enabled: _notificationEnabled ?? true,
                      onChanged: (value) {
                        setState(() => _communityNotificationsEnabled = value);
                        _saveSetting('community_notifications_enabled', value);
                      },
                    ),
                  ] else ...[
                    _buildSectionTitle('알림 설정'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '알림 권한을 허용하면 알림 설정을 관리할 수 있습니다.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (_permissionStatus) {
      case AuthorizationStatus.authorized:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = '알림 권한 허용됨';
        statusDescription = '모든 알림을 정상적으로 받을 수 있습니다.';
        break;
      case AuthorizationStatus.provisional:
        statusColor = Colors.orange;
        statusIcon = Icons.info;
        statusText = '임시 알림 권한';
        statusDescription = '조용한 알림 모드로 알림을 받고 있습니다.';
        break;
      case AuthorizationStatus.denied:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = '알림 권한 거부됨';
        statusDescription = '알림을 받을 수 없습니다. 설정에서 권한을 허용해주세요.';
        break;
      case AuthorizationStatus.notDetermined:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = '알림 권한 미확인';
        statusDescription = '알림 권한을 요청해주세요.';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = '알림 권한 상태 확인 중';
        statusDescription = '권한 상태를 확인하는 중입니다.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (_permissionStatus != AuthorizationStatus.authorized &&
              _permissionStatus != AuthorizationStatus.provisional) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('알림 권한 요청'),
              ),
            ),
            if (_permissionStatus == AuthorizationStatus.denied) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    openAppSettings();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(!kIsWeb && Platform.isIOS ? '설정 앱 열기' : '설정으로 이동'),
                ),
              ),
              if (!kIsWeb && Platform.isIOS) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '설정 앱에서 찾는 방법',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. 설정 앱 열기\n'
                        '2. 아래로 스크롤하여 "Playmate App" 찾기\n'
                        '3. "알림" 탭 선택\n'
                        '4. 알림 허용',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      value: enabled ? value : false,
      onChanged: enabled ? onChanged : null,
      activeTrackColor: AppColors.primary,
      activeThumbColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }
}

