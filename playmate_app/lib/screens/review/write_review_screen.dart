import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../models/user.dart';
import '../../models/matching.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class WriteReviewScreen extends StatefulWidget {
  final User targetUser; // 리뷰 대상자
  final Matching matching; // 해당 매칭

  const WriteReviewScreen({
    super.key,
    required this.targetUser,
    required this.matching,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _ntrpScore = 3.0; // 기본값 3.0
  double _mannerScore = 4.0; // 기본값 4.0
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('후기 작성'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitReview,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('완료'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 대상자 정보
            _buildTargetUserInfo(),
            const SizedBox(height: 24),
            
            // NTRP 점수 평가
            _buildNtrpScoreSection(),
            const SizedBox(height: 24),
            
            // 매너 점수 평가
            _buildMannerScoreSection(),
            const SizedBox(height: 24),
            
            // 후기 텍스트
            _buildCommentSection(),
            const SizedBox(height: 32),
            
            // 제출 버튼
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // 대상자 정보 위젯
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
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              widget.targetUser.nickname.isNotEmpty 
                  ? widget.targetUser.nickname[0] 
                  : '?',
              style: AppTextStyles.h2.copyWith(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.targetUser.nickname,
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 팔로우 버튼
                    _buildFollowButton(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.matching.courtName} • ${widget.matching.date.month}월 ${widget.matching.date.day}일',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 팔로우 버튼 위젯
  Widget _buildFollowButton() {
    // TODO: 실제 팔로우 상태 확인 로직으로 대체
    bool isFollowing = false; // 임시로 false로 설정
    
    return GestureDetector(
      onTap: () {
        setState(() {
          isFollowing = !isFollowing;
        });
        
        // 팔로우/언팔로우 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFollowing 
                ? '${widget.targetUser.nickname}님을 팔로우했습니다!' 
                : '${widget.targetUser.nickname}님을 언팔로우했습니다!',
            ),
            backgroundColor: isFollowing ? AppColors.success : AppColors.textSecondary,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing 
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFollowing ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowing ? Icons.person : Icons.person_add,
              size: 14,
              color: isFollowing ? AppColors.primary : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isFollowing ? '팔로잉' : '팔로우',
              style: AppTextStyles.caption.copyWith(
                color: isFollowing ? AppColors.primary : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NTRP 점수 평가 위젯
  Widget _buildNtrpScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '테니스 실력 평가 (NTRP)',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'NTRP 점수는 테니스 실력 수준을 객관적으로 평가하는 시스템입니다.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        // 점수 표시
        Center(
          child: Text(
            '${_ntrpScore.toStringAsFixed(1)}',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // 슬라이더
        Slider(
          value: _ntrpScore,
          min: 1.0,
          max: 7.0,
          divisions: 60, // 0.1 단위로 60개 구간
          activeColor: AppColors.primary,
          inactiveColor: AppColors.cardBorder,
          onChanged: (value) {
            setState(() {
              _ntrpScore = value;
            });
          },
        ),
        
        // 점수 범위 설명
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1.0\n초보자',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '4.0\n중급자',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '7.0\n엘리트',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 현재 점수 설명
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getNtrpDescription(_ntrpScore),
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // 매너 점수 평가 위젯
  Widget _buildMannerScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '매너 점수 평가',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '테니스 코트에서의 예의와 매너를 평가해주세요.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        // 점수 표시
        Center(
          child: Text(
            '${_mannerScore.toStringAsFixed(1)}',
            style: AppTextStyles.h1.copyWith(
              color: _getMannerScoreColor(_mannerScore),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // 슬라이더
        Slider(
          value: _mannerScore,
          min: 1.0,
          max: 5.0,
          divisions: 40, // 0.1 단위로 40개 구간
          activeColor: _getMannerScoreColor(_mannerScore),
          inactiveColor: AppColors.cardBorder,
          onChanged: (value) {
            setState(() {
              _mannerScore = value;
            });
          },
        ),
        
        // 점수 범위 설명
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1.0\n매우 나쁨',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '3.0\n보통',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '5.0\n매우 좋음',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 현재 점수 설명
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getMannerScoreColor(_mannerScore).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getMannerDescription(_mannerScore),
            style: AppTextStyles.body.copyWith(
              color: _getMannerScoreColor(_mannerScore),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // 후기 텍스트 위젯
  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '후기 작성',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '이번 매칭에 대한 솔직한 후기를 작성해주세요.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '매칭 경험, 상대방의 실력과 매너, 개선점 등을 자유롭게 작성해주세요.',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          style: AppTextStyles.body,
        ),
        
        const SizedBox(height: 8),
        Text(
          '${_commentController.text.length}/500',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // 제출 버튼 위젯
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                '후기 제출하기',
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // NTRP 점수 설명 반환
  String _getNtrpDescription(double score) {
    if (score < 1.5) return '테니스를 처음 시작하는 초보자';
    if (score < 2.5) return '기본적인 샷을 칠 수 있음';
    if (score < 3.5) return '일관성 있게 샷을 칠 수 있음';
    if (score < 4.5) return '다양한 샷과 전략을 구사할 수 있음';
    if (score < 5.5) return '고급 테크닉과 전략을 보유';
    if (score < 6.5) return '프로 수준의 실력';
    return '세계적 수준의 엘리트 선수';
  }

  // 매너 점수 설명 반환
  String _getMannerDescription(double score) {
    if (score < 2.0) return '매우 나쁜 매너와 예의';
    if (score < 3.0) return '개선이 필요한 매너';
    if (score < 4.0) return '보통 수준의 매너';
    if (score < 4.5) return '좋은 매너와 예의';
    return '매우 좋은 매너와 예의';
  }

  // 매너 점수 색상 반환
  Color _getMannerScoreColor(double score) {
    if (score < 2.0) return AppColors.error;
    if (score < 3.0) return Colors.orange;
    if (score < 4.0) return Colors.amber;
    if (score < 4.5) return Colors.lightGreen;
    return AppColors.success;
  }

  // 후기 제출
  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('후기 내용을 입력해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: 실제 API 호출로 대체
      await Future.delayed(const Duration(seconds: 2)); // API 호출 시뮬레이션
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('후기가 성공적으로 작성되었습니다!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // 이전 화면으로 돌아가기
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('후기 작성에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
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
}
