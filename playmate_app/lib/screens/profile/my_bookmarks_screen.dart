import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/bookmark_service.dart';
import '../../services/mock_post_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../community/community_screen.dart';

class MyBookmarksScreen extends StatefulWidget {
  const MyBookmarksScreen({super.key});

  @override
  State<MyBookmarksScreen> createState() => _MyBookmarksScreenState();
}

class _MyBookmarksScreenState extends State<MyBookmarksScreen> {
  List<PostData> _bookmarkedPosts = [];
  bool _isLoading = true;
  bool _hasBookmarks = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedPosts();
  }

  Future<void> _loadBookmarkedPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        final bookmarkedIds = await BookmarkService.getBookmarks(currentUser.id);
        
        if (bookmarkedIds.isNotEmpty) {
          // 북마크된 게시글들을 실제 데이터로 가져오기
          final List<PostData?> actualPosts = MockPostService.getPostsByIds(bookmarkedIds.toList());
          
          // null이 아닌 게시글들만 필터링하고 북마크 상태를 true로 설정
          _bookmarkedPosts = actualPosts.where((post) => post != null).map((PostData? post) {
            return PostData(
              id: post!.id,
              title: post.title,
              author: post.author,
              authorId: post.authorId,
              content: post.content,
              likes: post.likes,
              comments: post.comments,
              timeAgo: post.timeAgo,
              category: post.category,
              authorProfileImage: post.authorProfileImage,
              isFollowing: post.isFollowing,
              isLiked: post.isLiked,
              isBookmarked: true, // 북마크 상태는 true로 설정
              shareCount: post.shareCount,
              isSharedByCurrentUser: post.isSharedByCurrentUser,
              hashtags: post.hashtags,
            );
          }).toList();
          
          _hasBookmarks = _bookmarkedPosts.isNotEmpty;
        } else {
          _hasBookmarks = false;
        }
      }
    } catch (e) {
      print('북마크 목록 로드 오류: $e');
      _hasBookmarks = false;
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
        title: const Text('내가 북마크한 게시글'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasBookmarks
              ? _buildBookmarksList()
              : _buildEmptyState(),
    );
  }

  Widget _buildBookmarksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarkedPosts.length,
      itemBuilder: (context, index) {
        final post = _bookmarkedPosts[index];
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
                // 작성자 정보
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        post.author[0],
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                    // 북마크 제거 버튼
                    IconButton(
                      onPressed: () => _removeBookmark(post.id),
                      icon: const Icon(
                        Icons.bookmark,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      tooltip: '북마크 제거',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 게시글 내용
                Text(
                  post.content,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                
                // 해시태그
                if (post.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: post.hashtags.map((tag) => Container(
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
                    )).toList(),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // 상호작용 버튼들
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likes}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.shareCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 북마크한 게시글이 없어요',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '관심 있는 게시글을 북마크해보세요!',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 커뮤니티 화면으로 이동
              Navigator.of(context).pushNamed('/community');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('커뮤니티 둘러보기'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBookmark(int postId) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        await BookmarkService.toggleBookmark(currentUser.id, postId);
        await _loadBookmarkedPosts(); // 목록 새로고침
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('북마크가 제거되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('북마크 제거 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
