import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SimpleFilterModal extends StatefulWidget {
  final bool showOnlyRecruiting;
  final List<String> selectedGameTypes;
  final String? selectedSkillLevel;
  final List<String> selectedAgeRanges;
  final String? startTime;
  final String? endTime;
  final Function(bool, List<String>, String?, List<String>, String?, String?) onApply;

  const SimpleFilterModal({
    super.key,
    required this.showOnlyRecruiting,
    required this.selectedGameTypes,
    required this.selectedSkillLevel,
    required this.selectedAgeRanges,
    required this.startTime,
    required this.endTime,
    required this.onApply,
  });

  @override
  State<SimpleFilterModal> createState() => _SimpleFilterModalState();
}

class _SimpleFilterModalState extends State<SimpleFilterModal> {
  late bool _showOnlyRecruiting;
  late List<String> _selectedGameTypes;
  late String? _selectedSkillLevel;
  late List<String> _selectedAgeRanges;
  late String? _startTime;
  late String? _endTime;

  @override
  void initState() {
    super.initState();
    _showOnlyRecruiting = widget.showOnlyRecruiting;
    _selectedGameTypes = List.from(widget.selectedGameTypes);
    _selectedSkillLevel = widget.selectedSkillLevel;
    _selectedAgeRanges = List.from(widget.selectedAgeRanges);
    _startTime = widget.startTime;
    _endTime = widget.endTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '필터 설정',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('초기화'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('적용'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 필터 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 모집중만 보기
                  _buildFilterSection(
                    title: '모집 상태',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            label: '모집중만',
                            isSelected: _showOnlyRecruiting,
                            onTap: () {
                              setState(() {
                                _showOnlyRecruiting = !_showOnlyRecruiting;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 게임 유형
                  _buildFilterSection(
                    title: '게임 유형',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'mixed', 'male_doubles', 'female_doubles', 'singles'
                      ].map((gameType) {
                        final isSelected = _selectedGameTypes.contains(gameType);
                        return _buildFilterChip(
                          label: _getGameTypeLabel(gameType),
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGameTypes.remove(gameType);
                              } else {
                                _selectedGameTypes.add(gameType);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 구력
                  _buildFilterSection(
                    title: '구력',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '6개월', '1년', '2년', '3년', '4년', '5년', '6년+'
                      ].map((skill) {
                        final isSelected = _selectedSkillLevel == skill;
                        return _buildFilterChip(
                          label: skill,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedSkillLevel = isSelected ? null : skill;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 연령대
                  _buildFilterSection(
                    title: '연령대',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '20대', '30대', '40대', '50대+'
                      ].map((ageRange) {
                        final isSelected = _selectedAgeRanges.contains(ageRange);
                        return _buildFilterChip(
                          label: ageRange,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedAgeRanges.remove(ageRange);
                              } else {
                                _selectedAgeRanges.add(ageRange);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 시간대
                  _buildFilterSection(
                    title: '시간대',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '오전 (06:00-12:00)', '오후 (12:00-18:00)', '저녁 (18:00-24:00)'
                      ].map((timeSlot) {
                        final isSelected = _startTime != null && 
                            ((timeSlot.contains('오전') && _startTime!.startsWith('06')) ||
                             (timeSlot.contains('오후') && _startTime!.startsWith('12')) ||
                             (timeSlot.contains('저녁') && _startTime!.startsWith('18')));
                        return _buildFilterChip(
                          label: timeSlot,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (timeSlot.contains('오전')) {
                                _startTime = isSelected ? null : '06:00';
                                _endTime = isSelected ? null : '12:00';
                              } else if (timeSlot.contains('오후')) {
                                _startTime = isSelected ? null : '12:00';
                                _endTime = isSelected ? null : '18:00';
                              } else if (timeSlot.contains('저녁')) {
                                _startTime = isSelected ? null : '18:00';
                                _endTime = isSelected ? null : '24:00';
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5E5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  String _getGameTypeLabel(String gameType) {
    switch (gameType) {
      case 'mixed': return '혼복';
      case 'male_doubles': return '남복';
      case 'female_doubles': return '여복';
      case 'singles': return '단식';
      default: return gameType;
    }
  }

  void _resetFilters() {
    setState(() {
      _showOnlyRecruiting = false;
      _selectedGameTypes.clear();
      _selectedSkillLevel = null;
      _selectedAgeRanges.clear();
      _startTime = null;
      _endTime = null;
    });
  }

  void _applyFilters() {
    widget.onApply(
      _showOnlyRecruiting,
      _selectedGameTypes,
      _selectedSkillLevel,
      _selectedAgeRanges,
      _startTime,
      _endTime,
    );
    Navigator.pop(context);
  }
}
