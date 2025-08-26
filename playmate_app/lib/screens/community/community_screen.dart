import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_logo.dart';
import 'follow_list_screen.dart';
import 'comment_screen.dart';
import 'create_post_screen.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../services/share_service.dart';
import '../../services/report_service.dart';
import '../../services/block_service.dart';
import '../../services/notification_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/mock_post_service.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 게시글 데이터
  final List<PostData> _feedPosts = [];
  final List<PostData> _followingPosts = [];
  final List<PostData> _trendingPosts = [];
  final List<PostData> _myPosts = []; // 내 게시글 추가
  
  // 로딩 상태
  bool _isLoading = false;
  bool _isRefreshing = false;
  
  // 필터 상태
  String _currentFilter = '전체'; // 전체, 팔로잉, 인기
  
  // 무한 스크롤 관련 상태
  bool _hasMoreData = true;
  int _currentPage = 1;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();

    @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2개 탭으로 변경
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
    
    // 초기 데이터 로딩
    _loadInitialData();
    _loadMyPosts(); // 내 게시글 로드 추가
  }

  // 본문에서 해시태그 추출
  List<String> _extractHashtagsFromContent(String content) {
    final hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(content);
    return matches.map((match) => match.group(1)!).toList();
  }

  // 본문과 해시태그를 함께 표시 (해시태그는 칩으로 변환)
  Widget _buildContentWithHashtags(String content) {
    final hashtagRegex = RegExp(r'#(\w+)');
    final parts = content.split(hashtagRegex);
    final hashtags = hashtagRegex.allMatches(content).toList();
    
    if (hashtags.isEmpty) {
      // 해시태그가 없으면 일반 텍스트만 표시
      return Text(
        content,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      );
    }
    
    // 해시태그가 있으면 텍스트와 해시태그를 분리해서 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 일반 텍스트 부분
        if (parts[0].isNotEmpty)
          Text(
            parts[0],
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        
        // 해시태그들을 칩으로 표시
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hashtags.map((match) {
            final tag = match.group(1)!;
            return InkWell(
              onTap: () => _searchByHashtag(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        // 나머지 텍스트가 있으면 표시
        if (parts.length > 1 && parts[1].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              parts[1],
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  // 게시글 등록 후 피드 새로고침
  void _refreshFeedAfterPostCreation(Map<String, dynamic>? postData) {
    if (postData != null) {
      // 새로 등록된 게시글을 피드 맨 위에 추가
      final newPost = PostData(
        id: DateTime.now().millisecondsSinceEpoch, // 고유 ID 생성
        title: '새 게시글', // 제목 없음
        author: postData['author'] ?? '현재 사용자',
        authorId: postData['authorId'] ?? 999,
        content: postData['content'] ?? '내용 없음',
        likes: 0,
        comments: 0,
        timeAgo: '방금 전',
        category: '일반', // 기본 카테고리
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: false,
        isLiked: false,
        isBookmarked: false,
        shareCount: 0,
        isSharedByCurrentUser: false,
        hashtags: _extractHashtagsFromContent(postData['content'] ?? ''),
      );
      
      setState(() {
        _feedPosts.insert(0, newPost); // 맨 위에 새 게시글 추가
        _myPosts.insert(0, newPost); // 내 게시글에도 추가
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('CommunityScreen 빌드됨');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 테니스 공 아이콘
            Container(
              width: 28 * 0.6,
              height: 28 * 0.6,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.sports_tennis,
                  color: AppColors.primary,
                  size: 28 * 0.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 커뮤니티 텍스트
            Text(
              '커뮤니티',
              style: TextStyle(
                fontSize: 28 * 0.6,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
                letterSpacing: -0.5,
              ),
            ),
            // 장식 요소
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: _isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                ),
              )
            : const Icon(Icons.refresh),
          onPressed: _isLoading ? null : () {
            _refreshFeedAfterPostCreation(null);
          },
          tooltip: '새로고침',
        ),
        actions: [
          // 팔로우 관리 버튼
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () {
              _showFollowManagement();
            },
            tooltip: '팔로우 관리',
          ),
          // 알림 버튼
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // 알림 페이지로 이동
            },
            tooltip: '알림',
          ),
        ],
      ),
      body: Column(
        children: [
          // 탭 바와 필터를 같은 줄에 배치
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    // 탭 바 (왼쪽)
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        labelStyle: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                        tabs: const [
                          Tab(text: 'All'),
                          Tab(text: 'My'),
                        ],
                      ),
                    ),
                    // 필터 드롭다운 (오른쪽)
                    _buildFilterDropdown(),
                  ],
                ),
                // 하단 구분선 추가
                Container(
                  height: 1,
                  color: AppColors.cardBorder,
                ),
              ],
            ),
          ),
          // 탭 뷰
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeedTabWithFilter(), // 필터가 포함된 전체 탭
                _buildMyPostsTab(), // 내 게시글 탭
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 게시글 작성 페이지로 이동
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          
          // 게시글이 생성되면 피드 새로고침
          if (result != null && result is Map<String, dynamic>) {
            _refreshFeedAfterPostCreation(result);
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFeedTabWithFilter() {
    return Column(
      children: [
        // 필터 바 제거 (상단 탭과 같은 줄에 통합)
        // 게시글 목록
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshFeedAfterPostCreation(null);
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final posts = _getFilteredPosts();
                      if (index >= posts.length) {
                        // 로딩 인디케이터 또는 더 이상 데이터 없음
                        if (_isLoading) {
                          return _buildLoadingIndicator();
                        } else if (!_hasMoreData && posts.isNotEmpty) {
                          return _buildEndOfListIndicator();
                        } else {
                          return const SizedBox.shrink();
                        }
                      }
                      
                      return _buildPostCard(posts[index]);
                    },
                    childCount: _getFilteredPosts().length + (_hasMoreData || _isLoading ? 1 : 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 90, // 오버플로우 완전 해결을 위해 더 늘림
      height: 36, // 높이 고정으로 일관성 확보
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent, // 디자인시스템의 Cream Yellow 사용
        borderRadius: BorderRadius.circular(18), // 더 둥근 모서리
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.4), // Light Orange 테두리
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentFilter,
          icon: Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSurface, // Charcoal Navy 화살표
            size: 20,
          ),
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSurface, // Charcoal Navy 텍스트
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          items: const [
            DropdownMenuItem(
              value: '전체',
              child: Text('전체'),
            ),
            DropdownMenuItem(
              value: '팔로잉',
              child: Text('팔로잉'),
            ),
            DropdownMenuItem(
              value: '인기',
              child: Text('인기'),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _currentFilter = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  List<PostData> _getFilteredPosts() {
    switch (_currentFilter) {
      case '팔로잉':
        return _followingPosts;
      case '인기':
        return _trendingPosts;
      default:
        return _feedPosts;
    }
  }

  Widget _buildFollowingTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshFeedAfterPostCreation(null);
      },
      child: _buildSocialFeed([
        PostData(
          id: 101,
          title: '팔로우하는 사용자 게시글 1',
          author: '테니스프로',
          authorId: 101,
          content: '팔로우하는 사용자들의 게시글만 보여집니다. 오늘은 서브 연습을 했어요! #팔로잉 #테니스 #서브연습',
          likes: 8,
          comments: 3,
          timeAgo: '1시간 전',
          category: '일반',
          authorProfileImage: 'https://via.placeholder.com/40x40',
          isFollowing: true,
          isLiked: false,
          isBookmarked: false,
          shareCount: 1,
          isSharedByCurrentUser: false,
          hashtags: ['팔로잉', '테니스', '서브연습'],
        ),
        PostData(
          id: 102,
          title: '테니스 동호회 모임 후기',
          author: '동호회장',
          authorId: 102,
          content: '지난 주에 진행한 동호회 모임이 성공적으로 마무리되었습니다. 다음 모임도 기대해주세요! #동호회 #모임 #후기',
          likes: 15,
          comments: 7,
          timeAgo: '3시간 전',
          category: '모임',
          authorProfileImage: 'https://via.placeholder.com/40x40',
          isFollowing: true,
          isLiked: true,
          isBookmarked: true,
          shareCount: 3,
          isSharedByCurrentUser: false,
          hashtags: ['동호회', '모임', '후기'],
        ),
        PostData(
          id: 103,
          title: '테니스 레슨 추천',
          author: '레슨생',
          authorId: 103,
          content: '잠실 지역에서 좋은 테니스 레슨을 받고 있습니다. 초보자도 쉽게 배울 수 있어요! #레슨 #추천 #잠실',
          likes: 22,
          comments: 12,
          timeAgo: '5시간 전',
          category: '일반',
          authorProfileImage: 'https://via.placeholder.com/40x40',
          isFollowing: true,
          isLiked: false,
          isBookmarked: false,
          shareCount: 5,
          isSharedByCurrentUser: false,
          hashtags: ['레슨', '추천', '잠실'],
        ),
      ]),
    );
  }

  Widget _buildTrendingTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshFeedAfterPostCreation(null);
      },
      child: _buildSocialFeed([
        PostData(
          id: 201,
          title: '🔥 인기 게시글 - 테니스 서브 마스터하기',
          author: '테니스스타',
          authorId: 201,
          content: '현재 인기 있는 게시글입니다. 서브 연습 방법과 팁을 공유합니다! #트렌딩 #인기 #서브 #테니스팁',
          likes: 156,
          comments: 89,
          timeAgo: '3시간 전',
          category: '테니스팁',
          authorProfileImage: 'https://via.placeholder.com/40x40',
          isFollowing: false,
          isLiked: false,
          isBookmarked: false,
          shareCount: 25,
          isSharedByCurrentUser: false,
          hashtags: ['트렌딩', '인기', '서브', '테니스팁'],
        ),
        PostData(
          id: 202,
          title: '🏆 테니스 코트 추천 - 서울 최고의 코트들',
          author: '코트마스터',
          authorId: 202,
          content: '서울 지역 테니스 코트 추천합니다! 잠실, 올림픽공원, 한강공원 등 인기 코트 정보! #코트추천 #서울 #테니스장',
          likes: 234,
          comments: 67,
          timeAgo: '5시간 전',
          category: '코트리뷰',
          authorProfileImage: 'https://via.placeholder.com/40x40',
          isFollowing: false,
          isLiked: false,
          isBookmarked: false,
          shareCount: 42,
          isSharedByCurrentUser: false,
          hashtags: ['코트추천', '서울', '테니스장'],
        ),
        PostData(
          id: 203,
          title: '💪 테니스 체력 훈련 가이드',
          author: '피트니스코치',
          authorId: 203,
          content: '테니스에 필요한 체력 훈련 방법을 알려드립니다. 지구력, 순발력, 근력 향상! #체력훈련 #테니스 #피트니스',
          likes: 189,
          comments: 45,
          timeAgo: '7시간 전',
          category: '테니스팁',
          authorProfileImage: 'https://via.placeholder.com/40x40',
          isFollowing: false,
          isLiked: true,
          isBookmarked: true,
          shareCount: 18,
          isSharedByCurrentUser: false,
          hashtags: ['체력훈련', '테니스', '피트니스'],
        ),
        PostData(
          id: 204,
          title: '🎾 테니스 라켓 선택 가이드 2024',
          author: '라켓전문가',
          authorId: 204,
          content: '2024년 최신 테니스 라켓 추천과 선택 가이드입니다. 초보자부터 고급자까지! #라켓추천 #테니스용품 #가이드',
          likes: 312,
          comments: 78,
          timeAgo: '1일 전',
          category: '용품리뷰',
          authorProfileImage: 'https://via.placeholder.com/40x40',
          isFollowing: false,
          isLiked: false,
          isBookmarked: false,
          shareCount: 67,
          isSharedByCurrentUser: false,
          hashtags: ['라켓추천', '테니스용품', '가이드'],
        ),
      ]),
    );
  }

  Widget _buildMyPostsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadMyPosts(); // 내 게시글 새로고침
      },
      child: _myPosts.isEmpty
          ? _buildEmptyMyPosts()
          : ListView.builder(
              itemCount: _myPosts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(_myPosts[index]);
              },
            ),
    );
  }

  Widget _buildEmptyMyPosts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 작성한 게시글이 없습니다',
            style: AppTextStyles.h3.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 게시글을 작성해보세요!',
            style: AppTextStyles.body.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeBoardTab() {
    return _buildPostsList([
      PostData(
        id: 7,
        title: '테니스 라켓 추천해주세요',
        author: '라켓고민',
        authorId: 7,
        content: '초보자용 테니스 라켓 추천 부탁드립니다. 예산은 20만원 정도입니다.',
        likes: 32,
        comments: 28,
        timeAgo: '3시간 전',
        category: '자유',
        authorProfileImage: null,
        isFollowing: false,
        isLiked: false,
        isBookmarked: false,
        hashtags: ['라켓추천', '초보자'],
      ),
      PostData(
        id: 8,
        title: '테니스장 예약 팁',
        author: '예약고수',
        authorId: 8,
        content: '인기 테니스장 예약하는 팁을 공유합니다. 특히 주말 예약이 어려운데...',
        likes: 45,
        comments: 31,
        timeAgo: '6시간 전',
        category: '자유',
        authorProfileImage: null,
        isFollowing: false,
        isLiked: false,
        isBookmarked: false,
        hashtags: ['예약팁', '테니스장'],
      ),
    ]);
  }

  Widget _buildTennisTipsTab() {
    return _buildPostsList([
      PostData(
        id: 9,
        title: '서브 연습 방법',
        author: '서브마스터',
        authorId: 9,
        content: '서브 연습을 위한 단계별 가이드입니다. 처음부터 차근차근 연습해보세요.',
        likes: 67,
        comments: 42,
        timeAgo: '1일 전',
        category: '테니스팁',
        authorProfileImage: null,
        isFollowing: false,
        isLiked: false,
        isBookmarked: false,
        hashtags: ['서브', '연습', '가이드'],
      ),
      PostData(
        id: 10,
        title: '포핸드 그립 잡는 법',
        author: '그립전문가',
        authorId: 10,
        content: '포핸드 그립을 제대로 잡는 방법을 설명합니다. 그립이 중요해요!',
        likes: 89,
        comments: 56,
        timeAgo: '2일 전',
        category: '테니스팁',
        authorProfileImage: null,
        isFollowing: false,
        isLiked: false,
        isBookmarked: false,
        hashtags: ['포핸드', '그립', '기술'],
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
            // 1. 프로필사진 & 아이디
            Row(
              children: [
                // 프로필 사진
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: post.authorProfileImage != null 
                    ? NetworkImage(post.authorProfileImage!) 
                    : null,
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
                // 사용자 정보
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
                // 더보기 메뉴
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onSelected: (value) => _handleMenuAction(value, post),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report, size: 16),
                          SizedBox(width: 8),
                          Text('신고하기'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 16),
                          SizedBox(width: 8),
                          Text('사용자 차단'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, size: 16),
                          SizedBox(width: 8),
                          Text('게시글 숨기기'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 2. 내용 + 해시태그
            _buildContentWithHashtags(post.content),
            const SizedBox(height: 16),
            // 4. 좋아요, 댓글, 북마크
            Row(
              children: [
                // 좋아요 버튼
                InkWell(
                  onTap: () => _toggleLike(post),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: post.isLiked ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.likes.toString(),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // 댓글 버튼
                InkWell(
                  onTap: () {
                    _navigateToComments(post);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline, 
                        size: 20, 
                        color: Colors.grey
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.comments.toString(),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 24),
                
                // 북마크 버튼
                InkWell(
                  onTap: () => _toggleBookmark(post),
                  child: Icon(
                    post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: post.isBookmarked ? AppColors.primary : Colors.grey,
                  ),
                ),
                
                const Spacer(),
                
                // 공유 버튼 (추가 기능)
                InkWell(
                  onTap: () => _sharePost(post),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isSharedByCurrentUser ? Icons.share : Icons.share_outlined,
                        size: 20,
                        color: post.isSharedByCurrentUser ? AppColors.primary : Colors.grey,
                      ),
                      if (post.shareCount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          post.shareCount.toString(),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFollowManagement() {
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
              subtitle: const Text('내가 팔로우하는 사용자들'),
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
              leading: const Icon(Icons.people),
              title: Text('팔로워 (${currentUser.followingIds?.length ?? 0})'),
              subtitle: const Text('나를 팔로우하는 사용자들'),
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
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('사용자 검색'),
              subtitle: const Text('새로운 사용자 찾기'),
              onTap: () {
                Navigator.pop(context);
                _showUserSearch();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserSearch() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('사용자 검색'),
          content: const Text('사용자 검색 기능은 곧 구현될 예정입니다!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToComments(PostData postData) {
    // PostData를 Post로 변환
    final post = Post(
      id: postData.id,
      authorId: 1, // TODO: 실제 작성자 ID로 변경
      authorNickname: postData.author,
      authorProfileImage: postData.authorProfileImage,
      title: postData.title,
      content: postData.content,
      category: postData.category,
      likeCount: postData.likes,
      commentCount: postData.comments,
      shareCount: postData.shareCount,
      isLikedByCurrentUser: postData.isLiked,
      isBookmarkedByCurrentUser: postData.isBookmarked,
      isSharedByCurrentUser: postData.isSharedByCurrentUser,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: post),
      ),
    );
  }



  void _toggleLike(PostData post) async {
    setState(() {
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes++;
      } else {
        post.likes--;
      }
    });

    // 좋아요 시 알림 표시
    if (post.isLiked) {
      await NotificationService().showLikeNotification(
        postTitle: post.title,
        likerName: '현재 사용자', // TODO: 실제 사용자 이름으로 변경
      );
    }
  }

  Future<void> _toggleBookmark(PostData post) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        final isBookmarked = await BookmarkService.toggleBookmark(currentUser.id, post.id);
        
        setState(() {
          post.isBookmarked = isBookmarked;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBookmarked ? '북마크에 추가되었습니다' : '북마크에서 제거되었습니다'),
              backgroundColor: isBookmarked ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('북마크 처리 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sharePost(PostData post) async {
    // PostData를 Post로 변환
    final postModel = Post(
      id: post.id,
      authorId: 1, // TODO: 실제 작성자 ID로 변경
      authorNickname: post.author,
      authorProfileImage: post.authorProfileImage,
      title: post.title,
      content: post.content,
      category: post.category,
      likeCount: post.likes,
      commentCount: post.comments,
      shareCount: post.shareCount,
      isLikedByCurrentUser: post.isLiked,
      isBookmarkedByCurrentUser: post.isBookmarked,
      isSharedByCurrentUser: post.isSharedByCurrentUser,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    // 공유 서비스 호출
    await ShareService().sharePost(postModel, context);
    
    // 공유 상태 업데이트
    setState(() {
      post.isSharedByCurrentUser = true;
      post.shareCount++;
    });

    // 공유 시 알림 표시
    await NotificationService().showShareNotification(
      postTitle: post.title,
      sharerName: '현재 사용자', // TODO: 실제 사용자 이름으로 변경
    );
  }

  void _searchByHashtag(String hashtag) {
    // TODO: 해시태그 검색 기능 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"#$hashtag" 검색 결과를 보여줍니다.'),
        action: SnackBarAction(
          label: '확인',
          onPressed: () {},
        ),
      ),
    );
  }

  /// 초기 데이터 로딩
  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
    });

    try {
      // 초기 데이터를 바로 추가
      final initialPosts = _getMockPostsForPage(1);
      setState(() {
        _feedPosts.clear();
        _feedPosts.addAll(initialPosts);
        _currentPage = 2; // 다음 페이지부터 시작
      });
      
      // 추가 데이터 로딩 시뮬레이션
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('초기 데이터 로딩 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 추가 데이터 로딩
  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제 API 호출로 변경
      await Future.delayed(const Duration(milliseconds: 800)); // 로딩 시뮬레이션
      
      final newPosts = _getMockPostsForPage(_currentPage);
      
      if (newPosts.isEmpty) {
        setState(() {
          _hasMoreData = false;
        });
      } else {
        setState(() {
          _feedPosts.addAll(newPosts);
          _currentPage++;
        });
      }
    } catch (e) {
      print('추가 데이터 로딩 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 스크롤 이벤트 처리
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  /// 페이지별 목업 데이터 생성
  List<PostData> _getMockPostsForPage(int page) {
    if (page > 3) return []; // 3페이지까지만 데이터 제공
    
    final startIndex = (page - 1) * _pageSize;
    final allPosts = _getAllMockPosts();
    
    if (startIndex >= allPosts.length) return [];
    
    final endIndex = (startIndex + _pageSize).clamp(0, allPosts.length);
    return allPosts.sublist(startIndex, endIndex);
  }

  /// 모든 목업 데이터
  List<PostData> _getAllMockPosts() {
    return MockPostService.getAllMockPosts();
  }

  /// 내 게시글 로드
  Future<void> _loadMyPosts() async {
    try {
      // 현재 사용자 ID로 내 게시글 필터링
      final currentUserId = context.read<AuthProvider>().currentUser?.id ?? 1;
      final allPosts = _getAllMockPosts();
      
      setState(() {
        _myPosts.clear();
        _myPosts.addAll(
          allPosts.where((post) => post.authorId == currentUserId).toList(),
        );
      });
    } catch (e) {
      print('내 게시글 로딩 실패: $e');
    }
  }

  void _handleMenuAction(String action, PostData post) async {
    switch (action) {
      case 'report':
        await ReportService().showReportDialog(
          context: context,
          type: ReportType.post,
          targetId: post.id,
          targetTitle: post.title,
        );
        break;
      case 'block':
        final shouldBlock = await BlockService().showBlockConfirmDialog(
          context,
          1, // TODO: 실제 작성자 ID로 변경
          post.author,
        );
        if (shouldBlock) {
          await BlockService().blockUser(1, post.author, context);
        }
        break;
      case 'hide':
        await BlockService().hidePost(post.id, context);
        // TODO: 게시글 목록에서 제거
        break;
    }
  }

  /// 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('게시글을 불러오는 중...'),
          ],
        ),
      ),
    );
  }

  /// 리스트 끝 표시
  Widget _buildEndOfListIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.grey,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              '모든 게시글을 불러왔습니다',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostData {
  final int id;
  final String title;
  final String author;
  final int authorId;
  final String content;
  int likes;
  final int comments;
  final String timeAgo;
  final String category;
  final String? authorProfileImage;
  final bool isFollowing;
  bool isLiked;
  bool isBookmarked;
  int shareCount;
  bool isSharedByCurrentUser;
  final List<String> hashtags;

  PostData({
    required this.id,
    required this.title,
    required this.author,
    required this.authorId,
    required this.content,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.category,
    this.authorProfileImage,
    required this.isFollowing,
    required this.isLiked,
    required this.isBookmarked,
    required this.hashtags,
    this.shareCount = 0,
    this.isSharedByCurrentUser = false,
  });
}
