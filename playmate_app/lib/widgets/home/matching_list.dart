import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import 'improved_matching_card.dart';

class MatchingList extends StatelessWidget {
  final List<Matching> matchings;
  final User? currentUser;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final Function(Matching) onMatchingTap;
  final Function(Matching)? onMatchingEdit;
  final Function(Matching)? onMatchingDelete;

  const MatchingList({
    super.key,
    required this.matchings,
    required this.currentUser,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onMatchingTap,
    this.onMatchingEdit,
    this.onMatchingDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && matchings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null && matchings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (matchings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '매칭이 없습니다',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 매칭을 만들어보세요!',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matchings.length,
        itemBuilder: (context, index) {
          final matching = matchings[index];
          return ImprovedMatchingCard(
            matching: matching,
            currentUser: currentUser,
            onTap: () => onMatchingTap(matching),
            onEdit: onMatchingEdit != null 
              ? () => onMatchingEdit!(matching)
              : null,
            onDelete: onMatchingDelete != null 
              ? () => onMatchingDelete!(matching)
              : null,
          );
        },
      ),
    );
  }
}
