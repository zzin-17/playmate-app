import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/matching.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';

class WriteReviewScreen extends StatefulWidget {
  final Matching matching;
  final User targetUser; // 후기를 받을 사용자
  final User currentUser; // 후기를 작성하는 사용자

  const WriteReviewScreen({
    super.key,
    required this.matching,
    required this.targetUser,
    required this.currentUser,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 5.0;
  double _mannerScore = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  
  // 선택된 태그들
  final Set<String> _selectedTags = {};
  
  // 미리 정의된 태그들
  static const List<String> _availableTags = [
    '응답이 빨라요',
    '시간약속을 잘지켜요',
    '기본기가 충실해요',
    '매너가 좋아요',
    '게임운영능력이 뛰어나요',
    '테니스 실력이 좋아요',
    '친절해요',
    '정확한 스코어를 잘 쳐요',
    '코트 예약을 잘 챙겨요',
    '게임 분위기가 좋아요',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTargetUserInfo(),
            const SizedBox(height: 24),
            _buildRatingSection(),
            const SizedBox(height: 24),
            _buildMannerScoreSection(),
            const SizedBox(height: 24),
            _buildTagSelectionSection(),
            const SizedBox(height: 24),
            _buildReviewContentSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              widget.targetUser.nickname.substring(0, 1),
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
                  widget.targetUser.nickname,
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.matching.courtName} • ${widget.matching.formattedDate}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '전체 만족도',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _rating.toStringAsFixed(1),
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: AppColors.ratingStar, size: 32),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: _rating,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.cardBorder,
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('매우 나쁨', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text('매우 좋음', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMannerScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '매너 점수',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _mannerScore.toStringAsFixed(1),
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite, color: AppColors.primary, size: 32),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: _mannerScore,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.cardBorder,
                onChanged: (value) {
                  setState(() {
                    _mannerScore = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('매우 나쁨', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  Text('매우 좋음', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '어떤 점이 좋았나요?',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '해당하는 항목들을 선택해주세요 (복수 선택 가능)',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '리뷰 내용',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: 5,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: '매칭 참여 후기를 작성해주세요 (최대 200자)',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: _isSubmitting ? '후기 작성 중...' : '후기 작성 완료',
        onPressed: _isSubmitting ? null : _submitReview,
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty && _selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 내용을 입력하거나 태그를 선택해주세요')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: API 호출로 후기 저장
      // 선택된 태그들과 리뷰 내용을 함께 저장
      final reviewData = {
        'rating': _rating,
        'mannerScore': _mannerScore,
        'content': _reviewController.text.trim(),
        'tags': _selectedTags.toList(),
        'targetUserId': widget.targetUser.id,
        'reviewerId': widget.currentUser.id,
        'matchingId': widget.matching.id,
      };
      
      print('후기 데이터: $reviewData'); // 디버깅용
      
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이

      // 후기 작성 완료 알림 보내기
      _sendReviewCompletedNotification();

      // 팔로우 제안 다이얼로그 표시
      if (mounted) {
        _showFollowSuggestion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('후기 작성에 실패했습니다. 다시 시도해주세요')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 후기 작성 완료 알림 전송
  void _sendReviewCompletedNotification() {
    try {
      NotificationService().showReviewCompletedNotification(
        reviewerName: widget.currentUser.nickname,
        targetName: widget.targetUser.nickname,
        userId: widget.targetUser.id,
      );
    } catch (e) {
      print('후기 작성 완료 알림 전송 실패: $e');
    }
  }

  /// 팔로우 제안 다이얼로그 표시
  void _showFollowSuggestion() {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    final isFollowing = currentUser.followingIds?.contains(widget.targetUser.id) ?? false;
    
    if (!isFollowing) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('팔로우 제안'),
          content: Text('${widget.targetUser.nickname}님과 함께 테니스를 치면서 좋은 시간을 보냈나요?\n\n이제 팔로우하여 앞으로의 활동을 지켜보세요!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // 후기 작성 화면 닫기
              },
              child: const Text('나중에'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _followUser();
              },
              child: const Text('팔로우하기'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop(true); // 이미 팔로우 중이면 바로 닫기
    }
  }

  /// 사용자 팔로우
  Future<void> _followUser() async {
    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser == null) return;

      // TODO: 실제 API 호출로 변경
      print('팔로우 시도: ${widget.targetUser.nickname}');
      
      // Mock: 팔로우 상태 업데이트
      setState(() {
        currentUser.followingIds ??= [];
        currentUser.followingIds!.add(widget.targetUser.id);
        widget.targetUser.followerIds ??= [];
        widget.targetUser.followerIds!.add(currentUser.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.targetUser.nickname}님을 팔로우했습니다!'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.of(context).pop(true); // 후기 작성 화면 닫기
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로우 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
