const fs = require('fs').promises;
const path = require('path');

// 데이터 파일 경로
const DATA_DIR = path.join(__dirname, '../data');

// 배치 API 컨트롤러
class BatchController {
  // 배치 게시글 로드
  async batchLoadPosts(req, res) {
    try {
      const { userIds, limit = 20, offset = 0 } = req.body;
      
      if (!userIds || !Array.isArray(userIds)) {
        return res.status(400).json({
          success: false,
          error: 'userIds 배열이 필요합니다'
        });
      }

      // 모든 게시글 로드
      const postsData = await fs.readFile(path.join(DATA_DIR, 'posts.json'), 'utf8');
      const allPosts = JSON.parse(postsData);

      // 특정 사용자들의 게시글 필터링
      const filteredPosts = allPosts.filter(post => 
        userIds.includes(post.userId)
      );

      // 정렬 (최신순)
      filteredPosts.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      // 페이지네이션
      const paginatedPosts = filteredPosts.slice(offset, offset + limit);

      res.json({
        success: true,
        data: paginatedPosts,
        total: filteredPosts.length,
        limit,
        offset
      });
    } catch (error) {
      console.error('배치 게시글 로드 오류:', error);
      res.status(500).json({
        success: false,
        error: '배치 게시글 로드 실패'
      });
    }
  }

  // 배치 채팅방 로드
  async batchLoadChatRooms(req, res) {
    try {
      const { userIds } = req.body;
      
      if (!userIds || !Array.isArray(userIds)) {
        return res.status(400).json({
          success: false,
          error: 'userIds 배열이 필요합니다'
        });
      }

      // 모든 채팅방 로드
      const chatRoomsData = await fs.readFile(path.join(DATA_DIR, 'chat_rooms.json'), 'utf8');
      const allChatRooms = JSON.parse(chatRoomsData);

      // 특정 사용자들의 채팅방 필터링
      const filteredRooms = allChatRooms.filter(room => 
        userIds.some(userId => 
          room.participants && room.participants.includes(userId)
        )
      );

      res.json({
        success: true,
        data: filteredRooms,
        total: filteredRooms.length
      });
    } catch (error) {
      console.error('배치 채팅방 로드 오류:', error);
      res.status(500).json({
        success: false,
        error: '배치 채팅방 로드 실패'
      });
    }
  }

  // 배치 알림 로드
  async batchLoadNotifications(req, res) {
    try {
      const { userIds, limit = 50, offset = 0 } = req.body;
      
      if (!userIds || !Array.isArray(userIds)) {
        return res.status(400).json({
          success: false,
          error: 'userIds 배열이 필요합니다'
        });
      }

      // 모든 알림 로드 (메모리 기반이므로 실제로는 데이터베이스에서 조회)
      // 여기서는 빈 배열 반환 (실제 구현 시 알림 데이터 소스에서 조회)
      const notifications = [];

      res.json({
        success: true,
        data: notifications,
        total: notifications.length,
        limit,
        offset
      });
    } catch (error) {
      console.error('배치 알림 로드 오류:', error);
      res.status(500).json({
        success: false,
        error: '배치 알림 로드 실패'
      });
    }
  }

  // 배치 후기 로드
  async batchLoadReviews(req, res) {
    try {
      const { userIds, limit = 20, offset = 0 } = req.body;
      
      if (!userIds || !Array.isArray(userIds)) {
        return res.status(400).json({
          success: false,
          error: 'userIds 배열이 필요합니다'
        });
      }

      // 모든 후기 로드 (파일이 없으면 빈 배열)
      let allReviews = [];
      try {
        const reviewsData = await fs.readFile(path.join(DATA_DIR, 'reviews.json'), 'utf8');
        allReviews = JSON.parse(reviewsData);
      } catch (error) {
        if (error.code !== 'ENOENT') {
          throw error;
        }
        // 파일이 없으면 빈 배열로 처리
      }

      // 특정 사용자들의 후기 필터링 (targetUserId 기준)
      const filteredReviews = allReviews.filter(review => 
        userIds.includes(review.targetUserId)
      );

      // 정렬 (최신순)
      filteredReviews.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

      // 페이지네이션
      const paginatedReviews = filteredReviews.slice(offset, offset + limit);

      res.json({
        success: true,
        data: paginatedReviews,
        total: filteredReviews.length,
        limit,
        offset
      });
    } catch (error) {
      console.error('배치 후기 로드 오류:', error);
      res.status(500).json({
        success: false,
        error: '배치 후기 로드 실패'
      });
    }
  }

