import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/matching.dart';
import '../models/location.dart';
import '../services/matching_data_service.dart';

class HomeProvider extends ChangeNotifier {
  // 매칭 데이터
  List<Matching> _matchings = [];
  List<Matching> _filteredMatchings = [];
  bool _isLoading = false;
  String? _error;

  // 필터 상태
  String _searchQuery = '';
  List<String> _selectedGameTypes = [];
  String? _selectedSkillLevel;
  String? _selectedEndSkillLevel;
  List<String> _selectedAgeRanges = [];
  bool _noAgeRestriction = false;
  bool _showOnlyRecruiting = false;
  bool _showOnlyFollowing = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startTime;
  String? _endTime;

  // 위치 필터
  List<Location> _locationData = [];
  String? _selectedCityId;
  List<String> _selectedDistrictIds = [];

  // 정렬 상태
  String _sortBy = 'latest';
  bool _sortAscending = false;

  // 타이머들
  Timer? _autoRefreshTimer;
  Timer? _debounceTimer;
  
  // 필터 상태 추적 (메모이제이션용)
  Map<String, dynamic> _lastFilterState = {};


  // Getters
  List<Matching> get matchings => _matchings;
  List<Matching> get filteredMatchings => _filteredMatchings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  List<String> get selectedGameTypes => _selectedGameTypes;
  String? get selectedSkillLevel => _selectedSkillLevel;
  String? get selectedEndSkillLevel => _selectedEndSkillLevel;
  List<String> get selectedAgeRanges => _selectedAgeRanges;
  bool get noAgeRestriction => _noAgeRestriction;
  bool get showOnlyRecruiting => _showOnlyRecruiting;
  bool get showOnlyFollowing => _showOnlyFollowing;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get startTime => _startTime;
  String? get endTime => _endTime;
  List<Location> get locationData => _locationData;
  String? get selectedCityId => _selectedCityId;
  List<String> get selectedDistrictIds => _selectedDistrictIds;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // 초기화
  void initialize() {
    _locationData = LocationData.cities;
    _selectedCityId = null;
    _selectedDistrictIds = [];
    loadMatchings();
    _startAutoRefreshTimer();
  }

