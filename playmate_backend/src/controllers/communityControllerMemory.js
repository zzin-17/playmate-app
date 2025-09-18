const fs = require('fs');
const path = require('path');
const { validateUserId, logUserOperation } = require('../utils/userValidation');
const {
  sendSuccessResponse,
  sendPaginatedResponse,
  sendCreatedResponse,
  sendErrorResponse,
  sendNotFoundResponse,
  sendBadRequestResponse
} = require('../utils/responseHelper');

// 커뮤니티 데이터 파일 경로
const POSTS_FILE = path.join(__dirname, '../data/posts.json');
const COMMENTS_FILE = path.join(__dirname, '../data/comments.json');

// 메모리 스토어 (대규모 데이터 대응)
let posts = [];
let comments = [];
let nextPostId = 1;
let nextCommentId = 1;

// 성능 최적화를 위한 인덱스
const postIndexes = {
  byAuthorId: new Map(), // authorId별 게시글 인덱스
  byCategory: new Map(), // 카테고리별 게시글 인덱스
  byDate: new Map()      // 날짜별 게시글 인덱스
};

// 인덱스 업데이트 함수
const updatePostIndexes = (post, operation = 'add') => {
  const authorId = post.authorId;
  const category = post.category;
  const date = post.createdAt.split('T')[0]; // YYYY-MM-DD 형식
  
  if (operation === 'add') {
    // authorId 인덱스 업데이트
    if (!postIndexes.byAuthorId.has(authorId)) {
      postIndexes.byAuthorId.set(authorId, []);
    }
    postIndexes.byAuthorId.get(authorId).push(post);
    
    // category 인덱스 업데이트
    if (!postIndexes.byCategory.has(category)) {
      postIndexes.byCategory.set(category, []);
    }
    postIndexes.byCategory.get(category).push(post);
    
    // date 인덱스 업데이트
    if (!postIndexes.byDate.has(date)) {
      postIndexes.byDate.set(date, []);
    }
    postIndexes.byDate.get(date).push(post);
  } else if (operation === 'remove') {
    // 인덱스에서 제거
    if (postIndexes.byAuthorId.has(authorId)) {
      const authorPosts = postIndexes.byAuthorId.get(authorId);
      const index = authorPosts.findIndex(p => p.id === post.id);
      if (index > -1) authorPosts.splice(index, 1);
    }
    
    if (postIndexes.byCategory.has(category)) {
      const categoryPosts = postIndexes.byCategory.get(category);
      const index = categoryPosts.findIndex(p => p.id === post.id);
      if (index > -1) categoryPosts.splice(index, 1);
    }
    
    if (postIndexes.byDate.has(date)) {
      const datePosts = postIndexes.byDate.get(date);
      const index = datePosts.findIndex(p => p.id === post.id);
      if (index > -1) datePosts.splice(index, 1);
    }
  }
};

// 파일에서 데이터 로드
function loadFromFile() {
  try {
    // 게시글 데이터 로드
    if (fs.existsSync(POSTS_FILE)) {
      const postsData = fs.readFileSync(POSTS_FILE, 'utf8');
      posts = JSON.parse(postsData);
      console.log(`게시글 데이터 로드 완료: ${posts.length}개`);
    } else {
      posts = getDefaultPosts();
      console.log('기본 게시글 데이터 생성 완료');
    }

    // 댓글 데이터 로드
    if (fs.existsSync(COMMENTS_FILE)) {
      const commentsData = fs.readFileSync(COMMENTS_FILE, 'utf8');
      comments = JSON.parse(commentsData);
      console.log(`댓글 데이터 로드 완료: ${comments.length}개`);
    } else {
      comments = [];
      console.log('댓글 데이터 파일이 없습니다. 빈 배열로 시작합니다.');
    }

    // ID 카운터 설정
    if (posts.length > 0) {
      nextPostId = Math.max(...posts.map(p => p.id)) + 1;
    }
    if (comments.length > 0) {
      nextCommentId = Math.max(...comments.map(c => c.id)) + 1;
    }
  } catch (error) {
    console.error('커뮤니티 데이터 로드 실패:', error);
    posts = getDefaultPosts();
    comments = [];
    nextPostId = 1;
    nextCommentId = 1;
  }
}

