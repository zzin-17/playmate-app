import 'package:flutter/material.dart';
import '../../models/matching.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../services/matching_data_service.dart';

class EditMatchingScreen extends StatefulWidget {
  final Matching matching;
  final VoidCallback? onMatchingUpdated;

  const EditMatchingScreen({
    super.key,
    required this.matching,
    this.onMatchingUpdated,
  });

  @override
  State<EditMatchingScreen> createState() => _EditMatchingScreenState();
}

class _EditMatchingScreenState extends State<EditMatchingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courtNameController = TextEditingController();
  final _messageController = TextEditingController();
  final _guestCostController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = '09:00-11:00';
  String _selectedGameType = 'mixed';
  int _maleRecruitCount = 1;
  int _femaleRecruitCount = 1;
  int? _minLevel;
  int? _maxLevel;
  int? _minAge;
  int? _maxAge;
  int? _guestCost;
  bool _isFollowersOnly = false;
  bool _noAgeRestriction = false;
  
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '06:00~08:00',
    '08:00~10:00',
    '09:00~11:00',
    '10:00~12:00',
    '12:00~14:00',
    '14:00~16:00',
    '16:00~18:00',
    '18:00~20:00',
    '20:00~22:00',
  ];

  final List<String> _gameTypes = [
    'mixed',
    'male_doubles',
    'female_doubles',
    'singles',
    'rally',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    // setState를 호출하여 UI 업데이트 강제
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _initializeForm() {
    print('🔍 EditMatchingScreen 초기화:');
    print('  - 코트 이름: ${widget.matching.courtName}');
    print('  - 남성 모집: ${widget.matching.maleRecruitCount}');
    print('  - 여성 모집: ${widget.matching.femaleRecruitCount}');
    print('  - 게스트 비용: ${widget.matching.guestCost}');
    print('  - 게임 타입: ${widget.matching.gameType}');
    print('  - 시간대: ${widget.matching.timeSlot}');
    print('  - 최소 연령: ${widget.matching.minAge}');
    print('  - 최대 연령: ${widget.matching.maxAge}');
    
    _courtNameController.text = widget.matching.courtName;
    _messageController.text = widget.matching.message ?? '';
    _guestCostController.text = widget.matching.guestCost?.toString() ?? '';
    _selectedDate = widget.matching.date;
    _selectedTimeSlot = widget.matching.timeSlot;
    _selectedGameType = widget.matching.gameType;
    _maleRecruitCount = widget.matching.maleRecruitCount;
    _femaleRecruitCount = widget.matching.femaleRecruitCount;
    _minLevel = widget.matching.minLevel;
    _maxLevel = widget.matching.maxLevel;
    _minAge = widget.matching.minAge;
    _maxAge = widget.matching.maxAge;
    _guestCost = widget.matching.guestCost;
    _isFollowersOnly = widget.matching.isFollowersOnly;
    _noAgeRestriction = widget.matching.minAge == null && widget.matching.maxAge == null;
    
    print('🔍 연령대 초기화:');
    print('  - minAge: ${widget.matching.minAge}');
    print('  - maxAge: ${widget.matching.maxAge}');
    print('  - _noAgeRestriction: $_noAgeRestriction');
    print('  - _minAge: $_minAge');
    print('  - _maxAge: $_maxAge');
    
    print('🔍 초기화 완료:');
    print('  - _maleRecruitCount: $_maleRecruitCount');
    print('  - _femaleRecruitCount: $_femaleRecruitCount');
    print('  - _guestCost: $_guestCost');
    print('  - _guestCostController.text: ${_guestCostController.text}');
    print('  - _minAge: $_minAge');
    print('  - _maxAge: $_maxAge');
    
    // UI 업데이트를 위해 setState 호출
    setState(() {});
  }

  @override
  void dispose() {
    _courtNameController.dispose();
    _messageController.dispose();
    _guestCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매칭 수정'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveMatching,
            child: Text(
              '저장',
              style: AppTextStyles.body.copyWith(
                color: _isLoading ? AppColors.textSecondary : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '매칭을 수정하는 중...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildGameInfoSection(),
                    const SizedBox(height: 24),
                    _buildRecruitInfoSection(),
                    const SizedBox(height: 24),
                    _buildLevelAgeSection(),
                    const SizedBox(height: 24),
                    _buildCostSection(),
                    const SizedBox(height: 24),
                    _buildMessageSection(),
                    const SizedBox(height: 24),
                    _buildPrivacySection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기본 정보',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _courtNameController,
          decoration: const InputDecoration(
            labelText: '코트 이름',
            hintText: '예: 강남 테니스장',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '코트 이름을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜 및 시간',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTimeSlot,
                decoration: const InputDecoration(
                  labelText: '시간대',
                  border: OutlineInputBorder(),
                ),
                items: _timeSlots.map((slot) {
                  return DropdownMenuItem(
                    value: slot,
                    child: Text(slot),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTimeSlot = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '게임 정보',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGameType,
          decoration: const InputDecoration(
            labelText: '게임 타입',
            border: OutlineInputBorder(),
          ),
          items: _gameTypes.map((type) {
            String displayName;
            switch (type) {
              case 'mixed':
                displayName = '혼합 복식';
                break;
              case 'male_doubles':
                displayName = '남자 복식';
                break;
              case 'female_doubles':
                displayName = '여자 복식';
                break;
              case 'singles':
                displayName = '단식';
                break;
              case 'rally':
                displayName = '랠리';
                break;
              default:
                displayName = type;
            }
            return DropdownMenuItem(
              value: type,
              child: Text(displayName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGameType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRecruitInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '모집 인원',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('남성'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _maleRecruitCount > 0
                            ? () => setState(() => _maleRecruitCount--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$_maleRecruitCount',
                        style: AppTextStyles.h3,
                      ),
                      IconButton(
                        onPressed: () => setState(() => _maleRecruitCount++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('여성'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _femaleRecruitCount > 0
                            ? () => setState(() => _femaleRecruitCount--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$_femaleRecruitCount',
                        style: AppTextStyles.h3,
                      ),
                      IconButton(
                        onPressed: () => setState(() => _femaleRecruitCount++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '구력 및 연령 (선택사항)',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _minLevel,
                decoration: const InputDecoration(
                  labelText: '최소 구력',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('제한 없음'),
                  ),
                  ...List.generate(10, (index) {
                    return DropdownMenuItem<int?>(
                      value: index + 1,
                      child: Text('${index + 1}년'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _minLevel = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _maxLevel,
                decoration: const InputDecoration(
                  labelText: '최대 구력',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('제한 없음'),
                  ),
                  ...List.generate(10, (index) {
                    return DropdownMenuItem<int?>(
                      value: index + 1,
                      child: Text('${index + 1}년'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _maxLevel = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 연령 제한 없음 체크박스
        CheckboxListTile(
          title: const Text('연령 상관없음'),
          value: _noAgeRestriction,
          onChanged: (value) {
            setState(() {
              _noAgeRestriction = value ?? false;
              if (_noAgeRestriction) {
                _minAge = null;
                _maxAge = null;
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        if (!_noAgeRestriction) ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _minAge,
                  decoration: const InputDecoration(
                    labelText: '최소 연령',
                    border: OutlineInputBorder(),
                  ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('제한 없음'),
                  ),
                  ...List.generate(8, (index) {
                    final age = (index + 1) * 10;
                    return DropdownMenuItem<int?>(
                      value: age,
                      child: Text('${age}대'),
                    );
                  }),
                  // 49세 같은 중간값도 지원
                  const DropdownMenuItem<int?>(
                    value: 49,
                    child: Text('40대'),
                  ),
                  const DropdownMenuItem<int?>(
                    value: 59,
                    child: Text('50대'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _minAge = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _maxAge,
                decoration: const InputDecoration(
                  labelText: '최대 연령',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('제한 없음'),
                  ),
                  ...List.generate(8, (index) {
                    final age = (index + 1) * 10;
                    return DropdownMenuItem<int?>(
                      value: age,
                      child: Text('${age}대'),
                    );
                  }),
                  // 49세 같은 중간값도 지원
                  const DropdownMenuItem<int?>(
                    value: 49,
                    child: Text('40대'),
                  ),
                  const DropdownMenuItem<int?>(
                    value: 59,
                    child: Text('50대'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _maxAge = value;
                  });
                },
              ),
            ),
          ],
        ),
        ],
      ],
    );
  }

  Widget _buildCostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '비용 (선택사항)',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _guestCostController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '게스트 비용 (원)',
            hintText: '예: 15000',
            border: OutlineInputBorder(),
            suffixText: '원',
          ),
          onChanged: (value) {
            _guestCost = int.tryParse(value);
          },
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메시지 (선택사항)',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '매칭에 대한 추가 정보',
            hintText: '예: 초보자 환영, 실내 코트입니다',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '공개 설정',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('팔로워만 보기'),
          subtitle: const Text('나를 팔로우하는 사용자만 이 매칭을 볼 수 있습니다'),
          value: _isFollowersOnly,
          onChanged: (value) {
            setState(() {
              _isFollowersOnly = value;
            });
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: '매칭 수정',
        type: ButtonType.primary,
        onPressed: _isLoading ? null : _saveMatching,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMatching() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 수정된 매칭 데이터 생성
      final updatedMatching = widget.matching.copyWith(
        courtName: _courtNameController.text.trim(),
        date: _selectedDate,
        timeSlot: _selectedTimeSlot,
        gameType: _selectedGameType,
        maleRecruitCount: _maleRecruitCount,
        femaleRecruitCount: _femaleRecruitCount,
        minLevel: _minLevel,
        maxLevel: _maxLevel,
        minAge: _minAge,
        maxAge: _maxAge,
        guestCost: _guestCost,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
        isFollowersOnly: _isFollowersOnly,
      );

      // API 호출로 매칭 수정
      final success = await MatchingDataService.updateMatching(
        widget.matching.id,
        updatedMatching.toJson(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('매칭이 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 콜백 호출
        widget.onMatchingUpdated?.call();
        Navigator.of(context).pop(true); // 수정 완료 표시
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('매칭 수정에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
