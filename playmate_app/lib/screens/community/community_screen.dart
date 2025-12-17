import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';

import 'follow_list_screen.dart';
import 'comment_screen.dart';
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import '../profile/user_profile_home_screen.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../services/share_service.dart';
import '../../services/report_service.dart';
import '../../services/block_service.dart';
import '../../services/notification_service.dart';
import '../../services/community_service.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  final int initialTabIndex; // 초기 탭 인덱스 (0: All, 1: My)
  final bool showBackButton; // 뒤로가기 버튼 표시 여부
  
  const CommunityScreen({
    super.key,
    this.initialTabIndex = 0,
    this.showBackButton = false,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();
  
  // 게시글 데이터
  final List<Post> _feedPosts = [];      // 전체 게시글 (All 탭용)
  final List<Post> _followingPosts = []; // 팔로잉 게시글
  final List<Post> _trendingPosts = [];  // 인기 게시글
  final List<Post> _myPosts = [];        // 내 게시글 (My 탭용)
  
  // 로딩 상태
  bool _isLoading = false;
  bool _hasTriedLoadingMyPosts = false; // 내 게시글 로딩 시도 여부
  
  // 자동 새로고침 타이머
  Timer? _autoRefreshTimer;
  final Duration _refreshInterval = const Duration(seconds: 15); // 실시간 (15초마다)

  
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
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex, // 초기 탭 설정
    );
    
    // 탭 변경 리스너 추가
    _tabController.addListener(() {
      print('🔍 탭 변경됨: ${_tabController.index}');
      if (_tabController.index == 1) { // My 탭
        print('🔍 My 탭 선택됨 - _myPosts 길이: ${_myPosts.length}');
      }
    });
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);
    
    // 초기 데이터 로드 (비동기로 처리)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAllPosts();  // 전체 게시글 로드
      // _loadMyPosts는 필요할 때만 호출 (탭 선택 시)
    });
    
    // 자동 새로고침 타이머 시작 (새로운 게시글 업데이트)
    _startAutoRefreshTimer();
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
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

  // 게시글 등록 후 피드 새로고침 (실제 환경에 적합)
  void _refreshFeedAfterPostCreation(Map<String, dynamic>? postData) {
    // 게시글 작성 후 전체 데이터 새로고침 (API에서 최신 데이터 가져오기)
    _hasTriedLoadingMyPosts = false; // 플래그 리셋
    _loadAllPosts();
    _loadMyPosts();
  }

  // 실시간 새로고침 타이머 시작
  void _startAutoRefreshTimer() {
    print('🔄 커뮤니티 실시간 새로고침 활성화 (15초 주기)');
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _refreshCommunityData();
      } else {
        timer.cancel();
      }
    });
  }
  
  // 커뮤니티 데이터 새로고침 (기존 게시글 보존)
  void _refreshCommunityData() {
    print('🔄 커뮤니티 데이터 자동 새로고침 시작');
    
    // 기존 게시글은 보존하고 새로운 게시글만 추가
    _loadAllPosts();  // 전체 게시글 새로고침
    
    // 현재 탭이 "My"이면 내 게시글도 새로고침
    if (_tabController.index == 1) {
      _hasTriedLoadingMyPosts = false; // 플래그 리셋
      _loadMyPosts();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
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
        leading: widget.showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '뒤로가기',
            )
          : IconButton(
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
          color: AppColors.secondary.withValues(alpha: 0.4), // Light Orange 테두리
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

  List<Post> _getFilteredPosts() {
    switch (_currentFilter) {
      case '팔로잉':
        return _followingPosts;
      case '인기':
        return _trendingPosts;
      default:
        // "All" 탭에서는 전체 게시글 표시
        return _feedPosts;
    }
  }





  Widget _buildMyPostsTab() {
    print('🔍 _buildMyPostsTab 호출됨 - _myPosts 길이: ${_myPosts.length}');
    
    // 무한 루프 방지: 이미 로딩 중이거나 한 번 로드를 시도했으면 스킵
    if (_myPosts.isEmpty && !_isLoading && !_hasTriedLoadingMyPosts) {
      _hasTriedLoadingMyPosts = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMyPosts();
      });
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _hasTriedLoadingMyPosts = false; // 새로고침 시 플래그 리셋
        _loadMyPosts(); // 내 게시글 새로고침
      },
      child: _myPosts.isEmpty
          ? _buildEmptyMyPosts()
          : ListView.builder(
              key: const PageStorageKey('my_posts_list'),
              itemCount: _myPosts.length,
              itemBuilder: (context, index) {
                try {
                  return _buildPostCard(_myPosts[index]);
                } catch (e) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Text('게시글을 불러올 수 없습니다: $e'),
                  );
                }
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







  /*
  Widget _buildSocialPostCard(Post post) { // 사용되지 않음
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: post.authorProfileImage == null
                      ? Text(
                          post.authorNickname[0],
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
                        post.authorNickname,
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
                if (false) // Post 모델에는 isFollowing 필드가 없으므로 항상 팔로우 버튼 표시
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
                    post.likeCount > 0 ? Icons.favorite : Icons.favorite_border,
                    color: post.likeCount > 0 ? Colors.red : Colors.grey,
                  ),
                ),
                Text(
                  post.likeCount.toString(),
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
  */

  Widget _buildPostCard(Post post) {
    try {
      return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: post.authorProfileImage != null 
                    ? NetworkImage(post.authorProfileImage!) 
                    : null,
                  child: post.authorProfileImage == null 
                    ? Text(
                        post.authorNickname[0],
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
                      GestureDetector(
                        onTap: () => _showUserActionMenu(context, post.authorId, post.authorNickname),
                        child: Text(
                          post.authorNickname,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
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
                  itemBuilder: (context) {
                    final currentUser = context.read<AuthProvider>().currentUser;
                    final isMyPost = post.authorId == currentUser?.id;
                    
                    if (isMyPost) {
                      // 내 게시글인 경우
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('수정하기'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제하기', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    } else {
                      // 다른 사람의 게시글인 경우
                      return [
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
                      ];
                    }
                  },
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
                        post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: post.isLikedByCurrentUser ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        post.likeCount.toString(),
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
                        post.commentCount.toString(),
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
                    post.isBookmarkedByCurrentUser ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: post.isBookmarkedByCurrentUser ? AppColors.primary : Colors.grey,
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
    } catch (e) {
      print('❌ _buildPostCard 오류: $e');
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
          '게시글을 표시할 수 없습니다: $e',
          style: TextStyle(color: Colors.red[700]),
        ),
      );
    }
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
                      userId: currentUser.id,
                      isFollowing: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text('팔로워 (${currentUser.followerIds?.length ?? 0})'),
              subtitle: const Text('나를 팔로우하는 사용자들'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowListScreen(
                      title: '팔로워',
                      userId: currentUser.id,
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
        return UserSearchDialog();
      },
    );
  }

  void _navigateToComments(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(post: post),
      ),
    );
    
    // 댓글 화면에서 돌아왔을 때 게시글 목록 새로고침
    if (mounted) {
      print('🔄 댓글 화면에서 돌아옴 - 게시글 목록 새로고침');
      _loadAllPosts();
      _loadMyPosts();
    }
  }



  void _toggleLike(Post post) async {
    try {
      // 실제 API 호출
      final success = await _communityService.toggleLike(post.id);
      
      if (success) {
        // 좋아요 상태는 API에서 처리됨
        // UI는 API 응답에 따라 업데이트됨
        
        // 좋아요 시 알림 표시
        if (!post.isLikedByCurrentUser) {
          await NotificationService().showLikeNotification(
            postTitle: post.content,
            likerName: '현재 사용자', // 실제 사용자 이름으로 변경 (향후 구현)
          );
        }
      } else {
        throw Exception('좋아요 처리 실패');
      }
    } catch (e) {
      print('좋아요 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('좋아요 처리 중 오류가 발생했습니다'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleBookmark(Post post) async {
    try {
      // 실제 API 호출
      final success = await _communityService.toggleBookmark(post.id);
      
      if (success) {
        // 북마크 상태는 API에서 처리됨
        // UI는 API 응답에 따라 업데이트됨
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(!post.isBookmarkedByCurrentUser ? '북마크에 추가되었습니다' : '북마크에서 제거되었습니다'),
              backgroundColor: !post.isBookmarkedByCurrentUser ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('북마크 처리 실패');
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

  void _sharePost(Post post) async {

    // 공유 서비스 호출
    await ShareService().sharePost(post, context);
    
    // 공유 상태 업데이트는 API에서 처리됨

    // 공유 시 알림 표시
    await NotificationService().showShareNotification(
      postTitle: post.content.length > 30 ? '${post.content.substring(0, 30)}...' : post.content,
      sharerName: '현재 사용자', // 실제 사용자 이름으로 변경 (향후 구현)
    );
  }

  void _searchByHashtag(String hashtag) {
    // 해시태그 검색 기능 구현 (향후 구현)
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

  /// 전체 게시글 로딩 (All 탭용)
  Future<void> _loadAllPosts() async {
    print('🔍 _loadAllPosts 시작 - 전체 게시글 로드');
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
    });

    try {
      print('🔍 API에서 전체 게시글 로드 시작');
      final posts = await _communityService.getPosts();
      print('🔍 API에서 받은 전체 게시글 수: ${posts.length}');
      setState(() {
        _feedPosts.clear();
        _feedPosts.addAll(posts);
        _currentPage = 2; // 다음 페이지부터 시작
      });
      print('🔍 _feedPosts에 추가된 게시글 수: ${_feedPosts.length}');
    } catch (e) {
      print('전체 게시글 로딩 실패: $e');
      setState(() {
        _feedPosts.clear();
      });
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
      // 실제 API 호출로 변경 (향후 구현)
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

  /// 페이지별 게시글 데이터 로드 (API 우선, 실패 시 Mock 데이터)
  /*
  Future<List<Post>> _getPostsForPage(int page) async { // 사용되지 않음
    try {
      // 실제 API 호출
      final posts = await _communityService.getPosts(
        page: page,
        limit: _pageSize,
      );
      
      // Post 모델을 그대로 반환
      return posts;
    } catch (e) {
      print('API 호출 실패, Mock 데이터 사용: $e');
      // API 실패 시 Mock 데이터 사용
      return _getMockPostsForPage(page);
    }
  }
  */

  /// 페이지별 목업 데이터 생성 (폴백용)
  List<Post> _getMockPostsForPage(int page) {
    if (page > 3) return []; // 3페이지까지만 데이터 제공
    
    final startIndex = (page - 1) * _pageSize;
    final allPosts = _getAllMockPosts();
    
    if (startIndex >= allPosts.length) return [];
    
    final endIndex = (startIndex + _pageSize).clamp(0, allPosts.length);
    return allPosts.sublist(startIndex, endIndex);
  }

  /// 모든 목업 데이터 (폴백용) - 실제 환경에서는 사용하지 않음
  List<Post> _getAllMockPosts() {
    return []; // 실제 환경에서는 빈 목록 반환
  }



  /// 시간 차이를 문자열로 변환
  /*
  String _getTimeAgo(DateTime dateTime) { // 사용되지 않음
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
  */

  /// 내 게시글 로드
  Future<void> _loadMyPosts() async {
    try {
      print('🔍 _loadMyPosts 시작');
      // 실제 API 호출
      final posts = await _communityService.getMyPosts();
      print('🔍 API에서 받은 게시글 수: ${posts.length}');
      
      setState(() {
        // 기존 데이터를 새로운 데이터로 교체 (올바른 방식)
        _myPosts.clear();
        _myPosts.addAll(posts);
        print('🔍 _myPosts에 추가된 게시글 수: ${_myPosts.length}');
      });
    } catch (e) {
      print('내 게시글 로드 실패: $e');
      // API 실패 시에도 기존 데이터를 유지
      setState(() {
        // 에러 발생 시에도 기존 데이터 유지
        print('🔍 API 실패로 인해 기존 데이터 유지: ${_myPosts.length}개');
      });
    }
  }

  void _handleMenuAction(String action, Post post) async {
    switch (action) {
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _deletePost(post);
        break;
      case 'report':
        await ReportService().showReportDialog(
          context: context,
          type: ReportType.post,
          targetId: post.id,
          targetTitle: post.content.length > 30 ? '${post.content.substring(0, 30)}...' : post.content,
        );
        break;
      case 'block':
        final shouldBlock = await BlockService().showBlockConfirmDialog(
          context,
          post.authorId,
          post.authorNickname,
        );
        if (shouldBlock) {
          await BlockService().blockUser(post.authorId, post.authorNickname, context);
        }
        break;
      case 'hide':
        await BlockService().hidePost(post.id, context);
        // 게시글 목록에서 제거 (향후 구현)
        break;
    }
  }

  // 게시글 수정
  void _editPost(Post post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPostScreen(
          post: post,
          onPostUpdated: () {
            // 게시글 목록 새로고침
            _loadMyPosts();
          },
        ),
      ),
    );
  }

  // 게시글 삭제
  void _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _communityService.deletePost(post.id);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('게시글이 삭제되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 게시글 목록 새로고침
          _loadMyPosts();
        } else {
          throw Exception('게시글 삭제에 실패했습니다.');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글 삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  // 닉네임 클릭 시 사용자 액션 메뉴 표시
  void _showUserActionMenu(BuildContext context, int authorId, String authorNickname) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              authorNickname,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            
            // 액션 버튼들
            _buildActionButton(
              icon: Icons.person_add,
              title: '팔로우',
              subtitle: '이 사용자를 팔로우합니다',
              onTap: () async {
                Navigator.pop(context);
                await _followUserById(authorId, authorNickname);
              },
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: Icons.person,
              title: '프로필 방문',
              subtitle: '사용자 프로필을 확인합니다',
              onTap: () {
                Navigator.pop(context);
                _navigateToUserProfile(authorId);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ID로 사용자 팔로우
  Future<void> _followUserById(int userId, String nickname) async {
    try {
      final success = await _userService.followUser(userId);
      if (success && mounted) {
        // 팔로우 성공 메시지만 표시 (화면 전환 방지)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${nickname}님 팔로우를 성공했습니다'),
            backgroundColor: AppColors.primary,
          ),
        );
        
        // 커뮤니티 데이터만 새로고침
        _loadAllPosts();
        _loadMyPosts();
      } else {
        throw Exception('팔로우 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('팔로우 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 사용자 프로필로 이동
  void _navigateToUserProfile(int userId) async {
    print('🔍 _navigateToUserProfile 호출됨 - 사용자 ID: $userId');
    try {
      // 사용자 정보 조회
      print('🔍 사용자 정보 조회 시작 - ID: $userId');
      final user = await _userService.getUserProfile(userId);
      print('🔍 사용자 정보 조회 완료 - 사용자: ${user?.nickname}');
      if (user != null && mounted) {
        print('🔍 UserProfileHomeScreen으로 이동');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileHomeScreen(
              user: user,
              fromCommunity: true,
            ),
          ),
        );
      } else {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }
    } catch (e) {
      print('🔍 사용자 프로필 이동 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보 로드 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}

class PostData {
  final int id;
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

/// 사용자 검색 다이얼로그
class UserSearchDialog extends StatefulWidget {
  @override
  _UserSearchDialogState createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  List<User> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _userService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사용자 검색 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 제목
            Row(
              children: [
                Text(
                  '사용자 검색',
                  style: AppTextStyles.h2,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 검색 입력 필드
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '닉네임으로 검색하세요',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),
            
            // 검색 결과
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? '검색어를 입력하세요'
                                : '검색 결과가 없습니다',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return _buildUserCard(user);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
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
                ),
              )
            : null,
        ),
        title: Text(user.nickname),
        subtitle: Text('${user.skillLevel}년차 • ${user.region}'),
        trailing: ElevatedButton(
          onPressed: () => _followUser(user),
          child: const Text('팔로우'),
        ),
        onTap: () {
          Navigator.pop(context);
          // 사용자의 프로필 홈화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileHomeScreen(
                user: user,
                fromCommunity: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _followUser(User user) async {
    try {
      final success = await _userService.followUser(user.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.nickname}님 팔로우를 성공했습니다'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        throw Exception('팔로우 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('팔로우 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
