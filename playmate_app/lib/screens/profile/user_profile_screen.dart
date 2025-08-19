import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/mock_auth_service.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;
  final bool isHost;
  final bool embed; // true면 AppBar/Scaffold 없이 본문만 렌더
  final bool showEditOnAvatar; // 아바타에 연필 아이콘 표시
  final VoidCallback? onTapEditAvatar;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.isHost,
    this.embed = false,
    this.showEditOnAvatar = false,
    this.onTapEditAvatar,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final data = await MockAuthService.getUserReviews(widget.user.id);
    if (mounted) setState(() => _reviews = data);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embed) {
      return _buildBody();
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isHost ? '호스트 프로필' : '게스트 프로필'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSection(
            title: '기본 정보',
            child: Column(
              children: [
                _buildInfoRow('닉네임', widget.user.nickname),
                _buildInfoRow('성별', widget.user.genderText),
                if (widget.user.birthYear != null)
                  _buildInfoRow('연령대', widget.user.ageDecadeText),
                if (widget.user.region != null)
                  _buildInfoRow('활동 지역', widget.user.region!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '테니스 정보',
            child: Column(
              children: [
                _buildInfoRow('구력', widget.user.experienceText),
                if (widget.user.preferredCourt != null)
                  _buildInfoRow('선호 코트', widget.user.preferredCourt!),
                if (widget.user.preferredTime != null && widget.user.preferredTime!.isNotEmpty)
                  _buildInfoRow('선호 시간대', widget.user.preferredTime!.join(', ')),
                if (widget.user.playStyle != null)
                  _buildInfoRow('플레이 스타일', widget.user.playStyle!),
                _buildInfoRow('레슨 경험', widget.user.hasLesson == true ? '있음' : '없음'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '매너 점수',
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.user.mannerScoreText,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '매칭 참여 시 상대방의 매너를 평가할 수 있습니다.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '후기',
            child: _buildReviewsPreview(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '가입일',
            child: Text(
              '${widget.user.createdAt.year}년 ${widget.user.createdAt.month}월 ${widget.user.createdAt.day}일',
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        // 프로필 이미지
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Builder(
                  builder: (_) {
                    final src = widget.user.profileImage;
                    if (src == null || src.isEmpty) {
                      return Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                      );
                    }
                    if (src.startsWith('http')) {
                      return Image.network(src, fit: BoxFit.cover);
                    }
                    if (src.startsWith('file://')) {
                      return Image.file(
                        File(src.replaceFirst('file://', '')),
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                    );
                  },
                ),
              ),
            ),
            if (widget.showEditOnAvatar)
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: widget.onTapEditAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // 프로필 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.nickname,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isHost ? '매칭 호스트' : '게스트',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsPreview() {
    if (_reviews.isEmpty) {
      return Text('아직 후기가 없습니다', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary));
    }
    final preview = _expanded ? _reviews : _reviews.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...preview.map(_buildReviewItem),
        if (_reviews.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? '접기' : '더보기 (${_reviews.length - 3})'),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.reviews, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r['reviewer'] as String, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Icon(Icons.star, color: AppColors.ratingStar, size: 14),
                    Text((r['rating'] as double).toStringAsFixed(1), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const Spacer(),
                    Text('${(r['date'] as DateTime).month}/${(r['date'] as DateTime).day}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(r['content'] as String, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
