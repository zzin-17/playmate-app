import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/common/app_button.dart';
import '../../models/matching.dart';
import '../../models/user.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/matching_data_service.dart';
import '../../models/tennis_court.dart';
import '../../providers/auth_provider.dart';
import 'court_selection_screen.dart';

class ImprovedCreateMatchingScreen extends StatefulWidget {
  final Matching? editingMatching;
  final User? currentUser;
  
  const ImprovedCreateMatchingScreen({
    super.key, 
    this.editingMatching, 
    this.currentUser
  });

  @override
  State<ImprovedCreateMatchingScreen> createState() => _ImprovedCreateMatchingScreenState();
}

class _ImprovedCreateMatchingScreenState extends State<ImprovedCreateMatchingScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _courtNameController = TextEditingController();
  final _messageController = TextEditingController();
  final _courtNameFocusNode = FocusNode();
  final _guestCostController = TextEditingController();
  
  // 테니스장 선택 관련
  TennisCourt? _selectedCourt;
  
  // 기본 설정값
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedStartTime = '18:00';
  String _selectedEndTime = '20:00';
  int? _selectedMinLevel;
  int? _selectedMaxLevel;
  String _selectedGameType = 'mixed';
  int _maleRecruitCount = 1;
  int _femaleRecruitCount = 1;
  bool _isFollowersOnly = false;
  List<String> _selectedAgeRanges = [];
  bool _noAgeRestriction = false;
  
  // 탭 컨트롤러
  late TabController _tabController;
  int _currentStep = 0;
  
  // 로딩 상태
  bool _isLoading = false;
  
  // 연령대 옵션들
  static const List<String> _ageOptions = [
    '10대', '20대', '30대', '40대', '50대', '60대~'
  ];

  final List<String> _timeOptions = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00',
    '20:00', '21:00', '22:00', '23:00'
  ];

  final List<Map<String, String>> _gameTypes = [
    {'value': 'mixed', 'label': '혼복'},
    {'value': 'male_doubles', 'label': '남복'},
    {'value': 'female_doubles', 'label': '여복'},
    {'value': 'singles', 'label': '단식'},
    {'value': 'rally', 'label': '랠리'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 편집 모드인 경우 기존 데이터 로드
    if (widget.editingMatching != null) {
      _loadExistingData();
    }
    
    // 키보드 및 입력 시스템 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _courtNameFocusNode.unfocus();
            setState(() {});
          }
        });
      }
    });
  }

  void _loadExistingData() {
    final matching = widget.editingMatching!;
    _courtNameController.text = matching.courtName;
    _selectedDate = matching.date;
    _selectedStartTime = matching.timeSlot.split('~')[0];
    _selectedEndTime = matching.timeSlot.split('~')[1];
    _selectedMinLevel = matching.minLevel;
    _selectedMaxLevel = matching.maxLevel;
    _selectedGameType = matching.gameType;
    _maleRecruitCount = matching.maleRecruitCount;
    _femaleRecruitCount = matching.femaleRecruitCount;
    _guestCostController.text = matching.guestCost?.toString() ?? '0';
    _messageController.text = matching.message ?? '';
  }

  @override
  void dispose() {
    _courtNameController.dispose();
    _messageController.dispose();
    _courtNameFocusNode.dispose();
    _guestCostController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 테니스장 선택 화면으로 이동
  Future<void> _selectCourt() async {
    final result = await Navigator.of(context).push<TennisCourt>(
      MaterialPageRoute(
        builder: (context) => CourtSelectionScreen(
          selectedCourt: _selectedCourt,
          onCourtSelected: (court) {
            setState(() {
              _selectedCourt = court;
              _courtNameController.text = court.name;
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCourt = result;
        _courtNameController.text = result.name;
      });
    }
  }

  // 다음 단계로 이동
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _tabController.animateTo(_currentStep);
    }
  }

  // 이전 단계로 이동
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _tabController.animateTo(_currentStep);
    }
  }

  // 매칭 생성/수정
  Future<void> _submitMatching() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final matchingData = {
        'courtName': _courtNameController.text.trim(),
        'courtLat': _selectedCourt?.lat ?? 37.5665,
        'courtLng': _selectedCourt?.lng ?? 126.978,
        'date': _selectedDate.toIso8601String(),
        'timeSlot': '$_selectedStartTime~$_selectedEndTime',
        'minLevel': _selectedMinLevel,
        'maxLevel': _selectedMaxLevel,
        'gameType': _selectedGameType,
        'maleRecruitCount': _maleRecruitCount,
        'femaleRecruitCount': _femaleRecruitCount,
        'guestCost': int.tryParse(_guestCostController.text) ?? 0,
        'message': _messageController.text.trim(),
        'isFollowersOnly': _isFollowersOnly,
        'minAge': _noAgeRestriction ? null : _getMinAgeFromRanges(),
        'maxAge': _noAgeRestriction ? null : _getMaxAgeFromRanges(),
      };

      Matching? newMatching;

      if (widget.editingMatching != null) {
        // 수정 모드
        final success = await MatchingDataService.updateMatching(
          widget.editingMatching!.id,
          matchingData,
        );
        if (success) {
          newMatching = widget.editingMatching!.copyWith(
            courtName: matchingData['courtName'] as String,
            courtLat: matchingData['courtLat'] as double,
            courtLng: matchingData['courtLng'] as double,
            date: DateTime.parse(matchingData['date'] as String),
            timeSlot: matchingData['timeSlot'] as String,
            minLevel: matchingData['minLevel'] as int?,
            maxLevel: matchingData['maxLevel'] as int?,
            gameType: matchingData['gameType'] as String,
            maleRecruitCount: matchingData['maleRecruitCount'] as int,
            femaleRecruitCount: matchingData['femaleRecruitCount'] as int,
            guestCost: matchingData['guestCost'] as int?,
            message: matchingData['message'] as String?,
            isFollowersOnly: matchingData['isFollowersOnly'] as bool?,
            minAge: matchingData['minAge'] as int?,
            maxAge: matchingData['maxAge'] as int?,
          );
        }
      } else {
        // 생성 모드
        newMatching = await MatchingDataService.createMatching(matchingData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editingMatching != null 
                ? '매칭이 수정되었습니다' 
                : '게스트 모집이 시작되었습니다!'
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(newMatching);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int? _getMinAgeFromRanges() {
    if (_selectedAgeRanges.isEmpty) return null;
    final ages = _selectedAgeRanges.map((range) {
      switch (range) {
        case '10대': return 10;
        case '20대': return 20;
        case '30대': return 30;
        case '40대': return 40;
        case '50대': return 50;
        case '60대~': return 60;
        default: return 0;
      }
    }).toList();
    return ages.reduce((a, b) => a < b ? a : b);
  }

  int? _getMaxAgeFromRanges() {
    if (_selectedAgeRanges.isEmpty) return null;
    final ages = _selectedAgeRanges.map((range) {
      switch (range) {
        case '10대': return 19;
        case '20대': return 29;
        case '30대': return 39;
        case '40대': return 49;
        case '50대': return 59;
        case '60대~': return 100;
        default: return 100;
      }
    }).toList();
    return ages.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.editingMatching != null ? '매칭 수정하기' : '게스트 모집하기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기본 정보', icon: Icon(Icons.info_outline)),
            Tab(text: '게임 설정', icon: Icon(Icons.sports_tennis)),
            Tab(text: '추가 옵션', icon: Icon(Icons.tune)),
          ],
          onTap: (index) {
            setState(() {
              _currentStep = index;
            });
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 진행 표시기
            _buildProgressIndicator(),
            
            // 탭 내용
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildGameSettingsTab(),
                  _buildAdditionalOptionsTab(),
                ],
              ),
            ),
            
            // 하단 버튼들
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.cardBorder,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? AppColors.primary : AppColors.cardBorder,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 코트 이름
          _buildCourtNameSection(),
          const SizedBox(height: 24),
          
          // 날짜 선택
          _buildDateSection(),
          const SizedBox(height: 24),
          
          // 시간대 선택
          _buildTimeSection(),
        ],
      ),
    );
  }

  Widget _buildGameSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 구력 범위
          _buildSkillLevelSection(),
          const SizedBox(height: 24),
          
          // 게임 유형
          _buildGameTypeSection(),
          const SizedBox(height: 24),
          
          // 모집 인원
          _buildRecruitCountSection(),
          const SizedBox(height: 24),
          
          // 연령대 선택
          _buildAgeRangeSection(),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 게스트비용
          _buildGuestCostSection(),
          const SizedBox(height: 24),
          
          // 팔로워 전용 설정
          _buildFollowersOnlySection(),
          const SizedBox(height: 24),
          
          // 메시지
          _buildMessageSection(),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                text: '이전',
                onPressed: _previousStep,
                type: ButtonType.secondary,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: _currentStep == 2 
                ? (widget.editingMatching != null ? '수정하기' : '모집하기')
                : '다음',
              onPressed: _currentStep == 2 ? _submitMatching : _nextStep,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  // 각 섹션 빌더들 (기존 코드에서 가져와서 정리)
  Widget _buildCourtNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '코트 이름 *',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _courtNameController,
          focusNode: _courtNameFocusNode,
          decoration: InputDecoration(
            hintText: '예: 잠실종합운동장',
            hintStyle: AppTextStyles.placeholder,
            prefixIcon: const Icon(Icons.location_on, color: AppColors.textSecondary),
            suffixIcon: GestureDetector(
              onTap: _selectCourt,
              child: const Icon(Icons.search, color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '코트 이름을 입력해주세요';
            }
            return null;
          },
        ),
        if (_selectedCourt != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCourt!.name,
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _selectedCourt!.address,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // 나머지 섹션들은 기존 코드에서 가져와서 구현...
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜 *',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                  style: AppTextStyles.input,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시간대 *',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimeDropdown('시작', _selectedStartTime, (value) {
                setState(() {
                  _selectedStartTime = value!;
                });
              }),
            ),
            const SizedBox(width: 12),
            const Text('~', style: AppTextStyles.body),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeDropdown('종료', _selectedEndTime, (value) {
                setState(() {
                  _selectedEndTime = value!;
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _timeOptions.map((time) {
        return DropdownMenuItem(
          value: time,
          child: Text(time),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // 나머지 섹션들도 비슷하게 구현...
  Widget _buildSkillLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '구력 범위 *',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedMinLevel,
                decoration: InputDecoration(
                  labelText: '최소',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                items: List.generate(6, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('${index}년'),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedMinLevel = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text('~', style: AppTextStyles.body),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedMaxLevel,
                decoration: InputDecoration(
                  labelText: '최대',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                items: List.generate(6, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('${index}년'),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedMaxLevel = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '게임 유형 *',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _gameTypes.map((gameType) {
            final isSelected = _selectedGameType == gameType['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGameType = gameType['value']!;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  gameType['label']!,
                  style: AppTextStyles.body2.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecruitCountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '모집 인원 *',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCountSelector('남성', _maleRecruitCount, (value) {
                setState(() {
                  _maleRecruitCount = value;
                });
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCountSelector('여성', _femaleRecruitCount, (value) {
                setState(() {
                  _femaleRecruitCount = value;
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountSelector(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$value명', style: AppTextStyles.body),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '연령대',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('연령 제한 없음'),
          value: _noAgeRestriction,
          onChanged: (value) {
            setState(() {
              _noAgeRestriction = value ?? false;
              if (_noAgeRestriction) {
                _selectedAgeRanges.clear();
              }
            });
          },
        ),
        if (!_noAgeRestriction) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ageOptions.map((age) {
              final isSelected = _selectedAgeRanges.contains(age);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedAgeRanges.remove(age);
                    } else {
                      _selectedAgeRanges.add(age);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    age,
                    style: AppTextStyles.body2.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGuestCostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '게스트 비용',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _guestCostController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '0',
            suffixText: '원',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowersOnlySection() {
    return CheckboxListTile(
      title: const Text('팔로워만 볼 수 있게 하기'),
      subtitle: const Text('나를 팔로우하는 사용자만 이 매칭을 볼 수 있습니다'),
      value: _isFollowersOnly,
      onChanged: (value) {
        setState(() {
          _isFollowersOnly = value ?? false;
        });
      },
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메시지',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '게스트들에게 전하고 싶은 메시지를 작성해주세요',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
