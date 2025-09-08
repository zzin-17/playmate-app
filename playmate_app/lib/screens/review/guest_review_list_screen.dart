import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/matching.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'write_review_screen.dart';

class GuestReviewListScreen extends StatefulWidget {
  final Matching matching;
  final User hostUser;

  const GuestReviewListScreen({
    super.key,
    required this.matching,
    required this.hostUser,
  });

  @override
  State<GuestReviewListScreen> createState() => _GuestReviewListScreenState();
}

class _GuestReviewListScreenState extends State<GuestReviewListScreen> {
  final Set<int> _reviewedUserIds = <int>{};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReviewedUsers();
  }

  // 이미 후기를 작성한 사용자 목록 로드
  void _loadReviewedUsers() {
    // TODO: 실제 API 호출로 대체
    setState(() {
      _isLoading = false;
      // 임시로 빈 목록으로 시작
      _reviewedUserIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게스트 후기 작성'),
        actions: [
          TextButton(
            onPressed: _reviewedUserIds.length == (widget.matching.guests?.length ?? 0)
                ? null
                : () => _showCompleteAllReviewsDialog(),
            child: Text(
              '모두 완료 (${_reviewedUserIds.length}/${widget.matching.guests?.length ?? 0})',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 매칭 정보 헤더
                _buildMatchingHeader(),
                const SizedBox(height: 16),
                
                // 게스트 목록
                Expanded(
                  child: _buildGuestList(),
                ),
              ],
            ),
    );
  }

  // 매칭 정보 헤더 (전체 너비, 가운데 정렬)
  Widget _buildMatchingHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), // 좌우 여백 완전 제거, 테두리를 화면 양끝까지 확장
      padding: const EdgeInsets.all(20), // 패딩 증가로 여유 공간 확보
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16), // 모서리 둥글기 증가
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 가운데 정렬로 변경
        children: [
          Text(
            widget.matching.courtName,
            style: AppTextStyles.h2.copyWith( // h3 → h2로 크기 증가
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center, // 텍스트 가운데 정렬
          ),
          const SizedBox(height: 12), // 8 → 12로 간격 증가
          Text(
            '${widget.matching.date.month}월 ${widget.matching.date.day}일 • ${widget.matching.timeSlot}',
            style: AppTextStyles.h3.copyWith( // body → h3로 크기 증가
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500, // 폰트 굵기 추가
            ),
            textAlign: TextAlign.center, // 텍스트 가운데 정렬
          ),
          const SizedBox(height: 12), // 8 → 12로 간격 증가
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '게스트 ${widget.matching.guests?.length ?? 0}명',
              style: AppTextStyles.h3.copyWith( // body → h3로 크기 증가
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center, // 텍스트 가운데 정렬
            ),
          ),
        ],
      ),
    );
  }

  // 게스트 목록
  Widget _buildGuestList() {
    if (widget.matching.guests?.isEmpty ?? true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '게스트가 없습니다',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '확정된 게스트가 없어 후기를 작성할 수 없습니다.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.matching.guests?.length ?? 0,
      itemBuilder: (context, index) {
        final guest = widget.matching.guests![index];
        final hasReviewed = _reviewedUserIds.contains(guest.id);
        
        return _buildGuestCard(guest, hasReviewed);
      },
    );
  }

  // 게스트 카드
  Widget _buildGuestCard(User guest, bool hasReviewed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            guest.nickname.isNotEmpty ? guest.nickname[0] : '?',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          guest.nickname,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '구력 ${guest.experienceText} • ${guest.genderText}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: AppColors.ratingStar, size: 16),
                const SizedBox(width: 4),
                Text(
                  guest.mannerScoreText,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: hasReviewed
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success),
                ),
                child: Text(
                  '완료',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: () => _writeReview(guest),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('후기 작성'),
              ),
      ),
    );
  }

  // 후기 작성
  Future<void> _writeReview(User guest) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          targetUser: guest,
          matching: widget.matching,
        ),
      ),
    );
    
    if (result == true) {
      // 후기 작성 완료 시 해당 사용자를 완료 목록에 추가
      setState(() {
        _reviewedUserIds.add(guest.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${guest.nickname}님에 대한 후기가 작성되었습니다'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // 모든 후기 완료 다이얼로그
  void _showCompleteAllReviewsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('후기 작성 완료'),
        content: Text(
          '아직 ${(widget.matching.guests?.length ?? 0) - _reviewedUserIds.length}명의 게스트에 대한 후기가 남아있습니다.\n\n'
          '모든 게스트에 대한 후기를 작성하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 모든 게스트 후기 작성 화면으로 이동
              _navigateToAllReviews();
            },
            child: const Text('모두 작성하기'),
          ),
        ],
      ),
    );
  }

  // 모든 후기 작성 화면으로 이동
  void _navigateToAllReviews() {
    // TODO: 모든 게스트 후기를 한 번에 작성할 수 있는 화면 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('모든 후기 작성 기능은 추후 구현 예정입니다.'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
