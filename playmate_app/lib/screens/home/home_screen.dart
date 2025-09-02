import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../models/location.dart';
import '../matching/create_matching_screen.dart';
import '../matching/matching_detail_screen.dart';
import '../notification/notification_list_screen.dart';
import '../../services/matching_notification_service.dart';


import '../../widgets/common/app_logo.dart';
import '../../widgets/common/date_range_calendar.dart';

class HomeScreen extends StatefulWidget {
  final Matching? newMatching;
  final VoidCallback? onMatchingAdded;
  
  const HomeScreen({
    super.key,
    this.newMatching,
    this.onMatchingAdded,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _filterTabController;
  final MatchingNotificationService _notificationService = MatchingNotificationService();
  
  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: 6, vsync: this);
    
    // 매칭 데이터 초기화
    _createMockMatchings();
    
    // 위치 데이터 초기화 (디폴트로 선택 안됨)
    _locationData = LocationData.cities;
    _selectedCityId = null;
    _selectedDistrictIds = [];
    
    // 검색 컨트롤러 리스너 추가
    _searchController.addListener(_onSearchChanged);
    
    _applyFilters();
    
    // 자동 완료 처리 타이머 시작
    _startAutoCompletionTimer();
    
    // 실시간 업데이트 타이머 시작
    _startAutoRefreshTimer();
    
    // 테스트용 알림 생성 (개발 중에만 사용)
    _notificationService.createTestNotifications();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 새 매칭이 추가되면 처리
    if (widget.newMatching != null && oldWidget.newMatching != widget.newMatching) {
      _addNewMatching(widget.newMatching!);
    }
  }
  
  @override
  void dispose() {
    _filterTabController.dispose();
    _searchController.dispose();
    _autoRefreshTimer?.cancel(); // 실시간 업데이트 타이머 정리
    _autoCompleteTimer?.cancel(); // 자동 완료 타이머 정리
    super.dispose();
  }
  
  // 필터 관련 변수들
  final List<String> _selectedFilters = [];
  List<String> _selectedGameTypes = [];
  String? _selectedSkillLevel;
  String? _selectedEndSkillLevel;
  String? _selectedMinAge;
  String? _selectedMaxAge;
  bool _showOnlyRecruiting = false;
  bool _showOnlyFollowing = false; // 팔로우만 보기 추가
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startTime;
  String? _endTime;
  
  // 위치 필터 관련 변수들
  List<Location> _locationData = [];
  String? _selectedCityId;
  List<String> _selectedDistrictIds = [];
  
  // 검색 관련 변수들
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Matching> _filteredMatchings = [];
  List<String> _searchHistory = [];
  bool _showSearchHistory = false;
  
  // UI 상태 변수들
  bool _isLoading = false;
  String? _errorMessage;
  
  // 실시간 업데이트 관련 변수들
  Timer? _autoRefreshTimer;
  Timer? _autoCompleteTimer; // 자동 완료 타이머 추가
  static const Duration _refreshInterval = Duration(seconds: 30); // 30초마다 새로고침
  static const Duration _completeCheckInterval = Duration(minutes: 1); // 1분마다 완료 체크

  // 연령대 옵션들
  static const List<String> _ageOptions = [
    '10대', '20대', '30대', '40대', '50대', '60대~'
  ];


