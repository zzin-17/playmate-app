import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_service.dart';
import '../../services/user_service.dart';
import '../profile/user_profile_home_screen.dart';

class CommentScreen extends StatefulWidget {
  final Post post;

  const CommentScreen({
    super.key,
    required this.post,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _commentController = TextEditingController();
  final _replyController = TextEditingController();
  final _communityService = CommunityService();
  final _userService = UserService();
  bool _isSubmitting = false;
  Comment? _replyingTo; // 답글 대상 댓글
  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🔍 CommentScreen 초기화 - 게시글 정보:');
    print('   ID: ${widget.post.id}');
    print('   작성자: ${widget.post.authorNickname}');
    print('   내용: ${widget.post.content.substring(0, 30)}...');
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 댓글 로드 시작: 게시글 ID ${widget.post.id}');
      _comments = await _communityService.getComments(widget.post.id);
      print('✅ 댓글 로드 완료: ${_comments.length}개');
    } catch (e) {
      print('❌ 댓글 로드 실패: $e');
      _comments = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🔍 댓글 작성 시작: "${_commentController.text.trim()}"');
      final newComment = await _communityService.createComment(
        postId: widget.post.id,
        content: _commentController.text.trim(),
      );

      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment); // 최신 댓글을 맨 앞에 추가
          _commentController.clear();
        });
        print('✅ 댓글 작성 완료: ID ${newComment.id}');

        // 성공 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 작성되었습니다.')),
          );
        }
      } else {
        throw Exception('댓글 작성 응답이 null입니다');
      }
    } catch (e) {
      print('❌ 댓글 작성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty || _replyingTo == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🔍 답글 작성 시작: "${_replyController.text.trim()}"');
      final newReply = await _communityService.createComment(
        postId: widget.post.id,
        content: _replyController.text.trim(),
        parentCommentId: _replyingTo!.id,
      );

      if (newReply != null) {
        // 댓글 목록 새로고침하여 최신 상태 반영
        await _loadComments();
        
        setState(() {
          _replyController.clear();
          _replyingTo = null;
        });

        print('✅ 답글 작성 완료: ID ${newReply.id}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('답글이 작성되었습니다.')),
          );
        }
      } else {
        throw Exception('답글 작성 응답이 null입니다');
      }
    } catch (e) {
      print('❌ 답글 작성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('답글 작성에 실패했습니다.')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
    _replyController.clear();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
    _replyController.clear();
  }

  Future<void> _editComment(Comment comment) async {
    String? result;
    
    try {
      result = await showDialog<String>(
        context: context,
        builder: (context) => _EditCommentDialog(initialText: comment.content),
      );
    } catch (e) {
      print('❌ 댓글 수정 다이얼로그 오류: $e');
      return;
    }

    if (result != null && result.isNotEmpty && result != comment.content) {
      try {
        print('🔍 댓글 수정 시작: ID ${comment.id}');
        final updatedComment = await _communityService.updateComment(
          commentId: comment.id,
          content: result,
        );

        if (updatedComment != null && mounted) {
          // 댓글 목록 새로고침
          await _loadComments();
          print('✅ 댓글 수정 완료');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 수정되었습니다.')),
          );
        }
      } catch (e) {
        print('❌ 댓글 수정 실패: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글 수정에 실패했습니다.')),
          );
        }
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('🔍 댓글 삭제 시작: ID ${comment.id}');
        final success = await _communityService.deleteComment(comment.id);

        if (success) {
          setState(() {
            _comments.removeWhere((c) => c.id == comment.id);
          });
          print('✅ 댓글 삭제 완료');
          
          // 댓글 목록 새로고침
          await _loadComments();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('댓글이 삭제되었습니다.')),
            );
          }
        }
      } catch (e) {
        print('❌ 댓글 삭제 실패: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글 삭제에 실패했습니다.')),
          );
        }
      }
    }
  }

  Future<void> _toggleLike(Comment comment) async {
    try {
      print('🔍 댓글 좋아요 토글 시작: ID ${comment.id}');
      final success = await _communityService.toggleCommentLike(comment.id);
      
      if (success) {
        // 댓글 목록 새로고침하여 최신 상태 반영
        await _loadComments();
        print('✅ 댓글 좋아요 토글 완료');
      } else {
        throw Exception('댓글 좋아요 토글 실패');
      }
    } catch (e) {
      print('❌ 댓글 좋아요 토글 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('좋아요 처리에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          // 댓글 화면을 나갈 때 부모 화면에 새로고침 신호 전송
          print('🔄 댓글 화면 종료 - 커뮤니티 새로고침 필요');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('댓글 ${_comments.length}개'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
          // 게시글 미리보기
          _buildPostPreview(),
          
          // 구분선
          Container(
            height: 1,
            color: AppColors.cardBorder,
          ),
          
          // 댓글 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : _buildCommentList(),
          ),
          
          // 답글 입력 영역
          if (_replyingTo != null) _buildReplyInput(),
          
          // 댓글 입력 영역
          _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: widget.post.authorProfileImage != null 
                  ? NetworkImage(widget.post.authorProfileImage!)
                  : null,
                child: widget.post.authorProfileImage == null 
                  ? Text(
                      widget.post.authorNickname[0],
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
                      widget.post.authorNickname,
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.post.timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.post.content,
            style: AppTextStyles.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
                              Text(
                      '아직 댓글이 없습니다',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 댓글을 작성해보세요!',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 메인 댓글
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: comment.authorProfileImage != null 
                ? NetworkImage(comment.authorProfileImage!) 
                : null,
              child: comment.authorProfileImage == null 
                ? Text(
                    comment.authorNickname.isNotEmpty ? comment.authorNickname[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                        GestureDetector(
                          onTap: () => _showUserActionMenu(context, comment.authorId, comment.authorNickname),
                          child: Text(
                            comment.authorNickname,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // 작성자인 경우에만 수정/삭제 버튼 표시
                      if (comment.authorId == context.read<AuthProvider>().currentUser?.id) ...[
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editComment(comment);
                            } else if (value == 'delete') {
                              _deleteComment(comment);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('수정'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('삭제', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 좋아요 버튼
                      InkWell(
                        onTap: () => _toggleLike(comment),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLikedByCurrentUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: comment.isLikedByCurrentUser
                                  ? Colors.red
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likeCount}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 답글 버튼
                      InkWell(
                        onTap: () => _startReply(comment),
                        child: Text(
                          '답글',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // 답글들
        if (comment.replies.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: comment.replies.map((reply) => _buildReplyItem(reply)).toList(),
            ),
          ),
        ],
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReplyItem(Comment reply) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: reply.authorProfileImage != null 
            ? NetworkImage(reply.authorProfileImage!)
            : null,
          child: reply.authorProfileImage == null 
            ? Text(
                reply.authorNickname[0],
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              )
            : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    reply.authorNickname,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    reply.timeAgo,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                reply.content,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  InkWell(
                    onTap: () => _toggleLike(reply),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reply.isLikedByCurrentUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 14,
                          color: reply.isLikedByCurrentUser
                              ? Colors.red
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${reply.likeCount}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_replyingTo!.authorNickname}에게 답글',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _cancelReply,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: '답글을 입력하세요...',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  _isSubmitting ? '작성 중...' : '답글',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: Text(
              _isSubmitting ? '작성 중...' : '댓글',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
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
    try {
      // 사용자 정보 조회
      final user = await _userService.getUserProfile(userId);
      if (user != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileHomeScreen(user: user),
          ),
        );
      } else {
        throw Exception('사용자 정보를 찾을 수 없습니다');
      }
    } catch (e) {
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

// 안전한 TextEditingController 관리를 위한 커스텀 다이얼로그
class _EditCommentDialog extends StatefulWidget {
  final String initialText;

  const _EditCommentDialog({required this.initialText});

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('댓글 수정'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: '댓글을 수정하세요',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('수정'),
        ),
      ],
    );
  }
}
