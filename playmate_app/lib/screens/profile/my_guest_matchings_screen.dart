import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../matching/matching_detail_screen.dart';
import '../review/write_review_screen.dart';

class MyGuestMatchingsScreen extends StatefulWidget {
  final User currentUser;

  const MyGuestMatchingsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<MyGuestMatchingsScreen> createState() => _MyGuestMatchingsScreenState();
}

class _MyGuestMatchingsScreenState extends State<MyGuestMatchingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Matching> _myGuestMatchings = [];
  bool _isLoading = true;
  
  // 캘린더 관련 상태
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime(2025, 9, 1);
  DateTime? _selectedDay;
  Map<DateTime, List<Matching>> _events = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMyGuestMatchings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 게스트로 참여한 매칭 데이터 로드 (실제 매칭 데이터 기반)
  void _loadMyGuestMatchings() async {
    try {
      setState(() => _isLoading = true);
      
      // 실제 매칭 데이터 가져오기
      final token = await _getAuthToken();
      if (token != null) {
        // 내가 게스트로 참여한 매칭 가져오기
        final matchings = await ApiService.getMyMatchings(token);
        final guestMatchings = matchings.where((m) => 
          m.guests?.any((guest) => guest.id == widget.currentUser.id) ?? false
        ).toList();
        
        
        setState(() {
          _myGuestMatchings = guestMatchings;
          _isLoading = false;
        });
        
        // 캘린더 이벤트 설정
        _updateCalendarEvents();
      } else {
        setState(() {
          _myGuestMatchings = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('게스트 매칭 로드 실패: $e');
      setState(() {
        _myGuestMatchings = [];
        _isLoading = false;
      });
    }
  }
  
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      return null;
    }
  }
  
  // Mock 데이터 완전 제거됨

  // 캘린더 이벤트 업데이트
  void _updateCalendarEvents() {
    _events.clear();
    
    for (final matching in _myGuestMatchings) {
      // 날짜를 정규화하여 시간 정보 제거
      final date = DateTime.utc(
        matching.date.year,
        matching.date.month,
        matching.date.day,
      );
      
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add(matching);
    }
    
    // 캘린더 리빌드 강제
    setState(() {});
  }

  // 상태별 매칭 필터링
  List<Matching> _getMatchingsByStatus(String status) {
    return _myGuestMatchings.where((matching) => matching.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내가 참여한 일정'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '캘린더'),
            Tab(text: '완료된 일정'),
            Tab(text: '확정된 일정'),
            Tab(text: '참여 신청중'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarView(),
                _buildMatchingList(_getMatchingsByStatus('completed'), '완료'),
                _buildMatchingList(_getMatchingsByStatus('confirmed'), '확정'),
                _buildMatchingList(_getMatchingsByStatus('recruiting'), '참여중'),
              ],
            ),
    );
  }

  Widget _buildMatchingList(List<Matching> matchings, String status) {
    if (matchings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'recruiting' ? Icons.people_outline : 
              status == 'confirmed' ? Icons.check_circle : Icons.done_all,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '$status 매칭이 없습니다',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == 'recruiting' ? '새로운 매칭에 참여해보세요!' :
              status == 'confirmed' ? '곧 게임이 시작됩니다!' : '완료된 매칭입니다!',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matchings.length,
      itemBuilder: (context, index) {
        final matching = matchings[index];
        return _buildMatchingCard(matching);
      },
    );
  }

  Widget _buildMatchingCard(Matching matching) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MatchingDetailScreen(
                matching: matching,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 코트명과 상태
              Row(
                children: [
                  Expanded(
                    child: Text(
                      matching.courtName,
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(matching.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(matching.status),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 호스트 정보
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '호스트: ${matching.host.nickname}',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 중간: 날짜, 시간, 게임 유형
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${matching.date.month}월 ${matching.date.day}일',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    matching.timeSlot,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.sports_tennis, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    matching.gameTypeText,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${matching.maleRecruitCount + matching.femaleRecruitCount}명 모집',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              
              // 하단: 구력 범위
              if (matching.minLevel != null || matching.maxLevel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      matching.skillRangeText,
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              
              // 게스트 비용 (있는 경우)
              if (matching.guestCost != null && matching.guestCost! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '참여비: ${matching.guestCost}원',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              
              // 후기 작성 버튼 (완료된 매칭에만)
              if (matching.status == 'completed') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToWriteReview(matching),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('후기 작성하기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 상태별 색상 반환
  Color _getStatusColor(String status) {
    switch (status) {
      case 'recruiting':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  // 상태별 텍스트 반환
  String _getStatusText(String status) {
    switch (status) {
      case 'recruiting':
        return '참여중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return '알 수 없음';
    }
  }



  // 후기 작성 화면으로 이동
  void _navigateToWriteReview(Matching matching) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          targetUser: matching.host,
          matching: matching,
        ),
      ),
    );
  }

  // 캘린더 뷰 빌드
  Widget _buildCalendarView() {
    return Column(
      children: [
        // 캘린더
        TableCalendar<Matching>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            // 날짜를 정규화하여 시간 정보 제거
            final normalizedDay = DateTime.utc(day.year, day.month, day.day);
            return _events[normalizedDay] ?? [];
          },
          startingDayOfWeek: StartingDayOfWeek.sunday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: AppTextStyles.body.copyWith(
              color: AppColors.primary,
            ),
            defaultTextStyle: AppTextStyles.body,
            selectedTextStyle: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            todayTextStyle: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 10,
            markersAlignment: Alignment.bottomCenter,
            markerSize: 6.0,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            formatButtonTextStyle: AppTextStyles.caption.copyWith(
              color: Colors.white,
            ),
            titleTextStyle: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
        ),
        
        const SizedBox(height: 16),
        
        // 선택된 날짜의 매칭 목록
        Expanded(
          child: _buildSelectedDayEvents(),
        ),
      ],
    );
  }

  // 선택된 날짜의 이벤트 목록
  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '날짜를 선택해주세요',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '캘린더에서 매칭 일정을 확인할 수 있습니다',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final events = _events[_selectedDay!] ?? [];
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '선택한 날짜에 일정이 없습니다',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_selectedDay!.year}년 ${_selectedDay!.month}월 ${_selectedDay!.day}일 일정',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final matching = events[index];
              return _buildMatchingCard(matching);
            },
          ),
        ),
      ],
    );
  }
}
