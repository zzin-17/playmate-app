import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'follow_list_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('CommunityScreen 빌드됨');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('커뮤니티'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 검색 페이지로 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () {
              _showFollowOptions();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // 알림 페이지로 이동
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          _buildFollowingTab(),
          _buildTrendingTab(),
        ],
      ),
      // 하단 네비게이션 바 제거 (MainScreen에서 관리)
      // 플로팅 액션 버튼 제거 (MainScreen에서 관리)
    );
  }

  Widget _buildFeedTab() {
    return _buildSocialFeed([
      PostData(
        title: '테니스 초보자 모임 구합니다',
        author: '테니스러버',
        content: '테니스를 시작한 지 3개월 된 초보자입니다. 같이 연습할 분들 구합니다! #테니스초보 #모임 #연습',
        likes: 12,
        comments: 8,
        timeAgo: '2시간 전',
        category: '모임',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: true,
      ),
      PostData(
        title: '백핸드 스핀 치는 법 알려주세요',
        author: '스핀마스터',
        content: '백핸드로 스핀을 치려고 하는데 자꾸 실패합니다. 팁 부탁드려요! #백핸드 #스핀 #테니스팁',
        likes: 25,
        comments: 15,
        timeAgo: '5시간 전',
        category: '테니스팁',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: false,
      ),
      PostData(
        title: '주말에 같이 테니스 치실 분?',
        author: '주말테니스',
        content: '이번 주말에 올림픽공원에서 테니스 치실 분 구합니다. 실력은 상관없어요! #주말테니스 #올림픽공원 #매칭',
        likes: 18,
        comments: 12,
        timeAgo: '1일 전',
        category: '모임',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: true,
      ),
    ]);
  }

  Widget _buildFollowingTab() {
    return _buildSocialFeed([
      PostData(
        title: '팔로우하는 사용자 게시글',
        author: '테니스프로',
        content: '팔로우하는 사용자들의 게시글만 보여집니다. #팔로잉 #테니스',
        likes: 8,
        comments: 3,
        timeAgo: '1시간 전',
        category: '일반',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: true,
      ),
    ]);
  }

  Widget _buildTrendingTab() {
    return _buildSocialFeed([
      PostData(
        title: '인기 게시글',
        author: '테니스스타',
        content: '현재 인기 있는 게시글입니다. #트렌딩 #인기',
        likes: 156,
        comments: 89,
        timeAgo: '3시간 전',
        category: '테니스팁',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: false,
      ),
      PostData(
        title: '테니스 코트 추천',
        author: '코트마스터',
        content: '서울 지역 테니스 코트 추천합니다! #코트추천 #서울',
        likes: 234,
        comments: 67,
        timeAgo: '5시간 전',
        category: '코트리뷰',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: false,
      ),
    ]);
  }

  Widget _buildFreeBoardTab() {
    return _buildPostsList([
      PostData(
        title: '테니스 라켓 추천해주세요',
        author: '라켓고민',
        content: '초보자용 테니스 라켓 추천 부탁드립니다. 예산은 20만원 정도입니다.',
        likes: 32,
        comments: 28,
        timeAgo: '3시간 전',
        category: '자유',
        isFollowing: false,
      ),
      PostData(
        title: '테니스장 예약 팁',
        author: '예약고수',
        content: '인기 테니스장 예약하는 팁을 공유합니다. 특히 주말 예약이 어려운데...',
        likes: 45,
        comments: 31,
        timeAgo: '6시간 전',
        category: '자유',
        isFollowing: false,
      ),
    ]);
  }

  Widget _buildTennisTipsTab() {
    return _buildPostsList([
      PostData(
        title: '서브 연습 방법',
        author: '서브마스터',
        content: '서브 연습을 위한 단계별 가이드입니다. 처음부터 차근차근 연습해보세요.',
        likes: 67,
        comments: 42,
        timeAgo: '1일 전',
        category: '테니스팁',
        isFollowing: false,
      ),
      PostData(
        title: '포핸드 그립 잡는 법',
        author: '그립전문가',
        content: '포핸드 그립을 제대로 잡는 방법을 설명합니다. 그립이 중요해요!',
        likes: 89,
        comments: 56,
        timeAgo: '2일 전',
        category: '테니스팁',
        isFollowing: false,
      ),
    ]);
  }

  Widget _buildSocialFeed(List<PostData> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildSocialPostCard(post);
      },
    );
  }

  Widget _buildPostsList(List<PostData> posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildSocialPostCard(PostData post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (작성자 정보 + 팔로우 버튼)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.authorProfileImage != null
                      ? NetworkImage(post.authorProfileImage!)
                      : null,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: post.authorProfileImage == null
                      ? Text(
                          post.author[0],
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!post.isFollowing)
                  TextButton(
                    onPressed: () {
                      // 팔로우 기능
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('팔로우'),
                  )
                else
                  TextButton(
                    onPressed: () {
                      // 언팔로우 기능
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('팔로잉'),
                  ),
              ],
            ),
          ),
          
          // 내용
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 액션 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // 좋아요 기능
                  },
                  icon: Icon(
                    post.likes > 0 ? Icons.favorite : Icons.favorite_border,
                    color: post.likes > 0 ? Colors.red : Colors.grey,
                  ),
                ),
                Text(
                  post.likes.toString(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    // 댓글 기능
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                ),
                Text(
                  post.comments.toString(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    // 공유 기능
                  },
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // 북마크 기능
                  },
                  icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostData post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
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
                const Spacer(),
                Text(
                  post.timeAgo,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    post.author[0],
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  post.author,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      post.likes.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        // 댓글 기능
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                    ),
                    Text(
                      post.comments.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowOptions() {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text('팔로잉 (${currentUser.followingIds?.length ?? 0})'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowListScreen(
                      title: '팔로잉',
                      userIds: currentUser.followingIds ?? [],
                      isFollowing: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text('팔로워 (${currentUser.followingIds?.length ?? 0})'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowListScreen(
                      title: '팔로워',
                      userIds: currentUser.followerIds ?? [],
                      isFollowing: false,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PostData {
  final String title;
  final String author;
  final String content;
  final int likes;
  final int comments;
  final String timeAgo;
  final String category;
  final String? authorProfileImage;
  final bool isFollowing;

  PostData({
    required this.title,
    required this.author,
    required this.content,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.category,
    this.authorProfileImage,
    required this.isFollowing,
  });
}
