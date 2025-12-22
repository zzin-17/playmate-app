import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/matching.dart';
import '../models/user.dart';
import 'matching_data_service.dart';
import '../constants/app_colors.dart';
import 'matching_notification_service.dart';
import 'api_service.dart';
import 'chat_service.dart';

class MatchingService {
  static final MatchingService _instance = MatchingService._internal();
  factory MatchingService() => _instance;
  MatchingService._internal();

  /// 인증 토큰 가져오기
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      return null;
    }
  }

  // 매칭 상태 변경 메서드들
  Future<bool> joinMatching(Matching matching, User user) async {
    try {
      // 실제 API 호출로 매칭 참여 처리
      final token = await _getAuthToken();
      if (token != null) {
        await ApiService.requestMatching(matching.id, '참여 신청합니다!', token);
        
        // 성공시 채팅방 생성 요청
        print('🔍 채팅방 생성 요청 시작: 매칭 ID ${matching.id}, 호스트 ${matching.host.id}, 게스트 ${user.id}');
        final chatService = ChatService();
        final chatRoomCreated = await chatService.createChatRoom(matching.id, matching.host, user);
        print('🔍 채팅방 생성 결과: $chatRoomCreated');
        
        return true;
      }
      return false;
    } catch (e) {
      print('매칭 참여 실패: $e');
      return false;
    }
  }

  Future<bool> cancelMatching(Matching matching, User user) async {
    try {
      // 실제 API 호출로 매칭 취소 처리
      final result = await MatchingDataService.updateMatchingStatus(
        matching.id,
        'cancelled',
      );
      
      return result != null;
    } catch (e) {
      print('매칭 취소 실패: $e');
      return false;
    }
  }

  Future<bool> confirmGuest(Matching matching, User guest) async {
    try {
      // 실제 API 호출로 게스트 확정 처리
      final result = await MatchingDataService.respondToMatching(
        matchingId: matching.id,
        requestUserId: guest.id,
        action: 'accept',
      );
      
      return result;
    } catch (e) {
      print('게스트 확정 실패: $e');
      return false;
    }
  }

  Future<bool> rejectGuest(Matching matching, User guest) async {
    try {
      // 실제 API 호출로 게스트 거절 처리
      final result = await MatchingDataService.respondToMatching(
        matchingId: matching.id,
        requestUserId: guest.id,
        action: 'reject',
      );
      
      return result;
    } catch (e) {
      print('게스트 거절 실패: $e');
      return false;
    }
  }

  Future<bool> completeMatching(Matching matching) async {
    try {
      // 실제 API 호출로 매칭 완료 처리
      final result = await MatchingDataService.updateMatchingStatus(
        matching.id,
        'completed',
      );
      
      return result != null;
    } catch (e) {
      print('매칭 완료 실패: $e');
      return false;
    }
  }

  Future<bool> cancelMatchingByHost(Matching matching) async {
    try {
      // 실제 API 호출로 호스트가 매칭 취소 처리
      final result = await MatchingDataService.updateMatchingStatus(
        matching.id,
        'cancelled',
      );
      
      return result != null;
    } catch (e) {
      print('매칭 취소 실패: $e');
      return false;
    }
  }

  // ID로 매칭 조회
  Future<Matching?> getMatchingById(int matchingId) async {
    try {
      // 실제 API 호출로 매칭 조회
      return await MatchingDataService.getMatchingDetail(matchingId);
    } catch (e) {
      print('매칭 조회 실패: $e');
      return null;
    }
  }


  // 매칭 참여 시 호스트에게 알림 생성
  Future<bool> joinMatchingWithNotification(Matching matching, User guest) async {
    try {
      // 매칭 참여 처리
      final success = await joinMatching(matching, guest);
      
      if (success) {
        // 호스트에게 새로운 채팅 알림 생성
        final notificationService = MatchingNotificationService();
        notificationService.createNewChatNotification(matching, matching.host, guest);
        
        if (kDebugMode) {
          print('새로운 채팅 알림 생성: ${guest.nickname}님이 ${matching.courtName}에 참여');
        }
      }
      
      return success;
    } catch (e) {
      print('매칭 참여 실패: $e');
      return false;
    }
  }

  // 매칭 상태별 액션 버튼 생성
  List<Widget> buildActionButtons(
    BuildContext context,
    Matching matching,
    User currentUser,
    bool isParticipating,
    bool isHost,
    VoidCallback onJoin,
    VoidCallback onCancel,
    VoidCallback onComplete,
    VoidCallback onStartChat,
  ) {
    switch (matching.status) {
      case 'recruiting':
        if (isHost) {
          // 호스트: 매칭 취소, 게스트 관리 버튼
          return [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showCancelMatchingDialog(context, onCancel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                child: const Text('매칭 취소'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showGuestManagement(context, matching),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('게스트 관리'),
              ),
            ),
          ];
        } else if (isParticipating) {
          // 게스트: 참여 취소 버튼
          return [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showCancelParticipationDialog(context, onCancel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                child: const Text('참여 취소'),
              ),
            ),
          ];
        } else {
          // 일반 사용자: 참여 신청 버튼
          return [
            Expanded(
              child: ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('참여 신청'),
              ),
            ),
          ];
        }

      case 'confirmed':
        // 확정: 채팅 시작, 매칭 완료 버튼
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: onStartChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonChat,
                foregroundColor: Colors.white,
              ),
              child: const Text('채팅 시작'),
            ),
          ),
          if (isHost) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showCompleteMatchingDialog(context, onComplete),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('매칭 완료'),
              ),
            ),
          ],
        ];

      case 'completed':
        // 완료: 후기 작성 버튼
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showWriteReviewDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('후기 작성'),
            ),
          ),
        ];

      case 'cancelled':
        // 취소: 버튼 없음
        return [];

      default:
        return [];
    }
  }

  // 매칭 취소 확인 다이얼로그
  void _showCancelMatchingDialog(BuildContext context, VoidCallback onCancel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매칭 취소'),
        content: const Text('정말로 이 매칭을 취소하시겠습니까?\n이미 참여한 게스트들에게 알림이 발송됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // 참여 취소 확인 다이얼로그
  void _showCancelParticipationDialog(BuildContext context, VoidCallback onCancel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('참여 취소'),
        content: const Text('정말로 이 매칭 참여를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // 매칭 완료 확인 다이얼로그
  void _showCompleteMatchingDialog(BuildContext context, VoidCallback onComplete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매칭 완료'),
        content: const Text('이 매칭을 완료 상태로 변경하시겠습니까?\n완료 후에는 후기 작성이 가능합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }

  // 게스트 관리 화면 표시
  // 참고: 게스트 관리 기능은 ImprovedMatchingDetailScreen의 Participants 탭에서 구현됨
  // 호스트는 신청자 목록을 보고 확정/거절할 수 있음
  void _showGuestManagement(BuildContext context, Matching matching) {
    // 게스트 관리는 매칭 상세 화면에서 처리됨
    // 별도 화면이 필요하면 여기에 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('게스트 관리는 매칭 상세 화면에서 가능합니다.'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  // 후기 작성 다이얼로그
  void _showWriteReviewDialog(BuildContext context) {
    // TODO: 후기 작성 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('후기 작성 화면으로 이동합니다!'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