// 파일에 데이터 저장
function saveToFile() {
  try {
    // 게시글 데이터 저장
    const postsData = JSON.stringify(posts, null, 2);
    fs.writeFileSync(POSTS_FILE, postsData, 'utf8');

    // 댓글 데이터 저장
    const commentsData = JSON.stringify(comments, null, 2);
    fs.writeFileSync(COMMENTS_FILE, commentsData, 'utf8');

    console.log('커뮤니티 데이터 저장 완료');
  } catch (error) {
    console.error('커뮤니티 데이터 저장 실패:', error);
  }
}

// 기본 게시글 데이터
function getDefaultPosts() {
  return [];
}

// 게시글 목록 조회
const getPosts = (req, res) => {
  try {
    const { page = 1, limit = 20, category, search } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    console.log(`게시글 목록 조회 요청 (페이지: ${pageNum}, 제한: ${limitNum})`);

    let filteredPosts = [...posts];

    // 카테고리 필터링
    if (category && category !== '전체') {
      filteredPosts = filteredPosts.filter(post => post.category === category);
    }

    // 검색어 필터링
    if (search) {
      const searchLower = search.toLowerCase();
      filteredPosts = filteredPosts.filter(post => 
        post.content.toLowerCase().includes(searchLower) ||
        post.hashtags.some(tag => tag.toLowerCase().includes(searchLower))
      );
    }

    // 최신순 정렬
    filteredPosts.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    // 페이지네이션 적용
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedPosts = filteredPosts.slice(startIndex, endIndex);

    console.log(`필터링된 게시글 수: ${paginatedPosts.length}개`);

    sendPaginatedResponse(res, paginatedPosts, {
      page: pageNum,
      limit: limitNum,
      total: filteredPosts.length
    });
  } catch (error) {
    console.error('게시글 목록 조회 오류:', error);
    sendErrorResponse(res, '게시글 목록 조회에 실패했습니다.', 500, error);
  }
};

