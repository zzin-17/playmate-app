import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../matching/create_matching_screen.dart';
import '../matching/matching_detail_screen.dart';
import '../profile/my_profile_screen.dart';

import '../../widgets/common/app_logo.dart';
import '../../widgets/common/date_range_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // 필터 관련 변수들
  final List<String> _selectedFilters = [];
  List<String> _selectedGameTypes = [];
  String? _selectedSkillLevel;
  String? _selectedEndSkillLevel;
  bool _showOnlyRecruiting = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startTime;
  String? _endTime;

  // 임시 데이터 (실제로는 API에서 가져올 예정)
  final List<Matching> _mockMatchings = [
    Matching(
      id: 1,
      type: 'host',
      courtName: '잠실종합운동장',
      courtLat: 37.512,
      courtLng: 127.102,
      date: DateTime.now().add(const Duration(days: 1)),
      timeSlot: '18:00~20:00',
      minLevel: 2,
      maxLevel: 4,
      genderPreference: 'any',
      gameType: 'mixed',
      maleRecruitCount: 1,
      femaleRecruitCount: 1,
      status: 'recruiting',
      host: User(
        id: 1,
        email: 'host@example.com',
        nickname: '테린이',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Matching(
      id: 2,
      type: 'host',
      courtName: '양재시민의숲',
      courtLat: 37.469,
      courtLng: 127.038,
      date: DateTime.now().add(const Duration(days: 2)),
      timeSlot: '20:00~22:00',
      minLevel: 3,
      maxLevel: 5,
      genderPreference: 'male',
      gameType: 'male_doubles',
      maleRecruitCount: 2,
      femaleRecruitCount: 0,
      status: 'recruiting',
      host: User(
        id: 2,
        email: 'player@example.com',
        nickname: '테니스마스터',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 28),
        centerTitle: true,
        actions: [
          // 프로필/로그아웃 메뉴
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.person_outline),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await context.read<AuthProvider>().logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  } else if (value == 'profile') {
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyProfileScreen()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('내 프로필'),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('로그아웃'),
                  ),
                ],
              );
            },
          ),
          // 필터 버튼
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                        GestureDetector(
                          onTap: () {
                            _showFilterBottomSheet(context);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '적용된 필터',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
                              _showOnlyRecruiting = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            '모두 해제',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterGroups(),
                ],
              ),
            ),
          // 매칭 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getFilteredMatchings().length,
              itemBuilder: (context, index) {
                final matching = _getFilteredMatchings()[index];
                return _buildMatchingCard(matching);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final auth = context.read<AuthProvider>();
          if (!auth.isLoggedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('로그인이 필요합니다.')),
            );
            if (!mounted) return;
            Navigator.of(context).pushNamed('/login');
            return;
          }

          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateMatchingScreen()),
          );
          
          // 매칭이 생성되면 리스트에 추가
          if (result != null && result is Matching) {
            setState(() {
              _mockMatchings.insert(0, result); // 새 매칭을 맨 위에 추가
            });
            
            // 성공 메시지 표시
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('매칭이 생성되었습니다!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.person_add),
        label: const Text('게스트 모집'),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // TODO: 탭 네비게이션 구현
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '코트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: '중고거래',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
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

  // 매칭 삭제 메서드
  void _deleteMatching(Matching matching) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('매칭 삭제'),
          content: const Text('정말로 이 매칭을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _mockMatchings.removeWhere((m) => m.id == matching.id);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('매칭이 삭제되었습니다.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              child: const Text('삭제', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

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
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 코트명, 상태 배지, 수정/삭제 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 코트명
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
                  // 오른쪽: 상태 배지와 버튼들
                  Row(
                    children: [
                      // 상태 배지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          matching.statusText,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // 호스트인 경우에만 수정/삭제 버튼 표시
                      if (isHost) ...[
                        const SizedBox(width: 8),
                        // 수정 버튼
                        GestureDetector(
                          onTap: () => _editMatching(matching),
                          child: Container(
                            padding: const EdgeInsets.all(4),
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
                        // 삭제 버튼
                        GestureDetector(
                          onTap: () => _deleteMatching(matching),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.delete,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                        ),
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
                  // 왼쪽 열
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 위치 정보
                        Row(
                          children: [
                            Icon(Icons.location_on, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '서울 송파구',
                                style: AppTextStyles.body,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 날짜
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                matching.formattedDate,
                                style: AppTextStyles.body,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 시간
                        Row(
                          children: [
                            Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                matching.formattedTime,
                                style: AppTextStyles.body,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // 오른쪽 열
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 34),
                        // 게임 유형과 구력
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
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '|',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                matching.skillRangeText,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 모집인원
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              matching.recruitCountText,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
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
    // 로컬 상태 변수들
    bool localShowOnlyRecruiting = _showOnlyRecruiting;
    List<String> localSelectedGameTypes = List.from(_selectedGameTypes);
    String? localSelectedSkillLevel = _selectedSkillLevel;
    String? localSelectedEndSkillLevel = _selectedEndSkillLevel;
    DateTime? localStartDate = _startDate;
    DateTime? localEndDate = _endDate;
    String? localStartTime = _startTime;
    String? localEndTime = _endTime;
    List<String> localSelectedFilters = List.from(_selectedFilters);
    
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
                              localStartDate = null;
                              localEndDate = null;
                              localStartTime = null;
                              localEndTime = null;
                              localShowOnlyRecruiting = false;
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
                            setState(() {
                              _showOnlyRecruiting = localShowOnlyRecruiting;
                              _selectedGameTypes = List.from(localSelectedGameTypes);
                              _selectedSkillLevel = localSelectedSkillLevel;
                              _selectedEndSkillLevel = localSelectedEndSkillLevel;
                              _startDate = localStartDate;
                              _endDate = localEndDate;
                              _startTime = localStartTime;
                              _endTime = localEndTime;
                              _selectedFilters.clear();
                              _selectedFilters.addAll(localSelectedFilters);
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            '닫기',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 모집중만 보기 필터
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            localShowOnlyRecruiting = !localShowOnlyRecruiting;
                            if (localShowOnlyRecruiting) {
                              if (!localSelectedFilters.contains('모집중만')) {
                                localSelectedFilters.add('모집중만');
                              }
                            } else {
                              localSelectedFilters.remove('모집중만');
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Checkbox(
                              value: localShowOnlyRecruiting,
                              onChanged: (value) {
                                setModalState(() {
                                  localShowOnlyRecruiting = value ?? false;
                                  if (localShowOnlyRecruiting) {
                                    if (!localSelectedFilters.contains('모집중만')) {
                                      localSelectedFilters.add('모집중만');
                                    }
                                  } else {
                                    localSelectedFilters.remove('모집중만');
                                  }
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Text(
                                '모집중인 매칭만 보기',
                                style: AppTextStyles.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                          final isSelected = localSelectedGameTypes.contains(type);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  localSelectedGameTypes.remove(type);
                                  localSelectedFilters.remove(_getGameTypeText(type));
                                } else {
                                  localSelectedGameTypes.add(type);
                                  if (!localSelectedFilters.contains(_getGameTypeText(type))) {
                                    localSelectedFilters.add(_getGameTypeText(type));
                                  }
                                }
                              });
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
                      const SizedBox(height: 24),
                      // 구력 범위 필터 (바 형태)
                      Text(
                        '구력 범위',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '최소 1년 ~ 최대 5년 선택 가능',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 구력 막대
                      Container(
                        height: 60,
                        child: Row(
                          children: List.generate(12, (index) {
                            final skillLevels = [
                              '6개월', '1년', '2년', '3년', '4년', '5년',
                              '6년', '7년', '8년', '9년', '10년', '10년+'
                            ];
                            final skillText = skillLevels[index];
                            
                            // 선택된 구력들 확인
                            final selectedSkills = _getSelectedSkillLevels(localSelectedSkillLevel, localSelectedEndSkillLevel);
                            final isSelected = selectedSkills.contains(skillText);
                            
                            return Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    skillText,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          if (localSelectedSkillLevel == null) {
                                            // 첫 번째 선택
                                            localSelectedSkillLevel = skillText;
                                            localSelectedFilters.add('${skillText}부터');
                                          } else if (localSelectedEndSkillLevel == null) {
                                            // 두 번째 선택 (범위 설정) - 좌우 모두 가능
                                            final startValue = _getSkillLevelValue(localSelectedSkillLevel!);
                                            final endValue = _getSkillLevelValue(skillText);
                                            final difference = (endValue - startValue).abs();
                                            
                                            if (difference > 0 && difference <= 5) {
                                              // 범위가 5년 이하인 경우
                                              if (endValue > startValue) {
                                                // 좌에서 우로 선택
                                                localSelectedEndSkillLevel = skillText;
                                                localSelectedFilters.add('${skillText}까지');
                                              } else {
                                                // 우에서 좌로 선택 - 시작과 끝을 바꿈
                                                localSelectedEndSkillLevel = localSelectedSkillLevel;
                                                localSelectedSkillLevel = skillText;
                                                localSelectedFilters.clear();
                                                localSelectedFilters.add('${skillText}부터');
                                                localSelectedFilters.add('${localSelectedEndSkillLevel}까지');
                                              }
                                            }
                                          } else {
                                            // 다시 시작
                                            localSelectedSkillLevel = skillText;
                                            localSelectedEndSkillLevel = null;
                                            localSelectedFilters.removeWhere((filter) => 
                                              filter.contains('부터') || filter.contains('까지'));
                                            localSelectedFilters.add('${skillText}부터');
                                          }
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 날짜 범위 필터 (새로운 캘린더 UI)
                      Text(
                        '날짜 범위',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DateRangeCalendar(
                          startDate: localStartDate,
                          endDate: localEndDate,
                          onDateRangeChanged: (start, end) {
                            setModalState(() {
                              localStartDate = start;
                              localEndDate = end;
                              
                              // 기존 날짜 관련 필터 제거
                              localSelectedFilters.removeWhere((filter) => 
                                filter.contains('월') && filter.contains('일')
                              );
                              
                              // 새로운 날짜 범위 필터 추가
                              if (start != null && end != null) {
                                final filterText = '${start.month}월 ${start.day}일 ~ ${end.month}월 ${end.day}일';
                                if (!localSelectedFilters.contains(filterText)) {
                                  localSelectedFilters.add(filterText);
                                }
                              } else if (start != null) {
                                final filterText = '${start.month}월 ${start.day}일부터';
                                if (!localSelectedFilters.contains(filterText)) {
                                  localSelectedFilters.add(filterText);
                                }
                              } else if (end != null) {
                                final filterText = '${end.month}월 ${end.day}일까지';
                                if (!localSelectedFilters.contains(filterText)) {
                                  localSelectedFilters.add(filterText);
                                }
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 시간 범위 필터 (막대 형태)
                      Text(
                        '시간 범위',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '최소 1시간 ~ 최대 3시간 선택 가능',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 시간 막대
                      Container(
                        height: 60,
                        child: Row(
                          children: List.generate(18, (index) {
                            final hour = index + 6; // 6시부터 23시까지
                            final timeText = hour < 12 
                              ? '오전 ${hour}시' 
                              : hour == 12 
                                ? '오후 12시' 
                                : '오후 ${hour - 12}시';
                            
                            // 선택된 시간들 확인
                            final selectedHours = _getSelectedTimeHours(localStartTime, localEndTime);
                            final isSelected = selectedHours.contains(hour);
                            
                            return Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    timeText,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          if (localStartTime == null) {
                                            // 첫 번째 선택
                                            localStartTime = '${hour.toString().padLeft(2, '0')}:00';
                                            localSelectedFilters.add('${hour}시부터');
                                          } else if (localEndTime == null) {
                                            // 두 번째 선택 (범위 설정) - 좌우 모두 가능
                                            final startHour = int.parse(localStartTime!.split(':')[0]);
                                            final difference = (hour - startHour).abs();
                                            
                                            if (difference > 0 && difference <= 3) {
                                              // 범위가 3시간 이하인 경우
                                              if (hour > startHour) {
                                                // 좌에서 우로 선택
                                                localEndTime = '${hour.toString().padLeft(2, '0')}:00';
                                                localSelectedFilters.add('${hour}시까지');
                                              } else {
                                                // 우에서 좌로 선택 - 시작과 끝을 바꿈
                                                localEndTime = localStartTime;
                                                localStartTime = '${hour.toString().padLeft(2, '0')}:00';
                                                localSelectedFilters.clear();
                                                localSelectedFilters.add('${hour}시부터');
                                                localSelectedFilters.add('${localEndTime!.split(':')[0]}시까지');
                                              }
                                            }
                                          } else {
                                            // 다시 시작
                                            localStartTime = '${hour.toString().padLeft(2, '0')}:00';
                                            localEndTime = null;
                                            localSelectedFilters.removeWhere((filter) => 
                                              filter.contains('시부터') || filter.contains('시까지'));
                                            localSelectedFilters.add('${hour}시부터');
                                          }
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (value) {
                              // 마감 시간 체크박스 (기능 추가 예정)
                            },
                            activeColor: AppColors.primary,
                          ),
                          Text(
                            '마감',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 게임 유형 텍스트 변환
  String _getGameTypeText(String type) {
    switch (type) {
      case 'mixed': return '혼복';
      case 'male_doubles': return '남복';
      case 'female_doubles': return '여복';
      case 'singles': return '단식';
      case 'rally': return '랠리';
      default: return type;
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
}