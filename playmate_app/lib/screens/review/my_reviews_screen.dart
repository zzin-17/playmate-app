import 'dart:async';
import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/review_service.dart';
import '../../utils/logger.dart';

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
  
  // 자동 새로고침 타이머
  Timer? _autoRefreshTimer;
  final Duration _refreshInterval = const Duration(minutes: 3); // 3분마다 새로고침

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyReviews();
    _startAutoRefreshTimer();
  }

  // 자동 새로고침 타이머 시작
  void _startAutoRefreshTimer() {
    Logger.info('후기 자동 새로고침 활성화', tag: 'MyReviewsScreen');
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _refreshReviewData();
      } else {
        timer.cancel();
      }
    });
  }
  
  // 후기 데이터 새로고침 (기존 후기 보존하면서 새 후기 추가)
  void _refreshReviewData() {
    Logger.info('후기 데이터 자동 새로고침 시작', tag: 'MyReviewsScreen');
    
    // 새로운 후기만 로드하여 기존 목록에 병합
    _loadMyReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
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
      
      Logger.info('내 후기 목록 로드 완료: ${reviews.length}개', tag: 'MyReviewsScreen');
    } catch (e) {
      Logger.error('내 후기 목록 로드 실패', tag: 'MyReviewsScreen', error: e);
      setState(() {
        _myReviews = [];
        _isLoading = false;
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
                    review.reviewer?.nickname[0].toUpperCase() ?? '?',
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