// 게시글 상세 조회
const getPostById = (req, res) => {
  try {
    const { id } = req.params;
    const postId = parseInt(id);

    console.log(`게시글 상세 조회 요청: ID ${postId}`);

    const post = posts.find(p => p.id === postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: '게시글을 찾을 수 없습니다.'
      });
    }

    // 조회수 증가
    post.views += 1;
    saveToFile();

    console.log(`게시글 조회 성공: ${post.content.substring(0, 30)}...`);

    res.json({
      success: true,
      data: post
    });
  } catch (error) {
    console.error('게시글 상세 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '게시글 상세 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 게시글 생성
const createPost = (req, res) => {
  try {
    const { content, category, hashtags } = req.body;
    const authorId = req.user.id;

    if (!content) {
      return sendBadRequestResponse(res, '내용은 필수입니다.');
    }

    console.log(`게시글 생성 요청: ${content.substring(0, 50)}...`);

    const newPost = {
      id: nextPostId++,
      content: content.trim(),
      authorId: authorId,
      authorNickname: req.user.nickname || '익명',
      authorProfileImage: req.user.profileImage || null,
      category: category || '일반',
      hashtags: hashtags || [],
      likes: 0,
      comments: 0,
      shares: 0,
      views: 0,
      isLiked: false,
      isBookmarked: false,
      isShared: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    posts.unshift(newPost); // 최신 게시글이 맨 앞에 오도록
    saveToFile();

    console.log(`게시글 생성 완료: ID ${newPost.id}`);

    sendCreatedResponse(res, newPost, '게시글이 성공적으로 생성되었습니다.');
  } catch (error) {
    console.error('게시글 생성 오류:', error);
    sendErrorResponse(res, '게시글 생성에 실패했습니다.', 500, error);
  }
};

// 게시글 수정
const updatePost = (req, res) => {
  try {
    const { id } = req.params;
    const { content, category, hashtags } = req.body;
    const authorId = req.user.id;
    const postId = parseInt(id);

    console.log(`게시글 수정 요청: ID ${postId}`);

    const postIndex = posts.findIndex(p => p.id === postId);

    if (postIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '게시글을 찾을 수 없습니다.'
      });
    }

    const post = posts[postIndex];

    // 작성자 확인
    if (post.authorId !== authorId) {
      return res.status(403).json({
        success: false,
        message: '게시글을 수정할 권한이 없습니다.'
      });
    }

    // 게시글 수정
    posts[postIndex] = {
      ...post,
      content: content?.trim() || post.content,
      category: category || post.category,
      hashtags: hashtags || post.hashtags,
      updatedAt: new Date().toISOString()
    };

    saveToFile();

    console.log(`게시글 수정 완료: ID ${postId}`);

    res.json({
      success: true,
      data: posts[postIndex]
    });
  } catch (error) {
    console.error('게시글 수정 오류:', error);
    res.status(500).json({
      success: false,
      message: '게시글 수정에 실패했습니다.',
      error: error.message
    });
  }
};

// 게시글 삭제
const deletePost = (req, res) => {
  try {
    const { id } = req.params;
    const authorId = req.user.id;
    const postId = parseInt(id);

    console.log(`게시글 삭제 요청: ID ${postId}`);

    const postIndex = posts.findIndex(p => p.id === postId);

    if (postIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '게시글을 찾을 수 없습니다.'
      });
    }

    const post = posts[postIndex];

    // 작성자 확인
    if (post.authorId !== authorId) {
      return res.status(403).json({
        success: false,
        message: '게시글을 삭제할 권한이 없습니다.'
      });
    }

    // 게시글 삭제
    posts.splice(postIndex, 1);

    // 관련 댓글도 삭제
    comments = comments.filter(c => c.postId !== postId);

    saveToFile();

    console.log(`게시글 삭제 완료: ID ${postId}`);

    res.json({
      success: true,
      message: '게시글이 삭제되었습니다.'
    });
  } catch (error) {
    console.error('게시글 삭제 오류:', error);
    res.status(500).json({
      success: false,
      message: '게시글 삭제에 실패했습니다.',
      error: error.message
    });
  }
};

// 게시글 좋아요 토글
const togglePostLike = (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const postId = parseInt(id);

    console.log(`게시글 좋아요 토글 요청: ID ${postId}`);

    const post = posts.find(p => p.id === postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: '게시글을 찾을 수 없습니다.'
      });
    }

    // 좋아요 토글
    if (post.isLiked) {
      post.likes -= 1;
      post.isLiked = false;
    } else {
      post.likes += 1;
      post.isLiked = true;
    }

    saveToFile();

    console.log(`게시글 좋아요 토글 완료: ${post.isLiked ? '좋아요' : '좋아요 취소'}`);

    res.json({
      success: true,
      data: {
        isLiked: post.isLiked,
        likes: post.likes
      }
    });
  } catch (error) {
    console.error('게시글 좋아요 토글 오류:', error);
    res.status(500).json({
      success: false,
      message: '좋아요 처리에 실패했습니다.',
      error: error.message
    });
  }
};

