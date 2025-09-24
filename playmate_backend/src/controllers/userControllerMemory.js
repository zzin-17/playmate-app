const userStore = require('../stores/userStore');

// @desc    Get user profile
// @route   GET /api/users/:id
// @access  Private
const getUserProfile = (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    const user = userStore.getUserById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // 비밀번호 제외하고 반환
    const { password, ...userWithoutPassword } = user;
    
    // null 값들을 기본값으로 처리
    const safeUser = {
      ...userWithoutPassword,
      // 숫자 필드들 안전 처리
      birthYear: userWithoutPassword.birthYear ? parseInt(userWithoutPassword.birthYear) : 1990,
      skillLevel: userWithoutPassword.skillLevel ? parseInt(userWithoutPassword.skillLevel) : 1,
      reviewCount: userWithoutPassword.reviewCount ? parseInt(userWithoutPassword.reviewCount) : 0,
      mannerScore: userWithoutPassword.mannerScore ? parseFloat(userWithoutPassword.mannerScore) : 5.0,
      ntrpScore: userWithoutPassword.ntrpScore ? parseFloat(userWithoutPassword.ntrpScore) : 3.0,
      // 배열 필드들 안전 처리
      followingIds: Array.isArray(userWithoutPassword.followingIds) ? userWithoutPassword.followingIds : [],
      followerIds: Array.isArray(userWithoutPassword.followerIds) ? userWithoutPassword.followerIds : [],
      preferredTime: Array.isArray(userWithoutPassword.preferredTime) ? userWithoutPassword.preferredTime : [],
      // 문자열 필드들 안전 처리
      startYearMonth: userWithoutPassword.startYearMonth || "2020-01",
      preferredCourt: userWithoutPassword.preferredCourt || "",
      playStyle: userWithoutPassword.playStyle || "",
      preferredGameType: userWithoutPassword.preferredGameType || "mixed",
      bio: userWithoutPassword.bio || "",
      location: userWithoutPassword.location || "",
      // 불린 필드들 안전 처리
      hasLesson: userWithoutPassword.hasLesson === true,
      isVerified: userWithoutPassword.isVerified === true,
    };
    
    res.json({
      success: true,
      data: safeUser
    });
  } catch (error) {
    console.error('사용자 프로필 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get user profile',
      error: error.message
    });
  }
};

// @desc    Update user profile
// @route   PUT /api/users/:id
// @access  Private
const updateUserProfile = (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    const { nickname, bio, profileImage, location } = req.body;
    
    const updatedUser = userStore.updateUser(userId, {
      nickname,
      bio,
      profileImage,
      location
    });
    
    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // 파일에 저장 (비동기)
    userStore.saveUsersToFile().catch(console.error);
    
    // 비밀번호 제외하고 반환
    const { password, ...userWithoutPassword } = updatedUser;
    
    res.json({
      success: true,
      data: userWithoutPassword
    });
  } catch (error) {
    console.error('사용자 프로필 업데이트 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user profile',
      error: error.message
    });
  }
};

// @desc    Delete user account
// @route   DELETE /api/users/:id
// @access  Private
const deleteUser = (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    
    const updatedUser = userStore.updateUser(userId, {
      isActive: false
    });
    
    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // 파일에 저장 (비동기)
    userStore.saveUsersToFile().catch(console.error);
    
    res.json({
      success: true,
      message: 'User account deactivated successfully'
    });
  } catch (error) {
    console.error('사용자 계정 삭제 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user account',
      error: error.message
    });
  }
};

// @desc    Search users
// @route   GET /api/users/search?q=query
// @access  Private
const searchUsers = (req, res) => {
  try {
    const { q } = req.query;
    
    console.log(`🔍 사용자 검색 요청: "${q}"`);
    console.log(`📊 통합 저장소 상태: ${userStore.getUserCount()}명 로드됨`);
    
    if (!q || q.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }
    
    const results = userStore.searchUsers(q, 20);
    
    console.log(`✅ 사용자 검색 완료: ${results.length}명 찾음`);
    
    res.json({
      success: true,
      data: results
    });
  } catch (error) {
    console.error('❌ 사용자 검색 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search users',
      error: error.message
    });
  }
};

