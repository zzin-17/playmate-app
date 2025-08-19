import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class FollowListScreen extends StatefulWidget {
  final String title;
  final List<int> userIds;
  final bool isFollowing; // true: 팔로잉, false: 팔로워

  const FollowListScreen({
    super.key,
    required this.title,
    required this.userIds,
    required this.isFollowing,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제 API 호출로 변경
      // 현재는 Mock 데이터 사용
      _users = _getMockUsers();
    } catch (e) {
      print('사용자 목록 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> _getMockUsers() {
    return [
      User(
        id: 1,
        email: 'user1@example.com',
        nickname: '테니스왕김철수',
        gender: 'male',
        birthYear: 1990,
        region: '서울 강남구',
        skillLevel: 5,
        startYearMonth: '2020-03',
        preferredCourt: '하드코트',
        preferredTime: ['저녁'],
        playStyle: '공격적',
        hasLesson: true,
        mannerScore: 4.8,
        profileImage: 'https://via.placeholder.com/100x100',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        followingIds: [2, 3],
        followerIds: [2, 4],
        bio: '테니스 5년차입니다. 함께 즐겁게 치고 싶어요!',
      ),
      User(
        id: 2,
        email: 'user2@example.com',
        nickname: '라켓마스터',
        gender: 'female',
        birthYear: 1988,
        region: '서울 서초구',
        skillLevel: 7,
        startYearMonth: '2018-06',
        preferredCourt: '클레이코트',
        preferredTime: ['오전'],
        playStyle: '전략적',
        hasLesson: false,
        mannerScore: 4.9,
        profileImage: 'https://via.placeholder.com/100x100',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
        followingIds: [1, 3],
        followerIds: [1, 3],
        bio: '클레이코트를 좋아하는 테니스 애호가입니다.',
      ),
      User(
        id: 3,
        email: 'user3@example.com',
        nickname: '스매셔',
        gender: 'male',
        birthYear: 1992,
        region: '서울 송파구',
        skillLevel: 6,
        startYearMonth: '2019-01',
        preferredCourt: '하드코트',
        preferredTime: ['오후'],
        playStyle: '파워풀',
        hasLesson: true,
        mannerScore: 4.7,
        profileImage: 'https://via.placeholder.com/100x100',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now(),
        followingIds: [1, 2],
        followerIds: [1, 2],
        bio: '강한 서브와 스매시가 특기입니다!',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? _buildEmptyState()
              : _buildUserList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isFollowing ? Icons.people_outline : Icons.favorite_border,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            widget.isFollowing ? '아직 팔로우한 사용자가 없습니다' : '아직 팔로워가 없습니다',
            style: AppTextStyles.body.copyWith(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isFollowing 
                ? '관심 있는 사용자를 팔로우해보세요!'
                : '활발한 활동으로 팔로워를 늘려보세요!',
            style: AppTextStyles.body.copyWith(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isFollowing = currentUser?.followingIds?.contains(user.id) ?? false;
    final isCurrentUser = currentUser?.id == user.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(user.profileImage ?? 'https://via.placeholder.com/60x60'),
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 16),
            
            // 사용자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname ?? '사용자',
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.skillLevel}년차 • ${user.region}',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (user.bio != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // 팔로우/언팔로우 버튼
            if (!isCurrentUser)
              _buildFollowButton(user, isFollowing),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(User user, bool isFollowing) {
    return GestureDetector(
      onTap: () => _toggleFollow(user, isFollowing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.grey[200] : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? Colors.grey[400]! : AppColors.primary,
            width: 1,
          ),
        ),
        child: Text(
          isFollowing ? '언팔로우' : '팔로우',
          style: AppTextStyles.body.copyWith(
            color: isFollowing ? Colors.grey[700] : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFollow(User user, bool isFollowing) async {
    try {
      // TODO: 실제 API 호출로 변경
      print('${isFollowing ? "언팔로우" : "팔로우"} 시도: ${user.nickname}');
      
      // Mock: 팔로우 상태 토글
      setState(() {
        final currentUser = context.read<AuthProvider>().currentUser;
        if (currentUser != null) {
          if (isFollowing) {
            // 언팔로우
            currentUser.followingIds?.remove(user.id);
            user.followerIds?.remove(currentUser.id);
          } else {
            // 팔로우
            currentUser.followingIds ??= [];
            currentUser.followingIds!.add(user.id);
            user.followerIds ??= [];
            user.followerIds!.add(currentUser.id);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFollowing 
                ? '${user.nickname}님을 언팔로우했습니다'
                : '${user.nickname}님을 팔로우했습니다',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로우 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