  // 매칭 데이터 로딩
  Future<void> loadMatchings() async {
    _setLoading(true);
    _error = null;
    
    try {
      _matchings = await MatchingDataService.getMatchings(
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
      _sortMatchings();
      _error = null;
    } catch (e) {
      _error = _getUserFriendlyErrorMessage(e);
      // 에러 발생 시에도 기존 데이터 유지 (사용자 경험 개선)
      if (_matchings.isEmpty) {
        _matchings = [];
      }
    } finally {
      _setLoading(false);
    }
  }

  // 검색 쿼리 업데이트 (디바운싱 적용)
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      loadMatchings();
    });
  }

  // 필터 업데이트
  void updateGameTypes(List<String> gameTypes) {
    _selectedGameTypes = gameTypes;
    _applyFilters();
  }

  void updateSkillLevel(String? startLevel, String? endLevel) {
    _selectedSkillLevel = startLevel;
    _selectedEndSkillLevel = endLevel;
    _applyFilters();
  }

  void updateAgeRanges(List<String> ageRanges) {
    _selectedAgeRanges = ageRanges;
    _applyFilters();
  }

  void updateNoAgeRestriction(bool noRestriction) {
    _noAgeRestriction = noRestriction;
    _applyFilters();
  }

  void updateShowOnlyRecruiting(bool showOnly) {
    _showOnlyRecruiting = showOnly;
    _applyFilters();
  }

  void updateShowOnlyFollowing(bool showOnly) {
    _showOnlyFollowing = showOnly;
    _applyFilters();
  }

  void updateDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  void updateTimeRange(String? start, String? end) {
    _startTime = start;
    _endTime = end;
    _applyFilters();
  }

  void updateLocation(String? cityId, List<String> districtIds) {
    _selectedCityId = cityId;
    _selectedDistrictIds = districtIds;
    _applyFilters();
  }

  // 정렬 업데이트
  void updateSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _sortMatchings();
  }

  // 필터 적용 (메모이제이션 적용)
  void _applyFilters() {
    // 필터 상태가 변경되지 않았다면 기존 결과 재사용
    final currentFilterState = _getCurrentFilterState();
    // 필터 상태가 동일하면 재계산하지 않음
    if (_lastFilterState.toString() == currentFilterState.toString()) {
      return;
    }
    _lastFilterState = currentFilterState;
    
    List<Matching> filtered = List.from(_matchings);

    // 기본 조건: 완료되지 않은 매칭만 표시
    filtered = filtered.where((matching) => 
      matching.actualStatus != 'completed' && 
      matching.actualStatus != 'cancelled' && 
      matching.actualStatus != 'deleted'
    ).toList();

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
    if (_selectedSkillLevel != null || _selectedEndSkillLevel != null) {
      final startValue = _getSkillLevelFromText(_selectedSkillLevel);
      final endValue = _getSkillLevelFromText(_selectedEndSkillLevel);
      
      if (startValue != null && endValue != null) {
        filtered = filtered.where((matching) {
          final minLevel = matching.minLevel ?? 0;
          final maxLevel = matching.maxLevel ?? 10;
          return (minLevel <= endValue && maxLevel >= startValue);
        }).toList();
      } else if (startValue != null) {
        filtered = filtered.where((matching) => 
          (matching.maxLevel ?? 10) >= startValue
        ).toList();
      } else if (endValue != null) {
        filtered = filtered.where((matching) => 
          (matching.minLevel ?? 0) <= endValue
        ).toList();
      }
    }

    // 연령대 필터
    if (!_noAgeRestriction && _selectedAgeRanges.isNotEmpty) {
      final selectedMinAge = _getMinAgeFromRanges();
      final selectedMaxAge = _getMaxAgeFromRanges();
      
      if (selectedMinAge != null && selectedMaxAge != null) {
        filtered = filtered.where((matching) {
          final minAge = matching.minAge ?? 10;
          final maxAge = matching.maxAge ?? 60;
          return maxAge >= selectedMinAge && minAge <= selectedMaxAge;
        }).toList();
      }
    }

    // 날짜 범위 필터
    if (_startDate != null) {
      filtered = filtered.where((matching) => 
        !matching.date.isBefore(_startDate!)
      ).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((matching) => 
        !matching.date.isAfter(_endDate!)
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

    _filteredMatchings = filtered;
    notifyListeners();
  }

  // 정렬 적용
  void _sortMatchings() {
    _filteredMatchings.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'latest':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'level':
          final aLevel = (a.minLevel ?? 0) + (a.maxLevel ?? 0);
          final bLevel = (b.minLevel ?? 0) + (b.maxLevel ?? 0);
          comparison = aLevel.compareTo(bLevel);
          break;
        case 'participants':
          final aParticipants = a.maleRecruitCount + a.femaleRecruitCount;
          final bParticipants = b.maleRecruitCount + b.femaleRecruitCount;
          comparison = aParticipants.compareTo(bParticipants);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    notifyListeners();
  }

  // 필터 초기화
  void resetFilters() {
    _searchQuery = '';
    _selectedGameTypes.clear();
    _selectedSkillLevel = null;
    _selectedEndSkillLevel = null;
    _selectedAgeRanges.clear();
    _noAgeRestriction = false;
    _showOnlyRecruiting = false;
    _showOnlyFollowing = false;
    _startDate = null;
    _endDate = null;
    _startTime = null;
    _endTime = null;
    _selectedCityId = null;
    _selectedDistrictIds.clear();
    _applyFilters();
  }

  // 새 매칭 추가
  void addMatching(Matching matching) {
    _matchings.insert(0, matching);
    _applyFilters();
  }

  // 매칭 업데이트
  void updateMatching(Matching matching) {
    final index = _matchings.indexWhere((m) => m.id == matching.id);
    if (index != -1) {
      _matchings[index] = matching;
      _applyFilters();
    }
  }

  // 매칭 삭제
  void removeMatching(int matchingId) {
    _matchings.removeWhere((m) => m.id == matchingId);
    _applyFilters();
  }

  // 수동 새로고침
  Future<void> refresh() async {
    await loadMatchings();
  }

  // 매칭 새로고침 (별칭)
  Future<void> refreshMatchings() async {
    await loadMatchings();
  }

  // 자동 새로고침 타이머 시작
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isLoading) {
        loadMatchings();
      }
    });
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 필터 상태 가져오기 (메모이제이션용)
  Map<String, dynamic> _getCurrentFilterState() {
    return {
      'searchQuery': _searchQuery,
      'gameTypes': List.from(_selectedGameTypes),
      'skillLevel': _selectedSkillLevel,
      'endSkillLevel': _selectedEndSkillLevel,
      'ageRanges': List.from(_selectedAgeRanges),
      'noAgeRestriction': _noAgeRestriction,
      'showOnlyRecruiting': _showOnlyRecruiting,
      'showOnlyFollowing': _showOnlyFollowing,
      'startDate': _startDate?.millisecondsSinceEpoch,
      'endDate': _endDate?.millisecondsSinceEpoch,
      'startTime': _startTime,
      'endTime': _endTime,
      'cityId': _selectedCityId,
      'districtIds': List.from(_selectedDistrictIds),
      'matchingsLength': _matchings.length,
    };
  }

  // 사용자 친화적인 에러 메시지 생성
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('connection refused') || 
        errorString.contains('socketexception') ||
        errorString.contains('failed host lookup')) {
      return '서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
    } else if (errorString.contains('timeout')) {
      return '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
    } else if (errorString.contains('unauthorized') || 
               errorString.contains('401')) {
      return '로그인이 필요합니다. 다시 로그인해주세요.';
    } else if (errorString.contains('forbidden') || 
               errorString.contains('403')) {
      return '접근 권한이 없습니다.';
    } else if (errorString.contains('not found') || 
               errorString.contains('404')) {
      return '요청한 데이터를 찾을 수 없습니다.';
    } else if (errorString.contains('server error') || 
               errorString.contains('500')) {
      return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
    } else {
      return '데이터를 불러오는 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  // 유틸리티 메서드들
  int? _getSkillLevelFromText(String? text) {
    if (text == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  int? _getMinAgeFromRanges() {
    if (_selectedAgeRanges.isEmpty) return null;
    final ages = _selectedAgeRanges.map((range) {
      final match = RegExp(r'(\d+)대').firstMatch(range);
      return match != null ? int.tryParse(match.group(1)!) : null;
    }).where((age) => age != null).cast<int>().toList();
    return ages.isNotEmpty ? ages.reduce((a, b) => a < b ? a : b) : null;
  }

  int? _getMaxAgeFromRanges() {
    if (_selectedAgeRanges.isEmpty) return null;
    final ages = _selectedAgeRanges.map((range) {
      if (range.contains('+')) return 100;
      final match = RegExp(r'(\d+)대').firstMatch(range);
      return match != null ? int.tryParse(match.group(1)!) : null;
    }).where((age) => age != null).cast<int>().toList();
    return ages.isNotEmpty ? ages.reduce((a, b) => a > b ? a : b) : null;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
