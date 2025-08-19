import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'my_hosted_matchings_screen.dart';
import 'my_guest_matchings_screen.dart';
import '../review/my_reviews_screen.dart';

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
                _buildProfileHeader(user),
                
                const SizedBox(height: 24),
                
                // 메뉴 목록
                _buildMenuSection(
                  title: '내 활동',
                  items: [
                    MenuItem(
                      icon: Icons.sports_tennis,
                      title: '내가 모집한 일정',
                      subtitle: '호스트로 등록한 매칭 일정 관리',
                      onTap: () {
                        // 내가 모집한 일정 페이지로 이동
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MyHostedMatchingsScreen(currentUser: user!),
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      icon: Icons.people,
                      title: '게스트로 참여한 일정',
                      subtitle: '참여한 매칭 일정 및 히스토리',
                      onTap: () {
                        // 게스트로 참여한 일정 페이지로 이동
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MyGuestMatchingsScreen(currentUser: user!),
                          ),
                        );
                      },
                    ),
                    MenuItem(
                      icon: Icons.chat_bubble,
                      title: '내 게시글',
                      subtitle: '작성한 게시글',
                      onTap: () {
                        // 내 게시글 페이지로 이동
                      },
                    ),
                    MenuItem(
                      icon: Icons.shopping_bag,
                      title: '내 거래',
                      subtitle: '구매/판매 내역',
                      onTap: () {
                        // 내 거래 페이지로 이동
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
                        // 프로필 편집 페이지로 이동
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

  Widget _buildProfileHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            backgroundColor: AppColors.primary.withOpacity(0.1),
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
          
          // 통계 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('매칭', '12'),
              _buildStatItem('게시글', '8'),
              _buildStatItem('거래', '5'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
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
          ),
        ),
      ],
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
                color: Colors.black.withOpacity(0.05),
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
          color: AppColors.primary.withOpacity(0.1),
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
