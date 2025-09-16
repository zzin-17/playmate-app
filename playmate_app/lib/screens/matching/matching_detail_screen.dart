import 'package:flutter/material.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../services/matching_state_service.dart';
import '../../services/matching_data_service.dart';
import '../../services/user_service.dart';

import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';
import '../review/write_review_screen.dart';
import 'edit_matching_screen.dart';
import '../../services/matching_notification_service.dart';
import '../../widgets/tooltip_widget.dart';

class MatchingDetailScreen extends StatefulWidget {
  final Matching matching;
  final User currentUser;
  final VoidCallback? onMatchingUpdated;

  const MatchingDetailScreen({
    super.key,
    required this.matching,
    required this.currentUser,
    this.onMatchingUpdated,
  });

  @override
  State<MatchingDetailScreen> createState() => _MatchingDetailScreenState();
}

class _MatchingDetailScreenState extends State<MatchingDetailScreen> {
  bool _isLoading = false; // 데이터 로딩 상태
  String _currentMatchingStatus = 'recruiting'; // 현재 매칭 상태
  List<int> _confirmedUserIds = []; // 확정된 사용자 ID 목록
  bool _isFollowingHost = false; // 호스트 팔로우 상태

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    
    // 매칭 상태 서비스 초기화 및 리스너 등록
    final stateService = MatchingStateService();
    stateService.initializeMatchingState(widget.matching.id, widget.matching.status);
    
    // MatchingStateService에서 현재 상태 가져오기
    _currentMatchingStatus = stateService.getMatchingStatus(widget.matching.id);
    
    // 신청자 데이터 로드
    _loadApplicants();
    
    stateService.addStateChangeListener(widget.matching.id, _onMatchingStateChanged);
    