  // 배치 프로필 동기화
  async batchSyncProfiles(req, res) {
    try {
      const { userIds } = req.body;
      
      if (!userIds || !Array.isArray(userIds)) {
        return res.status(400).json({
          success: false,
          error: 'userIds 배열이 필요합니다'
        });
      }

      // 모든 사용자 로드
      const usersData = await fs.readFile(path.join(DATA_DIR, 'users.json'), 'utf8');
      const allUsers = JSON.parse(usersData);

      // 특정 사용자들의 프로필 필터링
      const filteredProfiles = allUsers.filter(user => 
        userIds.includes(user.id)
      );

      // 프로필 정보만 반환 (민감한 정보 제외)
      const profiles = filteredProfiles.map(user => ({
        id: user.id,
        nickname: user.nickname,
        profileImage: user.profileImage,
        skillLevel: user.skillLevel,
        ntrpScore: user.ntrpScore,
        mannerScore: user.mannerScore,
        reviewCount: user.reviewCount,
        updatedAt: user.updatedAt
      }));

      res.json({
        success: true,
        data: profiles,
        total: profiles.length
      });
    } catch (error) {
      console.error('배치 프로필 동기화 오류:', error);
      res.status(500).json({
        success: false,
        error: '배치 프로필 동기화 실패'
      });
    }
  }

  // 통합 배치 요청 (여러 타입을 한 번에 처리)
  async batchRequest(req, res) {
    try {
      const { requests } = req.body;
      
      if (!requests || !Array.isArray(requests)) {
        return res.status(400).json({
          success: false,
          error: 'requests 배열이 필요합니다'
        });
      }

      const results = [];

      // 각 요청을 병렬로 처리
      const promises = requests.map(async (request) => {
        try {
          let result;
          
          switch (request.type) {
            case 'loadPosts':
              result = await this._handleLoadPosts(request.params);
              break;
            case 'loadChatRooms':
              result = await this._handleLoadChatRooms(request.params);
              break;
            case 'loadNotifications':
              result = await this._handleLoadNotifications(request.params);
              break;
            case 'loadReviews':
              result = await this._handleLoadReviews(request.params);
              break;
            case 'syncProfile':
              result = await this._handleSyncProfile(request.params);
              break;
            default:
              throw new Error(`알 수 없는 요청 타입: ${request.type}`);
          }

          return {
            id: request.id,
            type: request.type,
            success: true,
            data: result
          };
        } catch (error) {
          return {
            id: request.id,
            type: request.type,
            success: false,
            error: error.message
          };
        }
      });

      const batchResults = await Promise.all(promises);

      res.json({
        success: true,
        data: batchResults
      });
    } catch (error) {
      console.error('통합 배치 요청 오류:', error);
      res.status(500).json({
        success: false,
        error: '통합 배치 요청 실패'
      });
    }
  }

  // 내부 헬퍼 메서드들
  async _handleLoadPosts(params) {
    const { userIds, limit = 20, offset = 0 } = params;
    const postsData = await fs.readFile(path.join(DATA_DIR, 'posts.json'), 'utf8');
    const allPosts = JSON.parse(postsData);
    const filteredPosts = allPosts.filter(post => userIds.includes(post.userId));
    filteredPosts.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return filteredPosts.slice(offset, offset + limit);
  }

  async _handleLoadChatRooms(params) {
    const { userIds } = params;
    const chatRoomsData = await fs.readFile(path.join(DATA_DIR, 'chat_rooms.json'), 'utf8');
    const allChatRooms = JSON.parse(chatRoomsData);
    return allChatRooms.filter(room => 
      userIds.some(userId => room.participants && room.participants.includes(userId))
    );
  }

  async _handleLoadNotifications(params) {
    // 알림은 메모리 기반이므로 빈 배열 반환
    return [];
  }

  async _handleLoadReviews(params) {
    const { userIds, limit = 20, offset = 0 } = params;
    try {
      const reviewsData = await fs.readFile(path.join(DATA_DIR, 'reviews.json'), 'utf8');
      const allReviews = JSON.parse(reviewsData);
      const filteredReviews = allReviews.filter(review => userIds.includes(review.targetUserId));
      filteredReviews.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      return filteredReviews.slice(offset, offset + limit);
    } catch (error) {
      // reviews.json 파일이 없으면 빈 배열 반환
      if (error.code === 'ENOENT') {
        return [];
      }
      throw error;
    }
  }

  async _handleSyncProfile(params) {
    const { userIds } = params;
    const usersData = await fs.readFile(path.join(DATA_DIR, 'users.json'), 'utf8');
    const allUsers = JSON.parse(usersData);
    const filteredProfiles = allUsers.filter(user => userIds.includes(user.id));
    return filteredProfiles.map(user => ({
      id: user.id,
      nickname: user.nickname,
      profileImage: user.profileImage,
      skillLevel: user.skillLevel,
      ntrpScore: user.ntrpScore,
      mannerScore: user.mannerScore,
      reviewCount: user.reviewCount,
      updatedAt: user.updatedAt
    }));
  }
}

const batchController = new BatchController();

module.exports = {
  batchLoadPosts: (req, res) => batchController.batchLoadPosts(req, res),
  batchLoadChatRooms: (req, res) => batchController.batchLoadChatRooms(req, res),
  batchLoadNotifications: (req, res) => batchController.batchLoadNotifications(req, res),
  batchLoadReviews: (req, res) => batchController.batchLoadReviews(req, res),
  batchSyncProfiles: (req, res) => batchController.batchSyncProfiles(req, res),
  batchRequest: (req, res) => batchController.batchRequest(req, res),
};

