import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/user_service.dart';
import '../../utils/logger.dart';

class FollowListScreen extends StatefulWidget {
  final String title;
  final int userId;
  final bool isFollowing; // true: 팔로잉, false: 팔로워

  const FollowListScreen({
    super.key,
    required this.title,
    required this.userId,
    required this.isFollowing,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  final UserService _userService = UserService();

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
      // 실제 API 호출
      if (widget.isFollowing) {
        // 팔로잉 목록 조회
        _users = await _userService.getFollowing(widget.userId);
        Logger.info('팔로잉 목록 로드 완료: ${_users.length}명', tag: 'FollowListScreen');
      } else {
        // 팔로워 목록 조회
        _users = await _userService.getFollowers(widget.userId);
        Logger.info('팔로워 목록 로드 완료: ${_users.length}명', tag: 'FollowListScreen');
      }
    } catch (e) {
      Logger.error('사용자 목록 로드 실패', tag: 'FollowListScreen', error: e);
      setState(() {
        _users = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user.profileImage != null 
                ? NetworkImage(user.profileImage!) 
                : null,
              child: user.profileImage == null 
                ? Text(
                    user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  )
                : null,
            ),
            const SizedBox(width: 16),
            
            // 사용자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname,
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
          isFollowing ? '팔로잉' : '팔로우',
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
      bool success = false;
      
      if (isFollowing) {
        // 언팔로우
        success = await _userService.unfollowUser(user.id);
      } else {
        // 팔로우
        success = await _userService.followUser(user.id);
      }
      
      if (success) {
        // 성공 시 로컬 상태도 업데이트
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
                  ? '${user.nickname}님 팔로우를 취소했습니다'
                  : '${user.nickname}님 팔로우를 성공했습니다',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        throw Exception('API 호출 실패');
      }
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
