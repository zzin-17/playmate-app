import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';

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
  bool _isSubmitting = false;
  Comment? _replyingTo; // 답글 대상 댓글
  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      // TODO: 실제 API 호출로 변경
      await Future.delayed(const Duration(milliseconds: 500));
      _comments = _getMockComments();
    } catch (e) {
      print('댓글 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Comment> _getMockComments() {
    return [
      Comment(
        id: 1,
        postId: widget.post.id,
        authorId: 2,
        authorNickname: '테니스러버',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        content: '정말 좋은 정보네요! 저도 도움이 많이 됐습니다.',
        likeCount: 3,
        isLikedByCurrentUser: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        replies: [
          Comment(
            id: 3,
            postId: widget.post.id,
            authorId: 1,
            authorNickname: '테니스마스터',
            authorProfileImage: 'https://via.placeholder.com/40x40',
            content: '도움이 되었다니 다행이에요!',
            parentCommentId: 1,
            likeCount: 1,
            isLikedByCurrentUser: true,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      Comment(
        id: 2,
        postId: widget.post.id,
        authorId: 3,
        authorNickname: '라켓킹',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        content: '이런 팁들이 정말 유용해요. 더 많은 정보를 기대합니다!',
        likeCount: 1,
        isLikedByCurrentUser: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: 실제 API 호출로 변경
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newComment = Comment(
        id: _comments.length + 1,
        postId: widget.post.id,
        authorId: context.read<AuthProvider>().currentUser?.id ?? 1,
        authorNickname: context.read<AuthProvider>().currentUser?.nickname ?? '사용자',
        authorProfileImage: context.read<AuthProvider>().currentUser?.profileImage,
        content: _commentController.text.trim(),
        likeCount: 0,
        isLikedByCurrentUser: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 작성되었습니다.')),
        );
      }
    } catch (e) {
      print('댓글 작성 실패: $e');
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
      // TODO: 실제 API 호출로 변경
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newReply = Comment(
        id: DateTime.now().millisecondsSinceEpoch,
        postId: widget.post.id,
        authorId: context.read<AuthProvider>().currentUser?.id ?? 1,
        authorNickname: context.read<AuthProvider>().currentUser?.nickname ?? '사용자',
        authorProfileImage: context.read<AuthProvider>().currentUser?.profileImage,
        content: _replyController.text.trim(),
        parentCommentId: _replyingTo!.id,
        likeCount: 0,
        isLikedByCurrentUser: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 부모 댓글에 답글 추가
      setState(() {
        final parentIndex = _comments.indexWhere((c) => c.id == _replyingTo!.id);
        if (parentIndex != -1) {
          final parentComment = _comments[parentIndex];
          final updatedParent = parentComment.copyWith(
            replies: [...parentComment.replies, newReply],
          );
          _comments[parentIndex] = updatedParent;
        }
        _replyController.clear();
        _replyingTo = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('답글이 작성되었습니다.')),
        );
      }
    } catch (e) {
      print('답글 작성 실패: $e');
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

  Future<void> _toggleLike(Comment comment) async {
    try {
      // TODO: 실제 API 호출로 변경
      await Future.delayed(const Duration(milliseconds: 300));
      
      setState(() {
        final commentIndex = _comments.indexWhere((c) => c.id == comment.id);
        if (commentIndex != -1) {
          final updatedComment = _comments[commentIndex].copyWith(
            isLikedByCurrentUser: !comment.isLikedByCurrentUser,
            likeCount: comment.isLikedByCurrentUser 
                ? comment.likeCount - 1 
                : comment.likeCount + 1,
          );
          _comments[commentIndex] = updatedComment;
        }
      });
    } catch (e) {
      print('좋아요 토글 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                backgroundImage: NetworkImage(
                  widget.post.authorProfileImage ?? 'https://via.placeholder.com/40x40',
                ),
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
              backgroundImage: NetworkImage(
                comment.authorProfileImage ?? 'https://via.placeholder.com/36x36',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.authorNickname,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
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
          backgroundImage: NetworkImage(
            reply.authorProfileImage ?? 'https://via.placeholder.com/28x28',
          ),
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
}
