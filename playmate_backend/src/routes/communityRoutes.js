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
  toggleCommentLike
} = require('../controllers/communityControllerMemory');

// 커뮤니티 관련 라우트
router.route('/posts')
  .get(protect, getPosts)
  .post(protect, createPost);

router.route('/posts/:id')
  .get(protect, getPostById)
  .put(protect, updatePost)
  .delete(protect, deletePost);

router.route('/posts/:id/like')
  .post(protect, togglePostLike);

router.route('/posts/:id/comments')
  .get(protect, getComments)
  .post(protect, createComment);

router.route('/comments/:commentId/like')
  .post(protect, toggleCommentLike);

module.exports = router;