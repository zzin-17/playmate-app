import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/matching.dart';
import '../models/user.dart';
import 'matching_data_service_v2.dart';

class MatchingHomeService extends ChangeNotifier {
  static final MatchingHomeService _instance = MatchingHomeService._internal();
  factory MatchingHomeService() => _instance;
  MatchingHomeService._internal();

  // 매칭 데이터
  List<Matching> _mockMatchings = [];
  List<Matching> _filteredMatchings = [];
  bool _isLoading = false;
  String? _error;

  // 필터 상태
  String _selectedFilter = 'all';
  String _searchQuery = '';
  List<String> _selectedGameTypes = [];
  String? _selectedSkillLevel;
  String? _selectedEndSkillLevel;
  List<String> _selectedAgeRanges = [];
  bool _noAgeRestriction = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startTime;
  String? _endTime;
  String? _selectedCityId;
  List<String> _selectedDistrictIds = [];
  bool _showOnlyRecruiting = false;
  bool _showOnlyFollowing = false;

  // Getters
  List<Matching> get mockMatchings => _mockMatchings;
  List<Matching> get filteredMatchings => _filteredMatchings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  List<String> get selectedGameTypes => _selectedGameTypes;
  String? get selectedSkillLevel => _selectedSkillLevel;
  String? get selectedEndSkillLevel => _selectedEndSkillLevel;
  List<String> get selectedAgeRanges => _selectedAgeRanges;
  bool get noAgeRestriction => _noAgeRestriction;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get startTime => _startTime;
  String? get endTime => _endTime;
  String? get selectedCityId => _selectedCityId;
  List<String> get selectedDistrictIds => _selectedDistrictIds;
  bool get showOnlyRecruiting => _showOnlyRecruiting;
  bool get showOnlyFollowing => _showOnlyFollowing;

  // 매칭 데이터 초기화
  void initializeMatchings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _mockMatchings = await MatchingDataServiceV2.getMatchings();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      // 오류 발생 시 Mock 데이터 사용
      _mockMatchings = _createMockMatchings();
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ImprovedHomeScreen에서 사용하는 메서드들
  void initializeData() {
    initializeMatchings();
  }

  void addMatching(Matching matching) {
    addNewMatching(matching);
  }

  void updateSearchQuery(String query) {
    setSearchQuery(query);
  }

