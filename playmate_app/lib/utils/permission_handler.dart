import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionUtils {
  // 위치 권한 요청
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // 사용자가 영구적으로 거부한 경우 설정으로 이동
      _showPermissionDialog(
        context,
        '위치 권한이 필요합니다',
        '정확한 매칭을 위해 위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
        () => openAppSettings(),
      );
    } else {
      // 일시적으로 거부한 경우
      _showPermissionDialog(
        context,
        '위치 권한이 필요합니다',
        '근처의 테니스 코트와 사용자를 찾기 위해 위치 권한이 필요합니다.',
        () => requestLocationPermission(context),
      );
    }
    
    return false;
  }

  // 알림 권한 요청
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // 사용자가 영구적으로 거부한 경우 설정으로 이동
      _showPermissionDialog(
        context,
        '알림 권한이 필요합니다',
        '매칭 요청과 중요한 알림을 받기 위해 알림 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
        () => openAppSettings(),
      );
    } else {
      // 일시적으로 거부한 경우
      _showPermissionDialog(
        context,
        '알림 권한이 필요합니다',
        '매칭 요청과 중요한 알림을 받기 위해 알림 권한이 필요합니다.',
        () => requestNotificationPermission(context),
      );
    }
    
    return false;
  }

  // 카메라 권한 요청 (프로필 사진 업로드용)
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        '카메라 권한이 필요합니다',
        '프로필 사진 촬영을 위해 카메라 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
        () => openAppSettings(),
      );
    } else {
      _showPermissionDialog(
        context,
        '카메라 권한이 필요합니다',
        '프로필 사진 촬영을 위해 카메라 권한이 필요합니다.',
        () => requestCameraPermission(context),
      );
    }
    
    return false;
  }

  // 갤러리 권한 요청 (프로필 사진 선택용)
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    final status = await Permission.photos.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog(
        context,
        '갤러리 권한이 필요합니다',
        '프로필 사진 선택을 위해 갤러리 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
        () => openAppSettings(),
      );
    } else {
      _showPermissionDialog(
        context,
        '갤러리 권한이 필요합니다',
        '프로필 사진 선택을 위해 갤러리 권한이 필요합니다.',
        () => requestPhotosPermission(context),
      );
    }
    
    return false;
  }

  // 권한 상태 확인
  static Future<Map<Permission, PermissionStatus>> checkPermissions() async {
    return await [
      Permission.location,
      Permission.notification,
      Permission.camera,
      Permission.photos,
    ].request();
  }

  // 권한 다이얼로그 표시
  static void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 모든 권한 요청 (앱 시작 시)
  static Future<void> requestAllPermissions(BuildContext context) async {
    await requestLocationPermission(context);
    await requestNotificationPermission(context);
  }
} 