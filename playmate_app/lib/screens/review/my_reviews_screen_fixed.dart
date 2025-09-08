import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/review_service.dart';

class MyReviewsScreen extends StatefulWidget {
  final User currentUser;

  const MyReviewsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Review> _myReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 내 후기 데이터 로드
  void _loadMyReviews() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 실제 API 호출
      final reviews = await ReviewService.getMyReviews();
      setState(() {
        _myReviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // 오류 발생 시 빈 리스트 유지
      });
    }
    
    // 임시로 모의 데이터 사용 (API가 구현되지 않은 경우)
    if (_myReviews.isEmpty) {
      setState(() {
        _isLoading = false;
        // 임시로 모의 데이터 사용
        _myReviews = [
          // NTRP 후기
          Review(
            id: 1,
            matchingId: 101,
            reviewerId: 201,
            reviewedUserId: widget.currentUser.id,
            ntrpScore: 3.5,
            mannerScore: 4.8,
            comment: '테니스 실력이 정말 좋으시네요! 기본기가 탄탄하고 다양한 샷을 구사하실 수 있어서 함께 치기 편했습니다. 시간 약속도 잘 지키시고 매너도 좋아요.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
            reviewer: User(
              id: 201,
              email: 'reviewer1@example.com',
              nickname: '테니스마스터',
              skillLevel: 4,
              gender: 'male',
              startYearMonth: '2020-01',
              mannerScore: 4.5,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          // 매너 후기
          Review(
            id: 2,
            matchingId: 102,
            reviewerId: 202,
            reviewedUserId: widget.currentUser.id,
            ntrpScore: 4.2,
            mannerScore: 5.0,
            comment: '정말 친절하고 예의 바른 분이에요! 게임 중에도 상대방을 배려하고, 스코어를 정확하게 쳐주셔서 편하게 게임할 수 있었습니다. 다음에도 함께 치고 싶어요!',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            updatedAt: DateTime.now().subtract(const Duration(days: 5)),
            reviewer: User(
              id: 202,
              email: 'reviewer2@example.com',
              nickname: '테니스러버',
              skillLevel: 3,
              gender: 'female',
              startYearMonth: '2021-06',
              mannerScore: 4.7,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ];
      });
    }
  }

  // 후기 필터링
  List<Review> _getReviewsByType(String type) {
    if (type == 'positive') {
      return _myReviews.where((review) => 
        review.ntrpScore >= 4.0 && review.mannerScore >= 4.0
      ).toList();
    } else if (type == 'negative') {
      return _myReviews.where((review) => 
        review.ntrpScore < 3.0 || review.mannerScore < 3.0
      ).toList();
    } else {
      return _myReviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('내 후기'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '긍정적'),
            Tab(text: '개선점'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReviewsList('all'),
                _buildReviewsList('positive'),
                _buildReviewsList('negative'),
              ],
            ),
    );
  }

  Widget _buildReviewsList(String type) {
    final reviews = _getReviewsByType(type);
    
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'positive' ? '긍정적인 후기가 없습니다' :
              type == 'negative' ? '개선점 후기가 없습니다' :
              '받은 후기가 없습니다',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '매칭을 통해 후기를 받아보세요!',
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
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 리뷰어 정보
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    review.reviewer?.nickname?[0].toUpperCase() ?? '?',
                    style: AppTextStyles.body.copyWith(
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
                        review.reviewer?.nickname ?? '알 수 없음',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${review.createdAt.toString().split(' ')[0]}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 평점 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(review.ntrpScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NTRP ${review.ntrpScore}',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 매너 점수
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '매너 ${review.mannerScore}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 후기 내용
            Text(
              review.comment,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 4.0) return AppColors.success;
    if (score >= 3.0) return AppColors.primary;
    return AppColors.error;
  }
}