  // 매칭 데이터 초기화 함수
  void _createMockMatchings() {
    _mockMatchings = [
      _createMockMatching(
        id: 1,
        courtName: '잠실종합운동장',
        courtLat: 37.512,
        courtLng: 127.102,
        date: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '18:00~20:00',
        minLevel: 2,
        maxLevel: 4,
        minAge: 20,
        maxAge: 30,
        gameType: 'mixed',
        maleRecruitCount: 1,
        femaleRecruitCount: 1,
        status: 'confirmed',
        host: User(
          id: 1,
          email: 'host@example.com',
          nickname: '테린이',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      _createMockMatching(
        id: 2,
        courtName: '양재시민의숲',
        courtLat: 37.469,
        courtLng: 127.038,
        date: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '20:00~22:00',
        minLevel: 3,
        maxLevel: 5,
        minAge: 25,
        maxAge: 40,
        gameType: 'male_doubles',
        maleRecruitCount: 2,
        femaleRecruitCount: 0,
        status: 'recruiting',
        isFollowersOnly: true, // 팔로워 전용 공개
        host: User(
          id: 2,
          email: 'player@example.com',
          nickname: '테니스마스터',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      // 추가 매칭 데이터 (위치 필터 테스트용)
      _createMockMatching(
        id: 3,
        courtName: '올림픽공원 테니스장',
        courtLat: 37.521,
        courtLng: 127.128,
        date: DateTime.now().add(const Duration(days: 3)),
        timeSlot: '14:00~16:00',
        minLevel: 1,
        maxLevel: 3,
        minAge: 18,
        maxAge: 35,
        gameType: 'mixed',
        maleRecruitCount: 1,
        femaleRecruitCount: 1,
        status: 'recruiting',
        host: User(
          id: 3,
          email: 'tennis@example.com',
          nickname: '테니스초보',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      _createMockMatching(
        id: 4,
        courtName: '한강공원 테니스장',
        courtLat: 37.528,
        courtLng: 126.933,
        date: DateTime.now().add(const Duration(days: 4)),
        timeSlot: '16:00~18:00',
        minLevel: 4,
        maxLevel: 6,
        minAge: 30,
        maxAge: 50,
        gameType: 'singles',
        maleRecruitCount: 0,
        femaleRecruitCount: 1,
        status: 'recruiting',
        host: User(
          id: 4,
          email: 'pro@example.com',
          nickname: '테니스프로',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      // 다양한 지역의 매칭 추가 (위치 필터 테스트용)
      _createMockMatching(
        id: 5,
        courtName: '분당테니스장',
        courtLat: 37.350,
        courtLng: 127.108,
        date: DateTime.now().add(const Duration(days: 5)),
        timeSlot: '10:00~12:00',
        minLevel: 2,
        maxLevel: 4,
        minAge: 20,
        maxAge: 45,
        gameType: 'female_doubles',
        maleRecruitCount: 0,
        femaleRecruitCount: 2,
        status: 'recruiting',
        host: User(
          id: 5,
          email: 'bundang@example.com',
          nickname: '분당테니스',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      _createMockMatching(
        id: 6,
        courtName: '인천대공원 테니스장',
        courtLat: 37.448,
        courtLng: 126.752,
        date: DateTime.now().add(const Duration(days: 6)),
        timeSlot: '19:00~21:00',
        minLevel: 3,
        maxLevel: 5,
        minAge: 25,
        maxAge: 55,
        gameType: 'mixed',
        maleRecruitCount: 1,
        femaleRecruitCount: 1,
        status: 'recruiting',
        host: User(
          id: 6,
          email: 'incheon@example.com',
          nickname: '인천테니스',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];
    
    // 필터링된 목록 초기화
    _filteredMatchings = List.from(_mockMatchings);
  }

  // 매칭 데이터 자동 생성 함수
  Matching _createMockMatching({
    required int id,
    required String courtName,
    required double courtLat,
    required double courtLng,
    required DateTime date,
    required String timeSlot,
    required int minLevel,
    required int maxLevel,
    int? minAge,
    int? maxAge,
    required String gameType,
    required int maleRecruitCount,
    required int femaleRecruitCount,
    required String status,
    required User host,
    bool isFollowersOnly = false,
  }) {
    final totalRecruitCount = maleRecruitCount + femaleRecruitCount;
    
    // 자동으로 게스트와 확정 인원 생성
    List<User> guests = [];
    List<int> confirmedUserIds = [];
    
    if (status == 'recruiting' || status == 'confirmed') {
      // 모집중/확정 상태면 자동으로 게스트 생성
      int guestId = id * 10; // 고유한 게스트 ID 생성
      
      // 확정 인원 수를 다양하게 설정 (테스트용)
      int confirmedCount = 0;
      
      // ID별로 다른 확정 인원 수 설정
      switch (id) {
        case 1: // 잠실종합운동장 - 100% 확정 (2명)
          confirmedCount = totalRecruitCount;
          break;
        case 2: // 양재시민의숲 - 50% 확정 (1명)
          confirmedCount = totalRecruitCount ~/ 2;
          break;
        case 3: // 올림픽공원 - 0% 확정 (0명)
          confirmedCount = 0;
          break;
        case 4: // 한강공원 - 100% 확정 (1명)
          confirmedCount = totalRecruitCount;
          break;
        case 5: // 분당 - 50% 확정 (1명)
          confirmedCount = totalRecruitCount ~/ 2;
          break;
        case 6: // 인천 - 100% 확정 (2명)
          confirmedCount = totalRecruitCount;
          break;
        default:
          confirmedCount = 0;
      }
      
      // 확정된 인원만큼 게스트 생성 및 확정 처리
      int confirmedMale = 0;
      int confirmedFemale = 0;
      
      // 남성 모집 인원 중 확정된 수만큼 생성
      for (int i = 0; i < maleRecruitCount && confirmedMale < confirmedCount; i++) {
        guests.add(User(
          id: guestId + i,
          email: 'guest${guestId + i}@example.com',
          nickname: '게스트${guestId + i}',
          gender: 'male',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        confirmedUserIds.add(guestId + i);
        confirmedMale++;
        confirmedCount--;
      }
      
      // 여성 모집 인원 중 확정된 수만큼 생성
      for (int i = 0; i < femaleRecruitCount && confirmedCount > 0; i++) {
        guests.add(User(
          id: guestId + maleRecruitCount + i,
          email: 'guest${guestId + maleRecruitCount + i}@example.com',
          nickname: '게스트${guestId + maleRecruitCount + i}',
          gender: 'female',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        confirmedUserIds.add(guestId + maleRecruitCount + i);
        confirmedFemale++;
        confirmedCount--;
      }
    }
    
    // 상태를 동적으로 결정 (확정 인원에 따라)
    String actualStatus = status;
    if (status == 'recruiting' || status == 'confirmed') {
      if (confirmedUserIds.length == totalRecruitCount) {
        actualStatus = 'confirmed'; // 100% 확정 완료
      } else if (confirmedUserIds.length > 0) {
        actualStatus = 'recruiting'; // 일부만 확정
      } else {
        actualStatus = 'recruiting'; // 미확정
      }
    }
    
    return Matching(
      id: id,
      type: 'host',
      courtName: courtName,
      courtLat: courtLat,
      courtLng: courtLng,
      date: date,
      timeSlot: timeSlot,
              minLevel: minLevel,
        maxLevel: maxLevel,
        minAge: minAge,
        maxAge: maxAge,
        gameType: gameType,
      maleRecruitCount: maleRecruitCount,
      femaleRecruitCount: femaleRecruitCount,
      status: actualStatus, // 동적으로 결정된 상태 사용
      host: host,
      guests: guests,
      confirmedUserIds: confirmedUserIds,
      isFollowersOnly: isFollowersOnly,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recoveryCount: 0,
    );
  }

  // 새 매칭 추가 메서드
  void _addNewMatching(Matching newMatching) {
    setState(() {
      // 새 매칭을 맨 위에 추가
              // 새로 생성된 매칭에 recoveryCount 추가
        final newMatchingWithRecovery = newMatching.copyWith(recoveryCount: 0);
        _mockMatchings.insert(0, newMatchingWithRecovery);
      // 필터링된 목록도 업데이트
      _applyFilters();
    });
    
    // 실제 운영환경에서는 백엔드 API 저장으로 채팅 서비스가 자동 업데이트됨
    // 개발환경에서만 임시로 로컬 상태 업데이트
    
    // 콜백 호출하여 MainScreen에 알림
    widget.onMatchingAdded?.call();
    
    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('새 매칭이 추가되었습니다: ${newMatching.courtName}'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 검색 및 필터링 메서드
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _showSearchHistory = _searchQuery.isEmpty && _searchHistory.isNotEmpty;
      _applyFilters();
    });
    
    // 검색어가 변경될 때마다 히스토리 업데이트
    if (_searchQuery.isNotEmpty) {
      _updateSearchHistory(_searchQuery);
    }
  }
  
  // 검색 히스토리 업데이트 (중복 제거 및 최신순 정렬)
  void _updateSearchHistory(String query) {
    if (query.isNotEmpty) {
      setState(() {
        // 기존에 같은 검색어가 있으면 제거
        _searchHistory.remove(query);
        // 맨 앞에 추가 (최신순)
        _searchHistory.insert(0, query);
        // 최대 15개까지만 유지
        if (_searchHistory.length > 15) {
          _searchHistory.removeLast();
        }
      });
    }
  }

  // 검색어 추가 (기존 함수 유지)
  void _addToSearchHistory(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        // 최대 10개까지만 유지
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }
  }

  // 검색 히스토리 칩 위젯
  Widget _buildSearchHistoryChip(String search) {
    return GestureDetector(
      onTap: () {
        _searchController.text = search;
        setState(() {
          _searchQuery = search;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              search,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            // 개별 삭제 버튼
            GestureDetector(
              onTap: () => _removeFromSearchHistory(search),
              child: Icon(
                Icons.close,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 검색 히스토리 전체 삭제
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }
  
  // 검색어 선택
  void _selectSearchHistory(String query) {
    setState(() {
      _searchController.text = query;
      _searchQuery = query;
      _showSearchHistory = false;
      _applyFilters();
    });
  }
  
  // 검색 히스토리 삭제
  void _removeFromSearchHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
  }
  
  void _applyFilters() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // 실제 필터링은 비동기로 처리 (UI 반응성 향상)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _performFiltering();
      }
    });
  }
  
  void _performFiltering() {

    
    _filteredMatchings = _mockMatchings.where((matching) {
      
      
      // 검색어 필터링
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!matching.courtName.toLowerCase().contains(query)) {

          return false;
        }
      }
      
      // 모집중만 보기 필터
      if (_showOnlyRecruiting && matching.actualStatus != 'recruiting') {
        
        return false;
      }
      
      // 팔로우만 보기 필터
      if (_showOnlyFollowing) {
        final authProvider = context.read<AuthProvider>();
        final currentUser = authProvider.currentUser;
        if (currentUser != null) {
          // 현재 사용자가 팔로우하는 사용자들의 ID 목록
          final followingIds = currentUser.followingIds ?? [];
          // 매칭 호스트가 팔로우 목록에 있는지 확인
          if (!followingIds.contains(matching.host.id)) {
  
            return false;
          }
        } else {
          // 로그인하지 않은 경우 팔로우 필터 적용 안함

        }
      }
      
      // 게임 유형 필터
      if (_selectedGameTypes.isNotEmpty && 
          !_selectedGameTypes.contains(matching.gameType)) {
        print('  - 게임 유형 불일치로 제외');
        return false;
      }
      
      // 구력 범위 필터
      if (_selectedSkillLevel != null || _selectedEndSkillLevel != null) {
        final startValue = _getSkillLevelFromText(_selectedSkillLevel);
        final endValue = _getSkillLevelFromText(_selectedEndSkillLevel);
        
        print('  - 구력 필터 확인');
        print('  - 선택된 시작 구력: $_selectedSkillLevel (값: $startValue)');
        print('  - 선택된 종료 구력: $_selectedEndSkillLevel (값: $endValue)');
        print('  - 매칭 구력: ${matching.minLevel}년-${matching.maxLevel}년');
        
        if (startValue != null && endValue != null) {
          // 시작 구력과 종료 구력이 모두 선택된 경우
          final minLevel = matching.minLevel ?? 0;
          final maxLevel = matching.maxLevel ?? 10;
          if (maxLevel < startValue || minLevel > endValue) {
            print('  - 구력 범위 불일치로 제외');
          return false;
        }
        } else if (startValue != null) {
          // 시작 구력만 선택된 경우
          final maxLevel = matching.maxLevel ?? 10;
          if (maxLevel < startValue) {
            print('  - 시작 구력보다 낮아서 제외');
            return false;
          }
        } else if (endValue != null) {
          // 종료 구력만 선택된 경우
          final minLevel = matching.minLevel ?? 0;
          if (minLevel > endValue) {
            print('  - 종료 구력보다 높아서 제외');
            return false;
          }
        }
        
        print('  - 구력 필터 통과');
      }
      
      // 연령대 범위 필터
      if (_selectedMinAge != null || _selectedMaxAge != null) {
        final startAge = _getAgeFromText(_selectedMinAge);
        final endAge = _getAgeFromText(_selectedMaxAge);
        
        print('  - 연령대 필터 확인');
        print('  - 선택된 시작 연령대: $_selectedMinAge (값: $startAge)');
        print('  - 선택된 종료 연령대: $_selectedMaxAge (값: $endAge)');
        print('  - 매칭 연령대: ${matching.minAge}대-${matching.maxAge}대');
        
        if (startAge != null && endAge != null) {
          // 시작 연령대와 종료 연령대가 모두 선택된 경우
          final minAge = matching.minAge ?? 10;
          final maxAge = matching.maxAge ?? 60;
          if (maxAge < startAge || minAge > endAge) {
            print('  - 연령대 범위 불일치로 제외');
            return false;
          }
        } else if (startAge != null) {
          // 시작 연령대만 선택된 경우
          final maxAge = matching.maxAge ?? 60;
          if (maxAge < startAge) {
            print('  - 시작 연령대보다 낮아서 제외');
            return false;
          }
        } else if (endAge != null) {
          // 종료 연령대만 선택된 경우
          final minAge = matching.minAge ?? 10;
          if (minAge > endAge) {
            print('  - 종료 연령대보다 높아서 제외');
            return false;
          }
        }
        
        print('  - 연령대 필터 통과');
      }
      
      // 날짜 범위 필터
      if (_startDate != null && matching.date.isBefore(_startDate!)) {
        print('  - 시작 날짜 이전이므로 제외');
        return false;
      }
      if (_endDate != null && matching.date.isAfter(_endDate!)) {
        print('  - 종료 날짜 이후이므로 제외');
        return false;
      }
      
      // 시간 범위 필터
      if (_startTime != null || _endTime != null) {
        // 매칭의 시간 슬롯을 파싱
        final timeParts = matching.timeSlot.split('~');
        if (timeParts.length == 2) {
          final matchStartTime = timeParts[0].trim();
          final matchEndTime = timeParts[1].trim();
          
          print('  - 매칭 시간: $matchStartTime ~ $matchEndTime');
          print('  - 선택된 시간: $_startTime ~ $_endTime');
          
          // 시작 시간이 선택된 시작 시간보다 이전이면 제외
          if (_startTime != null) {
            if (_compareTime(matchStartTime, _startTime!) < 0) {
              print('  - 시작 시간이 선택된 시작 시간보다 이전이므로 제외');
              return false;
            }
          }
          
          // 종료 시간이 선택된 종료 시간보다 늦으면 제외
          if (_endTime != null) {
            if (_compareTime(matchEndTime, _endTime!) > 0) {
              print('  - 종료 시간이 선택된 종료 시간보다 늦으므로 제외');
              return false;
            }
          }
          
          print('  - 시간 필터 통과');
        }
      }
      
      // 위치 필터
      if (_selectedCityId != null || _selectedDistrictIds.isNotEmpty) {
        // 도시 선택이 있거나 구/군 선택이 있는 경우
        bool locationMatch = false;
        
        // 코트별 위치 정보 매핑 (실제로는 데이터베이스에서 가져올 예정)
        Map<String, String> courtLocations = {
          '잠실종합운동장': '서울 송파구',
          '양재시민의숲': '서울 강남구',
          '올림픽공원 테니스장': '서울 송파구',
          '한강공원 테니스장': '서울 영등포구',
          '분당테니스장': '경기도 성남시',
          '인천대공원 테니스장': '인천 미추홀구',
        };
        
        String? courtLocation = courtLocations[matching.courtName];
        if (courtLocation == null) {
          print('    - 위치 정보 없음으로 제외');
          return false; // 위치 정보가 없으면 제외
        }
        
        print('    - 코트 위치: $courtLocation');
        
        // 도시 선택이 있는 경우
        if (_selectedCityId != null) {
          String cityName = _getCityName(_selectedCityId!);
          print('    - 선택된 도시: $cityName');
          if (!courtLocation.contains(cityName)) {
            print('    - 도시 불일치로 제외');
            return false; // 도시가 일치하지 않으면 제외
          }
        }
        
        // 구/군 선택이 있는 경우
        if (_selectedDistrictIds.isNotEmpty) {
          print('    - 선택된 구/군: $_selectedDistrictIds');
          bool districtMatch = false;
          for (String districtId in _selectedDistrictIds) {
            if (districtId.contains('_all')) {
              // 전체 선택인 경우 해당 도시의 모든 구/군 매칭
              String cityId = districtId.split('_')[0];
              String cityName = _getCityName(cityId);
              if (courtLocation.contains(cityName)) {
                districtMatch = true;
                print('    - 도시 전체 선택으로 매칭');
                break;
              }
            } else {
              // 특정 구/군 선택인 경우
              String districtName = _getDistrictName(districtId);
              print('    - 확인 중인 구/군: $districtName');
              if (courtLocation.contains(districtName)) {
                districtMatch = true;
                print('    - 구/군 매칭 성공');
                break;
              }
            }
          }
          if (!districtMatch) {
            print('    - 구/군 불일치로 제외');
            return false; // 구/군이 일치하지 않으면 제외
          }
        }
        
        locationMatch = true;
        print('    - 위치 필터 통과');
      }
      
      // 필터 상태 동기화
      _syncFilterState();
      
      print('  - 모든 필터 통과');
      return true;
    }).toList();
    
    print('필터링 결과: ${_filteredMatchings.length}개 매칭');
    print('=== 필터 적용 완료 ===');
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 필터 상태 동기화
  void _syncFilterState() {
    setState(() {
      // 기존 위치 관련 필터 제거
      _selectedFilters.removeWhere((filter) => 
        filter.contains('서울') || filter.contains('경기도') || 
        filter.contains('인천') || filter.contains('대전') || 
        filter.contains('세종') || filter.contains('충청남도') || 
        filter.contains('충청북도') || filter.contains('강원도') ||
        filter.contains('구') || filter.contains('시') || filter.contains('군'));
      
      // 기존 날짜 관련 필터 제거
      _selectedFilters.removeWhere((filter) => 
        filter.contains('월') && filter.contains('일'));
      
      // 기존 시간 관련 필터 제거
      _selectedFilters.removeWhere((filter) => 
        filter.contains('시'));
      
      // 기존 구력 관련 필터 제거
      _selectedFilters.removeWhere((filter) => 
        filter.contains('년') && (filter.contains('-') || filter.contains('이상') || filter.contains('이하')));
      
      // 도시 선택이 있는 경우 추가
      if (_selectedCityId != null) {
        String cityName = _getCityName(_selectedCityId!);
        if (!_selectedFilters.contains(cityName)) {
          _selectedFilters.add(cityName);
        }
      }
      
      // 구/군 선택이 있는 경우 추가
      for (String districtId in _selectedDistrictIds) {
        String districtName = _getDistrictName(districtId);
        if (!_selectedFilters.contains(districtName)) {
          _selectedFilters.add(districtName);
        }
      }
      
      // 날짜 범위가 있는 경우 추가
      if (_startDate != null && _endDate != null) {
        String dateFilter = '${_startDate!.month}월 ${_startDate!.day}일 ~ ${_endDate!.month}월 ${_endDate!.day}일';
        if (!_selectedFilters.contains(dateFilter)) {
          _selectedFilters.add(dateFilter);
        }
      }
      
      // 시간 범위가 있는 경우 추가
      if (_startTime != null && _endTime != null) {
        String timeFilter = '${_getHourFromString(_startTime!).toString().padLeft(2, '0')}:${_getMinuteFromString(_startTime!).toString().padLeft(2, '0')} ~ ${_getHourFromString(_endTime!).toString().padLeft(2, '0')}:${_getMinuteFromString(_endTime!).toString().padLeft(2, '0')}';
        if (!_selectedFilters.contains(timeFilter)) {
          _selectedFilters.add(timeFilter);
        }
      }
      
      // 게임 유형이 있는 경우 추가
      for (String gameType in _selectedGameTypes) {
        String gameTypeText = _getGameTypeText(gameType);
        if (!_selectedFilters.contains(gameTypeText)) {
          _selectedFilters.add(gameTypeText);
        }
      }
      
      // 구력 범위가 있는 경우 추가
      if (_selectedSkillLevel != null && _selectedEndSkillLevel != null) {
        String skillFilter = '$_selectedSkillLevel-$_selectedEndSkillLevel';
        if (!_selectedFilters.contains(skillFilter)) {
          _selectedFilters.add(skillFilter);
        }
      } else if (_selectedSkillLevel != null) {
        String skillFilter = '$_selectedSkillLevel 이상';
        if (!_selectedFilters.contains(skillFilter)) {
          _selectedFilters.add(skillFilter);
        }
      } else if (_selectedEndSkillLevel != null) {
        String skillFilter = '$_selectedEndSkillLevel 이하';
        if (!_selectedFilters.contains(skillFilter)) {
          _selectedFilters.add(skillFilter);
        }
      }
      
      // 모집중만 보기는 전용 체크박스로 관리하므로 필터 요약에서 제외
      // if (_showOnlyRecruiting) {
      //   if (!_selectedFilters.contains('모집중')) {
      //         _selectedFilters.add('모집중');
      //       }
      //   }
      
      // 팔로우만 보기는 전용 체크박스로 관리하므로 필터 요약에서 제외
      // if (_showOnlyFollowing) {
      //   if (!_selectedFilters.contains('팔로우만')) {
      //     _selectedFilters.add('팔로우만');
      //   }
      // }
      
      print('=== 필터 상태 동기화 완료 ===');
      print('_selectedFilters: $_selectedFilters');
    });
  }

  // 임시 데이터 (실제로는 API에서 가져올 예정)
  List<Matching> _mockMatchings = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 31), // 10% 증가 (28 → 31)
        centerTitle: true,
        leading: IconButton(
          icon: _isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _manualRefresh,
          tooltip: '새로고침',
        ),
        actions: [
          // 알림 버튼
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                // 읽지 않은 알림 개수 표시 (0개일 때는 숨김)
                if (_notificationService.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_notificationService.unreadCount}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              // 알림 화면으로 이동
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NotificationListScreen(
                    currentUser: context.read<AuthProvider>().currentUser!,
                  ),
                ),
              );
              // 알림 화면에서 돌아올 때 화면 새로고침
              setState(() {});
            },
            tooltip: '알림',
          ),
          // 필터 버튼
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
            tooltip: '필터',
          ),
        ],
      ),
      body: Column(
        children: [
                          // 검색바 추가
            Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, top: 16), // bottom margin 완전 제거
                  decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '코트명으로 검색하세요 (예: 잠실종합운동장)',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10, // 14 → 10 (약 29% 감소)
                    ),
                  ),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                      _applyFilters();
                    });
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _addToSearchHistory(value.trim());
                      setState(() {
                        _searchQuery = value.trim();
                        _showSearchHistory = false;
                        _applyFilters();
                      });
                    }
                  },
                ),
                // 검색 제안 (검색어가 비어있을 때만 표시)
                if (_searchQuery.isEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), // bottom padding 제거
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        // 구분선
                  Container(
                          height: 1,
                          color: AppColors.cardBorder,
                        ),
                        // SizedBox(height: 12) 제거 - 간격 완전 제거
                        // 최근 검색어만 표시 (인기 검색어 제거)
                        if (_searchHistory.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '최근 검색어',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _clearSearchHistory(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '전체 삭제',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4), // 8 → 4 (50% 감소)
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _searchHistory.take(8).map((search) => _buildSearchHistoryChip(search)).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
                          // "적용된 필터" 섹션 (개선된 디자인)
                if (_selectedFilters.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, top: 6), // top: 8 → 6 (20% 축소)
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // vertical: 12 → 10 (20% 축소)
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.filter_list,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '적용된 필터',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilters.clear();
                              _selectedGameTypes.clear();
                              _selectedSkillLevel = null;
                              _selectedEndSkillLevel = null;
                              _startDate = null;
                              _endDate = null;
                              _startTime = null;
                              _endTime = null;
                                  _selectedCityId = null;
                                  _selectedDistrictIds.clear();
                                  _applyFilters();
                            });
                          },
                          style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                                '초기화',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                                  fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                        if (_selectedFilters.isNotEmpty) ...[
                          const SizedBox(height: 6), // height: 8 → 6 (20% 축소)
                          // 필터 칩들
                          Wrap(
                            spacing: 5, // spacing: 6 → 5 (20% 축소)
                            runSpacing: 3, // runSpacing: 4 → 3 (20% 축소)
                            children: _selectedFilters.map((filter) => _buildFilterChip(filter)).toList(),
                          ),
                        ],
                ],
              ),
            ),
                  
                  // 모집중만 보기 & 팔로우만 보기 체크박스 (좌우로 나란히 배치)
                  Row(
                    children: [
          Expanded(
                        child: _buildRecruitingOnlyCheckbox(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFollowOnlyCheckbox(),
          ),
        ],
      ),
                  

                  
                  // 검색 결과 개수 표시 (작은 텍스트 형태)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _getSearchResultText(),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 필터 버튼들 (카테고리별 그룹화)
                  if (_selectedFilters.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // 중복 제목 제거 - 상단에 이미 "적용된 필터" 섹션이 있음
                                const SizedBox.shrink(),
                                // 하단 중복 초기화 버튼 제거 - 상단에 이미 초기화 버튼이 있음
                                const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  // chips/그룹은 제거하여 상단에는 요약만 유지
                ],
              ),
            ),
                  
          // 매칭 목록
          Expanded(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _filteredMatchings.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 16,
                          right: 16,
                          bottom: 120, // 플로팅 버튼 높이(56) + 하단 네비게이션(56) + 여유 공간(40) + 카드 간격(16)
                        ),
                        itemCount: _filteredMatchings.length,
              itemBuilder: (context, index) {
                          final matching = _filteredMatchings[index];
                return _buildMatchingCard(matching);
              },
            ),
          ),
        ],
      ),
      // 플로팅 액션 버튼과 하단 네비게이션 바 제거 (MainScreen에서 관리)
    );
  }

  // 매칭 수정 메서드
  void _editMatching(Matching matching) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateMatchingScreen(editingMatching: matching),
      ),
    );
  }

    // 상태 변경 다이얼로그 표시
  void _showStatusChangeDialog(Matching matching) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.sports_tennis,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${matching.courtName} 상태 변경'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 상태 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(matching.actualStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(matching.actualStatus).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(matching.actualStatus),
                      color: _getStatusColor(matching.actualStatus),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '현재 상태: ${matching.actualStatusText}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(matching.actualStatus),
                      ),
          ),
        ],
      ),
              ),
              const SizedBox(height: 16),
              
              // 매칭 정보 요약
              _buildMatchingSummary(matching),
              const SizedBox(height: 16),
              
              Text(
                '변경할 상태를 선택하세요:',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              // 상태 옵션들
              _buildStatusOptions(context, matching),
              
              const SizedBox(height: 16),
              
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '상태 변경 안내',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 취소된 매칭은 1회에 한해서 모집중으로 복구할 수 있습니다\n• 완료 상태는 게임 시간 종료 시 자동으로 처리됩니다\n• 확정 상태에서는 참여자와의 채팅이 가능합니다',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  // 취소 확인 다이얼로그 표시
  void _showCancellationConfirmation(BuildContext context, Matching matching) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('매칭 취소 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${matching.courtName} 매칭을 취소하시겠습니까?'),
              const SizedBox(height: 16),
              Text(
                '⚠️ 취소된 매칭은 1회에 한해서만 복구할 수 있습니다!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 취소 확인 다이얼로그 닫기
                Navigator.of(context).pop(); // 상태 변경 다이얼로그 닫기
                _changeMatchingStatus(matching, 'cancelled');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('취소하기'),
            ),
          ],
        );
      },
    );
  }

  // 매칭 정보 요약 위젯
  Widget _buildMatchingSummary(Matching matching) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${matching.formattedDate} ${matching.timeSlot}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${matching.recruitCountText}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (matching.confirmedCount > 0) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '확정: ${matching.confirmedCount}명',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 상태 옵션들 위젯
  Widget _buildStatusOptions(BuildContext context, Matching matching) {
    return Column(
      children: [
        // 모집중 → 확정
        if (matching.actualStatus == 'recruiting' && matching.confirmedCount > 0)
          _buildStatusOption(context, matching, 'confirmed', '확정', Colors.green),
        
        // 모집중 → 취소
        if (matching.actualStatus == 'recruiting')
          _buildStatusOption(context, matching, 'cancelled', '취소', Colors.red, requiresConfirmation: true),
        
        // 확정 → 완료는 자동으로 처리되므로 수동 옵션 제거
        
        // 취소 → 모집중 (복구)
        if (matching.status == 'cancelled' && (matching.recoveryCount ?? 0) < 1)
          _buildStatusOption(context, matching, 'recruiting', '모집중으로 복구', Colors.orange),
        
        // 삭제
        if (matching.actualStatus != 'deleted')
          _buildStatusOption(context, matching, 'deleted', '삭제', Colors.grey, requiresConfirmation: true),
      ],
    );
  }

  // 상태 옵션 위젯
  Widget _buildStatusOption(BuildContext context, Matching matching, String status, String label, Color color, {bool requiresConfirmation = false}) {
    return GestureDetector(
      onTap: () {
        if (requiresConfirmation) {
          // 취소 상태 변경 시 추가 확인
          _showCancellationConfirmation(context, matching);
        } else {
          _changeMatchingStatus(matching, status);
          Navigator.of(context).pop();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(status),
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 매칭 상태 변경
  void _changeMatchingStatus(Matching matching, String newStatus) {
    setState(() {
      final index = _mockMatchings.indexWhere((m) => m.id == matching.id);
      if (index != -1) {
        // 취소된 매칭을 모집중으로 복구할 때 복구 횟수 증가
        final newRecoveryCount = newStatus == 'recruiting' && matching.status == 'cancelled' 
            ? (matching.recoveryCount ?? 0) + 1 
            : matching.recoveryCount;
        
        // 상태별 추가 처리
        Map<String, dynamic> updateData = {
          'status': newStatus,
          'recoveryCount': newRecoveryCount,
          'updatedAt': DateTime.now(),
        };
        
        // 확정 상태로 변경할 때 신청자들을 확정자로 이동
        if (newStatus == 'confirmed' && matching.appliedUserIds != null && matching.appliedUserIds!.isNotEmpty) {
          updateData['confirmedUserIds'] = matching.appliedUserIds;
          updateData['appliedUserIds'] = []; // 신청자 목록 비우기
        }
        
        // 완료 상태는 자동으로 처리되므로 수동 변경 불가
        // if (newStatus == 'completed') {
        //   updateData['completedAt'] = DateTime.now();
        // }
        
        // 취소 상태로 변경할 때 취소 시간 기록
        if (newStatus == 'cancelled') {
          updateData['cancelledAt'] = DateTime.now();
        }
        
        _mockMatchings[index] = matching.copyWith(
          status: newStatus,
          recoveryCount: newRecoveryCount,
          updatedAt: DateTime.now(),
          confirmedUserIds: updateData['confirmedUserIds'],
          appliedUserIds: updateData['appliedUserIds'],
          completedAt: updateData['completedAt'],
          cancelledAt: updateData['cancelledAt'],
        );
      }
    });
    
    // 필터 적용
    _applyFilters();
    
    // 성공 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('매칭 상태가 "${_getStatusText(matching)}"로 변경되었습니다.'),
        backgroundColor: _getStatusColor(newStatus),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // 상태 변경 로그
    print('매칭 상태 변경: ${matching.courtName} (${matching.id}) ${matching.actualStatus} → $newStatus');
  }

  // 상태 텍스트 반환 메서드 (동적 상태 기반)
  String _getStatusText(Matching matching) {
    // 실제 상태에 따라 동적으로 결정
    final actualStatus = matching.actualStatus;
    
    switch (actualStatus) {
      case 'recruiting':
        return '모집중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      case 'deleted':
        return '삭제됨';
      default:
        return '알 수 없음';
    }
  }

  // 관련 데이터 확인 메서드
  bool _checkRelatedData(Matching matching) {
    // 게스트가 있는 경우
    if (matching.guests != null && matching.guests!.isNotEmpty) {
      return true;
    }
    
    // 채팅 이력이 있는 경우 (실제로는 API 호출이 필요하지만, 현재는 모의 데이터)
    // 여기서는 간단하게 게스트 수로 판단
    if (matching.maleRecruitCount > 0 || matching.femaleRecruitCount > 0) {
      return true;
    }
    
    // 상태가 모집중이 아닌 경우 (확정, 완료 등)
    if (matching.actualStatus != 'recruiting') {
      return true;
    }
    
    return false;
  }

  // 관련 데이터 경고 메시지 반환
  String _getRelatedDataWarning(Matching matching) {
    final warnings = <String>[];
    
    // 게스트가 있는 경우
    if (matching.guests != null && matching.guests!.isNotEmpty) {
      warnings.add('신청자가 ${matching.guests!.length}명 있습니다');
    }
    
    // 상태가 모집중이 아닌 경우
    if (matching.actualStatus != 'recruiting') {
      warnings.add('매칭이 ${matching.actualStatusText} 상태입니다');
    }
    
    // 채팅 이력이 있을 가능성이 있는 경우
    if (matching.maleRecruitCount > 0 || matching.femaleRecruitCount > 0) {
      warnings.add('채팅 이력이 있을 수 있습니다');
    }
    
    if (warnings.isEmpty) {
      return '관련 데이터가 있을 수 있습니다';
    }
    
    return '⚠️ ${warnings.join(', ')}';
  }

  // 카드 배경색 반환 메서드
  Color _getCardBackgroundColor(Matching matching) {
    // 팔로워 전용인 경우
    if (matching.isFollowersOnly) {
      return Colors.blue[50]!; // 연한 파란색
    }
    
    // 상태별 배경색
    switch (matching.actualStatus) {
      case 'recruiting':
        return AppColors.surface; // 모집중: 기본 배경색
      case 'confirmed':
        return Colors.green[50]!; // 확정: 연한 초록색
      case 'completed':
        return Colors.blue[50]!; // 완료: 연한 파란색
      case 'cancelled':
        return Colors.red[50]!; // 취소: 연한 빨간색
      case 'deleted':
        return Colors.grey[100]!; // 삭제됨: 연한 회색
      default:
        return AppColors.surface; // 기본: 기본 배경색
    }
  }

  // 삭제는 이제 상태 변경으로 통합됨 (삭제됨 상태로 변경)

  Widget _buildMatchingCard(Matching matching) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final isHost = currentUser != null && matching.host.id == currentUser.id;
    
    return GestureDetector(
      onTap: () {
        if (currentUser != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MatchingDetailScreen(
                matching: matching,
                currentUser: currentUser,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 필요합니다.')),
          );
          Navigator.of(context).pushNamed('/login');
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16), // 12 → 16 (카드 간격 증가로 가독성 향상)
        color: _getCardBackgroundColor(matching),
        elevation: matching.isFollowersOnly ? 2 : 1, // 팔로워 전용: 약간 더 높은 그림자
        shape: matching.isFollowersOnly 
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.blue[300]!, // 팔로워 전용: 파란색 테두리
                  width: 1.5,
                ),
              )
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
        child: Padding(
          padding: const EdgeInsets.all(18), // 16 → 18 (내부 여백 증가로 내용 가독성 향상)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 코트명, 상태 배지, 수정/삭제 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 코트명과 팔로워 전용 표시
                  Expanded(
                    child: Row(
                      children: [
                        if (matching.isFollowersOnly) ...[
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Colors.blue[600], // 파란색 자물쇠 아이콘
                          ),
                          const SizedBox(width: 6),
                        ],
                  Expanded(
                    child: Text(
                      matching.courtName,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽: 상태 배지와 버튼들
                  Row(
                    children: [
                      // 상태 배지 (상태별 색상 및 스타일 적용)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(matching.actualStatus).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(matching.actualStatus).withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(matching.actualStatus),
                              size: 12,
                              color: _getStatusColor(matching.actualStatus),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              matching.actualStatusText + matching.recoveryCountText,
                          style: AppTextStyles.caption.copyWith(
                                color: _getStatusColor(matching.actualStatus),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 팔로워 전용 공개 표시
                      if (matching.isFollowersOnly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 8,4 → 10,6 (팔로워 배지 크기 증가로 가독성 향상)
                          decoration: BoxDecoration(
                            color: AppColors.accent, // 모집중과 동일한 노란색 배경
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent, // 노란색 테두리
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: AppColors.textPrimary, // 어두운 색 아이콘
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '팔로워',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary, // 어두운 색 텍스트
                            fontWeight: FontWeight.w500,
                                  fontSize: 11,
                          ),
                        ),
                            ],
                      ),
                        ),
                      ],
                      // 호스트인 경우에만 수정/삭제 버튼 표시
                      if (isHost) ...[
                        const SizedBox(width: 8),
                        // 상태 변경 버튼 (호스트만)
                        if (isHost) ...[
                          Tooltip(
                            message: '상태 변경 (확정/취소/삭제됨)',
                            child: GestureDetector(
                              onTap: () => _showStatusChangeDialog(matching),
                          child: Container(
                                padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                                  Icons.swap_horiz,
                              size: 16,
                                  color: Colors.green,
                                ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ],
                        // 수정 버튼
                        GestureDetector(
                          onTap: () => _editMatching(matching),
                          child: Container(
                            padding: const EdgeInsets.all(6), // 4 → 6 (수정 버튼 크기 증가로 터치 영역 확대)
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 삭제 버튼 제거 - 상태 변경으로 통합됨
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 매칭 정보 (2열 레이아웃)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 열 (위치, 날짜, 시간)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 위치
                        Row(
                          children: [
                            Icon(Icons.location_on, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _getMatchingLocationText(matching),
                              style: AppTextStyles.body.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 날짜
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                                matching.formattedDate,
                              style: AppTextStyles.body.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 시간
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                                matching.formattedTime,
                              style: AppTextStyles.body.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // 오른쪽 열 (게임유형, 구력, 연령대, 모집인원)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 게임유형과 구력을 한 줄에 (오른쪽 정렬)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_tennis, color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              matching.gameTypeText,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                matching.skillRangeText,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 연령대 (오른쪽 정렬)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            matching.ageRangeText,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 모집인원 (오른쪽 정렬)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              matching.recruitCountText,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 필터링된 매칭 목록 반환
  List<Matching> _getFilteredMatchings() {
    List<Matching> filtered = _mockMatchings;
    
    // 모집중만 보기 필터
    if (_showOnlyRecruiting) {
      filtered = filtered.where((matching) => 
        matching.status == 'recruiting'
      ).toList();
    }
    
    // 게임 유형 필터
    if (_selectedGameTypes.isNotEmpty) {
      filtered = filtered.where((matching) => 
        _selectedGameTypes.contains(matching.gameType)
      ).toList();
    }
    
    // 구력 범위 필터
    if (_selectedSkillLevel != null && _selectedEndSkillLevel != null) {
      final startValue = _getSkillLevelFromText(_selectedSkillLevel!);
      final endValue = _getSkillLevelFromText(_selectedEndSkillLevel!);
      
      if (startValue != null && endValue != null) {
        filtered = filtered.where((matching) {
          final minLevel = matching.minLevel ?? 0;
          final maxLevel = matching.maxLevel ?? 10;
          
          // 구력 범위가 겹치는지 확인
          return (minLevel <= endValue && maxLevel >= startValue);
        }).toList();
      }
    } else if (_selectedSkillLevel != null) {
      final skillValue = _getSkillLevelFromText(_selectedSkillLevel!);
      if (skillValue != null) {
        filtered = filtered.where((matching) => 
          (matching.minLevel ?? 0) <= skillValue && (matching.maxLevel ?? 10) >= skillValue
        ).toList();
      }
    }
    
    // 날짜 범위 필터
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((matching) => 
        matching.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        matching.date.isBefore(_endDate!.add(const Duration(days: 1)))
      ).toList();
    }
    
    // 시간 범위 필터
    if (_startTime != null && _endTime != null) {
      filtered = filtered.where((matching) {
        final timeSlot = matching.timeSlot;
        final startTime = timeSlot.split('~')[0].trim();
        return startTime.compareTo(_startTime!) >= 0 && startTime.compareTo(_endTime!) <= 0;
      }).toList();
    }
    
    return filtered;
  }

  // 필터 바텀시트 표시
  void _showFilterBottomSheet(BuildContext context) {
    // 로컬 변수들 (모달 내부에서 사용)
    bool localShowOnlyRecruiting = _showOnlyRecruiting;
    List<String> localSelectedGameTypes = List.from(_selectedGameTypes);
    String? localSelectedSkillLevel = _selectedSkillLevel;
    String? localSelectedEndSkillLevel = _selectedEndSkillLevel;
    String? localSelectedMinAge = _selectedMinAge;
    String? localSelectedMaxAge = _selectedMaxAge;
    DateTime? localStartDate = _startDate;
    DateTime? localEndDate = _endDate;
    String? localStartTime = _startTime;
    String? localEndTime = _endTime;
    List<String> localSelectedFilters = List.from(_selectedFilters);
    String? localSelectedCityId = _selectedCityId;
    List<String> localSelectedDistrictIds = List.from(_selectedDistrictIds);
    
    print('=== 모달 열기 시 현재 필터 상태 ===');
    print('_startDate: $_startDate');
    print('_endDate: $_endDate');
    print('_startTime: $_startTime');
    print('_endTime: $_endTime');
    print('_selectedCityId: $_selectedCityId');
    print('_selectedDistrictIds: $_selectedDistrictIds');
    print('_selectedFilters: $_selectedFilters');
    
    // 현재 필터 상태가 null이 아닌 경우에만 로컬 변수에 복사
    if (_startDate != null) localStartDate = _startDate;
    if (_endDate != null) localEndDate = _endDate;
    if (_startTime != null) localStartTime = _startTime;
    if (_endTime != null) localEndTime = _endTime;
    if (_selectedCityId != null) localSelectedCityId = _selectedCityId;
    if (_selectedDistrictIds.isNotEmpty) localSelectedDistrictIds = List.from(_selectedDistrictIds);
    
    print('=== 모달 열기 시 로컬 변수 상태 ===');
    print('localStartDate: $localStartDate');
    print('localEndDate: $localEndDate');
    print('localStartTime: $localStartTime');
    print('localEndTime: $localEndTime');
    print('localSelectedCityId: $localSelectedCityId');
    print('localSelectedDistrictIds: $localSelectedDistrictIds');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '필터',
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              localSelectedFilters.clear();
                              localSelectedGameTypes.clear();
                              localSelectedSkillLevel = null;
                              localSelectedEndSkillLevel = null;
                              localSelectedMinAge = null;
                              localSelectedMaxAge = null;
                              localStartDate = null;
                              localEndDate = null;
                              localStartTime = null;
                              localEndTime = null;
                              localShowOnlyRecruiting = false;
                              localSelectedCityId = null;
                              localSelectedDistrictIds.clear();
                            });
                          },
                          child: Text(
                            '초기화',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            print('=== 모달 닫기 시 로컬 변수 상태 ===');
                            print('localStartDate: $localStartDate');
                            print('localEndDate: $localEndDate');
                            print('localStartTime: $localStartTime');
                            print('localEndTime: $localEndTime');
                            print('localSelectedCityId: $localSelectedCityId');
                            print('localSelectedDistrictIds: $localSelectedDistrictIds');
                            
                            // 모달을 닫기 전에 현재 실제 변수 상태를 local 변수에 복사
                            localStartDate = _startDate;
                            localEndDate = _endDate;
                            localStartTime = _startTime;
                            localEndTime = _endTime;
                            localSelectedCityId = _selectedCityId;
                            localSelectedDistrictIds = List.from(_selectedDistrictIds);
                            localSelectedSkillLevel = _selectedSkillLevel;
                            localSelectedEndSkillLevel = _selectedEndSkillLevel;
                            localSelectedMinAge = _selectedMinAge;
                            localSelectedMaxAge = _selectedMaxAge;
                            
                            print('=== 모달 닫기 전 local 변수 업데이트 ===');
                            print('localStartDate: $localStartDate');
                            print('localEndDate: $localEndDate');
                            print('localStartTime: $localStartTime');
                            print('localEndTime: $localEndTime');
                            print('localSelectedCityId: $localSelectedCityId');
                            print('localSelectedDistrictIds: $localSelectedDistrictIds');
                            print('localSelectedSkillLevel: $localSelectedSkillLevel');
                            print('localSelectedEndSkillLevel: $localSelectedEndSkillLevel');
                            
                            setState(() {
                              _showOnlyRecruiting = localShowOnlyRecruiting;
                              _selectedGameTypes = List.from(localSelectedGameTypes);
                              _selectedSkillLevel = localSelectedSkillLevel;
                              _selectedEndSkillLevel = localSelectedEndSkillLevel;
                              _selectedMinAge = localSelectedMinAge;
                              _selectedMaxAge = localSelectedMaxAge;
                              _startDate = localStartDate;
                              _endDate = localEndDate;
                              _startTime = localStartTime;
                              _endTime = localEndTime;
                              _selectedCityId = localSelectedCityId;
                              _selectedDistrictIds = List.from(localSelectedDistrictIds);
                              // _selectedFilters 초기화 후 필터 상태 동기화
                              _selectedFilters.clear();
                            });
                            
                            print('=== 모달 닫기 후 실제 변수 상태 ===');
                            print('_startDate: $_startDate');
                            print('_endDate: $_endDate');
                            print('_startTime: $_startTime');
                            print('_endTime: $_endTime');
                            print('_selectedCityId: $_selectedCityId');
                            print('_selectedDistrictIds: $_selectedDistrictIds');
                            print('_selectedSkillLevel: $_selectedSkillLevel');
                            print('_selectedEndSkillLevel: $_selectedEndSkillLevel');
                            
                            // 필터 상태 동기화하여 요약 UI 업데이트
                            _syncFilterState();
                            
                            // 필터 적용 후 검색 결과 업데이트
                            _applyFilters();
                            
                            print('=== 모달 닫기 후 _syncFilterState() 호출 완료 ===');
                            print('_selectedFilters: $_selectedFilters');
                            print('_selectedFilters.length: ${_selectedFilters.length}');
                            
                            Navigator.pop(context);
                          },
                          child: Text(
                            '완료',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 필터 옵션들
              Expanded(
                  child: Column(
                    children: [
                    // 탭 헤더
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      child: TabBar(
                        controller: _filterTabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: const [
                          Tab(text: '날짜'),
                          Tab(text: '시간'),
                          Tab(text: '위치'),
                          Tab(text: '게임 유형'),
                          Tab(text: '구력'),
                          Tab(text: '연령대'),
                        ],
                      ),
                    ),
                    // 탭 내용
                            Expanded(
                      child: TabBarView(
                        controller: _filterTabController,
                        children: [
                          // 날짜 탭
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildDateTab(localStartDate, localEndDate, localSelectedFilters, setModalState),
                          ),
                          // 시간 탭
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildTimeTab(localStartTime, localEndTime, localSelectedFilters, setModalState),
                          ),
                          // 위치 탭
                          _buildLocationTab(setModalState),
                          // 게임 유형 탭
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildGameTypeTab(localSelectedGameTypes, localSelectedFilters, setModalState),
                          ),
                          // 구력 탭
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildSkillLevelTab(localSelectedSkillLevel, localSelectedEndSkillLevel, localSelectedFilters, setModalState),
                            ),
                          // 연령대 탭
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildAgeRangeTab(localSelectedMinAge, localSelectedMaxAge, localSelectedFilters, setModalState),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 날짜 필터 탭 위젯
  Widget _buildDateTab(DateTime? startDate, DateTime? endDate, List<String> selectedFilters, StateSetter setModalState) {
    return Column(
                        children: [
        // 날짜 범위 필터 (새로운 캘린더 UI)
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DateRangeCalendar(
            startDate: startDate,
            endDate: endDate,
            onDateRangeChanged: (start, end) {
                              setModalState(() {
                startDate = start;
                endDate = end;
                
                // 기존 날짜 관련 필터 제거
                selectedFilters.removeWhere((filter) => 
                  filter.contains('월') && filter.contains('일')
                );
                
                // 새로운 날짜 범위 필터 추가
                if (start != null && end != null) {
                  final filterText = '${start.month}월 ${start.day}일 ~ ${end.month}월 ${end.day}일';
                  if (!selectedFilters.contains(filterText)) {
                    selectedFilters.add(filterText);
                  }
                } else if (start != null) {
                  final filterText = '${start.month}월 ${start.day}일부터';
                  if (!selectedFilters.contains(filterText)) {
                    selectedFilters.add(filterText);
                  }
                } else if (end != null) {
                  final filterText = '${end.month}월 ${end.day}일까지';
                  if (!selectedFilters.contains(filterText)) {
                    selectedFilters.add(filterText);
                                  }
                                }
                              });
              
              // 실제 상태 변수도 즉시 업데이트
              setState(() {
                _startDate = start;
                _endDate = end;
                // 필터 적용하여 상태 동기화
                _applyFilters();
                              });
                            },
          ),
        ),
        // 마감 체크박스 제거 - 모집중만 보기와 중복 기능
      ],
    );
  }

  // 시간 필터 탭 위젯
  Widget _buildTimeTab(String? startTime, String? endTime, List<String> selectedFilters, StateSetter setModalState) {
    return Column(
      children: [
        // 시간 범위 필터 개선된 UI
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              // 시간 범위 설명
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                      Text(
                    '시간 범위 선택',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 8),
                      Text(
                '시작 시간과 종료 시간을 각각 클릭하여 범위를 선택하세요',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              
              // 선택된 시간 표시
              if (startTime != null || endTime != null)
                      Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                        child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        startTime != null && endTime != null
                            ? '$startTime ~ $endTime'
                            : startTime != null
                                ? '$startTime부터'
                                : '$endTime까지',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (startTime != null || endTime != null) const SizedBox(height: 16),
              
              // 시간 선택 가이드
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _startTime != null && _endTime != null 
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _startTime != null && _endTime != null 
                        ? AppColors.primary 
                        : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: _startTime != null && _endTime != null 
                          ? AppColors.primary 
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _startTime == null
                            ? '시작 시간을 선택해주세요'
                            : _endTime == null
                                ? '${_startTime}부터 종료 시간을 선택해주세요'
                                : '${_startTime} ~ ${_endTime}',
                        style: AppTextStyles.body.copyWith(
                          color: _startTime == null || _endTime == null
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // 시간 선택 그리드
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
                              child: Column(
            children: [
              // 시간대별 그룹
              _buildTimeGroup('오전', 6, 11, setModalState),
              const SizedBox(height: 16),
              _buildTimeGroup('오후', 12, 23, setModalState),
            ],
          ),
        ),
      ],
    );
  }

  // 시간대별 그룹 위젯
  Widget _buildTimeGroup(String period, int startHour, int endHour, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
          period,
          style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(endHour - startHour + 1, (index) {
            final hour = startHour + index;
            final timeText = hour == 12 ? '12시' : hour < 12 ? '${hour}시' : '${hour - 12}시';
            final timeValue = '${hour.toString().padLeft(2, '0')}:00';
            
            // 선택된 시간들 확인 - 실제 상태 변수 사용
            final selectedHours = _getSelectedTimeHours(_startTime, _endTime);
            final isSelected = selectedHours.contains(hour);
            final isStartTime = _startTime == timeValue;
            final isEndTime = _endTime == timeValue;
            
            Color buttonColor;
            Color textColor;
            Color borderColor;
            
            if (isStartTime) {
              buttonColor = AppColors.primary;
              textColor = AppColors.surface;
              borderColor = AppColors.primary;
            } else if (isEndTime) {
              buttonColor = AppColors.accent;
              textColor = AppColors.surface;
              borderColor = AppColors.accent;
            } else if (isSelected) {
              buttonColor = AppColors.primary.withValues(alpha: 0.2);
              textColor = AppColors.primary;
              borderColor = AppColors.primary;
            } else {
              buttonColor = AppColors.surface;
              textColor = AppColors.textPrimary;
              borderColor = AppColors.cardBorder;
            }
            
            return GestureDetector(
                                      onTap: () {
                // 시간 선택 로직 - 모달 상태와 실제 상태 모두 업데이트
                if (_startTime == null) {
                  // 첫 번째 선택 (시작 시간)
                  print('시작 시간 선택: $timeValue');
                                        setModalState(() {
                    _startTime = timeValue;
                  });
                  // 실제 상태 변수도 즉시 업데이트
                  setState(() {
                    _startTime = timeValue;
                    // 필터 적용하여 상태 동기화
                    _applyFilters();
                  });
                  print('시작 시간 설정 완료: $_startTime');
                } else if (_endTime == null) {
                  // 두 번째 선택 (종료 시간)
                  final startHourInt = int.parse(_startTime!.split(':')[0]);
                  final difference = (hour - startHourInt).abs();
                  
                  // 디버깅 로그 추가
                  print('종료 시간 선택 시도: 시작=$startHourInt, 선택=$hour, 차이=$difference');
                  
                  if (difference > 0 && difference <= 10) { // 10시간까지 허용
                    // 범위가 10시간 이하인 경우
                    setModalState(() {
                      if (hour > startHourInt) {
                                                // 좌에서 우로 선택
                        _endTime = timeValue;
                                              } else {
                                                // 우에서 좌로 선택 - 시작과 끝을 바꿈
                        _endTime = _startTime;
                        _startTime = timeValue;
                      }
                    });
                    // 실제 상태 변수도 즉시 업데이트
                    setState(() {
                      if (hour > startHourInt) {
                        // 좌에서 우로 선택
                        _endTime = timeValue;
                      } else {
                        // 우에서 좌로 선택 - 시작과 끝을 바꿈
                        _endTime = _startTime;
                        _startTime = timeValue;
                      }
                      // 필터 적용하여 상태 동기화
                      _applyFilters();
                    });
                    print('종료 시간 설정 완료: $_endTime');
                                          } else {
                    print('시간 범위 제한 초과: $difference시간 (최대 10시간)');
                  }
                } else {
                  // 다시 시작
                  setModalState(() {
                    _startTime = timeValue;
                    _endTime = null;
                  });
                  // 실제 상태 변수도 즉시 업데이트
                  setState(() {
                    _startTime = timeValue;
                    _endTime = null;
                    // 필터 적용하여 상태 동기화
                    _applyFilters();
                  });
                }
                                      },
                                      child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                  color: buttonColor,
                  border: Border.all(color: borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  timeText,
                  style: AppTextStyles.body.copyWith(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                              ),
                            );
                          }),
                        ),
      ],
    );
  }

  // 위치 필터 탭 위젯
  Widget _buildLocationTab(StateSetter setModalState) {
    return Row(
      children: [
        // 왼쪽: 도시 목록
        Expanded(
          flex: 1,
          child: Container(
                        decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: ListView.builder(
              itemCount: _locationData.length,
              itemBuilder: (context, index) {
                final city = _locationData[index];
                final isSelected = _selectedCityId == city.id;
                
                return GestureDetector(
                  onTap: () {
                            setModalState(() {
                      _selectedCityId = city.id;
                      _selectedDistrictIds.clear();
                      
                      // 기존 위치 관련 필터 제거
                      _selectedFilters.removeWhere((filter) => 
                        filter.contains('서울') || filter.contains('경기도') || 
                        filter.contains('인천') || filter.contains('대전') || 
                        filter.contains('세종') || filter.contains('충청남도') || 
                        filter.contains('충청북도') || filter.contains('강원도') ||
                        filter.contains('구') || filter.contains('시') || filter.contains('군'));
                      
                      // 도시 필터 추가
                      _selectedFilters.add(city.name);
                      
                      // 필터 적용
                      _applyFilters();
                    });
                    
                    // 실제 상태 변수도 업데이트
                    setState(() {
                      _selectedCityId = city.id;
                      _selectedDistrictIds.clear();
                      
                      // 기존 위치 관련 필터 제거
                      _selectedFilters.removeWhere((filter) => 
                        filter.contains('서울') || filter.contains('경기도') || 
                        filter.contains('인천') || filter.contains('대전') || 
                        filter.contains('세종') || filter.contains('충청남도') || 
                        filter.contains('충청북도') || filter.contains('강원도') ||
                        filter.contains('구') || filter.contains('시') || filter.contains('군'));
                      
                      // 도시 필터 추가
                      _selectedFilters.add(city.name);
                      
                      // 필터 적용
                      _applyFilters();
                            });
                          },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                      ),
                    ),
                    child: Text(
                      city.name,
                      style: AppTextStyles.body.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 오른쪽: 구/군 목록
                                  Expanded(
          flex: 1,
          child: _selectedCityId != null
              ? ListView.builder(
                  itemCount: _locationData
                      .firstWhere(
                        (city) => city.id == _selectedCityId,
                        orElse: () => Location(id: '', name: '', subLocations: []),
                      )
                      .subLocations?.length ?? 0,
                  itemBuilder: (context, index) {
                    final city = _locationData.firstWhere(
                      (city) => city.id == _selectedCityId,
                      orElse: () => Location(id: '', name: '', subLocations: []),
                    );
                    final district = city.subLocations![index];
                    final isSelected = _selectedDistrictIds.contains(district.id);
                    
                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                          if (isSelected) {
                            _selectedDistrictIds.remove(district.id);
                            // 필터에서도 제거
                            _selectedFilters.remove(district.name);
                                              } else {
                            _selectedDistrictIds.add(district.id);
                            // 필터에 추가
                            if (!_selectedFilters.contains(district.name)) {
                              _selectedFilters.add(district.name);
                            }
                          }
                          
                          // 필터 적용
                          _applyFilters();
                        });
                        
                        // 실제 상태 변수도 업데이트
                        setState(() {
                          if (isSelected) {
                            _selectedDistrictIds.remove(district.id);
                            // 필터에서도 제거
                            _selectedFilters.remove(district.name);
                                          } else {
                            _selectedDistrictIds.add(district.id);
                            // 필터에 추가
                            if (!_selectedFilters.contains(district.name)) {
                              _selectedFilters.add(district.name);
                            }
                          }
                          
                          // 필터 적용
                          _applyFilters();
                                        });
                                      },
                                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                district.name,
                                style: AppTextStyles.body.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                color: AppColors.primary,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text(
                    '도시를 선택해주세요',
                    style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                ),
        ),
      ],
    );
  }

  // 게임 유형 필터 탭 위젯
  Widget _buildGameTypeTab(List<String> selectedGameTypes, List<String> selectedFilters, StateSetter setModalState) {
    return Column(
      children: [
        // 게임 유형 필터
        Text(
          '게임 유형',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'mixed', 'male_doubles', 'female_doubles', 'singles', 'rally'
          ].map((type) {
            final isSelected = selectedGameTypes.contains(type);
            return GestureDetector(
              onTap: () {
                setModalState(() {
                  if (isSelected) {
                    selectedGameTypes.remove(type);
                    selectedFilters.remove(_getGameTypeText(type));
                  } else {
                    selectedGameTypes.add(type);
                    if (!selectedFilters.contains(_getGameTypeText(type))) {
                      selectedFilters.add(_getGameTypeText(type));
                    }
                  }
                });
                
                // 실제 변수에도 즉시 반영
                setState(() {
                  if (isSelected) {
                    _selectedGameTypes.remove(type);
                  } else {
                    _selectedGameTypes.add(type);
                  }
                });
                
                // 필터 적용
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getGameTypeText(type),
                  style: AppTextStyles.body.copyWith(
                    color: isSelected ? AppColors.surface : AppColors.textPrimary,
          ),
        ),
      ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 게임 유형을 한글로 변환
  String _getGameTypeText(String gameType) {
    switch (gameType) {
      case 'mixed':
        return '혼복';
      case 'male_doubles':
        return '남복';
      case 'female_doubles':
        return '여복';
      case 'singles':
        return '단식';
      case 'rally':
        return '랠리';
      default:
        return gameType;
    }
  }

  // 구력 텍스트에서 숫자 값 추출
  int? _getSkillLevelFromText(String? skillText) {
    if (skillText == null) return null;
    
    if (skillText == '6개월') return 0;
    if (skillText == '10년+') return 10;
    
    // "N년" 형태에서 숫자 추출
    final match = RegExp(r'(\d+)년').firstMatch(skillText);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    
    return null;
  }

  // 연령대 텍스트에서 숫자 값 추출
  int? _getAgeFromText(String? ageText) {
    if (ageText == null) return null;
    
    if (ageText == '60대~') return 60;
    
    // "X대" 형태에서 숫자 추출
    final match = RegExp(r'(\d+)대').firstMatch(ageText);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    
    return null;
  }

  // 구력 텍스트의 숫자 값 반환
  int _getSkillLevelValue(String skillText) {
    if (skillText == '6개월') return 0;
    if (skillText == '10년+') return 10;
    
    // "N년" 형태에서 숫자 추출
    final match = RegExp(r'(\d+)년').firstMatch(skillText);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    
    return 0;
  }

  // 선택된 구력 범위 내의 모든 구력 텍스트 반환
  List<String> _getSelectedSkillLevels(String? startSkill, String? endSkill) {
    final skillLevels = [
      '6개월', '1년', '2년', '3년', '4년', '5년',
      '6년', '7년', '8년', '9년', '10년', '10년+'
    ];
    
    if (startSkill == null) return [];
    
    if (endSkill == null) {
      // 단일 선택
      return [startSkill];
    }
    
    // 범위 선택 - 시작과 끝을 올바르게 정렬
    final startValue = _getSkillLevelValue(startSkill);
    final endValue = _getSkillLevelValue(endSkill);
    final actualStart = startValue < endValue ? startValue : endValue;
    final actualEnd = startValue < endValue ? endValue : startValue;
    
    List<String> selectedSkills = [];
    for (final skill in skillLevels) {
      final skillValue = _getSkillLevelValue(skill);
      if (skillValue >= actualStart && skillValue <= actualEnd) {
        selectedSkills.add(skill);
      }
    }
    
    return selectedSkills;
  }

  // 선택된 시간 범위 내의 모든 시간 반환
  List<int> _getSelectedTimeHours(String? startTime, String? endTime) {
    if (startTime == null) return [];
    
    if (endTime == null) {
      // 단일 선택
      final startHour = int.tryParse(startTime.split(':')[0]) ?? 0;
      return [startHour];
    }
    
    // 범위 선택 - 시작과 끝을 올바르게 정렬
    final startHour = int.tryParse(startTime.split(':')[0]) ?? 0;
    final endHour = int.tryParse(endTime.split(':')[0]) ?? 0;
    final actualStart = startHour < endHour ? startHour : endHour;
    final actualEnd = startHour < endHour ? endHour : startHour;
    
    List<int> selectedHours = [];
    for (int hour = actualStart; hour <= actualEnd; hour++) {
      selectedHours.add(hour);
    }
    
    return selectedHours;
  }

  // 필터 그룹 위젯
  Widget _buildFilterGroups() {
    // 필터를 카테고리별로 분류
    Map<String, List<String>> filterGroups = {
      '모집중': [],
      '게임 유형': [],
      '구력': [],
      '연령대': [],
      '날짜': [],
      '시간': [],
    };
    
    for (final filter in _selectedFilters) {
      if (filter.contains('모집중')) {
        filterGroups['모집중']!.add(filter);
      } else if (filter.contains('혼복') || filter.contains('남복') || filter.contains('여복') || 
          filter.contains('단식') || filter.contains('랠리')) {
        filterGroups['게임 유형']!.add(filter);
      } else if (filter.contains('년') || filter.contains('개월')) {
        filterGroups['구력']!.add(filter);
      } else if (filter.contains('월') && filter.contains('일')) {
        filterGroups['날짜']!.add(filter);
      } else if (filter.contains('시')) {
        filterGroups['시간']!.add(filter);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 첫 번째 줄: 카테고리별 대표 필터
        Row(
          children: filterGroups.entries.map((entry) {
            final firstFilter = entry.value.isNotEmpty ? entry.value.first : null;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                child: _buildCategoryFilter(firstFilter, entry.key),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        // 두 번째 줄: 카테고리별 추가 필터들 (수직 정렬)
        if (filterGroups.values.any((filters) => filters.length > 1))
          Row(
            children: filterGroups.entries.map((entry) {
              if (entry.value.length > 1) {
                return Expanded(
                  child: Column(
                    children: entry.value.skip(1).map((filter) => 
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: _buildFilterButton(filter),
                      )
                    ).toList(),
                  ),
                );
              } else {
                return const Expanded(child: SizedBox());
              }
            }).toList(),
          ),
      ],
    );
  }

  // 카테고리별 대표 필터 버튼
  Widget _buildCategoryFilter(String? filter, String category) {
    IconData icon;
    Color color;
    String displayText;
    
    // 카테고리별 아이콘과 색상 설정
    switch (category) {
      case '모집중':
        icon = Icons.people;
        color = Colors.green;
        displayText = filter != null ? '모집중' : '전체';
        break;
      case '게임 유형':
        icon = Icons.sports_tennis;
        color = AppColors.accent;
        displayText = filter != null ? _getFilterDisplayText(filter) : '전체';
        break;
      case '구력':
        icon = Icons.timeline;
        color = AppColors.primary;
        displayText = filter != null ? _getFilterDisplayText(filter) : '전체';
        break;
      case '날짜':
        icon = Icons.calendar_today;
        color = Colors.orange;
        displayText = filter != null ? _getFilterDisplayText(filter) : '전체';
        break;
      case '시간':
        icon = Icons.access_time;
        color = Colors.purple;
        displayText = filter != null ? _getFilterDisplayText(filter) : '전체';
        break;
      default:
        icon = Icons.filter_list;
        color = AppColors.textSecondary;
        displayText = '전체';
    }
    
    return GestureDetector(
      onTap: () {
        if (filter != null) {
          // 필터가 선택된 상태: 필터 제거
          setState(() {
            _selectedFilters.removeWhere((f) => _getFilterCategory(f) == category);
            
            // 관련 변수 초기화
            if (category == '모집중') {
              _showOnlyRecruiting = false;
            } else if (category == '게임 유형') {
              _selectedGameTypes.clear();
            } else if (category == '구력') {
              _selectedSkillLevel = null;
              _selectedEndSkillLevel = null;
            } else if (category == '연령대') {
              _selectedMinAge = null;
              _selectedMaxAge = null;
            } else if (category == '날짜') {
              _startDate = null;
              _endDate = null;
            } else if (category == '시간') {
              _startTime = null;
              _endTime = null;
            }
          });
        } else {
          // 필터가 선택되지 않은 상태: 필터 설정 화면 열기
          _showFilterBottomSheet(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: filter != null ? color.withValues(alpha: 0.15) : AppColors.surface,
          border: Border.all(
            color: filter != null ? color : AppColors.cardBorder,
            width: filter != null ? 1.5 : 0.8,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: filter != null ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
                  child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: filter != null ? color : AppColors.textSecondary, size: 16),
              const SizedBox(height: 3),
              Flexible(
                child: Text(
                  displayText,
                  style: AppTextStyles.body.copyWith(
                    color: filter != null ? color : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: filter != null ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ),
    );
  }

  // 필터의 카테고리 반환
  String _getFilterCategory(String filter) {
    if (filter.contains('모집중')) return '모집중';
    if (filter.contains('혼복') || filter.contains('남복') || filter.contains('여복') || 
        filter.contains('단식') || filter.contains('랠리')) return '게임 유형';
    if (filter.contains('년') || filter.contains('개월')) return '구력';
    if (filter.contains('대')) return '연령대';
    if (filter.contains('월') && filter.contains('일')) return '날짜';
    if (filter.contains('시')) return '시간';
    return '기타';
  }

  // 필터 표시 텍스트 변환
  String _getFilterDisplayText(String filter) {
    if (filter.contains('모집중')) return '모집중';
    if (filter.contains('혼복')) return '혼복';
    if (filter.contains('남복')) return '남복';
    if (filter.contains('여복')) return '여복';
    if (filter.contains('단식')) return '단식';
    if (filter.contains('랠리')) return '랠리';
    if (filter.contains('년부터') && filter.contains('년까지')) {
      // "3년부터" + "5년까지" → "3-5년"
      final startMatch = RegExp(r'(\d+)년부터').firstMatch(filter);
      final endMatch = RegExp(r'(\d+)년까지').firstMatch(filter);
      if (startMatch != null && endMatch != null) {
        return '${startMatch.group(1)}-${endMatch.group(1)}년';
      }
    }
    if (filter.contains('월') && filter.contains('일')) {
      // "8월 9일부터" + "8월 10일까지" → "8월 9-10일"
      final startMatch = RegExp(r'(\d+)월 (\d+)일부터').firstMatch(filter);
      final endMatch = RegExp(r'(\d+)월 (\d+)일까지').firstMatch(filter);
      if (startMatch != null && endMatch != null) {
        return '${startMatch.group(1)}월 ${startMatch.group(2)}-${endMatch.group(2)}일';
      }
    }
    if (filter.contains('시부터') && filter.contains('시까지')) {
      // "7시부터" + "10시까지" → "7-10시"
      final startMatch = RegExp(r'(\d+)시부터').firstMatch(filter);
      final endMatch = RegExp(r'(\d+)시까지').firstMatch(filter);
      if (startMatch != null && endMatch != null) {
        return '${startMatch.group(1)}-${endMatch.group(1)}시';
      }
    }
    return filter;
  }

  // 필터 버튼 위젯
  Widget _buildFilterButton(String filter) {
    IconData icon;
    Color color;
    
    // 필터 타입에 따른 아이콘과 색상 설정
    if (filter.contains('혼복') || filter.contains('남복') || filter.contains('여복') || 
        filter.contains('단식') || filter.contains('랠리')) {
      icon = Icons.sports_tennis;
      color = AppColors.accent;
    } else if (filter.contains('년') || filter.contains('개월')) {
      icon = Icons.timeline;
      color = AppColors.primary;
    } else if (filter.contains('월') && filter.contains('일')) {
      icon = Icons.calendar_today;
      color = Colors.orange;
    } else if (filter.contains('시')) {
      icon = Icons.access_time;
      color = Colors.purple;
    } else if (filter.contains('모집중')) {
      icon = Icons.people;
      color = Colors.green;
    } else {
      icon = Icons.filter_list;
      color = AppColors.textSecondary;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilters.remove(filter);
          
          // 필터 제거 시 관련 변수도 초기화
          if (filter.contains('혼복') || filter.contains('남복') || filter.contains('여복') || 
              filter.contains('단식') || filter.contains('랠리')) {
            // 해당 게임 유형만 제거
            if (filter == '혼복') {
              _selectedGameTypes.remove('mixed');
            } else if (filter == '남복') {
              _selectedGameTypes.remove('male_doubles');
            } else if (filter == '여복') {
              _selectedGameTypes.remove('female_doubles');
            } else if (filter == '단식') {
              _selectedGameTypes.remove('singles');
            } else if (filter == '랠리') {
              _selectedGameTypes.remove('rally');
            }
          } else if (filter.contains('년') || filter.contains('개월')) {
            _selectedSkillLevel = null;
            _selectedEndSkillLevel = null;
          } else if (filter.contains('월') && filter.contains('일')) {
            _startDate = null;
            _endDate = null;
          } else if (filter.contains('시')) {
            _startTime = null;
            _endTime = null;
          } else if (filter.contains('모집중')) {
            _showOnlyRecruiting = false;
          } else if (filter.contains('팔로우만')) {
            // 팔로우만 보기는 전용 체크박스로 관리하므로 여기서는 제거하지 않음
            // _showOnlyFollowing = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                filter,
                style: AppTextStyles.body.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.close, color: color, size: 12),
          ],
        ),
      ),
    );
  }

  // 로딩 상태 표시 위젯
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            '매칭을 불러오는 중...',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 빈 상태 표시 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.sports_tennis,
            size: 60,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '검색 결과가 없습니다.' : '매칭이 없습니다.',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? '다른 검색어를 시도하거나 필터를 조정해보세요.'
                : _selectedFilters.isNotEmpty
                    ? '현재 필터 조건에 맞는 매칭이 없습니다.\n필터를 조정하거나 새로운 매칭을 만들어보세요!'
                    : '새로운 매칭을 만들어보세요!',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('검색어 지우기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _showFilterBottomSheet(context);
                  },
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('필터 조정'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 검색 결과 텍스트 생성
  String _getSearchResultText() {
    final totalCount = _mockMatchings.length;
    final filteredCount = _filteredMatchings.length;
    String resultText = '';

    if (_searchQuery.isNotEmpty) {
      if (filteredCount == 0) {
        return '"$_searchQuery" 검색 결과가 없습니다';
      } else if (filteredCount == totalCount) {
        return '"$_searchQuery" 검색 결과: $filteredCount개 매칭';
      } else {
        return '"$_searchQuery" 검색 결과: $filteredCount개 매칭 (전체 $totalCount개 중)';
      }
    }
    
    // 필터만 적용된 경우
    if (_selectedFilters.isNotEmpty || _showOnlyRecruiting || _showOnlyFollowing) {
      if (filteredCount == 0) {
        return '필터 결과가 없습니다';
      } else if (filteredCount == totalCount) {
        return '$filteredCount개 매칭';
      } else {
        return '$filteredCount개 매칭 (전체 $totalCount개 중)';
      }
    }
    
    // 기본 상태
    return '$totalCount개 매칭';
  }



  // 도시명 가져오기
  String _getCityName(String cityId) {
    final city = _locationData.firstWhere(
      (city) => city.id == cityId,
      orElse: () => Location(id: '', name: ''),
    );
    return city.name;
  }

  // 구/군명 가져오기
  String _getDistrictName(String districtId) {
    for (final city in _locationData) {
      if (city.subLocations != null) {
        final district = city.subLocations!.firstWhere(
          (district) => district.id == districtId,
          orElse: () => Location(id: '', name: ''),
        );
        if (district.id.isNotEmpty) {
          return district.name;
        }
      }
    }
    return '';
  }

  // 위치 필터 적용
  void _applyLocationFilter(String cityId, String? districtId) {
    setState(() {
      if (districtId == null) {
        // 도시 전체 선택
        _selectedCityId = cityId;
        _selectedDistrictIds.clear();
        
        // 도시 전체 선택 시에도 구/군은 선택하지 않음 (사용자가 직접 선택하도록)
        // _selectedDistrictIds.addAll(
        //   city.subLocations!.map((district) => district.id).toList()
        // );
      } else {
        // 특정 구/군 선택
        if (_selectedDistrictIds.contains(districtId)) {
          _selectedDistrictIds.remove(districtId);
        } else {
          _selectedDistrictIds.add(districtId);
        }
        
        // 도시 전체 선택 해제
        final city = _locationData.firstWhere(
          (city) => city.id == cityId,
          orElse: () => Location(id: '', name: ''),
        );
        if (city.subLocations != null) {
          final allDistrictIds = city.subLocations!.map((district) => district.id).toList();
          if (_selectedDistrictIds.every((id) => allDistrictIds.contains(id))) {
            // 모든 구/군이 선택된 경우 도시 전체 선택으로 변경
            _selectedDistrictIds.clear();
            _selectedDistrictIds.addAll(allDistrictIds);
          }
        }
      }
      
      // 필터 적용
      _applyFilters();
    });
  }

  // 매칭별 위치 정보 반환
  String _getMatchingLocationText(Matching matching) {
    // 코트별 위치 정보 매핑
    Map<String, String> courtLocations = {
      '잠실종합운동장': '서울 송파구',
      '양재시민의숲': '서울 강남구',
      '올림픽공원 테니스장': '서울 송파구',
      '한강공원 테니스장': '서울 영등포구',
      '분당테니스장': '경기도 성남시',
      '인천대공원 테니스장': '인천 미추홀구',
    };
    
    return courtLocations[matching.courtName] ?? '위치 정보 없음';
  }

  // 필터 칩 위젯
  Widget _buildFilterChip(String filter) {
    IconData icon;
    Color color;
    
    // 필터 타입에 따른 아이콘과 색상 설정 (더 부드러운 색상)
    if (filter.contains('혼복') || filter.contains('남복') || filter.contains('여복') || 
        filter.contains('단식') || filter.contains('랠리')) {
      icon = Icons.sports_tennis;
      color = const Color(0xFFE8B54A); // 부드러운 주황색
    } else if (filter.contains('년') || filter.contains('개월')) {
      icon = Icons.timeline;
      color = const Color(0xFF6B9E78); // 부드러운 초록색
    } else if (filter.contains('월') && filter.contains('일')) {
      icon = Icons.calendar_today;
      color = const Color(0xFFE8A87C); // 부드러운 주황색
    } else if (filter.contains('시')) {
      icon = Icons.access_time;
      color = const Color(0xFFB8A9C9); // 부드러운 보라색
    } else if (filter.contains('모집중')) {
      icon = Icons.people;
      color = const Color(0xFF7FB069); // 부드러운 초록색
    } else if (filter == '서울' || filter == '경기도' || filter == '인천') {
      icon = Icons.location_city;
      color = const Color(0xFF7BA7BC); // 부드러운 파란색
    } else if (filter.contains('구') || filter.contains('시') || filter.contains('군')) {
      icon = Icons.location_on;
      color = const Color(0xFF9B8BB4); // 부드러운 인디고색
    } else {
      icon = Icons.filter_list;
      color = AppColors.textSecondary;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 12,8 → 10,6 (약 20% 감소)
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.0), // 1.2 → 1.0 (약 17% 감소)
        borderRadius: BorderRadius.circular(16), // 20 → 16 (20% 감소)
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 5, // 6 → 5 (약 17% 감소)
            offset: const Offset(0, 1), // 2 → 1 (50% 감소)
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14), // 16 → 14 (12.5% 감소)
          const SizedBox(width: 5), // 6 → 5 (약 17% 감소)
          Flexible(
            child: Text(
              filter,
              style: AppTextStyles.body.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 12, // 13 → 12 (약 8% 감소)
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 5), // 6 → 5 (약 17% 감소)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilters.remove(filter);
                
                // 필터 제거 시 관련 변수도 초기화
                if (filter == '서울') {
                  _selectedCityId = null;
                } else if (filter == '송파구') {
                  _selectedDistrictIds.removeWhere((id) => _getDistrictName(id) == filter);
                } else if (filter.contains('혼복') || filter.contains('남복') || filter.contains('여복') || 
                    filter.contains('단식') || filter.contains('랠리')) {
                  // 해당 게임 유형만 제거
                  if (filter == '혼복') {
                    _selectedGameTypes.remove('mixed');
                  } else if (filter == '남복') {
                    _selectedGameTypes.remove('male_doubles');
                  } else if (filter == '여복') {
                    _selectedGameTypes.remove('female_doubles');
                  } else if (filter == '단식') {
                    _selectedGameTypes.remove('singles');
                  } else if (filter == '랠리') {
                    _selectedGameTypes.remove('rally');
                  }
                } else if (filter.contains('년') || filter.contains('개월')) {
                  _selectedSkillLevel = null;
                  _selectedEndSkillLevel = null;
                } else if (filter.contains('월') && filter.contains('일')) {
                  _startDate = null;
                  _endDate = null;
                } else if (filter.contains('시')) {
                  _startTime = null;
                  _endTime = null;
                } else if (filter.contains('모집중')) {
                  _showOnlyRecruiting = false;
                } else if (filter.contains('팔로우만')) {
                  // 팔로우만 보기는 전용 체크박스로 관리하므로 여기서는 제거하지 않음
                  // _showOnlyFollowing = false;
                }
                
                // 필터 상태 동기화하여 요약 UI 업데이트
                _syncFilterState();
                
                // 필터 적용
                _applyFilters();
              });
            },
            child: Icon(
              Icons.close,
              color: color.withValues(alpha: 0.7),
              size: 14, // 16 → 14 (12.5% 감소)
            ),
          ),
        ],
      ),
    );
  }

  // String 시간에서 hour와 minute 추출
  int _getHourFromString(String timeString) {
    try {
      return int.parse(timeString.split(':')[0]);
    } catch (e) {
      return 0;
    }
  }
  
  int _getMinuteFromString(String timeString) {
    try {
      return int.parse(timeString.split(':')[1]);
    } catch (e) {
      return 0;
    }
  }

  // 시간 비교 헬퍼 메서드
  int _compareTime(String time1, String time2) {
    final parts1 = time1.split(':');
    final parts2 = time2.split(':');
    
    if (parts1.length == 2 && parts2.length == 2) {
      final hour1 = int.parse(parts1[0]);
      final minute1 = int.parse(parts1[1]);
      final hour2 = int.parse(parts2[0]);
      final minute2 = int.parse(parts2[1]);
      
      final totalMinutes1 = hour1 * 60 + minute1;
      final totalMinutes2 = hour2 * 60 + minute2;
      
      if (totalMinutes1 < totalMinutes2) return -1;
      if (totalMinutes1 > totalMinutes2) return 1;
      return 0;
    }
    return 0;
  }

  // 연령대 범위 필터 탭 위젯
  Widget _buildAgeRangeTab(String? selectedMinAge, String? selectedMaxAge, List<String> selectedFilters, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 연령대 선택 안내
        Text(
          '연령대 범위',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '연령대 범위를 선택해 주세요',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        
        // 선택된 연령대 범위 표시
        if (selectedMinAge != null || selectedMaxAge != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedMinAge != null && selectedMaxAge != null
                      ? '$selectedMinAge ~ $selectedMaxAge'
                      : selectedMinAge != null
                          ? '$selectedMinAge 이상'
                          : '$selectedMaxAge 이하',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        // 연령대 선택 버튼들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ageOptions.map((age) {
            final isSelected = selectedMinAge == age || selectedMaxAge == age;
            final isInRange = selectedMinAge != null && selectedMaxAge != null &&
                _ageOptions.indexOf(age) >= _ageOptions.indexOf(selectedMinAge!) &&
                _ageOptions.indexOf(age) <= _ageOptions.indexOf(selectedMaxAge!);
            
            return GestureDetector(
              onTap: () {
                print('=== 연령대 버튼 클릭: $age ===');
                setModalState(() {
                  if (selectedMinAge == null) {
                    // 첫 번째 선택: 시작 연령대
                    selectedMinAge = age;
                    print('첫 번째 선택: 시작 연령대 = $age');
                  } else if (selectedMaxAge == null) {
                    // 두 번째 선택: 종료 연령대
                    selectedMaxAge = age;
                    print('두 번째 선택: 종료 연령대 = $age');
                    
                    // 종료 연령대가 시작 연령대보다 작으면 순서 변경
                    if (_ageOptions.indexOf(selectedMaxAge!) < _ageOptions.indexOf(selectedMinAge!)) {
                      final temp = selectedMinAge;
                      selectedMinAge = selectedMaxAge;
                      selectedMaxAge = temp;
                    }
                  } else {
                    // 새로운 선택: 시작 연령대로 재설정
                    selectedMinAge = age;
                    selectedMaxAge = null;
                    print('새로운 선택: 시작 연령대 재설정 = $age');
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected || isInRange
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected || isInRange
                        ? AppColors.primary
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  age,
                  style: AppTextStyles.body.copyWith(
                    color: isSelected || isInRange
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: isSelected || isInRange
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 20),
        
        // 선택 완료 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              print('=== 연령대 필터 선택 완료 ===');
              print('선택된 시작 연령대: $selectedMinAge');
              print('선택된 종료 연령대: $selectedMaxAge');
              
              // 필터 텍스트 생성
              if (selectedMinAge != null && selectedMaxAge != null) {
                final filterText = '$selectedMinAge-$selectedMaxAge';
                if (!selectedFilters.contains(filterText)) {
                  selectedFilters.add(filterText);
                }
              } else if (selectedMinAge != null) {
                final filterText = '$selectedMinAge 이상';
                if (!selectedFilters.contains(filterText)) {
                  selectedFilters.add(filterText);
                }
              } else if (selectedMaxAge != null) {
                final filterText = '$selectedMaxAge 이하';
                if (!selectedFilters.contains(filterText)) {
                  selectedFilters.add(filterText);
                }
              }
              
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('선택 완료'),
          ),
        ),
      ],
    );
  }

  // 구력 범위 필터 탭 위젯
  Widget _buildSkillLevelTab(String? selectedSkillLevel, String? selectedEndSkillLevel, List<String> selectedFilters, StateSetter setModalState) {
    final skillLevels = ['6개월', '1년', '2년', '3년', '4년', '5년', '6년', '7년', '8년', '9년', '10년+'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '구력 범위',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // 구력 선택 안내
        Text(
          '구력 범위를 선택해 주세요',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        // 선택된 구력 범위 표시 (모달 내에서도 실제 상태값을 사용)
        if (_selectedSkillLevel != null || _selectedEndSkillLevel != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  _selectedSkillLevel != null && _selectedEndSkillLevel != null
                      ? '${_selectedSkillLevel} ~ ${_selectedEndSkillLevel}'
                      : _selectedSkillLevel != null
                          ? '${_selectedSkillLevel} 이상'
                          : '${_selectedEndSkillLevel} 이하',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // 구력 선택 버튼들 (실제 상태값 기준으로 하이라이트)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skillLevels.map((level) {
            final isSelected = _selectedSkillLevel == level || _selectedEndSkillLevel == level;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print('=== 구력 버튼 클릭: $level ===');

                  String? newStart = _selectedSkillLevel;
                  String? newEnd = _selectedEndSkillLevel;

                  if (newStart == null) {
                    // 첫 번째 선택: 시작 구력
                    newStart = level;
                    newEnd = null;
                    print('첫 번째 선택: 시작 구력 = $level');
                  } else if (newEnd == null) {
                    // 두 번째 선택: 종료 구력
                    final startValue = _getSkillLevelFromText(newStart);
                    final endValue = _getSkillLevelFromText(level);

                    if (startValue != null && endValue != null) {
                      if (endValue > startValue) {
                        newEnd = level;
                        print('두 번째 선택: 범위 설정 = $newStart ~ $level');
                      } else {
                        // 종료 구력이 시작 구력보다 작으면 순서 변경
                        newEnd = newStart;
                        newStart = level;
                        print('순서 변경: 범위 설정 = $newStart ~ $newEnd');
                      }
                    }
                  } else {
                    // 새로운 선택: 시작 구력으로 재설정
                    newStart = level;
                    newEnd = null;
                    print('새로운 선택: 시작 구력 재설정 = $level');
                  }

                  // 실제 상태 업데이트 (모달/메인 동기화)
                  setState(() {
                    _selectedSkillLevel = newStart;
                    _selectedEndSkillLevel = newEnd;
                  });

                  // 모달 내 필터 요약 리스트 갱신
                  setModalState(() {
                    selectedFilters.removeWhere((filter) =>
                        filter.contains('년') && (filter.contains('-') || filter.contains('이상') || filter.contains('이하')));

                    if (newStart != null && newEnd != null) {
                      final text = '$newStart-$newEnd';
                      if (!selectedFilters.contains(text)) selectedFilters.add(text);
                    } else if (newStart != null) {
                      final text = '$newStart 이상';
                      if (!selectedFilters.contains(text)) selectedFilters.add(text);
                    } else if (newEnd != null) {
                      final text = '$newEnd 이하';
                      if (!selectedFilters.contains(text)) selectedFilters.add(text);
                    }
                  });

                  print('=== 구력 필터 선택 완료 ===');
                  print('선택된 시작 구력: $_selectedSkillLevel');
                  print('선택된 종료 구력: $_selectedEndSkillLevel');

                  // 필터 상태 동기화하여 요약 UI 업데이트
                  _syncFilterState();
                  
                  // 필터 적용
                  _applyFilters();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    level,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected ? AppColors.surface : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 자동 완료 처리 타이머 시작
  void _startAutoCompletionTimer() {
    // 1분마다 체크 (실제로는 더 긴 간격으로 설정 가능)
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _checkAndUpdateCompletedMatchings();
      } else {
        timer.cancel();
      }
    });
  }

  // 실시간 업데이트 타이머 시작
  void _startAutoRefreshTimer() {
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _refreshMatchingData();
      } else {
        timer.cancel();
      }
    });
  }

  // 매칭 데이터 새로고침
  void _refreshMatchingData() {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // 실제로는 API 호출을 통해 최신 데이터를 가져옴
    // 현재는 mock 데이터를 사용하므로 시뮬레이션
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // 새로운 매칭이 추가되었는지 시뮬레이션 (10% 확률)
        if (DateTime.now().millisecondsSinceEpoch % 10 == 0) {
          _simulateNewMatching();
        }
        
        // 기존 매칭 상태 변경 시뮬레이션 (5% 확률)
        if (DateTime.now().millisecondsSinceEpoch % 20 == 0) {
          _simulateStatusChange();
        }
        
        // 자동 완료 상태 변경 체크
        _checkAndUpdateCompletedMatchings();
        
        setState(() {
          _isLoading = false;
        });
        
        // 필터 재적용
        _applyFilters();
        
        print('매칭 데이터 새로고침 완료: ${DateTime.now()}');
      }
    });
  }

  // 새로운 매칭 추가 시뮬레이션
  void _simulateNewMatching() {
    final newMatching = Matching(
      id: DateTime.now().millisecondsSinceEpoch,
      type: 'host',
      courtName: '새로운 테니스장',
      courtLat: 37.5 + (DateTime.now().millisecondsSinceEpoch % 100) / 1000,
      courtLng: 127.0 + (DateTime.now().millisecondsSinceEpoch % 100) / 1000,
      date: DateTime.now().add(Duration(days: DateTime.now().millisecondsSinceEpoch % 7 + 1)),
      timeSlot: '${18 + (DateTime.now().millisecondsSinceEpoch % 6)}:00~${20 + (DateTime.now().millisecondsSinceEpoch % 6)}:00',
      minLevel: 1 + (DateTime.now().millisecondsSinceEpoch % 3),
      maxLevel: 3 + (DateTime.now().millisecondsSinceEpoch % 3),
      gameType: ['mixed', 'male_doubles', 'female_doubles'][DateTime.now().millisecondsSinceEpoch % 3],
      maleRecruitCount: 1 + (DateTime.now().millisecondsSinceEpoch % 2),
      femaleRecruitCount: DateTime.now().millisecondsSinceEpoch % 2,
      status: 'recruiting',
      host: User(
        id: 999,
        email: 'new@example.com',
        nickname: '새로운호스트',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recoveryCount: 0,
    );
    
    _mockMatchings.insert(0, newMatching);
    print('새로운 매칭 추가 시뮬레이션: ${newMatching.courtName}');
  }

  // 매칭 상태 변경 시뮬레이션
  void _simulateStatusChange() {
    if (_mockMatchings.isEmpty) return;
    
    final randomIndex = DateTime.now().millisecondsSinceEpoch % _mockMatchings.length;
    final matching = _mockMatchings[randomIndex];
    
    // 모집중인 매칭을 확정으로 변경
    if (matching.actualStatus == 'recruiting' && matching.appliedUserIds != null && matching.appliedUserIds!.isNotEmpty) {
      final updatedMatching = matching.copyWith(
        status: 'confirmed',
        confirmedUserIds: matching.appliedUserIds,
        updatedAt: DateTime.now(),
      );
      
      _mockMatchings[randomIndex] = updatedMatching;
      print('매칭 상태 변경 시뮬레이션: ${matching.courtName} → 확정');
    }
  }

  // 수동 새로고침
  void _manualRefresh() {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // 새로고침 애니메이션 효과
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _refreshMatchingData();
        
        // 새로고침 완료 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('새로고침이 완료되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  // 완료된 매칭 체크 및 업데이트 + 자동 확정
  void _checkAndUpdateCompletedMatchings() {
    final now = DateTime.now();
    bool hasUpdates = false;
    
    for (int i = 0; i < _mockMatchings.length; i++) {
      final matching = _mockMatchings[i];
      
      // 1. 자동 확정 체크: 모집중 상태이고 모집 인원이 다 찬 경우
      if (matching.status == 'recruiting' && _shouldAutoConfirm(matching)) {
        final autoConfirmedMatching = Matching(
          id: matching.id,
          type: matching.type,
          courtName: matching.courtName,
          courtLat: matching.courtLat,
          courtLng: matching.courtLng,
          date: matching.date,
          timeSlot: matching.timeSlot,
          minLevel: matching.minLevel,
          maxLevel: matching.maxLevel,
          gameType: matching.gameType,
          maleRecruitCount: matching.maleRecruitCount,
          femaleRecruitCount: matching.femaleRecruitCount,
          status: 'confirmed', // 자동 확정 상태로 변경
          message: matching.message,
          guestCost: matching.guestCost,
          isFollowersOnly: matching.isFollowersOnly,
          host: matching.host,
          guests: matching.guests,
          createdAt: matching.createdAt,
          updatedAt: now,
        );
        
        _mockMatchings[i] = autoConfirmedMatching.copyWith(recoveryCount: matching.recoveryCount);
        hasUpdates = true;
        
        print('자동 확정 처리: ${matching.courtName} (${matching.timeSlot})');
        
        // 자동 확정 알림 표시
        _showAutoConfirmationNotification(matching);
      }
      
      // 2. 확정 상태이고 게임 시간이 종료된 경우 (기존 로직)
      if (matching.status == 'confirmed' && _isGameTimeEnded(matching, now)) {
        // 새로운 Matching 객체 생성 (불변성 유지)
        final updatedMatching = Matching(
          id: matching.id,
          type: matching.type,
          courtName: matching.courtName,
          courtLat: matching.courtLat,
          courtLng: matching.courtLng,
          date: matching.date,
          timeSlot: matching.timeSlot,
          minLevel: matching.minLevel,
          maxLevel: matching.maxLevel,
          gameType: matching.gameType,
          maleRecruitCount: matching.maleRecruitCount,
          femaleRecruitCount: matching.femaleRecruitCount,
          status: 'completed', // 완료 상태로 변경
          message: matching.message,
          guestCost: matching.guestCost,
          isFollowersOnly: matching.isFollowersOnly,
          host: matching.host,
          guests: matching.guests,
          createdAt: matching.createdAt,
          updatedAt: now,
        );
        
        _mockMatchings[i] = updatedMatching.copyWith(recoveryCount: matching.recoveryCount);
        hasUpdates = true;
        
        print('자동 완료 처리: ${matching.courtName} (${matching.timeSlot})');
      }
    }
    
    // 업데이트가 있으면 필터 적용
    if (hasUpdates) {
      _applyFilters();
    }
  }

  // 자동 확정 조건 확인
  bool _shouldAutoConfirm(Matching matching) {
    // 모집 인원 수 계산
    final totalRecruitCount = matching.maleRecruitCount + matching.femaleRecruitCount;
    
    // 확정된 참여자 수 계산
    final confirmedCount = matching.confirmedUserIds?.length ?? 0;
    
    // 모집 인원이 다 찬 경우 자동 확정
    return confirmedCount >= totalRecruitCount;
  }

  // 게임 시간이 종료되었는지 확인
  bool _isGameTimeEnded(Matching matching, DateTime now) {
    // 매칭 날짜가 오늘이 아니면 false
    if (matching.date.year != now.year || 
        matching.date.month != now.month || 
        matching.date.day != now.day) {
      return false;
    }
    
    // 시간대 파싱 (예: "18:00~20:00")
    final timeParts = matching.timeSlot.split('~');
    if (timeParts.length != 2) return false;
    
    try {
      final startTimeParts = timeParts[0].trim().split(':');
      final endTimeParts = timeParts[1].trim().split(':');
      
      if (startTimeParts.length != 2 || endTimeParts.length != 2) return false;
      
      final startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      final endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);
      
      // 게임 종료 시간 계산
      final gameEndTime = DateTime(
        now.year,
        now.month,
        now.day,
        endHour,
        endMinute,
      );
      
      // 현재 시간이 게임 종료 시간을 지났으면 true
      return now.isAfter(gameEndTime);
    } catch (e) {
      print('시간 파싱 오류: $e');
      return false;
    }
  }

  // 자동 확정 알림 표시
  void _showAutoConfirmationNotification(Matching matching) {
    // 현재 화면이 활성화되어 있을 때만 알림 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${matching.courtName} 매칭이 자동으로 확정되었습니다!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '확인',
            textColor: Colors.white,
            onPressed: () {
              // 스낵바 닫기
            },
          ),
        ),
      );
    }
  }

  // 상태별 색상 반환 메서드
  Color _getStatusColor(String status) {
    switch (status) {
      case 'recruiting':
        return Colors.orange; // 모집중: 주황색
      case 'confirmed':
        return Colors.green; // 확정: 초록색
      case 'completed':
        return Colors.blue; // 완료: 파란색
      case 'cancelled':
        return Colors.red; // 취소: 빨간색
      case 'deleted':
        return Colors.grey; // 삭제됨: 회색
      default:
        return AppColors.textSecondary; // 기본: 회색
    }
  }



  // 상태별 아이콘 반환 메서드
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'recruiting':
        return Icons.person_add; // 모집중: 사람 추가 아이콘
      case 'confirmed':
        return Icons.check_circle; // 확정: 체크 원 아이콘
      case 'completed':
        return Icons.done_all; // 완료: 완료 아이콘
      case 'cancelled':
        return Icons.cancel; // 취소: 취소 아이콘
      case 'deleted':
        return Icons.delete_forever; // 삭제됨: 영구 삭제 아이콘
      default:
        return Icons.info; // 기본: 정보 아이콘
    }
  }

  // 모집중만 보기 체크박스
  Widget _buildRecruitingOnlyCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), // vertical: 4 → 3 (20% 축소)
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _showOnlyRecruiting,
              onChanged: (value) {
                setState(() {
                  _showOnlyRecruiting = value ?? false;
                  _applyFilters();
                });
              },
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _showOnlyRecruiting = !_showOnlyRecruiting;
                _applyFilters();
              });
            },
            child: Text(
              '모집중만',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 팔로우만 보기 체크박스
  Widget _buildFollowOnlyCheckbox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1), // vertical: 2 → 1 (20% 축소)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), // vertical: 4 → 3 (20% 축소)
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _showOnlyFollowing,
            onChanged: (value) {
              setState(() {
                _showOnlyFollowing = value ?? false;
              });
              _applyFilters();
            },
            activeColor: AppColors.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _showOnlyFollowing = !_showOnlyFollowing;
              });
              _applyFilters();
            },
            child: Text(
              '팔로우만',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


}