    print('매칭 상세 화면 초기화 완료: 상태=$_currentMatchingStatus, 확정된 사용자=$_confirmedUserIds');
  }

  @override
  void didUpdateWidget(MatchingDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 매칭 객체가 업데이트되면 UI 새로고침
    if (oldWidget.matching != widget.matching) {
      setState(() {
        _currentMatchingStatus = widget.matching.actualStatus;
      });
    }
  }

  // 호스트 팔로우 상태 확인
  Future<void> _checkFollowStatus() async {
    try {
      final userService = UserService();
      _isFollowingHost = await userService.isFollowing(widget.matching.host.id);
      print('호스트 팔로우 상태: $_isFollowingHost');
    } catch (e) {
      print('팔로우 상태 확인 실패: $e');
      _isFollowingHost = false;
    }
  }

  // 호스트 팔로우하기
  Future<void> _followHost() async {
    try {
      final userService = UserService();
      final success = await userService.followUser(widget.matching.host.id);
      
      if (success) {
        setState(() {
          _isFollowingHost = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.matching.host.nickname}님을 팔로우했습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('팔로우에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('팔로우 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('팔로우에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 사용자의 매칭 참여 상태 확인
  void _checkUserStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    // 팔로워 전용 매칭인 경우에만 팔로우 상태 확인
    if (widget.matching.isFollowersOnly) {
      await _checkFollowStatus();
    }

    try {
      // 호스트 여부 확인
      
      // 게스트로 참여 중인지 확인
      // if (widget.matching.guests != null) {
      //   _isParticipating = widget.matching.guests!.any((guest) => guest.id == currentUserId);
      // }
      
      // 신청 중인지 확인 (임시 로직)
      // _hasApplied = _applicants.any((applicant) => applicant['user'].id == currentUserId);
      
      // TODO: 실제 API 호출로 매칭 데이터 로딩
      await Future.delayed(const Duration(milliseconds: 1000)); // 로딩 시뮬레이션
      
    } catch (e) {
      print('매칭 데이터 로딩 실패: $e');
      // 에러 처리
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 매칭 상태 변경 리스너
  void _onMatchingStateChanged(String newStatus) {
    setState(() {
      _currentMatchingStatus = newStatus; // 현재 상태 업데이트
      
      // 매칭이 확정되면 모든 신청자를 확정된 사용자로 설정
      if (newStatus == 'confirmed' && _applicants.isNotEmpty) {
        _confirmedUserIds = _applicants.map((applicant) => applicant['user'].id as int).toList();
        print('확정된 사용자 설정: ${_confirmedUserIds}');
      } else if (newStatus == 'recruiting') {
        _confirmedUserIds.clear();
        print('확정된 사용자 초기화');
      }
      
      print('매칭 상태 변경됨: $newStatus');
    });
    
    // 취소 시 확정된 게스트들에게 알림 전송
    if (newStatus == 'cancelled') {
      _sendNotificationToConfirmedGuests('cancelled');
    }
    
    // 상위 화면에 매칭 업데이트 알림
    if (widget.onMatchingUpdated != null) {
      widget.onMatchingUpdated!();
    }
  }

  // 사용자가 확정된 사용자인지 확인
  bool _isConfirmedUser(int userId) {
    final isConfirmed = _confirmedUserIds.contains(userId);
    print('사용자 $userId 확정 여부 확인: $isConfirmed (확정된 사용자 목록: $_confirmedUserIds)');
    return isConfirmed;
  }
  
  // 신청자 목록 (API에서 로드)
  List<Map<String, dynamic>> _applicants = [];

  // 신청자 데이터 로드
  Future<void> _loadApplicants() async {
    try {
      // 현재는 매칭의 guests 데이터를 사용
      // 실제로는 별도의 신청자 API가 있어야 함
      if (widget.matching.guests != null && widget.matching.guests!.isNotEmpty) {
        _applicants = widget.matching.guests!.map((guest) => {
          'user': guest,
          'status': 'pending',
          'message': '신청했습니다.',
          'appliedAt': DateTime.now(),
        }).toList();
      } else {
        _applicants = [];
      }
      
      // 확정된 상태라면 모든 신청자를 확정된 사용자로 설정
      if (_currentMatchingStatus == 'confirmed' && _applicants.isNotEmpty) {
        _confirmedUserIds = _applicants.map((applicant) => applicant['user'].id as int).toList();
        print('신청자 로드: 확정된 사용자 설정: ${_confirmedUserIds}');
      }
      
      setState(() {});
      print('신청자 데이터 로드 완료: ${_applicants.length}명');
    } catch (e) {
      print('신청자 데이터 로드 실패: $e');
      _applicants = [];
    }
  }

  Widget _buildMatchingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_tennis,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.matching.courtName,
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.matching.actualStatus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(widget.matching.actualStatus),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow('날짜', _formatDate(widget.matching.date)),
          _buildInfoRow('시간', widget.matching.timeSlot),
          _buildInfoRow('구력', widget.matching.skillRangeText),
          _buildInfoRow('연령대', widget.matching.ageRangeText),
          _buildInfoRow('게임유형', widget.matching.gameTypeText),
          _buildInfoRow('모집인원', widget.matching.recruitCountText),
          if (_shouldShowConfirmedInfo()) _buildConfirmedInfoRow(),
          _buildInfoRow('게스트비용', '${widget.matching.guestCost?.toString() ?? '0'}원'),
          
          if (widget.matching.message != null && widget.matching.message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '호스트 메시지',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.matching.message!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 확정 정보를 표시할지 결정하는 함수
  bool _shouldShowConfirmedInfo() {
    final matching = widget.matching;
    return matching.confirmedCount > 0; // 확정된 인원이 있으면 표시
  }

  // 확정 인원 정보를 별도 행으로 표시하는 위젯
  Widget _buildConfirmedInfoRow() {
    final matching = widget.matching;
    final confirmedCount = matching.confirmedCount;
    final confirmedGenderText = matching.confirmedGenderCountText;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '확정인원',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${confirmedCount}명',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (confirmedGenderText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      confirmedGenderText,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 호스트 정보 섹션
  Widget _buildHostInfo() {
    final host = widget.matching.host;
    final isHost = widget.currentUser.email == host.email;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '호스트 정보',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // 호스트 안내 툴팁
              if (isHost && _currentMatchingStatus == 'recruiting')
                TooltipWidget(
                  message: '채팅에서 참여자들과 소통하고 매칭 확정 버튼으로 최종 확정하세요',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '안내',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 호스트 기본 정보
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  host.nickname.isNotEmpty ? host.nickname.substring(0, 1) : '사',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.nickname.isNotEmpty ? host.nickname : '사용자',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '구력 ${host.experienceText}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 프로필 보기 버튼
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        user: host,
                        isHost: true,
                      ),
                    ),
                  );
                },
                child: Text(
                  '프로필 보기',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 호스트 점수 정보
          Row(
            children: [
              // NTRP 점수
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'NTRP',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${host.ntrpScore?.toStringAsFixed(1) ?? '-'}',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 매너 점수
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '매너',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${host.mannerScore?.toStringAsFixed(1) ?? '-'}',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 후기 개수
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '후기',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${host.reviewCount ?? 0}',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantsSection() {
    // 호스트인지 확인 (이메일 기반으로 변경)
    final isHost = widget.currentUser.email == widget.matching.host.email;
    
    print('🔍 신청자 목록 권한 체크:');
    print('  - 현재 사용자 ID: ${widget.currentUser.id}');
    print('  - 현재 사용자 이메일: ${widget.currentUser.email}');
    print('  - 현재 사용자 닉네임: ${widget.currentUser.nickname}');
    print('  - 호스트 ID: ${widget.matching.host.id}');
    print('  - 호스트 이메일: ${widget.matching.host.email}');
    print('  - 호스트 닉네임: ${widget.matching.host.nickname}');
    print('  - isHost: $isHost');
    print('  - 신청자 수: ${_applicants.length}');
    
    // 호스트가 아니면 신청자 수만 표시
    if (!isHost) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '신청자 목록',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_applicants.length}명 신청',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '신청자 목록',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_applicants.length}명 신청',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_applicants.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '아직 신청자가 없습니다',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '채팅을 통해 참여자를 모집해보세요',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _applicants.length,
              itemBuilder: (context, index) {
                final applicant = _applicants[index];
                return _buildApplicantCard(applicant);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    final user = applicant['user'] as User;
    final message = applicant['message'] as String;
    
    // 현재 상태에 따른 상태 결정
    String currentStatus;
    if (_currentMatchingStatus == 'confirmed' && _isConfirmedUser(user.id)) {
      currentStatus = 'confirmed';
    } else {
      currentStatus = 'pending';
    }
    
    print('신청자 ${user.nickname} (ID: ${user.id}) 상태 결정: $currentStatus (매칭 상태: $_currentMatchingStatus)');
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              user: user,
              isHost: false,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    user.nickname.substring(0, 1),
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '구력 ${_getSkillLevelText(user.skillLevel)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${user.genderText}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: AppColors.ratingStar,
                              ),
                              Text(
                                '${user.mannerScore?.toStringAsFixed(1) ?? "0.0"}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 상태 배지 (하나만 표시)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getApplicantStatusColor(currentStatus),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getApplicantStatusText(currentStatus),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            
            // 호스트만 채팅하기 버튼 표시 (상태와 관계없이)
            if (widget.currentUser.email == widget.matching.host.email) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: '채팅하기',
                  icon: Icons.chat,
                  type: ButtonType.secondary,
                  onPressed: () {
                    if (widget.currentUser.id == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그인이 필요합니다.')),
                      );
                      Navigator.of(context).pushNamed('/login');
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          matching: widget.matching,
                          currentUser: widget.currentUser,
                          chatPartner: user, // 채팅 상대방 정보 전달
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 확정된 게스트 목록 섹션
  /*
  Widget _buildConfirmedGuestsSection() { // 사용되지 않음
    // 호스트인지 확인
    final isHost = widget.currentUser.email == widget.matching.host.email;
    
    // 호스트가 아니거나 확정된 게스트가 없으면 빈 컨테이너 반환
    if (!isHost || widget.matching.confirmedCount == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '확정된 참여자',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.matching.confirmedCount}명 확정',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 확정된 게스트 목록
          _buildConfirmedGuestsList(),
          
          const SizedBox(height: 16),
          
          // 안내 메시지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '개별 참여자의 확정을 취소하면 해당 자리를 다시 모집할 수 있습니다',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 확정된 게스트 목록 위젯
  Widget _buildConfirmedGuestsList() {
    // 실제로는 API에서 확정된 게스트 정보를 가져와야 함
    // 현재는 mock 데이터 사용
    final confirmedGuests = _getMockConfirmedGuests();
    
    if (confirmedGuests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                '확정된 참여자가 없습니다',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: confirmedGuests.map((guest) => _buildConfirmedGuestCard(guest)).toList(),
    );
  }
  */

  // 확정된 게스트 카드 위젯
  Widget _buildConfirmedGuestCard(Map<String, dynamic> guest) {
    final user = guest['user'] as User;
    final confirmedAt = guest['confirmedAt'] as DateTime;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // 프로필 아바타
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.success.withValues(alpha: 0.1),
            child: Text(
              user.nickname.isNotEmpty ? user.nickname.substring(0, 1) : '사',
              style: AppTextStyles.body.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 게스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '확정: ${_formatDateTime(confirmedAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 확정 취소 버튼
          IconButton(
            onPressed: () => _showUnconfirmDialog(user),
            icon: Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: 20,
            ),
            tooltip: '확정 취소',
          ),
        ],
      ),
    );
  }

  // 확정 취소 확인 다이얼로그
  void _showUnconfirmDialog(User guest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('확정 취소 확인'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${guest.nickname}님의 참여 확정을 취소하시겠습니까?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '확정 취소 후 해당 자리를 다시 모집할 수 있습니다',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unconfirmGuest(guest);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('확정 취소'),
            ),
          ],
        );
      },
    );
  }

  // 게스트 확정 취소 처리
  void _unconfirmGuest(User guest) {
    // TODO: 실제 API 호출로 확정 취소 처리
    // 현재는 UI만 업데이트
    
    setState(() {
      // mock 데이터에서 해당 게스트 제거
      // 실제로는 matching.confirmedUserIds에서 제거
    });
    
    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${guest.nickname}님의 참여 확정이 취소되었습니다'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // 매칭 상태 재계산 필요
    // TODO: 매칭 상태를 다시 계산하여 UI 업데이트
  }

  // Mock 확정된 게스트 데이터
  List<Map<String, dynamic>> _getMockConfirmedGuests() {
    // 실제로는 API에서 가져와야 함
    return [
      {
        'user': User(
          id: 5,
          email: 'guest1@example.com',
          nickname: '테니스러버',
          gender: 'male',
          birthYear: 1992,
          startYearMonth: '2020-03',
          skillLevel: 3,
          mannerScore: 4.2,
          ntrpScore: 3.8,
          reviewCount: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        'confirmedAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'user': User(
          id: 6,
          email: 'guest2@example.com',
          nickname: '테니스초보',
          gender: 'female',
          birthYear: 1995,
          startYearMonth: '2023-01',
          skillLevel: 2,
          mannerScore: 4.5,
          ntrpScore: 2.5,
          reviewCount: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        'confirmedAt': DateTime.now().subtract(const Duration(hours: 1)),
      },
    ];
  }

  // 날짜/시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }





  Color _getStatusColor(String status) {
    switch (status) {
      case 'recruiting':
        return AppColors.primary;
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'deleted':
        return AppColors.textSecondary;
      case 'full':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'recruiting':
        return '모집중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      case 'deleted':
        return '삭제됨';
      case 'full':
        return '마감';
      default:
        return '알 수 없음';
    }
  }

  Color _getApplicantStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
              case 'rejected':
          return AppColors.error;
        case 'confirmed':
          return AppColors.success;
        default:
          return AppColors.textSecondary;
    }
  }

  String _getApplicantStatusText(String status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'approved':
        return '승인됨';
              case 'rejected':
          return '거절됨';
        case 'confirmed':
          return '확정';
        default:
          return '알 수 없음';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일 (${_getDayOfWeek(date.weekday)})';
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }

  /*
  String _getGenderText(String gender) { // 사용되지 않음
    switch (gender) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      case 'any':
        return '성별 무관';
      default:
        return '알 수 없음';
    }
  }
  */

  String _getSkillLevelText(int? skillLevel) {
    switch (skillLevel) {
      case 1:
        return '1년';
      case 2:
        return '2년';
      case 3:
        return '3년';
      case 4:
        return '4년';
      case 5:
        return '5년';
      default:
        return '미설정';
    }
  }


  
  @override
  Widget build(BuildContext context) {

    final isHost = widget.currentUser.email == widget.matching.host.email;
    
    // 매칭 상태 확인
    final matchingStatus = widget.matching.status;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.matching.courtName),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          // 호스트만 수정/삭제 메뉴 표시 (모집중, 확정 상태에서만)
          if (isHost && (matchingStatus == 'recruiting' || matchingStatus == 'confirmed'))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editMatching();
                    break;
                  case 'delete':
                    _showDeleteDialog();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: 매칭 상세 정보 표시
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '매칭 정보를 불러오는 중...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMatchingInfo(),
                        _buildHostInfo(),
                        const SizedBox(height: 24),
                        _buildApplicantsSection(),
                      ],
                    ),
                  ),
                ),
                // 하단 고정 버튼 (게스트만 표시)
                if (!isHost) _buildBottomButtons(),
              ],
            ),
    );
  }


  // 하단 버튼들 위젯
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
              child: Column(
          children: [
            // 상태별 안내 메시지
            _buildStatusMessage(),
            const SizedBox(height: 16),
            
            // 상태별 버튼
            Row(
              children: _buildActionButtons(),
            ),
          ],
        ),
    );
  }


  // 채팅 시작 함수
  Future<void> _startChat() async {
    final isHost = widget.currentUser.email == widget.matching.host.email;
    final isApplicant = _applicants.any((applicant) => applicant['user'].email == widget.currentUser.email);
    
    print('🔍 채팅 권한 체크:');
    print('  - 현재 사용자 ID: ${widget.currentUser.id}');
    print('  - 현재 사용자 이메일: ${widget.currentUser.email}');
    print('  - 현재 사용자 닉네임: ${widget.currentUser.nickname}');
    print('  - 호스트 ID: ${widget.matching.host.id}');
    print('  - 호스트 이메일: ${widget.matching.host.email}');
    print('  - 호스트 닉네임: ${widget.matching.host.nickname}');
    print('  - isHost: $isHost');
    print('  - isApplicant: $isApplicant');
    
    // 권한 체크: 
    // 1. 호스트는 항상 채팅 가능
    // 2. 팔로워만 모집인 경우: 팔로워이거나 신청자여야 함
    // 3. 일반 모집인 경우: 누구나 호스트와 1:1 채팅 가능
    if (!isHost) {
      if (widget.matching.isFollowersOnly) {
        // 팔로워만 모집인 경우: 팔로워이거나 신청자여야 함
        if (!_isFollowingHost && !isApplicant) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('팔로워만 모집입니다. 호스트를 팔로우하거나 신청해주세요.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
      // 일반 모집인 경우: 추가 권한 체크 없음 (누구나 호스트와 1:1 채팅 가능)
    }
    
    // 호스트인 경우: 첫 번째 신청자와 채팅 (신청자가 있는 경우)
    // 게스트인 경우: 호스트와 채팅
    User? chatPartner;
    
    if (isHost) {
      // 호스트: 첫 번째 신청자와 채팅
      if (_applicants.isNotEmpty) {
        chatPartner = _applicants.first['user'] as User;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신청자가 없습니다.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    } else {
      // 게스트: 호스트와 채팅
      chatPartner = widget.matching.host;
      
      // 게스트가 채팅을 시작하면 신청자로 등록
      await _applyToMatching();
    }
    
    // 채팅 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matching: widget.matching,
          currentUser: widget.currentUser,
          chatPartner: chatPartner, // 채팅 상대방 정보 전달
        ),
      ),
    );
  }





  // 상태별 안내 메시지 생성
  Widget _buildStatusMessage() {
    final status = _currentMatchingStatus;
    final isHost = widget.matching.host.email == widget.currentUser.email;
    
    switch (status) {
      case 'recruiting':
        if (isHost) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '게스트를 모집 중입니다. 채팅을 통해 참여자를 확정해주세요.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.accent,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_add, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이 매칭에 참여하고 싶으시다면 채팅을 시작해보세요!',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
      case 'confirmed':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '매칭이 확정되었습니다! 게임을 즐기세요.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.success,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'completed':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.sports_tennis, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '게임이 완료되었습니다. 후기를 작성해보세요!',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'cancelled':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '이 매칭은 취소되었습니다.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  // 상태별 액션 버튼 생성
  List<Widget> _buildActionButtons() {
    final status = _currentMatchingStatus;
    final isHost = widget.matching.host.email == widget.currentUser.email;
    
    switch (status) {
      case 'recruiting':
        // 모집중: 호스트는 항상 채팅 가능, 게스트는 매칭 타입에 따라
        if (isHost) {
          return [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _startChat(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonChat,
                  foregroundColor: AppColors.textSurface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '채팅하기',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        } else {
          // 게스트: 팔로워 전용 매칭인지 확인
          if (widget.matching.isFollowersOnly) {
            // 팔로워 전용 매칭: 팔로우 상태에 따라 채팅 버튼 활성화/비활성화
            if (_isFollowingHost) {
              return [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startChat(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonChat,
                      foregroundColor: AppColors.textSurface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '채팅하기',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            } else {
              return [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _followHost(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '팔로우하기',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            }
          } else {
            // 일반 매칭: 팔로우 상태와 관계없이 채팅 가능
            return [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startChat(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonChat,
                    foregroundColor: AppColors.textSurface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '채팅하기',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          }
        }
        
      case 'confirmed':
        // 확정: 호스트와 게스트 모두 채팅 가능, 호스트는 완료 처리도 가능
        if (isHost) {
          return [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _startChat(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonChat,
                  foregroundColor: AppColors.textSurface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '채팅하기',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                onPressed: () => _completeMatching(),
                text: '매칭 완료',
                type: ButtonType.primary,
              ),
            ),
          ];
        } else {
          // 게스트: 팔로워 전용 매칭인지 확인
          if (widget.matching.isFollowersOnly) {
            // 팔로워 전용 매칭: 팔로우 상태에 따라 채팅 버튼 활성화/비활성화
            if (_isFollowingHost) {
              return [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startChat(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonChat,
                      foregroundColor: AppColors.textSurface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '채팅하기',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            } else {
              return [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _followHost(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '팔로우하기',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            }
          } else {
            // 일반 매칭: 팔로우 상태와 관계없이 채팅 가능
            return [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startChat(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonChat,
                    foregroundColor: AppColors.textSurface,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '채팅하기',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          }
        }
        
      case 'completed':
        // 완료: 호스트와 게스트 모두 후기 작성 가능
        return [
          Expanded(
            child: AppButton(
              onPressed: () => _writeReview(),
              text: '후기 작성',
              type: ButtonType.secondary,
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

  // 매칭 수정 함수
  void _editMatching() {
    // 매칭 수정 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMatchingScreen(
          matching: widget.matching,
          onMatchingUpdated: () {
            // 매칭 수정 후 상세화면 새로고침
            setState(() {});
          },
        ),
      ),
    );
  }

  // 확정된 게스트들에게 알림 전송
  void _sendNotificationToConfirmedGuests(String newStatus) {
    try {
      final notificationService = MatchingNotificationService();
      
      // 취소 또는 삭제 사유 설정
      String reason = newStatus == 'cancelled' ? '호스트에 의한 취소' : '호스트에 의한 삭제';
      
      // 매칭 취소/삭제 알림 생성
      notificationService.createMatchingCancelledNotification(
        widget.matching, 
        widget.currentUser, 
        reason
      );
      
      print('확정된 게스트들에게 ${newStatus} 알림 전송 완료: ${widget.matching.courtName}');
    } catch (e) {
      print('알림 전송 오류: $e');
    }
  }

  // 매칭 삭제 확인 다이얼로그
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('매칭 삭제'),
          content: const Text(
            '정말로 이 매칭을 삭제하시겠습니까?\n\n'
            '삭제된 매칭은 복구할 수 없습니다.\n'
            '채팅 내용은 보존됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMatching();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 매칭 삭제 실행
  Future<void> _deleteMatching() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await MatchingDataService.deleteMatching(widget.matching.id);
      
      if (success) {
        // 확정된 게스트들에게 삭제 알림 전송
        _sendNotificationToConfirmedGuests('deleted');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('매칭이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // 상세 화면에서 나가기
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('매칭 삭제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 후기 작성 함수
  void _writeReview() {
    // 후기 작성 화면으로 이동
    // 현재 사용자가 호스트인지 게스트인지에 따라 대상자 결정
    final isHost = widget.matching.host.email == widget.currentUser.email;
    final targetUser = isHost 
        ? (widget.matching.guests?.isNotEmpty == true ? widget.matching.guests!.first : widget.currentUser)
        : widget.matching.host;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          matching: widget.matching,
          targetUser: targetUser,
        ),
      ),
    );
  }

  // 매칭 신청 함수 (채팅 시작 시 자동 호출)
  Future<void> _applyToMatching() async {
    try {
      // 이미 신청자인지 확인
      final isAlreadyApplied = _applicants.any((applicant) => 
        applicant['user'].email == widget.currentUser.email);
      
      if (!isAlreadyApplied) {
        // 신청자 목록에 추가
        _applicants.add({
          'user': widget.currentUser,
          'message': '채팅을 통해 참여 신청',
          'appliedAt': DateTime.now(),
        });
        
        // UI 업데이트
        setState(() {});
        
        print('✅ 매칭 신청 완료: ${widget.currentUser.nickname}');
      }
    } catch (e) {
      print('❌ 매칭 신청 실패: $e');
    }
  }

  // 매칭 참여 함수 (사용되지 않음)
  /*
  void _joinMatching() async {
    // final success = await MatchingService().joinMatching(widget.matching, widget.currentUser);
    final success = false; // 임시로 false 반환
    if (success) {
      setState(() {
        // _isParticipating = true;
        // _hasApplied = false;
      });
      
      // 실제 운영환경에서는 API 호출로 백엔드가 자동 처리함
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매칭에 참여했습니다!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매칭 참여에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  */

  // 매칭 취소 함수 (사용되지 않음)
  /*
  void _cancelMatching() async {
    // final success = await MatchingService().cancelMatching(widget.matching, widget.currentUser);
    final success = false; // 임시로 false 반환
    if (success) {
      setState(() {
        // _isParticipating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매칭 참여가 취소되었습니다.'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매칭 취소에 실패했습니다. 다시 시도해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  */

  // 매칭 완료 함수
  void _completeMatching() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매칭 완료'),
        content: const Text('이 매칭을 완료 상태로 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 매칭 상태를 'completed'로 변경하는 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('매칭이 완료되었습니다.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('완료'),
          ),
        ],
      ),
    );
  }
}