import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../matching/matching_detail_screen.dart';
import '../review/write_review_screen.dart';

class MyGuestMatchingsScreen extends StatefulWidget {
  final User currentUser;

  const MyGuestMatchingsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<MyGuestMatchingsScreen> createState() => _MyGuestMatchingsScreenState();
}

class _MyGuestMatchingsScreenState extends State<MyGuestMatchingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Matching> _myGuestMatchings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyGuestMatchings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 게스트로 참여한 매칭 데이터 로드
  void _loadMyGuestMatchings() {
    // TODO: 실제 API 호출로 대체
    setState(() {
      _isLoading = false;
      // 홈 화면의 모의 데이터를 사용하여 테스트
      _myGuestMatchings = [
        // 잠실종합운동장 (참여중)
        Matching(
          id: 101,
          type: 'guest',
          courtName: '잠실종합운동장',
          courtLat: 37.512,
          courtLng: 127.102,
          date: DateTime.now().add(const Duration(days: 1)),
          timeSlot: '18:00~20:00',
          minLevel: 2,
          maxLevel: 4,
          gameType: 'mixed',
          maleRecruitCount: 1,
          femaleRecruitCount: 1,
          status: 'recruiting',
          guestCost: 15000,
          host: User(
            id: 101,
            email: 'host101@example.com',
            nickname: '잠실테니스',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recoveryCount: 0,
        ),
        // 양재시민의숲 (확정)
        Matching(
          id: 102,
          type: 'guest',
          courtName: '양재시민의숲',
          courtLat: 37.469,
          courtLng: 127.038,
          date: DateTime.now().add(const Duration(days: 2)),
          timeSlot: '20:00~22:00',
          minLevel: 3,
          maxLevel: 5,
          gameType: 'male_doubles',
          maleRecruitCount: 2,
          femaleRecruitCount: 0,
          status: 'confirmed',
          guestCost: 20000,
          host: User(
            id: 102,
            email: 'player102@example.com',
            nickname: '양재마스터',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recoveryCount: 0,
        ),
        // 올림픽공원 테니스장 (완료)
        Matching(
          id: 103,
          type: 'guest',
          courtName: '올림픽공원 테니스장',
          courtLat: 37.521,
          courtLng: 127.128,
          date: DateTime.now().subtract(const Duration(days: 1)),
          timeSlot: '14:00~16:00',
          minLevel: 1,
          maxLevel: 3,
          gameType: 'mixed',
          maleRecruitCount: 1,
          femaleRecruitCount: 1,
          status: 'completed',
          guestCost: 12000,
          host: User(
            id: 103,
            email: 'tennis103@example.com',
            nickname: '올림픽테니스',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recoveryCount: 0,
        ),
        // 한강공원 테니스장 (취소)
        Matching(
          id: 104,
          type: 'guest',
          courtName: '한강공원 테니스장',
          courtLat: 37.528,
          courtLng: 126.933,
          date: DateTime.now().add(const Duration(days: 3)),
          timeSlot: '16:00~18:00',
          minLevel: 4,
          maxLevel: 6,
          gameType: 'singles',
          maleRecruitCount: 0,
          femaleRecruitCount: 1,
          status: 'cancelled',
          guestCost: 18000,
          host: User(
            id: 104,
            email: 'pro104@example.com',
            nickname: '한강프로',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recoveryCount: 0,
        ),
      ];
    });
  }

  // 상태별 매칭 필터링
  List<Matching> _getMatchingsByStatus(String status) {
    return _myGuestMatchings.where((matching) => matching.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게스트로 참여한 일정'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '완료'),
            Tab(text: '확정'),
            Tab(text: '참여중'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMatchingList(_getMatchingsByStatus('completed'), '완료'),
                _buildMatchingList(_getMatchingsByStatus('confirmed'), '확정'),
                _buildMatchingList(_getMatchingsByStatus('recruiting'), '참여중'),
              ],
            ),
    );
  }

  Widget _buildMatchingList(List<Matching> matchings, String status) {
    if (matchings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'recruiting' ? Icons.people_outline : 
              status == 'confirmed' ? Icons.check_circle : Icons.done_all,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '$status 매칭이 없습니다',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == 'recruiting' ? '새로운 매칭에 참여해보세요!' :
              status == 'confirmed' ? '곧 게임이 시작됩니다!' : '완료된 매칭입니다!',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matchings.length,
      itemBuilder: (context, index) {
        final matching = matchings[index];
        return _buildMatchingCard(matching);
      },
    );
  }

  Widget _buildMatchingCard(Matching matching) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MatchingDetailScreen(
                matching: matching,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 코트명과 상태
              Row(
                children: [
                  Expanded(
                    child: Text(
                      matching.courtName,
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(matching.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(matching.status),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 호스트 정보
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '호스트: ${matching.host.nickname}',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 중간: 날짜, 시간, 게임 유형
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${matching.date.month}월 ${matching.date.day}일',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    matching.timeSlot,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.sports_tennis, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    matching.gameTypeText,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${matching.maleRecruitCount + matching.femaleRecruitCount}명 모집',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              
              // 하단: 구력 범위
              if (matching.minLevel != null || matching.maxLevel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      matching.skillRangeText,
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              
              // 게스트 비용 (있는 경우)
              if (matching.guestCost != null && matching.guestCost! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '참여비: ${matching.guestCost}원',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              
              // 후기 작성 버튼 (완료된 매칭에만)
              if (matching.status == 'completed') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToWriteReview(matching),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('후기 작성하기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 상태별 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'recruiting':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  // 상태별 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'recruiting':
        return '참여중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return '알 수 없음';
    }
  }



  // 후기 작성 화면으로 이동
  void _navigateToWriteReview(Matching matching) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          targetUser: matching.host,
          matching: matching,
        ),
      ),
    );
  }
}
