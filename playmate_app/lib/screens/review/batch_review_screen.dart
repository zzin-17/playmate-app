import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/matching.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'write_review_screen.dart';

/// 모든 게스트에 대한 후기를 순차적으로 작성하는 화면
class BatchReviewScreen extends StatefulWidget {
  final Matching matching;
  final User hostUser;
  final List<User> guests;
  final Set<int> alreadyReviewedIds;

  const BatchReviewScreen({
    super.key,
    required this.matching,
    required this.hostUser,
    required this.guests,
    this.alreadyReviewedIds = const {},
  });

  @override
  State<BatchReviewScreen> createState() => _BatchReviewScreenState();
}

class _BatchReviewScreenState extends State<BatchReviewScreen> {
  int _currentIndex = 0;
  final Set<int> _reviewedUserIds = <int>{};

  List<User> get _remainingGuests {
    return widget.guests
        .where((guest) => !widget.alreadyReviewedIds.contains(guest.id))
        .toList();
  }

  bool get _isLastGuest => _currentIndex >= _remainingGuests.length - 1;
  bool get _isFirstGuest => _currentIndex == 0;
  User? get _currentGuest => _remainingGuests.isNotEmpty && _currentIndex < _remainingGuests.length
      ? _remainingGuests[_currentIndex]
      : null;

  @override
  void initState() {
    super.initState();
    _reviewedUserIds.addAll(widget.alreadyReviewedIds);
  }

  // 다음 게스트로 이동
  void _moveToNextGuest() {
    if (!_isLastGuest) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  // 이전 게스트로 이동
  void _moveToPreviousGuest() {
    if (!_isFirstGuest) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  // 후기 작성 완료 처리
  Future<void> _onReviewCompleted() async {
    if (_currentGuest != null) {
      setState(() {
        _reviewedUserIds.add(_currentGuest!.id);
      });

      if (_isLastGuest) {
        // 모든 후기 작성 완료
        if (mounted) {
          Navigator.of(context).pop(true); // true 반환하여 완료 알림
        }
      } else {
        // 다음 게스트로 이동
        _moveToNextGuest();
      }
    }
  }

  // 나중에 버튼 처리
  void _onSkip() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingGuests.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('게스트 후기 작성'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                '모든 후기 작성 완료',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '모든 게스트에 대한 후기를 작성하셨습니다.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('후기 작성 (${_currentIndex + 1}/${_remainingGuests.length})'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onSkip,
        ),
      ),
      body: Column(
        children: [
          // 진행 상황 표시
          _buildProgressIndicator(),
          
          // 현재 게스트 후기 작성 화면
          Expanded(
            child: _currentGuest != null
                ? WriteReviewScreen(
                    targetUser: _currentGuest!,
                    matching: widget.matching,
                    onReviewCompleted: _onReviewCompleted,
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          
          // 네비게이션 버튼
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // 진행 상황 표시
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '진행 상황',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_reviewedUserIds.length}/${widget.guests.length}명 완료',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _reviewedUserIds.length / widget.guests.length,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  // 네비게이션 버튼
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!_isFirstGuest) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _moveToPreviousGuest,
                child: const Text('이전'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _isFirstGuest ? 1 : 2,
            child: ElevatedButton(
              onPressed: _onSkip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textSecondary,
              ),
              child: const Text('나중에'),
            ),
          ),
        ],
      ),
    );
  }
}






