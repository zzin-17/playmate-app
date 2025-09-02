import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class ReviewListScreen extends StatefulWidget {
  final User? targetUser;
  final List<Review> reviews;

  const ReviewListScreen({
    super.key,
    this.targetUser,
    required this.reviews,
  });

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.targetUser?.nickname ?? '사용자'}님의 리뷰'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 필터 섹션
          _buildFilterSection(),
          
          // 리뷰 통계
          _buildReviewStats(),
          
          // 리뷰 목록
          Expanded(
            child: _buildReviewList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final filters = [
      {'value': 'all', 'label': '전체'},
      {'value': 'positive', 'label': '긍정적'},
      {'value': 'neutral', 'label': '보통'},
      {'value': 'negative', 'label': '부정적'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(filter['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['value']!;
                  });
                },
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                labelStyle: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewStats() {
    final filteredReviews = _getFilteredReviews();
    final stats = _calculateStats(filteredReviews);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'NTRP 점수',
                  '${stats['ntrp']?.toStringAsFixed(1) ?? '0.0'}',
                  Icons.sports_tennis,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '매너 점수',
                  '${stats['manner']?.toStringAsFixed(1) ?? '0.0'}',
                  Icons.favorite,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '리뷰 수',
                  '${filteredReviews.length}',
                  Icons.rate_review,
                  AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewList() {
    final filteredReviews = _getFilteredReviews();

    if (filteredReviews.isEmpty) {
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
              widget.targetUser != null ? '리뷰가 없습니다' : '사용자 정보가 없습니다',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.targetUser != null 
                ? '아직 작성된 리뷰가 없어요'
                : '리뷰를 확인할 사용자 정보를 찾을 수 없어요',
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
      itemCount: filteredReviews.length,
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return _buildReviewItem(review);
      },
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리뷰어 정보
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  (review.reviewer?.nickname ?? 'U').substring(0, 1),
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
                      review.reviewer?.nickname ?? '사용자',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
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
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 점수 정보
          Row(
            children: [
              Expanded(
                child: _buildScoreItem(
                  'NTRP',
                  review.ntrpScore,
                  Icons.sports_tennis,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildScoreItem(
                  '매너',
                  review.mannerScore,
                  Icons.favorite,
                  AppColors.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 리뷰 내용
          if (review.comment.isNotEmpty) ...[
            Text(
              review.comment,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // 태그들
          _buildReviewTags(review),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTags(Review review) {
    final tags = <String>[];
    
    // NTRP 태그
    if (review.ntrpScore >= 4.5) tags.add('실력자');
    else if (review.ntrpScore >= 3.5) tags.add('중급자');
    else tags.add('초급자');
    
    // 매너 태그
    if (review.mannerScore >= 4.5) tags.add('매너 좋음');
    else if (review.mannerScore >= 3.5) tags.add('보통');
    else tags.add('개선 필요');
    
    // 특별한 태그
    if (review.comment.contains('친절')) tags.add('친절함');
    if (review.comment.contains('시간')) tags.add('시간 준수');
    if (review.comment.contains('연습')) tags.add('열심히 연습');

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) => Chip(
        label: Text(
          tag,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        backgroundColor: AppColors.primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      )).toList(),
    );
  }

  List<Review> _getFilteredReviews() {
    switch (_selectedFilter) {
      case 'positive':
        return widget.reviews.where((review) => 
          review.ntrpScore >= 4.0 && review.mannerScore >= 4.0
        ).toList();
      case 'neutral':
        return widget.reviews.where((review) => 
          (review.ntrpScore >= 3.0 && review.ntrpScore < 4.0) ||
          (review.mannerScore >= 3.0 && review.mannerScore < 4.0)
        ).toList();
      case 'negative':
        return widget.reviews.where((review) => 
          review.ntrpScore < 3.0 || review.mannerScore < 3.0
        ).toList();
      default:
        return widget.reviews;
    }
  }

  Map<String, double> _calculateStats(List<Review> reviews) {
    if (reviews.isEmpty) return {'ntrp': 0.0, 'manner': 0.0};
    
    final totalNtrp = reviews.fold(0.0, (sum, review) => sum + review.ntrpScore);
    final totalManner = reviews.fold(0.0, (sum, review) => sum + review.mannerScore);
    
    return {
      'ntrp': totalNtrp / reviews.length,
      'manner': totalManner / reviews.length,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
}
