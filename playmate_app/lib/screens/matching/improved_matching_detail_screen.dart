import 'package:flutter/material.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../services/matching_state_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';
import '../review/write_review_screen.dart';
import 'edit_matching_screen.dart';

class ImprovedMatchingDetailScreen extends StatefulWidget {
  final Matching matching;
  final User currentUser;
  final VoidCallback? onMatchingUpdated;

  const ImprovedMatchingDetailScreen({
    super.key,
    required this.matching,
    required this.currentUser,
    this.onMatchingUpdated,
  });

  @override
  State<ImprovedMatchingDetailScreen> createState() => _ImprovedMatchingDetailScreenState();
}

class _ImprovedMatchingDetailScreenState extends State<ImprovedMatchingDetailScreen> 
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _currentMatchingStatus = 'recruiting';
  List<int> _confirmedUserIds = [];
  bool _isFollowingHost = false;
  List<Map<String, dynamic>> _applicants = [];
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserStatus();
    _initializeMatchingState();
    _loadApplicants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMatchingState() {
    final stateService = MatchingStateService();
    stateService.initializeMatchingState(widget.matching.id, widget.matching.status);
    _currentMatchingStatus = stateService.getMatchingStatus(widget.matching.id);
    stateService.addStateChangeListener(widget.matching.id, _onMatchingStateChanged);
  }

  void _onMatchingStateChanged(String newStatus) {
    setState(() {
      _currentMatchingStatus = newStatus;
    });
  }

  Future<void> _checkUserStatus() async {
    try {
      final userService = UserService();
      _isFollowingHost = await userService.isFollowing(widget.matching.host.id);
    } catch (e) {
      print('팔로우 상태 확인 실패: $e');
      _isFollowingHost = false;
    }
  }

  Future<void> _loadApplicants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제 신청자 목록 API 연동
      // final matchingService = MatchingService();
      // final applicants = await matchingService.getMatchingApplicants(widget.matching.id);
      
      setState(() {
        _applicants = []; // 임시로 빈 리스트
        _isLoading = false;
      });
    } catch (e) {
      print('신청자 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            content: Text('${widget.matching.host.nickname}님 팔로우를 성공했습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로우 실패: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _unfollowHost() async {
    try {
      final userService = UserService();
      final success = await userService.unfollowUser(widget.matching.host.id);
      
      if (success) {
        setState(() {
          _isFollowingHost = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.matching.host.nickname}님 팔로우를 취소했습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로우 취소 실패: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool get isHost => widget.currentUser.id == widget.matching.host.id;
  bool get isExpired => widget.matching.date.isBefore(DateTime.now());
  bool get isFull => (widget.matching.maleRecruitCount + widget.matching.femaleRecruitCount) <= 
                     (widget.matching.guests?.length ?? 0);
  bool get isParticipant => widget.matching.guests?.any((guest) => guest.id == widget.currentUser.id) ?? false;
  bool get canWriteReview => isExpired && isParticipant && _currentMatchingStatus == 'completed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHost ? '내 매칭' : '매칭 상세'),
        actions: [
          if (isHost) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editMatching(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showHostMenu(),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '정보', icon: Icon(Icons.info_outline)),
            Tab(text: '참가자', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    '매칭 정보를 불러오는 중...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInfoTab(),
                      _buildParticipantsTab(),
                    ],
                  ),
                ),
                if (!isHost) _buildBottomButtons(),
              ],
            ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 매칭 상태 배지
        _buildStatusBadge(),
        const SizedBox(height: 16),
        
        // 매칭 기본 정보
        _buildMatchingInfo(),
        const SizedBox(height: 24),
        
        // 게임 정보
        _buildGameInfo(),
        const SizedBox(height: 24),
        
        // 호스트 정보
        _buildHostInfo(),
        const SizedBox(height: 24),
        
        // 메시지
        if (widget.matching.message?.isNotEmpty == true) ...[
          _buildMessageSection(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    if (isExpired) {
      badgeColor = AppColors.textSecondary;
      statusText = '종료됨';
      statusIcon = Icons.schedule;
    } else if (isFull) {
      badgeColor = AppColors.warning;
      statusText = '모집완료';
      statusIcon = Icons.check_circle;
    } else if (_currentMatchingStatus == 'confirmed') {
      badgeColor = AppColors.success;
      statusText = '확정됨';
      statusIcon = Icons.verified;
    } else {
      badgeColor = AppColors.primary;
      statusText = '모집중';
      statusIcon = Icons.person_add;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: badgeColor, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: AppTextStyles.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 코트명
            Text(
              widget.matching.courtName,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 날짜와 시간
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${widget.matching.date.month}월 ${widget.matching.date.day}일',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  widget.matching.timeSlot,
                  style: AppTextStyles.body2,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 위치 정보
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: LocationService().getDistrictFromCoordinates(
                      widget.matching.courtLat, 
                      widget.matching.courtLng
                    ),
                    builder: (context, snapshot) {
                      final location = snapshot.data ?? '위치 정보 없음';
                      return Text(
                        location,
                        style: AppTextStyles.body2,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 모집 인원 정보
            Row(
              children: [
                Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '남성 ${widget.matching.maleRecruitCount}명, 여성 ${widget.matching.femaleRecruitCount}명',
                  style: AppTextStyles.body2,
                ),
                const Spacer(),
                if (widget.matching.guestCost != null && widget.matching.guestCost! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.matching.guestCost}원',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '호스트',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (!isHost) ...[
                  IconButton(
                    onPressed: _isFollowingHost ? _unfollowHost : _followHost,
                    icon: Icon(
                      _isFollowingHost ? Icons.person_remove : Icons.person_add,
                      color: _isFollowingHost ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _viewHostProfile(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      widget.matching.host.nickname.isNotEmpty 
                        ? widget.matching.host.nickname[0].toUpperCase()
                        : '?',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
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
                          widget.matching.host.nickname,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '테니스 레벨 ${widget.matching.host.skillLevel}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '게임 정보',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildCompactInfoChip(Icons.sports_tennis, _getGameTypeLabel(widget.matching.gameType)),
                _buildCompactInfoChip(Icons.star, '${widget.matching.minLevel}~${widget.matching.maxLevel}년'),
                if (widget.matching.minAge != null && widget.matching.maxAge != null)
                  _buildCompactInfoChip(Icons.people, '${widget.matching.minAge}~${widget.matching.maxAge}세'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '호스트 메시지',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.matching.message!,
              style: AppTextStyles.body2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsTab() {
    if (isHost) {
      return _buildApplicantsList();
    } else {
      return _buildGuestsList();
    }
  }

  Widget _buildApplicantsList() {
    if (_applicants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              '아직 신청자가 없습니다',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _applicants.length,
      itemBuilder: (context, index) {
        final applicant = _applicants[index];
        return _buildApplicantCard(applicant);
      },
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    final user = applicant['user'] as User;
    final message = applicant['message'] as String;
    final isConfirmed = _confirmedUserIds.contains(user.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => _viewUserProfile(user),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _viewUserProfile(user),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nickname,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '레벨 ${user.skillLevel} • ${user.region}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.primary),
                  onPressed: () => _openChatWithUser(user),
                ),
                if (isConfirmed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '확정',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: AppTextStyles.body2,
                ),
              ),
            ],
            if (!isConfirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: '확정하기',
                  onPressed: () => _confirmApplicant(user.id),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsList() {
    final guests = widget.matching.guests ?? [];
    
    if (guests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              '아직 참가자가 없습니다',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...guests.map((guest) => _buildGuestCard(guest)),
        
        // 후기 작성 버튼 (조건: 참가자이고, 일정 종료되고, 매칭 완료된 경우)
        if (canWriteReview) ...[
          const SizedBox(height: 16),
          Card(
            color: AppColors.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.rate_review, size: 32, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    '매칭이 완료되었습니다',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '함께한 플레이어들에게 후기를 남겨주세요',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: '후기 작성하기',
                      onPressed: () => _writeReview(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuestCard(User guest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            guest.nickname.isNotEmpty ? guest.nickname[0].toUpperCase() : '?',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(guest.nickname),
        subtitle: Text('레벨 ${guest.skillLevel} • ${guest.region}'),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.primary),
          onPressed: () => _openChatWithUser(guest),
        ),
        onTap: () => _viewUserProfile(guest),
      ),
    );
  }

  Widget _buildBottomButtons() {
    // 이미 참가 중인 경우
    if (isParticipant) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 20, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    '참가 신청이 완료되었습니다',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 모집 완료 또는 종료된 경우
    if (isFull || isExpired) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: AppButton(
          text: isExpired ? '모집 종료' : '모집 완료',
          onPressed: null,
          type: ButtonType.secondary,
        ),
      );
    }

    // 신청 가능한 경우
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: AppButton(
          text: '신청하기',
          onPressed: () => _applyToMatching(),
        ),
      ),
    );
  }

  String _getGameTypeLabel(String gameType) {
    switch (gameType) {
      case 'mixed': return '혼복';
      case 'male_doubles': return '남복';
      case 'female_doubles': return '여복';
      case 'singles': return '단식';
      case 'rally': return '랠리';
      default: return gameType;
    }
  }

  void _editMatching() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMatchingScreen(
          matching: widget.matching,
        ),
      ),
    ).then((_) {
      widget.onMatchingUpdated?.call();
    });
  }

  void _showHostMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정하기'),
              onTap: () {
                Navigator.pop(context);
                _editMatching();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.error),
              title: const Text('모집 마감', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _closeMatching();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewHostProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          user: widget.matching.host,
          isHost: true,
        ),
      ),
    );
  }

  void _viewUserProfile(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          user: user,
          isHost: false,
        ),
      ),
    );
  }

  void _confirmApplicant(int userId) {
    // 신청자 확정 로직
    setState(() {
      _confirmedUserIds.add(userId);
    });
  }

  void _applyToMatching() {
    // 매칭 신청 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('매칭 신청이 완료되었습니다'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _openChatWithUser(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matching: widget.matching,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _writeReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          targetUser: widget.matching.host,
          matching: widget.matching,
        ),
      ),
    );
  }

  void _closeMatching() {
    // 모집 마감 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('모집이 마감되었습니다'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
