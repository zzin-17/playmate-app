const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getPosts,
  getPost,
  createPost,
  updatePost,
  deletePost,
  toggleLike,
  toggleBookmark,
  addComment
} = require('../controllers/communityController');

// 커뮤니티 관련 라우트
router.route('/posts')
  .get(protect, getPosts)
  .post(protect, createPost);

router.route('/posts/:id')
  .get(protect, getPost)
  .put(protect, updatePost)
  .delete(protect, deletePost);

router.route('/posts/:id/like')
  .post(protect, toggleLike);

router.route('/posts/:id/bookmark')
  .post(protect, toggleBookmark);

router.route('/posts/:id/comments')
  .post(protect, addComment);

module.exports = router;