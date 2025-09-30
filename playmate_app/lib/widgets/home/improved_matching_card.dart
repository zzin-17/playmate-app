import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../services/location_service.dart';

class ImprovedMatchingCard extends StatelessWidget {
  final Matching matching;
  final User? currentUser;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ImprovedMatchingCard({
    super.key,
    required this.matching,
    required this.currentUser,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isHost = currentUser != null && matching.host.email == currentUser!.email;
    final isExpired = matching.date.isBefore(DateTime.now());
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isExpired ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpired 
                ? AppColors.textSecondary.withValues(alpha: 0.3)
                : _getStatusColor(matching.actualStatus).withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpired 
                  ? Colors.grey.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 코트명, 상태, 액션 버튼
              _buildHeader(isHost),
              
              // 메인 정보: 날짜, 시간, 위치
              _buildMainInfo(),
              
              // 게임 정보: 유형, 구력, 연령
              _buildGameInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isHost) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _getStatusColor(matching.actualStatus).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // 코트명
          Expanded(
            child: Row(
              children: [
                if (matching.isFollowersOnly) ...[
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    matching.courtName,
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(matching.actualStatus),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(matching.actualStatus),
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(matching.actualStatus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // 호스트 액션 버튼
          if (isHost) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16),
                      SizedBox(width: 8),
                      Text('삭제'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainInfo() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // 날짜와 시간
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(matching.date),
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                matching.timeSlot,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // 위치 정보 (시군구 표시)
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FutureBuilder<String>(
                  future: LocationService().getDistrictFromCoordinates(matching.courtLat, matching.courtLng),
                  builder: (context, snapshot) {
                    final location = snapshot.data ?? '위치 정보 없음';
                    return Text(
                      location,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // 모집 인원 정보
          Row(
            children: [
              Icon(
                Icons.people,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                matching.recruitCountText,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
          // 상태별 인원 표시
          if (matching.remainingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${matching.remainingCount}명 남음',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            )
          else if (matching.remainingCount == 0 && matching.actualStatus == 'recruiting')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '모집 완료',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 게임 유형
          Expanded(
            child: _buildInfoItem(
              icon: Icons.sports_tennis,
              label: '게임',
              value: _getGameTypeText(matching.gameType),
            ),
          ),
          
          // 구력
          Expanded(
            child: _buildInfoItem(
              icon: Icons.trending_up,
              label: '구력',
              value: '${matching.minLevel}~${matching.maxLevel}년',
            ),
          ),
          
          // 연령
          Expanded(
            child: _buildInfoItem(
              icon: Icons.person,
              label: '연령',
              value: '${matching.minAge}~${matching.maxAge}세',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 12,
          color: AppColors.primary,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'recruiting':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'recruiting':
        return Icons.person_add;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'recruiting':
        return '모집중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return status;
    }
  }

  String _getGameTypeText(String gameType) {
    switch (gameType) {
      case 'mixed':
        return '혼복';
      case 'male_doubles':
        return '남복';
      case 'female_doubles':
        return '여복';
      case 'singles':
        return '단식';
      default:
        return gameType;
    }
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return '오늘';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return '내일';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return '어제';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
