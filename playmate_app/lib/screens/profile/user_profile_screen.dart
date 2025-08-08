import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class UserProfileScreen extends StatelessWidget {
  final User user;
  final bool isHost;

  const UserProfileScreen({
    super.key,
    required this.user,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isHost ? '호스트 프로필' : '게스트 프로필'),
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
            // 프로필 헤더
            _buildProfileHeader(),
            const SizedBox(height: 24),
            
            // 기본 정보
            _buildSection(
              title: '기본 정보',
              child: Column(
                children: [
                  _buildInfoRow('닉네임', user.nickname),
                  _buildInfoRow('성별', user.genderText),
                  if (user.birthYear != null)
                    _buildInfoRow('나이', '${DateTime.now().year - user.birthYear!}세'),
                  if (user.region != null)
                    _buildInfoRow('활동 지역', user.region!),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 테니스 정보
            _buildSection(
              title: '테니스 정보',
              child: Column(
                children: [
                  _buildInfoRow('구력', user.skillLevelText),
                  if (user.preferredCourt != null)
                    _buildInfoRow('선호 코트', user.preferredCourt!),
                  if (user.preferredTime != null && user.preferredTime!.isNotEmpty)
                    _buildInfoRow('선호 시간대', user.preferredTime!.join(', ')),
                  if (user.playStyle != null)
                    _buildInfoRow('플레이 스타일', user.playStyle!),
                  _buildInfoRow('레슨 경험', user.hasLesson == true ? '있음' : '없음'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 매너 점수
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
                        user.mannerScoreText,
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

            // 가입일
            _buildSection(
              title: '가입일',
              child: Text(
                '${user.createdAt.year}년 ${user.createdAt.month}월 ${user.createdAt.day}일',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        // 프로필 이미지
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Builder(
              builder: (_) {
                final src = user.profileImage;
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
        const SizedBox(width: 16),
        
        // 프로필 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.nickname,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isHost ? '매칭 호스트' : '게스트',
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
}
