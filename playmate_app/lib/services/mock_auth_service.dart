import 'dart:async';
import '../models/user.dart';

class MockAuthService {
  // 테스트용 더미 사용자 데이터
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'test@playmate.com': {
      'id': 1,
      'email': 'test@playmate.com',
      'password': '123456',
      'nickname': '테스트유저',
      'gender': 'male',
      'birthYear': 1990,
      'region': '서울시 강남구',
      'skillLevel': 3,
      'startYearMonth': '2021-05',
      'ntrpScore': 3.5,
      'preferredCourt': '잠실종합운동장',
      'preferredTime': ['평일 저녁', '주말 오전'],
      'playStyle': '싱글스/복식 모두',
      'hasLesson': true,
      'mannerScore': 4.5,
      'profileImage': null,
      'followingIds': [2], // 양재시민의숲 호스트(ID: 2) 팔로우
      'followerIds': [],
      'reviewCount': 8,
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      'updatedAt': DateTime.now(),
    },
    'user1@playmate.com': {
      'id': 1,
      'email': 'user1@playmate.com',
      'password': '123456',
      'nickname': 'user1',
      'gender': 'male',
      'birthYear': 1990,
      'region': '서울시 강남구',
      'skillLevel': 3,
      'startYearMonth': '2021-05',
      'ntrpScore': 3.5,
      'preferredCourt': '잠실종합운동장',
      'preferredTime': ['평일 저녁', '주말 오전'],
      'playStyle': '싱글스/복식 모두',
      'hasLesson': true,
      'mannerScore': 4.5,
      'profileImage': null,
      'followingIds': [2], // 양재시민의숲 호스트(ID: 2) 팔로우
      'followerIds': [],
      'reviewCount': 8,
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      'updatedAt': DateTime.now(),
    },
    'demo@playmate.com': {
      'id': 2,
      'email': 'demo@playmate.com',
      'password': '123456',
      'nickname': '데모유저',
      'gender': 'female',
      'birthYear': 1995,
      'region': '서울시 서초구',
      'skillLevel': 2,
      'startYearMonth': '2022-03',
      'ntrpScore': 2.8,
      'preferredCourt': '양재시민의숲',
      'preferredTime': ['주말 오후'],
      'playStyle': '싱글스',
      'hasLesson': false,
      'mannerScore': 4.8,
      'profileImage': null,
      'followingIds': [1], // 테스트유저(ID: 1) 팔로우
      'followerIds': [1], // 테스트유저(ID: 1)에게 팔로우됨
      'reviewCount': 12,
      'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      'updatedAt': DateTime.now(),
    },
    'user2@playmate.com': {
      'id': 2,
      'email': 'user2@playmate.com',
      'password': '123456',
      'nickname': 'user2',
      'gender': 'female',
      'birthYear': 1995,
      'region': '서울시 서초구',
      'skillLevel': 2,
      'startYearMonth': '2022-03',
      'ntrpScore': 2.8,
      'preferredCourt': '양재시민의숲',
      'preferredTime': ['주말 오후'],
      'playStyle': '싱글스',
      'hasLesson': false,
      'mannerScore': 4.8,
      'profileImage': null,
      'followingIds': [],
      'followerIds': [],
      'reviewCount': 3,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      'updatedAt': DateTime.now(),
    },
    'guest@playmate.com': {
      'id': 5,
      'email': 'guest@playmate.com',
      'password': '123456',
      'nickname': '게스트유저',
      'gender': 'male',
      'birthYear': 1992,
      'region': '서울시 송파구',
      'skillLevel': 4,
      'startYearMonth': '2020-08',
      'ntrpScore': 4.2,
      'preferredCourt': '올림픽공원 테니스장',
      'preferredTime': ['주말 오전', '평일 저녁'],
      'playStyle': '복식 선호',
      'hasLesson': false,
      'mannerScore': 4.3,
      'profileImage': null,
      'followingIds': [1, 2], // 테스트유저와 데모유저 팔로우
      'followerIds': [],
      'reviewCount': 5,
      'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      'updatedAt': DateTime.now(),
    },
  };

  // 사용자 후기 데이터 (간단한 목업)
  static final Map<int, List<Map<String, dynamic>>> _mockReviews = {
    1: [
      {
        'reviewer': '테니스러버',
        'rating': 4.5,
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'content': '시간 약속 잘 지키시고 매너가 좋아요! 다음에 또 같이 쳐요.'
      },
      {
        'reviewer': '스매시왕',
        'rating': 4.8,
        'date': DateTime.now().subtract(const Duration(days: 10)),
        'content': '랠리 템포가 좋아서 재미있었습니다.'
      },
      {
        'reviewer': '포핸드장인',
        'rating': 4.2,
        'date': DateTime.now().subtract(const Duration(days: 20)),
        'content': '코트 예약을 잘 챙겨주셔서 편했어요.'
      },
      {
        'reviewer': '더블스좋아',
        'rating': 4.7,
        'date': DateTime.now().subtract(const Duration(days: 30)),
        'content': '더블스 호흡이 좋았습니다.'
      },
      {
        'reviewer': '발리장인',
        'rating': 4.6,
        'date': DateTime.now().subtract(const Duration(days: 45)),
        'content': '볼을 안정적으로 넘겨주셔서 게임이 수월했어요.'
      },
    ],
  };

  // 로그인 시뮬레이션
  static Future<Map<String, dynamic>> login(String email, String password) async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(seconds: 1));
    
    if (_mockUsers.containsKey(email)) {
      final userData = _mockUsers[email]!;
      // 자동 로그인을 위한 특별 처리 (비밀번호 검증 생략)
      if (password == 'auto_password' || userData['password'] == password) {
        return {
          'success': true,
          'token': 'mock_token_${userData['id']}',
          'user': User(
            id: userData['id'] as int,
            email: userData['email'] as String,
            nickname: userData['nickname'] as String,
            gender: userData['gender'] as String?,
            birthYear: userData['birthYear'] as int?,
            region: userData['region'] as String?,
            skillLevel: userData['skillLevel'] as int?,
            startYearMonth: userData['startYearMonth'] as String?,
            preferredCourt: userData['preferredCourt'] as String?,
            preferredTime: userData['preferredTime'] as List<String>?,
            playStyle: userData['playStyle'] as String?,
            hasLesson: userData['hasLesson'] as bool?,
            mannerScore: userData['mannerScore'] as double?,
            profileImage: userData['profileImage'] as String?,
            followingIds: (userData['followingIds'] as List<dynamic>?)?.cast<int>() ?? [],
            followerIds: (userData['followerIds'] as List<dynamic>?)?.cast<int>() ?? [],
            createdAt: userData['createdAt'] as DateTime,
            updatedAt: userData['updatedAt'] as DateTime,
          ),
        };
      } else {
        throw Exception('비밀번호가 올바르지 않습니다.');
      }
    } else {
      throw Exception('등록되지 않은 이메일입니다.');
    }
  }

  // 회원가입 시뮬레이션
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nickname,
    String? gender,
    int? birthYear,
    String? startYearMonth,
  }) async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(seconds: 1));
    
    if (_mockUsers.containsKey(email)) {
      throw Exception('이미 등록된 이메일입니다.');
    }
    
    final newUserId = _mockUsers.length + 1;
    final newUser = {
      'id': newUserId,
      'email': email,
      'password': password,
      'nickname': nickname,
      'gender': gender,
      'birthYear': birthYear,
      'region': null,
      'skillLevel': null,
      'preferredCourt': null,
      'preferredTime': [],
      'playStyle': null,
      'hasLesson': false,
      'mannerScore': null,
      'profileImage': null,
      'startYearMonth': startYearMonth,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
    
    _mockUsers[email] = newUser;
    
            return {
              'success': true,
              'token': 'mock_token_$newUserId',
              'user': User(
                id: newUser['id'] as int,
                email: newUser['email'] as String,
                nickname: newUser['nickname'] as String,
                gender: newUser['gender'] as String?,
                birthYear: newUser['birthYear'] as int?,
                region: newUser['region'] as String?,
                skillLevel: newUser['skillLevel'] as int?,
                preferredCourt: newUser['preferredCourt'] as String?,
                preferredTime: newUser['preferredTime'] as List<String>?,
                playStyle: newUser['playStyle'] as String?,
                hasLesson: newUser['hasLesson'] as bool?,
                mannerScore: newUser['mannerScore'] as double?,
                profileImage: newUser['profileImage'] as String?,
                followingIds: [], // 회원가입 시 팔로우 목록은 비워둠
                followerIds: [], // 회원가입 시 팔로워 목록은 비워둠
                createdAt: newUser['createdAt'] as DateTime,
                updatedAt: newUser['updatedAt'] as DateTime,
              ),
            };
  }

  // 사용자 정보 조회 시뮬레이션
  static Future<User> getCurrentUser(String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 토큰에서 사용자 ID 추출
    final userId = int.tryParse(token.split('_').last) ?? 1;
    
    // 해당 사용자 찾기
    final userData = _mockUsers.values.firstWhere(
      (user) => user['id'] == userId,
      orElse: () => _mockUsers['test@playmate.com']!,
    );
    
    return User(
      id: userData['id'] as int,
      email: userData['email'] as String,
      nickname: userData['nickname'] as String,
      gender: userData['gender'] as String?,
      birthYear: userData['birthYear'] as int?,
      region: userData['region'] as String?,
      skillLevel: userData['skillLevel'] as int?,
        startYearMonth: userData['startYearMonth'] as String?,
      preferredCourt: userData['preferredCourt'] as String?,
      preferredTime: userData['preferredTime'] as List<String>?,
      playStyle: userData['playStyle'] as String?,
      hasLesson: userData['hasLesson'] as bool?,
      mannerScore: userData['mannerScore'] as double?,
      profileImage: userData['profileImage'] as String?,
      followingIds: (userData['followingIds'] as List<dynamic>?)?.cast<int>() ?? [],
      followerIds: (userData['followerIds'] as List<dynamic>?)?.cast<int>() ?? [],
      createdAt: userData['createdAt'] as DateTime,
      updatedAt: userData['updatedAt'] as DateTime,
    );
  }

  // 프로필 업데이트 시뮬레이션
  static Future<User> updateProfile(String token, Map<String, dynamic> profileData) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final userId = int.tryParse(token.split('_').last) ?? 1;
    final userData = _mockUsers.values.firstWhere(
      (user) => user['id'] == userId,
      orElse: () => _mockUsers['test@playmate.com']!,
    );
    
    // 프로필 데이터 업데이트
    userData.addAll(profileData);
    userData['updatedAt'] = DateTime.now();
    
    return User(
      id: userData['id'] as int,
      email: userData['email'] as String,
      nickname: userData['nickname'] as String,
      gender: userData['gender'] as String?,
      birthYear: userData['birthYear'] as int?,
      region: userData['region'] as String?,
      skillLevel: userData['skillLevel'] as int?,
      startYearMonth: userData['startYearMonth'] as String?,
      ntrpScore: userData['ntrpScore'] as double?,
      preferredCourt: userData['preferredCourt'] as String?,
      preferredTime: userData['preferredTime'] as List<String>?,
      playStyle: userData['playStyle'] as String?,
      hasLesson: userData['hasLesson'] as bool?,
      mannerScore: userData['mannerScore'] as double?,
      profileImage: userData['profileImage'] as String?,
      followingIds: (userData['followingIds'] as List<dynamic>?)?.cast<int>() ?? [],
      followerIds: (userData['followerIds'] as List<dynamic>?)?.cast<int>() ?? [],
      reviewCount: userData['reviewCount'] as int?,
      createdAt: userData['createdAt'] as DateTime,
      updatedAt: userData['updatedAt'] as DateTime,
    );
  }

  // 사용자 후기 조회
  static Future<List<Map<String, dynamic>>> getUserReviews(int userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Map<String, dynamic>>.from(_mockReviews[userId] ?? []);
  }

  // 카카오 로그인 시뮬레이션
  static Future<Map<String, dynamic>> loginWithKakao() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final userData = _mockUsers['test@playmate.com']!;
    return {
      'success': true,
      'token': 'mock_token_${userData['id']}',
      'user': User(
        id: userData['id'] as int,
        email: userData['email'] as String,
        nickname: userData['nickname'] as String,
        gender: userData['gender'] as String?,
        birthYear: userData['birthYear'] as int?,
        region: userData['region'] as String?,
        skillLevel: userData['skillLevel'] as int?,
        startYearMonth: userData['startYearMonth'] as String?,
        ntrpScore: userData['ntrpScore'] as double?,
        preferredCourt: userData['preferredCourt'] as String?,
        preferredTime: userData['preferredTime'] as List<String>?,
        playStyle: userData['playStyle'] as String?,
        hasLesson: userData['hasLesson'] as bool?,
        mannerScore: userData['mannerScore'] as double?,
        profileImage: userData['profileImage'] as String?,
        followingIds: (userData['followingIds'] as List<dynamic>?)?.cast<int>() ?? [],
        followerIds: (userData['followerIds'] as List<dynamic>?)?.cast<int>() ?? [],
        reviewCount: userData['reviewCount'] as int?,
        createdAt: userData['createdAt'] as DateTime,
        updatedAt: userData['updatedAt'] as DateTime,
      ),
    };
  }

  // Apple 로그인 시뮬레이션
  static Future<Map<String, dynamic>> loginWithApple() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final userData = _mockUsers['demo@playmate.com']!;
    return {
      'success': true,
      'token': 'mock_token_${userData['id']}',
      'user': User(
        id: userData['id'] as int,
        email: userData['email'] as String,
        nickname: userData['nickname'] as String,
        gender: userData['gender'] as String?,
        birthYear: userData['birthYear'] as int?,
        region: userData['region'] as String?,
        skillLevel: userData['skillLevel'] as int?,
        startYearMonth: userData['startYearMonth'] as String?,
        ntrpScore: userData['ntrpScore'] as double?,
        preferredCourt: userData['preferredCourt'] as String?,
        preferredTime: userData['preferredTime'] as List<String>?,
        playStyle: userData['playStyle'] as String?,
        hasLesson: userData['hasLesson'] as bool?,
        mannerScore: userData['mannerScore'] as double?,
        profileImage: userData['profileImage'] as String?,
        followingIds: (userData['followingIds'] as List<dynamic>?)?.cast<int>() ?? [],
        followerIds: (userData['followerIds'] as List<dynamic>?)?.cast<int>() ?? [],
        reviewCount: userData['reviewCount'] as int?,
        createdAt: userData['createdAt'] as DateTime,
        updatedAt: userData['updatedAt'] as DateTime,
      ),
    };
  }
} 