// 댓글 목록 조회
const getComments = (req, res) => {
  try {
    const { postId } = req.params;
    const postIdNum = parseInt(postId);

    console.log(`댓글 목록 조회 요청: 게시글 ID ${postIdNum}`);

    const postComments = comments
      .filter(c => c.postId === postIdNum && !c.parentCommentId)
      .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));

    // 각 댓글의 답글도 포함
    const commentsWithReplies = postComments.map(comment => {
      const replies = comments
        .filter(c => c.parentCommentId === comment.id)
        .sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
      
      return {
        ...comment,
        replies
      };
    });

    console.log(`댓글 수: ${commentsWithReplies.length}개`);

    res.json({
      success: true,
      data: commentsWithReplies
    });
  } catch (error) {
    console.error('댓글 목록 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '댓글 목록 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 댓글 생성
const createComment = (req, res) => {
  try {
    const { postId } = req.params;
    const { content, parentCommentId } = req.body;
    const authorId = req.user.id;
    const postIdNum = parseInt(postId);

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: '댓글 내용은 필수입니다.'
      });
    }

    console.log(`댓글 생성 요청: 게시글 ID ${postIdNum}`);

    // 게시글 존재 확인
    const post = posts.find(p => p.id === postIdNum);
    if (!post) {
      return res.status(404).json({
        success: false,
        message: '게시글을 찾을 수 없습니다.'
      });
    }

    const newComment = {
      id: nextCommentId++,
      postId: postIdNum,
      authorId: authorId,
      authorNickname: req.user.nickname || '익명',
      authorProfileImage: req.user.profileImage || null,
      content: content.trim(),
      parentCommentId: parentCommentId ? parseInt(parentCommentId) : null,
      likeCount: 0,
      isLiked: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      replies: []
    };

    comments.push(newComment);

    // 게시글의 댓글 수 증가
    post.comments += 1;
    saveToFile();

    console.log(`댓글 생성 완료: ID ${newComment.id}`);

    res.status(201).json({
      success: true,
      data: newComment
    });
  } catch (error) {
    console.error('댓글 생성 오류:', error);
    res.status(500).json({
      success: false,
      message: '댓글 생성에 실패했습니다.',
      error: error.message
    });
  }
};

// 댓글 좋아요 토글
const toggleCommentLike = (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.user.id;
    const commentIdNum = parseInt(commentId);

    console.log(`댓글 좋아요 토글 요청: ID ${commentIdNum}`);

    const comment = comments.find(c => c.id === commentIdNum);

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: '댓글을 찾을 수 없습니다.'
      });
    }

    // 좋아요 토글
    if (comment.isLiked) {
      comment.likeCount -= 1;
      comment.isLiked = false;
    } else {
      comment.likeCount += 1;
      comment.isLiked = true;
    }

    saveToFile();

    console.log(`댓글 좋아요 토글 완료: ${comment.isLiked ? '좋아요' : '좋아요 취소'}`);

    res.json({
      success: true,
      data: {
        isLiked: comment.isLiked,
        likeCount: comment.likeCount
      }
    });
  } catch (error) {
    console.error('댓글 좋아요 토글 오류:', error);
    res.status(500).json({
      success: false,
      message: '댓글 좋아요 처리에 실패했습니다.',
      error: error.message
    });
  }
};

// 내 게시글 조회
const getMyPosts = async (req, res) => {
  try {
    const userId = req.user.id;
    const userEmail = req.user.email;
    
    console.log('🔍 getMyPosts 호출됨 - userId:', userId, 'userEmail:', userEmail);
    
    // 기본 검증 (간단하게)
    if (!userId || !userEmail) {
      console.log('❌ 사용자 정보 누락');
      return res.status(400).json({
        success: false,
        message: '사용자 정보가 없습니다.'
      });
    }
    
    // 사용자 작업 로깅
    logUserOperation(req, '내 게시글 조회');
    
    console.log('🔍 전체 게시글 수:', posts.length);
    console.log('🔍 전체 게시글 authorId들:', posts.map(p => p.authorId));
    
    // 간단한 필터링으로 조회
    const myPosts = posts.filter(post => post.authorId === userId);
    
    console.log('🔍 필터링된 내 게시글 수:', myPosts.length);
    
    res.json({
      success: true,
      data: myPosts,
      count: myPosts.length
    });
  } catch (error) {
    console.error('내 게시글 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '내 게시글 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 서버 시작 시 데이터 로드
loadFromFile();

module.exports = {
  getPosts,
  getPostById,
  createPost,
  updatePost,
  deletePost,
  togglePostLike,
  getComments,
  createComment,
  toggleCommentLike,
  getMyPosts,
  loadFromFile,
  saveToFile
};
