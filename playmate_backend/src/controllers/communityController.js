const asyncHandler = require('express-async-handler');
const Post = require('../models/Post');

// @desc    Get all posts
// @route   GET /api/community/posts
// @access  Private
const getPosts = asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, category, hashtag } = req.query;
  
  const query = { isPublic: true };
  if (category) query.category = category;
  if (hashtag) query.hashtags = hashtag;
  
  const posts = await Post.find(query)
    .populate('author', 'nickname profileImage')
    .populate('likes.user', 'nickname')
    .populate('bookmarks.user', 'nickname')
    .populate('comments.author', 'nickname profileImage')
    .sort({ createdAt: -1 })
    .limit(limit * 1)
    .skip((page - 1) * limit);
  
  const total = await Post.countDocuments(query);
  
  res.json({
    success: true,
    data: posts,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: total,
      totalPages: Math.ceil(total / limit)
    }
  });
});

// @desc    Get single post
// @route   GET /api/community/posts/:id
// @access  Private
const getPost = asyncHandler(async (req, res) => {
  const post = await Post.findById(req.params.id)
    .populate('author', 'nickname profileImage')
    .populate('likes.user', 'nickname')
    .populate('bookmarks.user', 'nickname')
    .populate('comments.author', 'nickname profileImage');
  
  if (!post) {
    res.status(404);
    throw new Error('Post not found');
  }
  
  res.json({
    success: true,
    data: post
  });
});

// @desc    Create new post
// @route   POST /api/community/posts
// @access  Private
const createPost = asyncHandler(async (req, res) => {
  const { content, category, images, hashtags } = req.body;
  
  const post = await Post.create({
    author: req.user.id,
    content,
    category,
    images,
    hashtags
  });
  
  const populatedPost = await Post.findById(post._id)
    .populate('author', 'nickname profileImage');
  
  res.status(201).json({
    success: true,
    data: populatedPost
  });
});

// @desc    Update post
// @route   PUT /api/community/posts/:id
// @access  Private
const updatePost = asyncHandler(async (req, res) => {
  const post = await Post.findById(req.params.id);
  
  if (!post) {
    res.status(404);
    throw new Error('Post not found');
  }
  
  // 작성자만 수정 가능
  if (post.author.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to update this post');
  }
  
  const updatedPost = await Post.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true, runValidators: true }
  ).populate('author', 'nickname profileImage');
  
  res.json({
    success: true,
    data: updatedPost
  });
});

// @desc    Delete post
// @route   DELETE /api/community/posts/:id
// @access  Private
const deletePost = asyncHandler(async (req, res) => {
  const post = await Post.findById(req.params.id);
  
  if (!post) {
    res.status(404);
    throw new Error('Post not found');
  }
  
  // 작성자만 삭제 가능
  if (post.author.toString() !== req.user.id) {
    res.status(403);
    throw new Error('Not authorized to delete this post');
  }
  
  await post.deleteOne();
  
  res.json({
    success: true,
    message: 'Post deleted successfully'
  });
});

// @desc    Toggle like on post
// @route   POST /api/community/posts/:id/like
// @access  Private
const toggleLike = asyncHandler(async (req, res) => {
  const post = await Post.findById(req.params.id);
  
  if (!post) {
    res.status(404);
    throw new Error('Post not found');
  }
  
  const existingLike = post.likes.find(
    like => like.user.toString() === req.user.id
  );
  
  if (existingLike) {
    // 이미 좋아요를 누른 경우 취소
    post.likes = post.likes.filter(
      like => like.user.toString() !== req.user.id
    );
  } else {
    // 좋아요 추가
    post.likes.push({ user: req.user.id });
  }
  
  await post.save();
  
  res.json({
    success: true,
    data: {
      isLiked: !existingLike,
      likeCount: post.likes.length
    }
  });
});

// @desc    Toggle bookmark on post
// @route   POST /api/community/posts/:id/bookmark
// @access  Private
const toggleBookmark = asyncHandler(async (req, res) => {
  const post = await Post.findById(req.params.id);
  
  if (!post) {
    res.status(404);
    throw new Error('Post not found');
  }
  
  const existingBookmark = post.bookmarks.find(
    bookmark => bookmark.user.toString() === req.user.id
  );
  
  if (existingBookmark) {
    // 이미 북마크한 경우 취소
    post.bookmarks = post.bookmarks.filter(
      bookmark => bookmark.user.toString() !== req.user.id
    );
  } else {
    // 북마크 추가
    post.bookmarks.push({ user: req.user.id });
  }
  
  await post.save();
  
  res.json({
    success: true,
    data: {
      isBookmarked: !existingBookmark,
      bookmarkCount: post.bookmarks.length
    }
  });
});

// @desc    Add comment to post
// @route   POST /api/community/posts/:id/comments
// @access  Private
const addComment = asyncHandler(async (req, res) => {
  const { content } = req.body;
  
  const post = await Post.findById(req.params.id);
  
  if (!post) {
    res.status(404);
    throw new Error('Post not found');
  }
  
  post.comments.push({
    author: req.user.id,
    content
  });
  
  await post.save();
  
  const updatedPost = await Post.findById(post._id)
    .populate('comments.author', 'nickname profileImage');
  
  res.json({
    success: true,
    data: updatedPost.comments[updatedPost.comments.length - 1]
  });
});

module.exports = {
  getPosts,
  getPost,
  createPost,
  updatePost,
  deletePost,
  toggleLike,
  toggleBookmark,
  addComment
};