const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getMyReviews,
  getReviewsAboutUser,
  createReview,
  updateReview,
  deleteReview
} = require('../controllers/reviewController');

// 리뷰 관련 라우트
router.route('/my')
  .get(protect, getMyReviews);

router.route('/about/:userId')
  .get(protect, getReviewsAboutUser);

router.route('/')
  .post(protect, createReview);

router.route('/:id')
  .put(protect, updateReview)
  .delete(protect, deleteReview);

module.exports = router;