import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'my_hosted_matchings_screen.dart';
import 'my_guest_matchings_screen.dart';
import 'my_bookmarks_screen.dart';
import '../review/my_reviews_screen.dart';
import '../community/community_screen.dart';
import '../profile/edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 설정 페이지로 이동
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 프로필 헤더
                _buildProfileHeader(context, user),
                
                const SizedBox(height: 24),
                
                // 메뉴 목록
                _buildMenuSection(
                  title: '추가 기능',
                  items: [
                    MenuItem(
                      icon: Icons.bookmark_outline,
                      title: '내가 북마크한 게시글',
                      subtitle: '북마크한 게시글 목록',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MyBookmarksScreen(),
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      icon: Icons.favorite,
                      title: '내가 좋아요한 게시글',
                      subtitle: '좋아요한 게시글 목록',
                      onTap: () {
                        // 내가 좋아요한 게시글 페이지로 이동
                      },
                    ),
                    MenuItem(
                      icon: Icons.comment,
                      title: '내가 댓글단 게시글',
                      subtitle: '댓글을 작성한 게시글 목록',
                      onTap: () {
                        // 내가 댓글단 게시글 페이지로 이동
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                _buildMenuSection(
                  title: '리뷰',
                  items: [
                    MenuItem(
                      icon: Icons.rate_review,
                      title: '나의 리뷰',
                      subtitle: '나를 평가한 리뷰 확인',
                      onTap: () {
                        // 나의 리뷰 페이지로 이동
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MyReviewsScreen(currentUser: user!),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                _buildMenuSection(
                  title: '설정',
                  items: [
                    MenuItem(
                      icon: Icons.person,
                      title: '프로필 편집',
                      subtitle: '개인정보 수정',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(currentUser: user!),
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      icon: Icons.notifications,
                      title: '알림 설정',
                      subtitle: '푸시 알림 관리',
                      onTap: () {
                        // 알림 설정 페이지로 이동
                      },
                    ),
                    MenuItem(
                      icon: Icons.privacy_tip,
                      title: '개인정보',
                      subtitle: '개인정보 처리방침',
                      onTap: () {
                        // 개인정보 페이지로 이동
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                _buildMenuSection(
                  title: '지원',
                  items: [
                    MenuItem(
                      icon: Icons.help,
                      title: '도움말',
                      subtitle: '자주 묻는 질문',
                      onTap: () {
                        // 도움말 페이지로 이동
                      },
                    ),
                    MenuItem(
                      icon: Icons.feedback,
                      title: '문의하기',
                      subtitle: '고객센터 연락처',
                      onTap: () {
                        // 문의하기 페이지로 이동
                      },
                    ),
                    MenuItem(
                      icon: Icons.info,
                      title: '앱 정보',
                      subtitle: '버전 1.0.0',
                      onTap: () {
                        // 앱 정보 페이지로 이동
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // 로그아웃 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 로그아웃 확인 다이얼로그
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text('정말 로그아웃 하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('로그아웃'),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldLogout == true) {
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              user?.nickname?.substring(0, 1) ?? 'U',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 사용자 이름
          Text(
            user?.nickname ?? '사용자',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 이메일
          Text(
            user?.email ?? 'email@example.com',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const SizedBox(height: 16),
          
          // 통계 정보 (클릭 가능한 카드)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  value: '12',
                  label: '매칭',
                  onTap: () => _navigateToMatching(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.article,
                  value: '8',
                  label: '게시글',
                  onTap: () => _navigateToPosts(context),
                ),
              ),
              // TODO: 거래 기능 구현 완료 시 활성화
              // const SizedBox(width: 12),
              // Expanded(
              //   child: _buildStatCard(
              //     icon: Icons.shopping_bag,
              //     value: '5',
              //     label: '거래',
              //     onTap: () => _navigateToTransactions(),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 네비게이션 메서드들
  void _navigateToMatching(BuildContext context) {
    // 매칭 관련 페이지로 이동 (내가 모집한 일정)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyHostedMatchingsScreen(
          currentUser: context.read<AuthProvider>().currentUser!,
        ),
      ),
    );
  }

  void _navigateToPosts(BuildContext context) {
    // 내 게시글 페이지로 이동 (내가 작성한 글)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CommunityScreen(),
      ),
    );
  }

  void _navigateToTransactions(BuildContext context) {
    // 내 거래 페이지로 이동
    // TODO: 내 거래 페이지 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('거래 기능은 곧 구현될 예정입니다! 💰'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) => _buildMenuItem(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        item.title,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: item.onTap,
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
