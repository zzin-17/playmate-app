import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../services/user_service.dart';
import '../../services/community_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// 특정 사용자의 프로필 홈화면
class UserProfileHomeScreen extends StatefulWidget {
  final User user;
  final bool fromCommunity; // 커뮤니티에서 왔는지 여부

  const UserProfileHomeScreen({
    Key? key,
    required this.user,
    this.fromCommunity = false,
  }) : super(key: key);

  @override
  State<UserProfileHomeScreen> createState() => _UserProfileHomeScreenState();
}

class _UserProfileHomeScreenState extends State<UserProfileHomeScreen> {
  final UserService _userService = UserService();
  final CommunityService _communityService = CommunityService();
  
  User? _currentUser;
  User? _latestUser; // 최신 사용자 정보
  List<Post> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // build 완료 후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 현재 사용자 정보 로드 (최신 정보로 업데이트)
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadCurrentUser(); // 최신 정보 로드
      _currentUser = authProvider.currentUser;
      
      // 최신 사용자 프로필 정보 가져오기
      final latestUser = await _userService.getUserProfile(widget.user.id);
      if (latestUser == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }
      
      // 팔로우 상태 확인
      if (_currentUser != null) {
        _isFollowing = _currentUser!.followingIds?.contains(latestUser.id) ?? false;
        print('🔍 팔로우 상태 확인 - 현재 사용자: ${_currentUser!.nickname}');
        print('🔍 현재 사용자 팔로잉 목록: ${_currentUser!.followingIds}');
        print('🔍 대상 사용자 ID: ${latestUser.id}');
        print('🔍 팔로우 상태: $_isFollowing');
      }

      // 사용자 게시글 로드
      final posts = await _communityService.getUserPosts(widget.user.id);
      
      // 디버그 로그 추가
      print('🔍 사용자 프로필 데이터: ${latestUser.nickname}');
      print('🔍 팔로워 수: ${latestUser.followerIds?.length ?? 0}');
      print('🔍 팔로워 ID들: ${latestUser.followerIds}');
      print('🔍 팔로잉 수: ${latestUser.followingIds?.length ?? 0}');
      print('🔍 팔로잉 ID들: ${latestUser.followingIds}');
      
      setState(() {
        _userPosts = posts;
        _latestUser = latestUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUser == null) return;

    try {
      bool success;
      if (_isFollowing) {
        success = await _userService.unfollowUser(widget.user.id);
      } else {
        success = await _userService.followUser(widget.user.id);
      }

      if (success && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });

        // 현재 사용자 정보 새로고침
        final authProvider = context.read<AuthProvider>();
        await authProvider.loadCurrentUser();
        _currentUser = authProvider.currentUser;
        
        // 팔로우 상태 다시 확인
        if (_latestUser != null) {
          _isFollowing = _currentUser?.followingIds?.contains(_latestUser!.id) ?? false;
          print('🔍 팔로우 후 상태 업데이트: $_isFollowing');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing 
              ? '${widget.user.nickname}님 팔로우를 성공했습니다' 
              : '${widget.user.nickname}님 팔로우를 취소했습니다'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('팔로우 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.nickname),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: widget.fromCommunity
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // 커뮤니티에서 왔으면 커뮤니티로 돌아가기
                Navigator.popUntil(context, (route) {
                  return route.settings.name == '/community' || 
                         route.isFirst;
                });
              },
            )
          : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? _buildErrorWidget()
          : _buildProfileContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: AppTextStyles.body.copyWith(
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 프로필 헤더
          _buildProfileHeader(),
          const Divider(height: 1),
          
          // 게시글 목록
          _buildPostsList(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _latestUser ?? widget.user; // 최신 사용자 정보 사용
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        children: [
          // 닉네임과 프로필사진을 한 줄에
          Row(
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
                      user.nickname.isNotEmpty 
                        ? user.nickname[0].toUpperCase() 
                        : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 16),
              
              // 닉네임과 기본 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname,
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.skillLevel ?? 0}년차 • ${user.region ?? '지역 미설정'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 팔로우 버튼
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[300] : AppColors.primary,
                  foregroundColor: _isFollowing ? Colors.grey[600] : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: _isFollowing 
                      ? BorderSide(color: Colors.grey[400]!)
                      : BorderSide.none,
                  ),
                ),
                child: Text(
                  _isFollowing ? '팔로잉' : '팔로우',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // 자기소개 (텍스트 및 태그)
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                user.bio!,
                style: AppTextStyles.body,
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // 팔로워 수와 매칭후기점수
          Row(
            children: [
              // 팔로워 수
              Row(
                children: [
                  Text(
                    '팔로워 ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${user.followerIds?.length ?? 0}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 24),
              
              // 매칭후기점수
              Row(
                children: [
                  Text(
                    '매칭후기 ',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${user.mannerScore ?? 5.0}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    final user = _latestUser ?? widget.user; // 최신 사용자 정보 사용
    
    if (_userPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '${user.nickname}님이 작성한 게시글이 없습니다',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Post post) {
    final user = _latestUser ?? widget.user; // 최신 사용자 정보 사용
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 게시글 상세 화면으로 이동
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (context) => PostDetailScreen(post: post),
          // ));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 게시글 헤더 (작성자 정보, 시간)
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: user.profileImage != null 
                      ? NetworkImage(user.profileImage!) 
                      : null,
                    child: user.profileImage == null 
                      ? Text(
                          user.nickname[0].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nickname,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 카테고리 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.category,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 게시글 내용
              Text(
                post.content,
                style: AppTextStyles.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 해시태그
              if (post.hashtags != null && post.hashtags!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: post.hashtags!.map((tag) => 
                    Text(
                      '#$tag',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // 게시글 통계 (좋아요, 댓글 등)
              Row(
                children: [
                  Icon(
                    post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: post.isLikedByCurrentUser ? AppColors.error : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likeCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(post.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
