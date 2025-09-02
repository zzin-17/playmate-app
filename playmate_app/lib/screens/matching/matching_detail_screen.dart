import 'package:flutter/material.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../services/matching_service.dart';
import '../../services/matching_state_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';
import '../review/write_review_screen.dart';

class MatchingDetailScreen extends StatefulWidget {
  final Matching matching;
  final User currentUser;

  const MatchingDetailScreen({
    super.key,
    required this.matching,
    required this.currentUser,
  });

  @override
  State<MatchingDetailScreen> createState() => _MatchingDetailScreenState();
}

class _MatchingDetailScreenState extends State<MatchingDetailScreen> {
  bool _isExpanded = false;
  bool _hasApplied = false;
  bool _isParticipating = false; // 매칭 참여 여부
  bool _isLoading = false; // 데이터 로딩 상태
  bool _isHost = false; // 호스트 여부
  String _currentMatchingStatus = 'recruiting'; // 현재 매칭 상태
  List<int> _confirmedUserIds = []; // 확정된 사용자 ID 목록

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    
    // 매칭 상태 서비스 초기화 및 리스너 등록
    final stateService = MatchingStateService();
    stateService.initializeMatchingState(widget.matching.id, widget.matching.status);
    
    // MatchingStateService에서 현재 상태 가져오기
    _currentMatchingStatus = stateService.getMatchingStatus(widget.matching.id);
    
    // 확정된 상태라면 모든 신청자를 확정된 사용자로 설정
    if (_currentMatchingStatus == 'confirmed' && _applicants.isNotEmpty) {
      _confirmedUserIds = _applicants.map((applicant) => applicant['user'].id as int).toList();
      print('초기화: 확정된 사용자 설정: ${_confirmedUserIds}');
    }
    
    stateService.addStateChangeListener(widget.matching.id, _onMatchingStateChanged);
    
    print('매칭 상세 화면 초기화 완료: 상태=$_currentMatchingStatus, 확정된 사용자=$_confirmedUserIds');
  }

  // 사용자의 매칭 참여 상태 확인
  void _checkUserStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = widget.currentUser.id;
      
      // 호스트 여부 확인
      _isHost = widget.matching.host.id == currentUserId;
      
      // 게스트로 참여 중인지 확인
      if (widget.matching.guests != null) {
        _isParticipating = widget.matching.guests!.any((guest) => guest.id == currentUserId);
      }
      
      // 신청 중인지 확인 (임시 로직)
      _hasApplied = _applicants.any((applicant) => applicant['user'].id == currentUserId);
      
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
  }

  // 사용자가 확정된 사용자인지 확인
  bool _isConfirmedUser(int userId) {
    final isConfirmed = _confirmedUserIds.contains(userId);
    print('사용자 $userId 확정 여부 확인: $isConfirmed (확정된 사용자 목록: $_confirmedUserIds)');
    return isConfirmed;
  }
  
  // 임시 신청자 데이터
  final List<Map<String, dynamic>> _applicants = [
    {
      'user': User(
        id: 3,
        email: 'applicant1@example.com',
        nickname: '테니스러버',
        skillLevel: 3,
        gender: 'male',
        birthYear: 1992,
        startYearMonth: '2020-03',
        mannerScore: 4.2,
        ntrpScore: 3.8,
        reviewCount: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'status': 'pending', // pending, approved, rejected
      'message': '안녕하세요! 같이 테니스 치고 싶습니다.',
      'appliedAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'user': User(
        id: 4,
        email: 'applicant2@example.com',
        nickname: '테니스초보',
        skillLevel: 2,
        gender: 'female',
        birthYear: 1995,
        startYearMonth: '2023-01',
        mannerScore: 4.5,
        ntrpScore: 2.5,
        reviewCount: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'status': 'pending',
      'message': '초보지만 열심히 하겠습니다!',
      'appliedAt': DateTime.now().subtract(const Duration(hours: 1)),
    },
  ];

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
                  color: _getStatusColor(_currentMatchingStatus),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(_currentMatchingStatus),
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
    // 호스트인지 확인
    final isHost = widget.currentUser.id == widget.matching.host.id;
    
    // 호스트가 아니면 빈 컨테이너 반환
    if (!isHost) {
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '채팅에서 매칭 확정 버튼을 눌러 참여자를 확정하세요',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
            if (widget.currentUser.id == widget.matching.host.id) ...[
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
  Widget _buildConfirmedGuestsSection() {
    // 호스트인지 확인
    final isHost = widget.currentUser.id == widget.matching.host.id;
    
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

  String _getGenderText(String gender) {
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
    // 데이터 검증
    if (widget.matching == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('매칭 상세'),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              SizedBox(height: 16),
              Text(
                '매칭 정보를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '잠시 후 다시 시도해주세요',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isHost = widget.currentUser.id == widget.matching.host.id;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.matching.courtName),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
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
                                                            if (isHost && _currentMatchingStatus == 'recruiting')
                    _buildHostGuidance(),
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

  Widget _buildHostGuidance() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '호스트 안내',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '채팅에서 참여자들과 소통하고 매칭 확정 버튼으로 최종 확정하세요',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 하단 버튼들 위젯
  Widget _buildBottomButtons() {
    final isHost = widget.currentUser.id == widget.matching.host.id;
    
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
  void _startChat() {
    // 채팅 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matching: widget.matching,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }





  // 상태별 안내 메시지 생성
  Widget _buildStatusMessage() {
    final status = _currentMatchingStatus;
    final isHost = widget.matching.host.id == widget.currentUser.id;
    
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
    final isHost = widget.matching.host.id == widget.currentUser.id;
    
    switch (status) {
      case 'recruiting':
        // 모집중: 게스트는 참여 신청, 호스트는 채팅
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
                      '참여 신청',
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
        
      case 'confirmed':
        // 확정: 호스트는 완료 처리, 게스트는 채팅
        if (isHost) {
          return [
            Expanded(
              child: AppButton(
                onPressed: () => _completeMatching(),
                text: '매칭 완료',
                type: ButtonType.primary,
              ),
            ),
          ];
        } else {
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
        
      case 'completed':
        // 완료: 후기 작성 버튼
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

  // 후기 작성 함수
  void _writeReview() {
    // 후기 작성 화면으로 이동
    // 현재 사용자가 호스트인지 게스트인지에 따라 대상자 결정
    final isHost = widget.matching.host.id == widget.currentUser.id;
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

  // 매칭 참여 함수
  void _joinMatching() async {
    final success = await MatchingService().joinMatching(widget.matching, widget.currentUser);
    if (success) {
      setState(() {
        _isParticipating = true;
        _hasApplied = false;
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

  // 매칭 취소 함수
  void _cancelMatching() async {
    final success = await MatchingService().cancelMatching(widget.matching, widget.currentUser);
    if (success) {
      setState(() {
        _isParticipating = false;
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