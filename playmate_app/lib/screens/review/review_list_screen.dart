import 'package:flutter/material.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import 'write_review_screen.dart';

class ReviewListScreen extends StatefulWidget {
  final Matching matching;
  final User currentUser;
  final User? chatPartner; // 채팅 상대방 (채팅에서 넘어온 경우)
  final User? selectedUser; // 선택된 사용자 (개별 후기 작성용)

  const ReviewListScreen({
    super.key,
    required this.matching,
    required this.currentUser,
    this.chatPartner, // 채팅 상대방 정보 추가
    this.selectedUser, // 선택된 사용자 정보 추가
  });

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  List<User> _participants = [];
  Set<int> _reviewedUsers = {}; // 이미 후기를 작성한 사용자 ID들

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  void _loadParticipants() {
    final participants = <User>[];
    
    // 선택된 사용자가 지정된 경우 (개별 후기 작성용)
    if (widget.selectedUser != null) {
      participants.add(widget.selectedUser!);
    }
    // 채팅 상대방이 지정된 경우 (채팅에서 넘어온 경우)
    else if (widget.chatPartner != null) {
      participants.add(widget.chatPartner!);
    } else {
      // 일반적인 경우: 모든 참여자 목록
      // 호스트가 현재 사용자가 아닌 경우 호스트 추가
      if (widget.matching.host.id != widget.currentUser.id) {
        participants.add(widget.matching.host);
      }
      
      // 게스트 목록 추가
      if (widget.matching.guests != null) {
        for (final guest in widget.matching.guests!) {
          if (guest.id != widget.currentUser.id) {
            participants.add(guest);
          }
        }
      }
      
      // 목업 데이터: 실제 게스트가 없을 때 테스트용
      if (participants.isEmpty && widget.matching.host.id != widget.currentUser.id) {
        participants.add(User(
          id: 999,
          email: 'test@example.com',
          nickname: '테니스러버',
          birthYear: 1990,
          gender: 'male',
          skillLevel: 3,
          region: '서울',
          preferredCourt: '잠실종합운동장',
          preferredTime: ['오후', '저녁'],
          playStyle: '공격적',
          hasLesson: false,
          mannerScore: 4.5,
          startYearMonth: '2020-03',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }
    
    setState(() {
      _participants = participants;
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _participants.isEmpty
                ? _buildEmptyState()
                : _buildParticipantsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.matching.courtName,
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.matching.formattedDate} ${widget.matching.timeSlot}',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '매칭에 참여한 분들에게 후기를 작성해주세요',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            '후기 작성할 참여자가 없습니다',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '매칭에 참여한 다른 사용자가 없습니다',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        final hasReviewed = _reviewedUsers.contains(participant.id);
        
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
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                participant.nickname.substring(0, 1),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              participant.nickname,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '구력 ${participant.experienceText} • ${participant.genderText}',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.ratingStar, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      participant.mannerScoreText,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            trailing: hasReviewed
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
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
                : AppButton(
                    text: '후기작성',
                    type: ButtonType.secondary,
                    onPressed: () => _writeReview(participant),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _writeReview(User participant) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          matching: widget.matching,
          targetUser: participant,
          currentUser: widget.currentUser,
        ),
      ),
    );
    
    if (result == true) {
      // 후기 작성 완료 시 해당 사용자를 완료 목록에 추가
      setState(() {
        _reviewedUsers.add(participant.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${participant.nickname}님에 대한 후기가 작성되었습니다'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
