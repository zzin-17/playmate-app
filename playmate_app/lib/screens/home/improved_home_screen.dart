import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../models/matching.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/search_bar.dart' as custom;
import '../../widgets/home/filter_tabs.dart';
import '../../widgets/home/sort_and_filter_summary.dart';
import '../../widgets/home/matching_list.dart';
import '../../widgets/home/simple_filter_modal.dart';
import '../matching/matching_detail_screen.dart';
import '../matching/edit_matching_screen.dart';
import '../notification/notification_list_screen.dart';

class ImprovedHomeScreen extends StatefulWidget {
  final Matching? newMatching;
  final VoidCallback? onMatchingAdded;
  final Function(VoidCallback)? onRefreshCallbackSet;
  
  const ImprovedHomeScreen({
    super.key,
    this.newMatching,
    this.onMatchingAdded,
    this.onRefreshCallbackSet,
  });

  @override
  State<ImprovedHomeScreen> createState() => _ImprovedHomeScreenState();
}

class _ImprovedHomeScreenState extends State<ImprovedHomeScreen> with TickerProviderStateMixin {
  late TabController _filterTabController;
  final TextEditingController _searchController = TextEditingController();
  // 알림 서비스는 필요시에만 사용
  // final MatchingNotificationService _notificationService = MatchingNotificationService();