// @desc    Test data status
// @route   GET /api/users/test
// @access  Public
const testDataStatus = (req, res) => {
  console.log(`🔍 테스트 API 호출: 사용자 데이터 ${userStore.getUserCount()}명`);
  res.json({
    success: true,
    message: `사용자 데이터 ${userStore.getUserCount()}명 로드됨`,
    data: userStore.getAllUsersArray().map(user => ({ 
      id: user.id, 
      nickname: user.nickname, 
      email: user.email 
    }))
  });
};

// @desc    Follow user
// @route   POST /api/users/:id/follow
// @access  Private
const followUser = (req, res) => {
  try {
    const targetUserId = parseInt(req.params.id);
    const currentUserId = req.user.id;
    
    if (targetUserId === currentUserId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot follow yourself'
      });
    }
    
    const targetUser = userStore.getUserById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // 팔로우 관계 추가
    const currentUser = userStore.getUserById(currentUserId);
    if (currentUser) {
      // 현재 사용자의 팔로잉 목록에 추가
      if (!currentUser.followingIds) {
        currentUser.followingIds = [];
      }
      if (!currentUser.followingIds.includes(targetUserId)) {
        currentUser.followingIds.push(targetUserId);
      }
      
      // 대상 사용자의 팔로워 목록에 추가
      if (!targetUser.followerIds) {
        targetUser.followerIds = [];
      }
      if (!targetUser.followerIds.includes(currentUserId)) {
        targetUser.followerIds.push(currentUserId);
      }
      
      // 데이터 저장 (실제로는 데이터베이스에 저장해야 함)
      userStore.saveUsersToFile();
    }
    
    console.log(`👥 사용자 ${currentUserId}가 ${targetUserId}를 팔로우했습니다`);
    
    res.status(200).json({
      success: true,
      message: 'Successfully followed user'
    });
  } catch (error) {
    console.error('팔로우 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Unfollow user
// @route   DELETE /api/users/:id/follow
// @access  Private
const unfollowUser = (req, res) => {
  try {
    const targetUserId = parseInt(req.params.id);
    const currentUserId = req.user.id;
    
    if (targetUserId === currentUserId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot unfollow yourself'
      });
    }
    
    const targetUser = userStore.getUserById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // 언팔로우 관계 제거 (실제로는 데이터베이스에서 삭제해야 함)
    console.log(`👥 사용자 ${currentUserId}가 ${targetUserId}를 언팔로우했습니다`);
    
    res.status(200).json({
      success: true,
      message: 'Successfully unfollowed user'
    });
  } catch (error) {
    console.error('언팔로우 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get followers list
// @route   GET /api/users/:id/followers
// @access  Private
const getFollowers = (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    const user = userStore.getUserById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // 팔로워 목록 반환 (실제로는 데이터베이스에서 조회해야 함)
    const followers = user.followerIds || [];
    const followerUsers = followers.map(followerId => {
      const follower = userStore.getUserById(followerId);
      if (follower) {
        const { password, ...followerWithoutPassword } = follower;
        return followerWithoutPassword;
      }
      return null;
    }).filter(Boolean);
    
    res.json({
      success: true,
      data: followerUsers
    });
  } catch (error) {
    console.error('팔로워 목록 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

// @desc    Get following list
// @route   GET /api/users/:id/following
// @access  Private
const getFollowing = (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    const user = userStore.getUserById(userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // 팔로잉 목록 반환 (실제로는 데이터베이스에서 조회해야 함)
    const following = user.followingIds || [];
    const followingUsers = following.map(followingId => {
      const followingUser = userStore.getUserById(followingId);
      if (followingUser) {
        const { password, ...followingWithoutPassword } = followingUser;
        return followingWithoutPassword;
      }
      return null;
    }).filter(Boolean);
    
    res.json({
      success: true,
      data: followingUsers
    });
  } catch (error) {
    console.error('팔로잉 목록 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
};

module.exports = {
  getUserProfile,
  updateUserProfile,
  deleteUser,
  searchUsers,
  testDataStatus,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing
};