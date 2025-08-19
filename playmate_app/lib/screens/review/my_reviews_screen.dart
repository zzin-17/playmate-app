import 'package:flutter/material.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import 'review_list_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  final User currentUser;

  const MyReviewsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Matching> _pendingReviews = []; // 후기 작성 대기 중인 매칭들
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingReviews();
  }

  void _loadPendingReviews() {
    // TODO: API에서 사용자가 참여한 매칭 중 후기 작성 대기 중인 것들을 가져오기
    // 현재는 목업 데이터 사용
    
    setState(() {
      _isLoading = false;
      _pendingReviews = [
        // 목업 데이터: 후기 작성 대기 중인 매칭들
        Matching(
          id: 1,
          type: 'host',
          courtName: '잠실종합운동장',
          courtLat: 37.5665,
          courtLng: 126.9780,
          date: DateTime.now().subtract(const Duration(days: 2)),
          timeSlot: '18:00~20:00',
                  minLevel: 3,
        maxLevel: 5,
        gameType: 'mixed',
          maleRecruitCount: 2,
          femaleRecruitCount: 2,
          status: 'confirmed',
          message: '즐거운 테니스 하실 분들 모집합니다!',
          guestCost: 15000,
          host: User(
            id: 1,
            email: 'test@playmate.com',
            nickname: '테린이',
            birthYear: 1990,
            gender: 'male',
            skillLevel: 4,
            region: '서울',
            preferredCourt: '잠실종합운동장',
            preferredTime: ['오후', '저녁'],
            playStyle: '공격적',
            hasLesson: true,
            mannerScore: 4.5,
            startYearMonth: '2021-05',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          guests: [
            User(
              id: 999,
              email: 'guest@example.com',
              nickname: '테니스러버',
              birthYear: 1992,
              gender: 'male',
              skillLevel: 3,
              region: '서울',
              preferredCourt: '잠실종합운동장',
              preferredTime: ['오후', '저녁'],
              playStyle: '안정적',
              hasLesson: false,
              mannerScore: 4.2,
              startYearMonth: '2020-03',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Matching(
          id: 2,
          type: 'guest',
          courtName: '올림픽공원 테니스장',
          courtLat: 37.5215,
          courtLng: 127.1274,
          date: DateTime.now().subtract(const Duration(days: 5)),
          timeSlot: '14:00~16:00',
                  minLevel: 2,
        maxLevel: 4,
        gameType: 'singles',
          maleRecruitCount: 1,
          femaleRecruitCount: 0,
          status: 'confirmed',
          message: '단식 테니스 하실 분 구합니다',
          guestCost: 10000,
          host: User(
            id: 888,
            email: 'host@example.com',
            nickname: '스매시왕',
            birthYear: 1988,
            gender: 'male',
            skillLevel: 4,
            region: '서울',
            preferredCourt: '올림픽공원 테니스장',
            preferredTime: ['오후'],
            playStyle: '공격적',
            hasLesson: true,
            mannerScore: 4.7,
            startYearMonth: '2019-08',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          guests: [widget.currentUser],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('후기 작성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingReviews.isEmpty
              ? _buildEmptyState()
              : _buildReviewsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '작성할 후기가 없습니다',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '매칭 확정 후 후기를 작성할 수 있습니다',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingReviews.length,
      itemBuilder: (context, index) {
        final matching = _pendingReviews[index];
        final isHost = matching.host.id == widget.currentUser.id;
        final reviewTargets = _getReviewTargets(matching);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 매칭 기본 정보
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHost ? AppColors.primary.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHost ? '호스트' : '게스트',
                        style: AppTextStyles.caption.copyWith(
                          color: isHost ? AppColors.primary : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      matching.formattedDate,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  matching.courtName,
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${matching.formattedDate} ${matching.timeSlot}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '${matching.gameTypeText} • ${matching.recruitCountText}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                
                // 후기 작성 대상자 목록
                Text(
                  '후기 작성 대상자',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...reviewTargets.map((target) => _buildReviewTargetCard(target, matching)),
                const SizedBox(height: 16),
                
                // 전체 후기 작성 버튼
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: '전체 후기 작성하기',
                    type: ButtonType.primary,
                    onPressed: () => _navigateToReview(matching),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<User> _getReviewTargets(Matching matching) {
    final targets = <User>[];
    
    if (matching.host.id == widget.currentUser.id) {
      // 호스트인 경우: 게스트들에게 후기 작성
      if (matching.guests != null) {
        targets.addAll(matching.guests!);
      }
    } else {
      // 게스트인 경우: 호스트에게 후기 작성
      targets.add(matching.host);
    }
    
    return targets;
  }

  Widget _buildReviewTargetCard(User target, Matching matching) {
    final isHost = matching.host.id == widget.currentUser.id;
    final targetRole = isHost ? '게스트' : '호스트';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // 프로필 이미지 (기본 아이콘)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      target.nickname,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                                         Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: AppColors.info.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Text(
                         targetRole,
                         style: AppTextStyles.caption.copyWith(
                           color: AppColors.info,
                           fontSize: 10,
                         ),
                       ),
                     ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '구력: ${target.experienceText}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '매너점수: ${target.mannerScore}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 개별 후기 작성 버튼
          Container(
            height: 32,
            child: OutlinedButton(
              onPressed: () => _navigateToIndividualReview(matching, target),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '후기작성',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToReview(Matching matching) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewListScreen(
          matching: matching,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _navigateToIndividualReview(Matching matching, User target) {
    // TODO: 개별 사용자에 대한 후기 작성 화면으로 이동
    // 현재는 ReviewListScreen으로 이동하되, 해당 사용자 선택된 상태로 표시
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewListScreen(
          matching: matching,
          currentUser: widget.currentUser,
          selectedUser: target,
        ),
      ),
    );
  }
}
