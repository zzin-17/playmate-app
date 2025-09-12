const fs = require('fs');
const path = require('path');

// 커뮤니티 데이터 파일 경로
const POSTS_FILE = path.join(__dirname, '../data/posts.json');
const COMMENTS_FILE = path.join(__dirname, '../data/comments.json');

// 메모리 스토어
let posts = [];
let comments = [];
let nextPostId = 1;
let nextCommentId = 1;

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
  return [
    {
      id: 1,
      title: '테니스 초보자 모임 구합니다',
      content: '테니스를 시작한 지 3개월 된 초보자입니다. 같이 연습할 분들 구합니다! #테니스초보 #모임 #연습',
      authorId: 1,
      authorNickname: '테니스러버',
      authorProfileImage: null,
      category: '모임',
      hashtags: ['테니스초보', '모임', '연습'],
      likes: 12,
      comments: 8,
      shares: 2,
      views: 156,
      isLiked: false,
      isBookmarked: false,
      isShared: false,
      createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(), // 2시간 전
      updatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: 2,
      title: '백핸드 스핀 치는 법 알려주세요',
      content: '백핸드로 스핀을 치려고 하는데 자꾸 실패합니다. 팁 부탁드려요! #백핸드 #스핀 #테니스팁',
      authorId: 2,
      authorNickname: '스핀마스터',
      authorProfileImage: null,
      category: '테니스팁',
      hashtags: ['백핸드', '스핀', '테니스팁'],
      likes: 25,
      comments: 15,
      shares: 5,
      views: 234,
      isLiked: true,
      isBookmarked: false,
      isShared: true,
      createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(), // 5시간 전
      updatedAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: 3,
      title: '주말에 같이 테니스 치실 분?',
      content: '이번 주말에 잠실에서 테니스 치실 분 구합니다. 초급~중급 수준이에요! #주말 #잠실 #테니스',
      authorId: 3,
      authorNickname: '주말테니스',
      authorProfileImage: null,
      category: '모임',
      hashtags: ['주말', '잠실', '테니스'],
      likes: 18,
      comments: 12,
      shares: 3,
      views: 189,
      isLiked: false,
      isBookmarked: true,
      isShared: false,
      createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // 1일 전
      updatedAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: 4,
      title: '테니스 라켓 추천 부탁드려요',
      content: '초보자용 테니스 라켓 추천해주세요. 예산은 20만원 정도입니다. #라켓추천 #초보자 #테니스',
      authorId: 4,
      authorNickname: '라켓고민',
      authorProfileImage: null,
      category: '일반',
      hashtags: ['라켓추천', '초보자', '테니스'],
      likes: 32,
      comments: 28,
      shares: 8,
      views: 312,
      isLiked: true,
      isBookmarked: false,
      isShared: false,
      createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(), // 2일 전
      updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    },
    {
      id: 5,
      title: '코트 예약 팁 공유합니다',
      content: '잠실 테니스장 예약하는 팁을 공유합니다. 새벽 6시에 예약하면 확률이 높아요! #코트예약 #팁 #잠실',
      authorId: 5,
      authorNickname: '코트마스터',
      authorProfileImage: null,
      category: '테니스팁',
      hashtags: ['코트예약', '팁', '잠실'],
      likes: 45,
      comments: 35,
      shares: 12,
      views: 456,
      isLiked: false,
      isBookmarked: false,
      isShared: false,
      createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(), // 3일 전
      updatedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
    },
  ];
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
        post.title.toLowerCase().includes(searchLower) ||
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

    res.json({
      success: true,
      data: paginatedPosts,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: filteredPosts.length,
        totalPages: Math.ceil(filteredPosts.length / limitNum)
      }
    });
  } catch (error) {
    console.error('게시글 목록 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '게시글 목록 조회에 실패했습니다.',
      error: error.message
    });
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

    console.log(`게시글 조회 성공: ${post.title}`);

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
    const { title, content, category, hashtags } = req.body;
    const authorId = req.user.id;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: '제목과 내용은 필수입니다.'
      });
    }

    console.log(`게시글 생성 요청: ${title}`);

    const newPost = {
      id: nextPostId++,
      title: title.trim(),
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

    res.status(201).json({
      success: true,
      data: newPost
    });
  } catch (error) {
    console.error('게시글 생성 오류:', error);
    res.status(500).json({
      success: false,
      message: '게시글 생성에 실패했습니다.',
      error: error.message
    });
  }
};

// 게시글 수정
const updatePost = (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, category, hashtags } = req.body;
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
      title: title?.trim() || post.title,
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
  loadFromFile,
  saveToFile
};
