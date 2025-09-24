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
    console.log(`📁 POSTS_FILE 경로: ${POSTS_FILE}`);
    console.log(`📁 파일 존재 여부: ${fs.existsSync(POSTS_FILE)}`);
    
    // 게시글 데이터 로드
    if (fs.existsSync(POSTS_FILE)) {
      const postsData = fs.readFileSync(POSTS_FILE, 'utf8');
      posts = JSON.parse(postsData);
      console.log(`게시글 데이터 로드 완료: ${posts.length}개`);
      console.log(`게시글 ID 목록:`, posts.map(p => p.id));
    } else {
      posts = getDefaultPosts();
      console.log('기본 게시글 데이터 생성 완료');
      console.log(`기본 게시글 개수: ${posts.length}개`);
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

// 게시글의 실제 댓글 수 계산 및 업데이트
function updatePostCommentCounts() {
  posts.forEach(post => {
    const actualCommentCount = comments.filter(c => c.postId === post.id).length;
    if (post.comments !== actualCommentCount) {
      console.log(`📊 게시글 ${post.id} 댓글 수 업데이트: ${post.comments} → ${actualCommentCount}`);
      post.comments = actualCommentCount;
    }
  });
}

// 파일에 데이터 저장
function saveToFile() {
  try {
    // 댓글 수 동기화
    updatePostCommentCounts();
    
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
    const postId = req.params.id; // 라우트가 /posts/:id/comments 이므로 req.params.id 사용
    const postIdNum = parseInt(postId);

    console.log(`댓글 목록 조회 요청: 게시글 ID ${postIdNum}`);

    const postComments = comments
      .filter(c => c.postId === postIdNum && !c.parentCommentId)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)); // 최신 댓글이 상단에

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
    const postId = req.params.id; // 라우트가 /posts/:id/comments 이므로 req.params.id 사용
    const { content, parentCommentId } = req.body;
    const authorId = req.user.id;
    const postIdNum = parseInt(postId);

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: '댓글 내용은 필수입니다.'
      });
    }

    console.log(`🔍 원본 postId: "${postId}" (타입: ${typeof postId})`);
    console.log(`🔍 parseInt 결과: ${postIdNum} (타입: ${typeof postIdNum})`);
    console.log(`댓글 생성 요청: 게시글 ID ${postIdNum}`);
    console.log(`현재 posts 배열 길이: ${posts.length}`);
    console.log(`posts 배열:`, posts.map(p => ({ id: p.id, authorId: p.authorId })));

    // 게시글 존재 확인
    const post = posts.find(p => p.id === postIdNum);
    if (!post) {
      console.log(`❌ 게시글 ID ${postIdNum}을 찾을 수 없음`);
      return res.status(404).json({
        success: false,
        message: '게시글을 찾을 수 없습니다.'
      });
    }
    console.log(`✅ 게시글 찾음: ID ${post.id}, 작성자: ${post.authorNickname}`);

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

    // saveToFile()에서 자동으로 댓글 수 계산됨
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

// 댓글 수정
const updateComment = (req, res) => {
  try {
    const { commentId } = req.params;
    const { content } = req.body;
    const userId = req.user.id;
    const commentIdNum = parseInt(commentId);

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: '댓글 내용은 필수입니다.'
      });
    }

    console.log(`댓글 수정 요청: 댓글 ID ${commentIdNum}, 사용자 ID ${userId}`);

    // 댓글 찾기
    const commentIndex = comments.findIndex(c => c.id === commentIdNum);
    if (commentIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '댓글을 찾을 수 없습니다.'
      });
    }

    const comment = comments[commentIndex];

    // 작성자 권한 확인
    if (comment.authorId !== userId) {
      return res.status(403).json({
        success: false,
        message: '댓글 수정 권한이 없습니다.'
      });
    }

    // 댓글 수정
    comment.content = content.trim();
    comment.updatedAt = new Date().toISOString();
    
    saveToFile();

    console.log(`댓글 수정 완료: ID ${commentIdNum}`);

    res.json({
      success: true,
      data: comment
    });
  } catch (error) {
    console.error('댓글 수정 오류:', error);
    res.status(500).json({
      success: false,
      message: '댓글 수정에 실패했습니다.',
      error: error.message
    });
  }
};

