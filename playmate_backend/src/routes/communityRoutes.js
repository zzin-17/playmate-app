const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getPosts,
  getPostById,
  createPost,
  updatePost,
  deletePost,
  togglePostLike,
  getComments,
  createComment,
  updateComment,
  deleteComment,
  toggleCommentLike,
  getMyPosts,
  getUserPosts,
  getMyBookmarks,
  getMyLikes,
  getMyCommentedPosts,
  getPostShareStatistics
} = require('../controllers/communityControllerMemory');

// 커뮤니티 관련 라우트
router.route('/posts')
  .get(protect, getPosts)
  .post(protect, createPost);

// 내 게시글 조회 (특별한 라우트를 먼저 정의)
router.route('/posts/my-posts')
  .get(protect, getMyPosts);

// 내가 북마크한 게시글 조회
router.route('/posts/my-bookmarks')
  .get(protect, getMyBookmarks);

// 내가 좋아요한 게시글 조회
router.route('/posts/my-likes')
  .get(protect, getMyLikes);

// 내가 댓글단 게시글 조회
router.route('/posts/my-comments')
  .get(protect, getMyCommentedPosts);

router.route('/posts/user/:userId')
  .get(protect, getUserPosts);

router.route('/posts/:id')
  .get(protect, getPostById)
  .put(protect, updatePost)
  .delete(protect, deletePost);

router.route('/posts/:id/like')
  .post(protect, togglePostLike);

router.route('/posts/:id/share-statistics')
  .get(protect, getPostShareStatistics);

router.route('/posts/:id/comments')
  .get(protect, getComments)
  .post(protect, (req, res, next) => {
    console.log(`🔍 댓글 작성 라우트 호출됨: POST /posts/${req.params.id}/comments`);
    console.log(`🔍 요청자 ID: ${req.user?.id}, 닉네임: ${req.user?.nickname}`);
    createComment(req, res, next);
  });

router.route('/comments/:commentId')
  .put(protect, updateComment)
  .delete(protect, deleteComment);

router.route('/comments/:commentId/like')
  .post(protect, toggleCommentLike);

module.exports = router;