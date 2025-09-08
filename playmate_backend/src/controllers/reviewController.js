const asyncHandler = require('express-async-handler');
const Review = require('../models/Review');
const Matching = require('../models/Matching');

// @desc    Get user's reviews
// @route   GET /api/reviews/my
// @access  Private
const getMyReviews = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10 } = req.query;
  
  const reviews = await Review.find({ reviewer: req.user.id })
    .populate('reviewee', 'nickname profileImage')
    .populate('matching', 'title gameType date')
    .sort({ createdAt: -1 })
    .limit(limit * 1)
    .skip((page - 1) * limit);
  
  const total = await Review.countDocuments({ reviewer: req.user.id });
  
  res.json({
    success: true,
    data: reviews,
    pagination: {
      current: parseInt(page),
      pages: Math.ceil(total / limit),
      total
    }
  });
});

// @desc    Get reviews about user
// @route   GET /api/reviews/about/:userId
// @access  Private
const getReviewsAboutUser = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { page = 1, limit = 10 } = req.query;
  
  const reviews = await Review.find({ reviewee: userId })
    .populate('reviewer', 'nickname profileImage')
    .populate('matching', 'title gameType date')
    .sort({ createdAt: -1 })
    .limit(limit * 1)
    .skip((page - 1) * limit);
  
  const total = await Review.countDocuments({ reviewee: userId });
  
  res.json({
    success: true,
    data: reviews,
    pagination: {
      current: parseInt(page),
      pages: Math.ceil(total / limit),
      total
    }
  });
});

// @desc    Create review
// @route   POST /api/reviews
// @access  Private
const createReview = asyncHandler(async (req, res) => {
  const { revieweeId, matchingId, rating, content, tags } = req.body;
  
  // 매칭 참여자 확인
  const matching = await Matching.findById(matchingId);
  
  if (!matching) {
    res.status(404);
    throw new Error('Matching not found');
  }
  
  // 리뷰 작성자가 매칭에 참여했는지 확인
  const isParticipant = matching.host.toString() === req.user.id ||
    matching.guests.some(guest => guest.user.toString() === req.user.id);
  
  if (!isParticipant) {
    res.status(403);
    throw new Error('Not authorized to review this matching');
  }
  
  // 리뷰 대상자가 매칭에 참여했는지 확인
  const isRevieweeParticipant = matching.host.toString() === revieweeId ||
    matching.guests.some(guest => guest.user.toString() === revieweeId);
  
  if (!isRevieweeParticipant) {
    res.status(400);
    throw new Error('Reviewee is not a participant of this matching');
  }
  
  // 자기 자신에게 리뷰 작성 불가
  if (revieweeId === req.user.id) {
    res.status(400);
    throw new Error('Cannot review yourself');
  }
  
  // 이미 리뷰를 작성했는지 확인
  const existingReview = await Review.findOne({
    reviewer: req.user.id,
    reviewee: revieweeId,
    matching: matchingId
  });
  
  if (existingReview) {
    res.status(400);
    throw new Error('Review already exists for this matching');
  }
  
  const review = await Review.create({
    reviewer: req.user.id,
    reviewee: revieweeId,
    matching: matchingId,
    rating,
    content,
    tags
  });
  
  const populatedReview = await Review.findById(review._id)
    .populate('reviewer', 'nickname profileImage')
    .populate('reviewee', 'nickname profileImage')
    .populate('matching', 'title gameType date');
  
  res.status(201).json({
    success: true,
    data: populatedReview
  });
});

// @desc    Update review
// @route   PUT /api/reviews/:id
// @access  Private
const updateReview = asyncHandler(async (req, res) => {
  const { rating, content, tags } = req.body;
  
  const review = await Review.findById(req.params.id);
  
  if (!review) {
    res.status(404);
    throw new Error('Review not found');
  }
  
  // 작성자만 수정 가능
  if (review.reviewer.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to update this review');
  }
  
  const updatedReview = await Review.findByIdAndUpdate(
    req.params.id,
    { rating, content, tags },
    { new: true, runValidators: true }
  ).populate('reviewer', 'nickname profileImage')
   .populate('reviewee', 'nickname profileImage')
   .populate('matching', 'title gameType date');
  
  res.json({
    success: true,
    data: updatedReview
  });
});

// @desc    Delete review
// @route   DELETE /api/reviews/:id
// @access  Private
const deleteReview = asyncHandler(async (req, res) => {
  const review = await Review.findById(req.params.id);
  
  if (!review) {
    res.status(404);
    throw new Error('Review not found');
  }
  
  // 작성자만 삭제 가능
  if (review.reviewer.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to delete this review');
  }
  
  await review.deleteOne();
  
  res.json({
    success: true,
    message: 'Review deleted successfully'
  });
});

module.exports = {
  getMyReviews,
  getReviewsAboutUser,
  createReview,
  updateReview,
  deleteReview
};