  void updateSelectedFilter(String filter) {
    setFilter(filter);
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _mockMatchings = await MatchingDataServiceV2.getMatchings(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        gameTypes: _selectedGameTypes.isNotEmpty ? _selectedGameTypes : null,
        skillLevel: _selectedSkillLevel,
        endSkillLevel: _selectedEndSkillLevel,
        ageRanges: _selectedAgeRanges.isNotEmpty ? _selectedAgeRanges : null,
        noAgeRestriction: _noAgeRestriction,
        startDate: _startDate,
        endDate: _endDate,
        startTime: _startTime,
        endTime: _endTime,
        cityId: _selectedCityId,
        districtIds: _selectedDistrictIds.isNotEmpty ? _selectedDistrictIds : null,
        showOnlyRecruiting: _showOnlyRecruiting,
        showOnlyFollowing: _showOnlyFollowing,
      );
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      // 오류 발생 시 기존 데이터 유지
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleGameType(String gameType) {
    if (_selectedGameTypes.contains(gameType)) {
      _selectedGameTypes.remove(gameType);
    } else {
      _selectedGameTypes.add(gameType);
    }
    _applyFilters();
    notifyListeners();
  }

  void applyFilters() {
    _applyFilters();
    notifyListeners();
  }

  // 필터 설정
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setGameTypes(List<String> gameTypes) {
    _selectedGameTypes = gameTypes;
    _applyFilters();
    notifyListeners();
  }

  void setSkillLevel(String? minLevel, String? maxLevel) {
    _selectedSkillLevel = minLevel;
    _selectedEndSkillLevel = maxLevel;
    _applyFilters();
    notifyListeners();
  }

  void setAgeRanges(List<String> ageRanges, bool noRestriction) {
    _selectedAgeRanges = ageRanges;
    _noAgeRestriction = noRestriction;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
    notifyListeners();
  }

  void setTimeRange(String? start, String? end) {
    _startTime = start;
    _endTime = end;
    _applyFilters();
    notifyListeners();
  }

  void setLocation(String? cityId, List<String> districtIds) {
    _selectedCityId = cityId;
    _selectedDistrictIds = districtIds;
    _applyFilters();
    notifyListeners();
  }

  void setShowOnlyRecruiting(bool showOnly) {
    _showOnlyRecruiting = showOnly;
    _applyFilters();
    notifyListeners();
  }

  void setShowOnlyFollowing(bool showOnly) {
    _showOnlyFollowing = showOnly;
    _applyFilters();
    notifyListeners();
  }

  // 필터 적용
  void _applyFilters() {
    List<Matching> filtered = List.from(_mockMatchings);

    // 검색어 필터
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((matching) =>
          matching.courtName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          matching.host.nickname.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          matching.gameType.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // 게임 타입 필터
    if (_selectedGameTypes.isNotEmpty) {
      filtered = filtered.where((matching) =>
          _selectedGameTypes.contains(matching.gameType)
      ).toList();
    }

    // 실력 레벨 필터
    if (_selectedSkillLevel != null) {
      final minLevel = int.tryParse(_selectedSkillLevel!) ?? 0;
      filtered = filtered.where((matching) =>
          (matching.minLevel ?? 0) >= minLevel
      ).toList();
    }

    if (_selectedEndSkillLevel != null) {
      final maxLevel = int.tryParse(_selectedEndSkillLevel!) ?? 10;
      filtered = filtered.where((matching) =>
          (matching.maxLevel ?? 10) <= maxLevel
      ).toList();
    }

    // 연령대 필터
    if (!_noAgeRestriction && _selectedAgeRanges.isNotEmpty) {
      filtered = filtered.where((matching) {
        if (matching.minAge == null || matching.maxAge == null) return false;
        
        for (String ageRange in _selectedAgeRanges) {
          final age = int.tryParse(ageRange) ?? 0;
          if (matching.minAge! <= age && matching.maxAge! >= age) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    // 날짜 필터
    if (_startDate != null) {
      filtered = filtered.where((matching) =>
          matching.date.isAfter(_startDate!) || matching.date.isAtSameMomentAs(_startDate!)
      ).toList();
    }

    if (_endDate != null) {
      filtered = filtered.where((matching) =>
          matching.date.isBefore(_endDate!) || matching.date.isAtSameMomentAs(_endDate!)
      ).toList();
    }

    // 시간 필터
    if (_startTime != null) {
      filtered = filtered.where((matching) =>
          matching.timeSlot.compareTo(_startTime!) >= 0
      ).toList();
    }

    if (_endTime != null) {
      filtered = filtered.where((matching) =>
          matching.timeSlot.compareTo(_endTime!) <= 0
      ).toList();
    }

    // 모집중만 보기 필터
    if (_showOnlyRecruiting) {
      filtered = filtered.where((matching) =>
          matching.status == 'recruiting'
      ).toList();
    }

    // 팔로잉만 보기 필터 (실제로는 팔로잉 관계 확인 필요)
    if (_showOnlyFollowing) {
      // TODO: 실제 팔로잉 관계 확인 로직 구현
    }

    // 상태별 필터
    switch (_selectedFilter) {
      case 'recruiting':
        filtered = filtered.where((matching) => matching.status == 'recruiting').toList();
        break;
      case 'confirmed':
        filtered = filtered.where((matching) => matching.status == 'confirmed').toList();
        break;
      case 'completed':
        filtered = filtered.where((matching) => matching.status == 'completed').toList();
        break;
      case 'cancelled':
        filtered = filtered.where((matching) => matching.status == 'cancelled').toList();
        break;
      case 'my_matchings':
        // TODO: 현재 사용자의 매칭만 필터링
        break;
    }

    _filteredMatchings = filtered;
  }

  // 매칭 상태 변경
  void changeMatchingStatus(int matchingId, String newStatus) {
    final index = _mockMatchings.indexWhere((m) => m.id == matchingId);
    if (index != -1) {
      final matching = _mockMatchings[index];
      
      // 취소된 매칭을 모집중으로 복구할 때 복구 횟수 증가
      final newRecoveryCount = newStatus == 'recruiting' && matching.status == 'cancelled' 
          ? (matching.recoveryCount ?? 0) + 1 
          : matching.recoveryCount;
      
      _mockMatchings[index] = matching.copyWith(
        status: newStatus,
        recoveryCount: newRecoveryCount,
        updatedAt: DateTime.now(),
      );
      
      _applyFilters();
      notifyListeners();
    }
  }

  // 새 매칭 추가
  void addNewMatching(Matching newMatching) {
    _mockMatchings.insert(0, newMatching);
    _applyFilters();
    notifyListeners();
  }

  // 매칭 데이터 새로고침
  Future<void> refreshMatchingData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 실제로는 API 호출을 통해 최신 데이터를 가져옴
      await Future.delayed(const Duration(milliseconds: 500));
      
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
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 새로운 매칭 추가 시뮬레이션
  void _simulateNewMatching() {
    final newMatching = _createMockMatching(
      id: DateTime.now().millisecondsSinceEpoch,
      courtName: '새로운 코트 ${DateTime.now().hour}',
      date: DateTime.now().add(const Duration(days: 1)),
    );
    
    addNewMatching(newMatching);
  }

  // 상태 변경 시뮬레이션
  void _simulateStatusChange() {
    if (_mockMatchings.isNotEmpty) {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % _mockMatchings.length;
      final matching = _mockMatchings[randomIndex];
      
      if (matching.status == 'recruiting') {
        changeMatchingStatus(matching.id, 'confirmed');
      }
    }
  }

  // 완료된 매칭 체크 및 업데이트
  void _checkAndUpdateCompletedMatchings() {
    final now = DateTime.now();
    bool hasUpdates = false;
    
    for (int i = 0; i < _mockMatchings.length; i++) {
      final matching = _mockMatchings[i];
      
      // 자동 확정 체크: 모집중 상태이고 모집 인원이 다 찬 경우
      if (matching.status == 'recruiting' && _shouldAutoConfirm(matching)) {
        _mockMatchings[i] = matching.copyWith(
          status: 'confirmed',
          updatedAt: now,
        );
        hasUpdates = true;
      }
      
      // 확정 상태이고 게임 시간이 종료된 경우
      if (matching.status == 'confirmed' && _isGameTimeEnded(matching, now)) {
        _mockMatchings[i] = matching.copyWith(
          status: 'completed',
          completedAt: now,
          updatedAt: now,
        );
        hasUpdates = true;
      }
    }
    
    if (hasUpdates) {
      _applyFilters();
      notifyListeners();
    }
  }

  // 자동 확정 여부 확인
  bool _shouldAutoConfirm(Matching matching) {
    final totalRecruitCount = matching.maleRecruitCount + matching.femaleRecruitCount;
    final confirmedCount = matching.confirmedUserIds?.length ?? 0;
    return confirmedCount >= totalRecruitCount;
  }

  // 게임 시간 종료 여부 확인
  bool _isGameTimeEnded(Matching matching, DateTime now) {
    final gameEndTime = _getGameEndTime(matching);
    return now.isAfter(gameEndTime);
  }

  // 게임 종료 시간 계산
  DateTime _getGameEndTime(Matching matching) {
    final timeSlot = matching.timeSlot;
    final endTimeStr = timeSlot.split('~')[1];
    final endHour = int.tryParse(endTimeStr.split(':')[0]) ?? 12;
    final endMinute = int.tryParse(endTimeStr.split(':')[1]) ?? 0;
    
    return DateTime(
      matching.date.year,
      matching.date.month,
      matching.date.day,
      endHour,
      endMinute,
    );
  }

  // Mock 매칭 데이터 생성
  List<Matching> _createMockMatchings() {
    final now = DateTime.now();
    final List<Matching> matchings = [];

    // 다양한 매칭 데이터 생성
    for (int i = 1; i <= 20; i++) {
      final matching = _createMockMatching(
        id: i,
        courtName: '테니스 코트 $i',
        date: now.add(Duration(days: i % 7)),
        gameType: ['mixed', 'male_doubles', 'female_doubles', 'singles'][i % 4],
        status: ['recruiting', 'confirmed', 'completed', 'cancelled'][i % 4],
      );
      matchings.add(matching);
    }

    return matchings;
  }

  // 개별 Mock 매칭 생성
  Matching _createMockMatching({
    required int id,
    required String courtName,
    required DateTime date,
    String gameType = 'mixed',
    String status = 'recruiting',
    int maleRecruitCount = 2,
    int femaleRecruitCount = 2,
    int minLevel = 1,
    int maxLevel = 5,
    int? minAge,
    int? maxAge,
    bool isFollowersOnly = false,
  }) {
    final host = User(
      id: id + 1000,
      email: 'host$id@example.com',
      nickname: '호스트$id',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Matching(
      id: id,
      type: 'host',
      courtName: courtName,
      courtLat: 37.5665 + (id * 0.001),
      courtLng: 126.9780 + (id * 0.001),
      date: date,
      timeSlot: '10:00~12:00',
      minLevel: minLevel,
      maxLevel: maxLevel,
      minAge: minAge,
      maxAge: maxAge,
      gameType: gameType,
      maleRecruitCount: maleRecruitCount,
      femaleRecruitCount: femaleRecruitCount,
      status: status,
      isFollowersOnly: isFollowersOnly,
      host: host,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      recoveryCount: 0,
    );
  }

  // 필터 초기화
  void resetFilters() {
    _selectedFilter = 'all';
    _searchQuery = '';
    _selectedGameTypes = [];
    _selectedSkillLevel = null;
    _selectedEndSkillLevel = null;
    _selectedAgeRanges = [];
    _noAgeRestriction = false;
    _startDate = null;
    _endDate = null;
    _startTime = null;
    _endTime = null;
    _selectedCityId = null;
    _selectedDistrictIds = [];
    _showOnlyRecruiting = false;
    _showOnlyFollowing = false;
    
    _applyFilters();
    notifyListeners();
  }

  // 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