// 댓글 삭제
const deleteComment = (req, res) => {
  try {
    const { commentId } = req.params;
    const userId = req.user.id;
    const commentIdNum = parseInt(commentId);

    console.log(`댓글 삭제 요청: 댓글 ID ${commentIdNum}, 사용자 ID ${userId}`);

    // 댓글 찾기
    const commentIndex = comments.findIndex(c => c.id === commentIdNum);
    if (commentIndex === -1) {
      return res.status(404).json({
        success: false,
        message: '댓글을 찾을 수 없습니다.'
      });
    }

    const comment = comments[commentIndex];

    // 작성자 권한 확인
    if (comment.authorId !== userId) {
      return res.status(403).json({
        success: false,
        message: '댓글 삭제 권한이 없습니다.'
      });
    }

    // 댓글 삭제
    comments.splice(commentIndex, 1);

    // saveToFile()에서 자동으로 댓글 수 계산됨
    saveToFile();

    console.log(`댓글 삭제 완료: ID ${commentIdNum}`);

    res.json({
      success: true,
      message: '댓글이 삭제되었습니다.'
    });
  } catch (error) {
    console.error('댓글 삭제 오류:', error);
    res.status(500).json({
      success: false,
      message: '댓글 삭제에 실패했습니다.',
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
console.log('🔄 커뮤니티 데이터 로드 시작...');
loadFromFile();
console.log(`✅ 커뮤니티 데이터 로드 완료: posts=${posts.length}개, comments=${comments.length}개`);

// 특정 사용자의 게시글 조회
const getUserPosts = (req, res) => {
  try {
    const { userId } = req.params;
    const targetUserId = parseInt(userId);

    console.log(`특정 사용자 게시글 조회: 사용자 ID ${targetUserId}`);

    // 해당 사용자의 게시글 필터링
    const userPosts = posts.filter(post => post.authorId === targetUserId);
    const currentUserId = req.user.id;

    // 각 게시글에 현재 사용자의 좋아요 상태 추가
    const postsWithLikeStatus = userPosts.map(post => {
      const isLiked = post.likedBy && post.likedBy.includes(currentUserId);
      const isBookmarked = post.bookmarkedBy && post.bookmarkedBy.includes(currentUserId);
      
      const { isLiked: oldIsLiked, isBookmarked: oldIsBookmarked, isShared, likes, comments, shares, ...postWithoutOldFields } = post;
      return {
        ...postWithoutOldFields,
        likeCount: likes || 0,
        commentCount: comments || 0,
        shareCount: shares || 0,
        isLikedByCurrentUser: isLiked || false,
        isBookmarkedByCurrentUser: isBookmarked || false,
        isSharedByCurrentUser: false // 공유 기능은 아직 구현되지 않음
      };
    });

    // 최신순 정렬
    postsWithLikeStatus.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    console.log(`사용자 ${targetUserId}의 게시글 ${postsWithLikeStatus.length}개 반환`);

    res.json({
      success: true,
      data: postsWithLikeStatus,
      count: postsWithLikeStatus.length
    });
  } catch (error) {
    console.error('사용자 게시글 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '사용자 게시글 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 내가 북마크한 게시글 조회
const getMyBookmarks = (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log(`북마크한 게시글 조회 요청: 사용자 ID ${userId}`);
    
    // 북마크한 게시글 필터링
    const bookmarkedPosts = posts.filter(post => 
      post.bookmarks && post.bookmarks.some(bookmark => bookmark.userId === userId)
    );
    
    console.log(`북마크한 게시글 개수: ${bookmarkedPosts.length}`);
    
    res.json({
      success: true,
      data: bookmarkedPosts,
      count: bookmarkedPosts.length
    });
  } catch (error) {
    console.error('북마크한 게시글 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '북마크한 게시글 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 내가 좋아요한 게시글 조회
const getMyLikes = (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log(`좋아요한 게시글 조회 요청: 사용자 ID ${userId}`);
    
    // 좋아요한 게시글 필터링
    const likedPosts = posts.filter(post => 
      post.isLiked && post.authorId !== userId // 내가 작성한 게시글은 제외
    );
    
    console.log(`좋아요한 게시글 개수: ${likedPosts.length}`);
    
    res.json({
      success: true,
      data: likedPosts,
      count: likedPosts.length
    });
  } catch (error) {
    console.error('좋아요한 게시글 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '좋아요한 게시글 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 내가 댓글단 게시글 조회
const getMyCommentedPosts = (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log(`댓글단 게시글 조회 요청: 사용자 ID ${userId}`);
    
    // 댓글을 작성한 게시글 필터링
    const commentedPosts = posts.filter(post => 
      post.comments && post.comments.some(comment => comment.authorId === userId)
    );
    
    console.log(`댓글단 게시글 개수: ${commentedPosts.length}`);
    
    res.json({
      success: true,
      data: commentedPosts,
      count: commentedPosts.length
    });
  } catch (error) {
    console.error('댓글단 게시글 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '댓글단 게시글 조회에 실패했습니다.',
      error: error.message
    });
  }
};

module.exports = {
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
  loadFromFile,
  saveToFile
};
