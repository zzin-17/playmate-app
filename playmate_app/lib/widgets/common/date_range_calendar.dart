import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class DateRangeCalendar extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime? start, DateTime? end) onDateRangeChanged;
  final DateTime? initialDate;

  const DateRangeCalendar({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
    this.initialDate,
  });

  @override
  State<DateRangeCalendar> createState() => _DateRangeCalendarState();
}

class _DateRangeCalendarState extends State<DateRangeCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '날짜와 시간을 선택해 주세요.',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // 월 네비게이션
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
                icon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
              ),
              Text(
                '${_focusedDay.year}.${_focusedDay.month}',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
                icon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 요일 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: day == '일' ? Colors.red : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 캘린더 그리드
        _buildCalendarGrid(),
        
        const SizedBox(height: 24),
        
        // 선택된 날짜 범위 표시
        if (_selectedStartDate != null || _selectedEndDate != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDateRangeText(),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_selectedStartDate != null || _selectedEndDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStartDate = null;
                        _selectedEndDate = null;
                      });
                      widget.onDateRangeChanged(null, null);
                    },
                    child: Text(
                      '초기화',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    // 이전 달의 마지막 날들
    final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 0);
    final prevMonthDays = prevMonth.day;
    
    List<Widget> calendarDays = [];
    
    // 이전 달의 날들
    for (int i = firstWeekday - 1; i > 0; i--) {
      final day = prevMonthDays - i + 1;
      calendarDays.add(_buildDayCell(day, isCurrentMonth: false));
    }
    
    // 현재 달의 날들
    for (int day = 1; day <= daysInMonth; day++) {
      calendarDays.add(_buildDayCell(day, isCurrentMonth: true));
    }
    
    // 다음 달의 날들 (7의 배수로 맞추기)
    final remainingDays = 42 - calendarDays.length; // 6주 * 7일 = 42
    for (int day = 1; day <= remainingDays; day++) {
      calendarDays.add(_buildDayCell(day, isCurrentMonth: false));
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              return Expanded(child: calendarDays[weekIndex * 7 + dayIndex]);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(int day, {required bool isCurrentMonth}) {
    final currentDate = DateTime(_focusedDay.year, _focusedDay.month, day);
    final isToday = _isToday(currentDate);
    final isSelected = _isDateSelected(currentDate);
    final isInRange = _isDateInRange(currentDate);
    final isSunday = currentDate.weekday == 7;
    final isHoliday = _isHoliday(currentDate);
    
    Color textColor = AppColors.textPrimary;
    Color backgroundColor = Colors.transparent;
    
    if (!isCurrentMonth) {
      textColor = AppColors.textSecondary.withValues(alpha: 0.3);
    } else if (isToday) {
      textColor = Colors.white;
      backgroundColor = AppColors.primary;
    } else if (isSelected) {
      textColor = Colors.white;
      backgroundColor = AppColors.accent;
    } else if (isInRange) {
      textColor = AppColors.primary;
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
    } else if (isSunday || isHoliday) {
      textColor = Colors.red;
    }
    
    return GestureDetector(
      onTap: isCurrentMonth ? () => _onDaySelected(currentDate) : null,
      child: Container(
        height: 50,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: AppTextStyles.body.copyWith(
                color: textColor,
                fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isToday)
              Text(
                '오늘',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            if (isHoliday)
              Text(
                _getHolidayName(currentDate),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.red,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isDateSelected(DateTime date) {
    return (_selectedStartDate != null && _isSameDay(date, _selectedStartDate!)) ||
           (_selectedEndDate != null && _isSameDay(date, _selectedEndDate!));
  }

  bool _isDateInRange(DateTime date) {
    if (_selectedStartDate == null || _selectedEndDate == null) return false;
    return date.isAfter(_selectedStartDate!.subtract(const Duration(days: 1))) &&
           date.isBefore(_selectedEndDate!.add(const Duration(days: 1)));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  bool _isHoliday(DateTime date) {
    // 간단한 공휴일 체크 (8월 15일 광복절)
    return date.month == 8 && date.day == 15;
  }

  String _getHolidayName(DateTime date) {
    if (date.month == 8 && date.day == 15) return '광복절';
    return '';
  }

  void _onDaySelected(DateTime selectedDate) {
    setState(() {
      if (_selectedStartDate == null) {
        _selectedStartDate = selectedDate;
        _selectedEndDate = null;
      } else if (_selectedEndDate == null) {
        if (selectedDate.isBefore(_selectedStartDate!)) {
          _selectedEndDate = _selectedStartDate;
          _selectedStartDate = selectedDate;
        } else {
          _selectedEndDate = selectedDate;
        }
      } else {
        _selectedStartDate = selectedDate;
        _selectedEndDate = null;
      }
    });
    
    widget.onDateRangeChanged(_selectedStartDate, _selectedEndDate);
  }

  String _getDateRangeText() {
    if (_selectedStartDate != null && _selectedEndDate != null) {
      return '${_selectedStartDate!.month}월 ${_selectedStartDate!.day}일 ~ ${_selectedEndDate!.month}월 ${_selectedEndDate!.day}일';
    } else if (_selectedStartDate != null) {
      return '${_selectedStartDate!.month}월 ${_selectedStartDate!.day}일부터';
    } else if (_selectedEndDate != null) {
      return '${_selectedEndDate!.month}월 ${_selectedEndDate!.day}일까지';
    }
    return '날짜를 선택해주세요';
  }
}