  // 탭 라벨과 인덱스 매핑
  final List<String> _tabLabels = [
    '전체',
    '모집중',
    '확정',
    '내가 만든',
    '참여중',
    '팔로우',
  ];

  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: _tabLabels.length, vsync: this);
    
    // MainScreen에 새로고침 콜백 등록
    _registerRefreshCallback();
    
    // Provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().initialize();
    });
  }

  @override
  void didUpdateWidget(ImprovedHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 새 매칭이 추가되면 처리
    if (widget.newMatching != null && oldWidget.newMatching != widget.newMatching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HomeProvider>().addMatching(widget.newMatching!);
          widget.onMatchingAdded?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _filterTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // MainScreen에 새로고침 콜백 등록
  void _registerRefreshCallback() {
    if (widget.onRefreshCallbackSet != null) {
      widget.onRefreshCallbackSet!(_refresh);
    }
  }

  // 새로고침
  void _refresh() {
    context.read<HomeProvider>().refresh();
  }

  // 검색 쿼리 변경
  void _onSearchChanged(String query) {
    context.read<HomeProvider>().updateSearchQuery(query);
  }

  // 검색 초기화
  void _onSearchClear() {
    _searchController.clear();
    context.read<HomeProvider>().updateSearchQuery('');
  }

  // 탭 변경
  void _onTabChanged(int index) {
    final homeProvider = context.read<HomeProvider>();
    
    switch (index) {
      case 0: // 전체
        homeProvider.resetFilters();
        break;
      case 1: // 모집중
        homeProvider.resetFilters();
        homeProvider.updateShowOnlyRecruiting(true);
        break;
      case 2: // 확정
        homeProvider.resetFilters();
        // 확정된 매칭만 보기 로직 추가 필요
        break;
      case 3: // 내가 만든
        homeProvider.resetFilters();
        // 내가 만든 매칭만 보기 로직 추가 필요
        break;
      case 4: // 참여중
        homeProvider.resetFilters();
        // 참여중인 매칭만 보기 로직 추가 필요
        break;
      case 5: // 팔로우
        homeProvider.resetFilters();
        homeProvider.updateShowOnlyFollowing(true);
        break;
    }
  }

  // 필터 모달 표시
  void _showFilterModal() {
    final homeProvider = context.read<HomeProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SimpleFilterModal(
        showOnlyRecruiting: homeProvider.showOnlyRecruiting,
        selectedGameTypes: homeProvider.selectedGameTypes,
        selectedSkillLevel: homeProvider.selectedSkillLevel,
        selectedAgeRanges: homeProvider.selectedAgeRanges,
        startTime: homeProvider.startTime,
        endTime: homeProvider.endTime,
        onApply: (showOnlyRecruiting, gameTypes, skillLevel, ageRanges, startTime, endTime) {
          homeProvider.updateShowOnlyRecruiting(showOnlyRecruiting);
          homeProvider.updateGameTypes(gameTypes);
          homeProvider.updateSkillLevel(skillLevel, null);
          homeProvider.updateAgeRanges(ageRanges);
          homeProvider.updateTimeRange(startTime, endTime);
        },
      ),
    );
  }

  // 정렬 다이얼로그 표시
  void _showSortDialog() {
    final homeProvider = context.read<HomeProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정렬 기준'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('latest', '최신순', homeProvider.sortBy),
            _buildSortOption('date', '날짜순', homeProvider.sortBy),
            _buildSortOption('level', '구력순', homeProvider.sortBy),
            _buildSortOption('participants', '참여자순', homeProvider.sortBy),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, String currentSort) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: currentSort,
      onChanged: (value) {
        if (value != null) {
          context.read<HomeProvider>().updateSorting(value, false);
          Navigator.pop(context);
        }
      },
    );
  }

  // 매칭 탭
  void _onMatchingTap(Matching matching) {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchingDetailScreen(
            matching: matching,
            currentUser: currentUser,
          ),
        ),
      );
    }
  }

  // 매칭 수정
  void _onMatchingEdit(Matching matching) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMatchingScreen(matching: matching),
      ),
    );
  }

  // 매칭 삭제
  void _onMatchingDelete(Matching matching) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매칭 삭제'),
        content: const Text('이 매칭을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<HomeProvider>().removeMatching(matching.id);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 알림 탭
  void _onNotificationTap() {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationListScreen(currentUser: currentUser),
        ),
      );
    }
  }

  // 필터 초기화
  void _onClearFilters() {
    context.read<HomeProvider>().resetFilters();
  }

  // 정렬 텍스트 가져오기
  String _getSortText(String sortBy) {
    switch (sortBy) {
      case 'latest': return '최신순';
      case 'date': return '날짜순';
      case 'level': return '구력순';
      case 'participants': return '참여자순';
      default: return '최신순';
    }
  }

  // 활성 필터 목록 가져오기
  List<String> _getActiveFilters(HomeProvider homeProvider) {
    List<String> filters = [];
    
    if (homeProvider.showOnlyRecruiting) {
      filters.add('모집중');
    }
    
    if (homeProvider.selectedGameTypes.isNotEmpty) {
      filters.addAll(homeProvider.selectedGameTypes.map((type) {
        switch (type) {
          case 'mixed': return '혼복';
          case 'male_doubles': return '남복';
          case 'female_doubles': return '여복';
          case 'singles': return '단식';
          default: return type;
        }
      }));
    }
    
    if (homeProvider.selectedSkillLevel != null) {
      filters.add('${homeProvider.selectedSkillLevel}년');
    }
    
    if (homeProvider.selectedAgeRanges.isNotEmpty) {
      filters.addAll(homeProvider.selectedAgeRanges);
    }
    
    return filters;
  }

  // 탭별 매칭 개수 계산
  List<int> _getTabCounts(HomeProvider homeProvider) {
    final allMatchings = homeProvider.matchings;
    final recruitingMatchings = allMatchings.where((m) => m.status == 'recruiting').length;
    final confirmedMatchings = allMatchings.where((m) => m.status == 'confirmed').length;
    // TODO: 내가 만든, 참여중, 팔로우 매칭 개수 계산 로직 추가
    
    return [
      allMatchings.length,
      recruitingMatchings,
      confirmedMatchings,
      0, // 내가 만든
      0, // 참여중
      0, // 팔로우
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<HomeProvider, AuthProvider>(
        builder: (context, homeProvider, authProvider, child) {
          final tabCounts = _getTabCounts(homeProvider);
          final activeFilters = _getActiveFilters(homeProvider);
          
          return Column(
            children: [
              // 헤더
              HomeHeader(
                isLoading: homeProvider.isLoading,
                unreadNotificationCount: 0, // TODO: 실제 알림 개수 연동
                onRefresh: _refresh,
                onNotificationTap: _onNotificationTap,
              ),
              
              // 검색 바
              custom.SearchBar(
                controller: _searchController,
                hintText: '테니스장, 지역으로 검색하세요',
                onFilterTap: _showFilterModal,
                onChanged: _onSearchChanged,
                onClear: _onSearchClear,
              ),
              
              // 필터 탭
              FilterTabs(
                controller: _filterTabController,
                tabLabels: _tabLabels,
                tabCounts: tabCounts,
                onTabChanged: _onTabChanged,
              ),
              
              // 정렬 및 필터 요약
              SortAndFilterSummary(
                sortText: _getSortText(homeProvider.sortBy),
                activeFilters: activeFilters,
                onSortTap: _showSortDialog,
                onFilterTap: _showFilterModal,
                onClearFilters: _onClearFilters,
              ),
              
              // 매칭 리스트
              Expanded(
                child: TabBarView(
                  controller: _filterTabController,
                  children: List.generate(_tabLabels.length, (index) {
                    return MatchingList(
                      matchings: homeProvider.filteredMatchings,
                      currentUser: authProvider.currentUser,
                      isLoading: homeProvider.isLoading,
                      error: homeProvider.error,
                      onRefresh: _refresh,
                      onMatchingTap: _onMatchingTap,
                      onMatchingEdit: _onMatchingEdit,
                      onMatchingDelete: _onMatchingDelete,
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
