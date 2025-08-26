import '../screens/community/community_screen.dart';

class MockPostService {
  static const int _pageSize = 10;
  
  /// 모든 목업 데이터
  static List<PostData> getAllMockPosts() {
    return [
      PostData(
        id: 1,
        title: '테니스 초보자 모임 구합니다',
        author: '테니스러버',
        authorId: 1,
        content: '테니스를 시작한 지 3개월 된 초보자입니다. 같이 연습할 분들 구합니다! #테니스초보 #모임 #연습',
        likes: 12,
        comments: 8,
        timeAgo: '2시간 전',
        category: '모임',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: true,
        isLiked: false,
        isBookmarked: false,
        shareCount: 2,
        isSharedByCurrentUser: false,
        hashtags: ['테니스초보', '모임', '연습'],
      ),
      PostData(
        id: 2,
        title: '백핸드 스핀 치는 법 알려주세요',
        author: '스핀마스터',
        authorId: 2,
        content: '백핸드로 스핀을 치려고 하는데 자꾸 실패합니다. 팁 부탁드려요! #백핸드 #스핀 #테니스팁',
        likes: 25,
        comments: 15,
        timeAgo: '5시간 전',
        category: '테니스팁',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: false,
        isLiked: true,
        isBookmarked: false,
        shareCount: 5,
        isSharedByCurrentUser: true,
        hashtags: ['백핸드', '스핀', '테니스팁'],
      ),
      PostData(
        id: 3,
        title: '주말에 같이 테니스 치실 분?',
        author: '주말테니스',
        authorId: 3,
        content: '이번 주말에 잠실에서 테니스 치실 분 구합니다. 초급~중급 수준이에요! #주말 #잠실 #테니스',
        likes: 18,
        comments: 12,
        timeAgo: '1일 전',
        category: '모임',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: true,
        isLiked: false,
        isBookmarked: true,
        shareCount: 3,
        isSharedByCurrentUser: false,
        hashtags: ['주말', '잠실', '테니스'],
      ),
      PostData(
        id: 4,
        title: '테니스 라켓 추천 부탁드려요',
        author: '라켓고민',
        authorId: 4,
        content: '초보자용 테니스 라켓 추천해주세요. 예산은 20만원 정도입니다. #라켓추천 #초보자 #테니스',
        likes: 32,
        comments: 28,
        timeAgo: '2일 전',
        category: '일반',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: false,
        isLiked: true,
        isBookmarked: false,
        shareCount: 8,
        isSharedByCurrentUser: false,
        hashtags: ['라켓추천', '초보자', '테니스'],
      ),
      PostData(
        id: 5,
        title: '코트 예약 팁 공유합니다',
        author: '코트마스터',
        authorId: 5,
        content: '잠실 테니스장 예약하는 팁을 공유합니다. 새벽 6시에 예약하면 확률이 높아요! #코트예약 #팁 #잠실',
        likes: 45,
        comments: 35,
        timeAgo: '3일 전',
        category: '테니스팁',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: true,
        isLiked: false,
        isBookmarked: false,
        shareCount: 12,
        isSharedByCurrentUser: false,
        hashtags: ['코트예약', '팁', '잠실'],
      ),
      PostData(
        id: 6,
        title: '테니스 동호회 모집합니다',
        author: '동호회장',
        authorId: 6,
        content: '잠실 지역 테니스 동호회 회원을 모집합니다. 매주 토요일 오후에 연습합니다! #동호회 #모집 #잠실',
        likes: 28,
        comments: 22,
        timeAgo: '4일 전',
        category: '모임',
        authorProfileImage: 'https://via.placeholder.com/40x40',
        isFollowing: false,
        isLiked: false,
        isBookmarked: false,
        shareCount: 6,
        isSharedByCurrentUser: false,
        hashtags: ['동호회', '모집', '잠실'],
      ),
    ];
  }
  
  /// ID로 게시글 찾기
  static PostData? getPostById(int id) {
    final allPosts = getAllMockPosts();
    try {
      return allPosts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 여러 ID로 게시글들 찾기
  static List<PostData?> getPostsByIds(List<int> ids) {
    final allPosts = getAllMockPosts();
    return ids.map((id) {
      try {
        return allPosts.firstWhere((post) => post.id == id);
      } catch (e) {
        return null; // 해당 ID의 게시글이 없는 경우
      }
    }).toList();
  }
}
