import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class MyReviewsScreen extends StatefulWidget {
  final User currentUser;

  const MyReviewsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Review> _myReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 내 후기 데이터 로드
  void _loadMyReviews() {
    // TODO: 실제 API 호출로 대체
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
        // 실력 후기
        Review(
          id: 3,
          matchingId: 103,
          reviewerId: 203,
          reviewedUserId: widget.currentUser.id,
          ntrpScore: 4.8,
          mannerScore: 4.6,
          comment: '와, 정말 실력이 대단하세요! 서브가 강력하고 포핸드도 정확해서 압도당했습니다. 하지만 게임 중에는 항상 겸손하고 상대방을 배려하는 모습이 인상적이었어요.',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          updatedAt: DateTime.now().subtract(const Duration(days: 8)),
          reviewer: User(
            id: 203,
            email: 'reviewer3@example.com',
            nickname: '테니스프로',
            skillLevel: 5,
            gender: 'male',
            startYearMonth: '2018-03',
            mannerScore: 4.9,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        // 개선점 후기
        Review(
          id: 4,
          matchingId: 104,
          reviewerId: 204,
          reviewedUserId: widget.currentUser.id,
          ntrpScore: 3.0,
          mannerScore: 4.3,
          comment: '기본기는 좋은데 백핸드가 조금 불안정해 보이네요. 하지만 열심히 연습하시는 모습이 보여서 곧 좋아질 것 같아요. 매너는 정말 좋습니다!',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          updatedAt: DateTime.now().subtract(const Duration(days: 12)),
          reviewer: User(
            id: 204,
            email: 'reviewer4@example.com',
            nickname: '테니스코치',
            skillLevel: 4,
            gender: 'female',
            startYearMonth: '2019-09',
            mannerScore: 4.8,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ];
    });
  }

  // 후기 필터링
  List<Review> _getReviewsByType(String type) {
    if (type == 'positive') {
      return _myReviews.where((review) => 
        review.ntrpScore >= 4.0 && review.mannerScore >= 4.0
      ).toList();
    } else if (type == 'all') {
      return _myReviews;
    }
    return [];
  }

  // 종합 평가 점수 계산
  Map<String, double> _getOverallScores() {
    if (_myReviews.isEmpty) return {'ntrp': 0.0, 'manner': 0.0};
    
    final totalNtrp = _myReviews.fold(0.0, (sum, review) => sum + review.ntrpScore);
    final totalManner = _myReviews.fold(0.0, (sum, review) => sum + review.mannerScore);
    
    return {
      'ntrp': totalNtrp / _myReviews.length,
      'manner': totalManner / _myReviews.length,
    };
  }

  // NTRP 점수 분포 계산 (숫자 범위로 변경)
  Map<String, int> _getNtrpDistribution() {
    final distribution = <String, int>{
      '1.0-1.5': 0,
      '1.5-2.5': 0,
      '2.5-3.5': 0,
      '3.5-4.5': 0,
      '4.5-5.5': 0,
      '5.5-6.5': 0,
      '6.5+': 0,
    };
    
    for (final review in _myReviews) {
      if (review.ntrpScore < 1.5) distribution['1.0-1.5'] = (distribution['1.0-1.5'] ?? 0) + 1;
      else if (review.ntrpScore < 2.5) distribution['1.5-2.5'] = (distribution['1.5-2.5'] ?? 0) + 1;
      else if (review.ntrpScore < 3.5) distribution['2.5-3.5'] = (distribution['2.5-3.5'] ?? 0) + 1;
      else if (review.ntrpScore < 4.5) distribution['3.5-4.5'] = (distribution['3.5-4.5'] ?? 0) + 1;
      else if (review.ntrpScore < 5.5) distribution['4.5-5.5'] = (distribution['4.5-5.5'] ?? 0) + 1;
      else if (review.ntrpScore < 6.5) distribution['5.5-6.5'] = (distribution['5.5-6.5'] ?? 0) + 1;
      else distribution['6.5+'] = (distribution['6.5+'] ?? 0) + 1;
    }
    
    return distribution;
  }

  // 매너 점수 분포 계산
  Map<String, int> _getMannerDistribution() {
    final distribution = <String, int>{
      '매우 나쁨': 0,
      '개선 필요': 0,
      '보통': 0,
      '좋음': 0,
      '매우 좋음': 0,
    };
    
    for (final review in _myReviews) {
      if (review.mannerScore < 2.0) distribution['매우 나쁨'] = (distribution['매우 나쁨'] ?? 0) + 1;
      else if (review.mannerScore < 3.0) distribution['개선 필요'] = (distribution['개선 필요'] ?? 0) + 1;
      else if (review.mannerScore < 4.0) distribution['보통'] = (distribution['보통'] ?? 0) + 1;
      else if (review.mannerScore < 4.5) distribution['좋음'] = (distribution['좋음'] ?? 0) + 1;
      else distribution['매우 좋음'] = (distribution['매우 좋음'] ?? 0) + 1;
    }
    
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 후기'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '긍정적'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReviewList(_getReviewsByType('all'), '전체'),
                _buildReviewList(_getReviewsByType('positive'), '긍정적'),
              ],
            ),
    );
  }

  Widget _buildReviewList(List<Review> reviews, String type) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == '긍정적' ? Icons.thumb_up : Icons.rate_review,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              type == '긍정적' ? '긍정적인 후기가 없습니다' : '아직 받은 후기가 없습니다',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == '긍정적' ? '더 많은 후기를 받아보세요!' : '매칭에 참여하면 후기를 받을 수 있어요!',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 상단 종합평가 섹션
        _buildOverallScoreSection(),
        const SizedBox(height: 24),
        
        // 후기 목록
        ...reviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  // 상단 종합평가 섹션 위젯 (높이 최적화)
  Widget _buildOverallScoreSection() {
    final overallScores = _getOverallScores();
    final ntrpDistribution = _getNtrpDistribution();
    final mannerDistribution = _getMannerDistribution();
    
    return Container(
      padding: const EdgeInsets.all(16), // 20 → 16으로 감소
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12), // 16 → 12로 감소
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03), // 0.05 → 0.03으로 감소
            blurRadius: 6, // 10 → 6으로 감소
            offset: const Offset(0, 1), // 2 → 1로 감소
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 (높이 최적화)
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.primary,
                size: 20, // 24 → 20으로 감소
              ),
              const SizedBox(width: 6), // 8 → 6으로 감소
              Text(
                '종합 평가',
                style: AppTextStyles.h3.copyWith( // h2 → h3으로 감소
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 12,6 → 10,4로 감소
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16), // 20 → 16으로 감소
                ),
                child: Text(
                  '총 ${_myReviews.length}개 후기',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11, // 폰트 크기 감소
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12), // 20 → 12로 감소
          
          // 주요 점수 (높이 최적화)
          Row(
            children: [
              // NTRP 점수
              Expanded(
                child: _buildScoreCard(
                  title: '테니스 실력',
                  score: overallScores['ntrp'] ?? 0.0,
                  maxScore: 7.0,
                  color: AppColors.primary,
                  subtitle: _getNtrpScoreText(overallScores['ntrp'] ?? 0.0), // 레벨 → 점수로 변경
                ),
              ),
              
              const SizedBox(width: 12), // 16 → 12로 감소
              
              // 매너 점수
              Expanded(
                child: _buildScoreCard(
                  title: '매너 점수',
                  score: overallScores['manner'] ?? 0.0,
                  maxScore: 5.0,
                  color: _getMannerScoreColor(overallScores['manner'] ?? 0.0),
                  subtitle: _getMannerLevelText(overallScores['manner'] ?? 0.0),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12), // 20 → 12로 감소
          
          // 점수 분포 (컴팩트 버전)
          _buildCompactDistributionSection(
            title: '점수 분포',
            ntrpDistribution: ntrpDistribution,
            mannerDistribution: mannerDistribution,
          ),
        ],
      ),
    );
  }

  // 점수 카드 위젯 (높이 최적화)
  Widget _buildScoreCard({
    required String title,
    required double score,
    required double maxScore,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // 16 → 12로 감소
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8), // 12 → 8로 감소
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 11, // 폰트 크기 감소
            ),
          ),
          const SizedBox(height: 6), // 8 → 6으로 감소
          Text(
            score.toStringAsFixed(1),
            style: AppTextStyles.h2.copyWith( // h1 → h2로 감소
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 10, // 11 → 10으로 감소
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 컴팩트한 분포 섹션 위젯
  Widget _buildCompactDistributionSection({
    required String title,
    required Map<String, int> ntrpDistribution,
    required Map<String, int> mannerDistribution,
  }) {
    final ntrpTotal = ntrpDistribution.values.fold(0, (sum, count) => sum + count);
    final mannerTotal = mannerDistribution.values.fold(0, (sum, count) => sum + count);
    
    if (ntrpTotal == 0 && mannerTotal == 0) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12), // 16 → 12로 감소
        
        // NTRP 분포 (가로 배치)
        Row(
          children: [
            Expanded(
              child: _buildCompactDistributionRow(
                title: 'NTRP',
                distribution: ntrpDistribution,
                total: ntrpTotal,
                colors: [
                  AppColors.primary,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.red,
                  Colors.purple,
                  Colors.indigo,
                ],
              ),
            ),
            
            const SizedBox(width: 12), // 16 → 12로 감소
            
            // 매너 분포 (가로 배치)
            Expanded(
              child: _buildCompactDistributionRow(
                title: '매너',
                distribution: mannerDistribution,
                total: mannerTotal,
                colors: [
                  AppColors.error,
                  Colors.orange,
                  Colors.amber,
                  Colors.lightGreen,
                  AppColors.success,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 컴팩트한 분포 행 위젯
  Widget _buildCompactDistributionRow({
    required String title,
    required Map<String, int> distribution,
    required int total,
    required List<Color> colors,
  }) {
    if (total == 0) return const SizedBox.shrink();
    
    // 0%가 아닌 항목만 필터링
    final nonZeroEntries = distribution.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    if (nonZeroEntries.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Row(
            children: [
              Icon(
                title == 'NTRP' ? Icons.sports_tennis : Icons.favorite,
                size: 16,
                color: title == 'NTRP' ? AppColors.primary : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 분포 항목들 (점수와 퍼센트 분리, 양끝 정렬)
          Column(
            children: nonZeroEntries.map((entry) {
              final percentage = (entry.value / total * 100);
              final colorIndex = distribution.keys.toList().indexOf(entry.key) % colors.length;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    // 왼쪽: 점수 범위
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors[colorIndex],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: AppTextStyles.caption.copyWith(
                              color: colors[colorIndex],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 오른쪽: 퍼센트
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.caption.copyWith(
                        color: colors[colorIndex],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // NTRP 점수 텍스트 반환 (점수 기반)
  String _getNtrpScoreText(double score) {
    if (score < 1.5) return '1.0-1.5';
    if (score < 2.5) return '1.5-2.5';
    if (score < 3.5) return '2.5-3.5';
    if (score < 4.5) return '3.5-4.5';
    if (score < 5.5) return '4.5-5.5';
    if (score < 6.5) return '5.5-6.5';
    return '6.5+';
  }

  // NTRP 레벨 텍스트 반환 (기존 유지)
  String _getNtrpLevelText(double score) {
    if (score < 1.5) return '초보자';
    if (score < 2.5) return '입문자';
    if (score < 3.5) return '초급자';
    if (score < 4.5) return '중급자';
    if (score < 5.5) return '고급자';
    if (score < 6.5) return '전문가';
    return '엘리트';
  }

  // 매너 레벨 텍스트 반환
  String _getMannerLevelText(double score) {
    if (score < 2.0) return '매우 나쁨';
    if (score < 3.0) return '개선 필요';
    if (score < 4.0) return '보통';
    if (score < 4.5) return '좋음';
    return '매우 좋음';
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 리뷰어 정보와 날짜
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    review.reviewer?.nickname.isNotEmpty == true 
                        ? review.reviewer!.nickname[0] 
                        : '?',
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
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 리뷰어의 매너점수
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        review.reviewer?.mannerScoreText ?? '평가 없음',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 중간: 점수 정보
            Row(
              children: [
                // NTRP 점수
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '테니스 실력',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.ntrpScoreText,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          review.ntrpLevelText,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
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
                      color: _getMannerScoreColor(review.mannerScore).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '매너 점수',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.mannerScoreText,
                          style: AppTextStyles.h3.copyWith(
                            color: _getMannerScoreColor(review.mannerScore),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          review.mannerLevelText,
                          style: AppTextStyles.caption.copyWith(
                            color: _getMannerScoreColor(review.mannerScore),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 하단: 후기 텍스트
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                review.comment,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  // 매너 점수 색상 반환
  Color _getMannerScoreColor(double score) {
    if (score < 2.0) return AppColors.error;
    if (score < 3.0) return Colors.orange;
    if (score < 4.0) return Colors.amber;
    if (score < 4.5) return Colors.lightGreen;
    return AppColors.success;
  }
}
