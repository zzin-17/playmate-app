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
import '../../services/matching_event_bus.dart';
import 'court_selection_screen.dart';

class CreateMatchingScreen extends StatefulWidget {
  final Matching? editingMatching;
  final User? currentUser;
  
  const CreateMatchingScreen({super.key, this.editingMatching, this.currentUser});

  @override
  State<CreateMatchingScreen> createState() => _CreateMatchingScreenState();
}

class _CreateMatchingScreenState extends State<CreateMatchingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courtNameController = TextEditingController();
  final _messageController = TextEditingController();
  final _courtNameFocusNode = FocusNode();
  
  // 테니스장 선택 관련
  TennisCourt? _selectedCourt;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedStartTime = '18:00';
  String _selectedEndTime = '20:00';
  int? _selectedMinLevel;
  int? _selectedMaxLevel;
  String _selectedGameType = 'mixed';
  int _maleRecruitCount = 1;
  int _femaleRecruitCount = 1;
  final _guestCostController = TextEditingController();
  bool _isFollowersOnly = false; // 팔로워 전용 공개 여부
  
  // 연령대 선택 (홈화면과 동일한 방식)
  List<String> _selectedAgeRanges = [];
  bool _noAgeRestriction = false; // 연령 제한 없음 (기본값 false로 변경)
  
  // 연령대 옵션들 (홈화면과 동일)
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

  /// 인증 토큰 가져오기
  /*
  Future<String?> _getAuthToken() async { // 사용되지 않음
    try {
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getString('playmate_auth_token');
      return null; // 임시로 null 반환
    } catch (e) {
      return null;
    }
  }
  */

  @override
  void initState() {
    super.initState();
    
    // 편집 모드인 경우 기존 데이터 로드
    if (widget.editingMatching != null) {
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
      _guestCostController.text = matching.guestCost?.toString() ?? '0'; // 게스트 비용 초기화
      _messageController.text = matching.message ?? '';
    }
    
    // 키보드 및 입력 시스템 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 키보드 설정 초기화
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _courtNameFocusNode.unfocus();
            setState(() {
              // 입력 시스템 리프레시
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _courtNameController.dispose();
    _messageController.dispose();
    _guestCostController.dispose();
    _courtNameFocusNode.dispose();
    super.dispose();
  }

  // 테니스장 선택 화면으로 이동
  Future<void> _selectCourt() async {
    final result = await Navigator.of(context).push<TennisCourt>(
      MaterialPageRoute(
        builder: (context) => CourtSelectionScreen(
          selectedCourt: _selectedCourt,
          initialSearchQuery: _courtNameController.text.isNotEmpty ? _courtNameController.text : null,
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createMatching() async {
    print('매칭 생성 버튼 클릭됨');
    
    // 디버깅을 위한 필드 값 확인
    print('=== 폼 필드 값 확인 ===');
    print('코트 이름: ${_courtNameController.text}');
    print('선택된 날짜: $_selectedDate');
    print('시작 시간: $_selectedStartTime');
    print('종료 시간: $_selectedEndTime');
    print('최소 구력: $_selectedMinLevel');
    print('최대 구력: $_selectedMaxLevel');
    print('게임 유형: $_selectedGameType');
    print('남성 모집: $_maleRecruitCount');
    print('여성 모집: $_femaleRecruitCount');
    print('연령 제한 없음: $_noAgeRestriction');
    print('선택된 연령대: $_selectedAgeRanges');
    print('계산된 최소 연령: ${_getMinAgeFromRanges()}');
    print('계산된 최대 연령: ${_getMaxAgeFromRanges()}');
    print('최종 minAge: ${_noAgeRestriction ? null : _getMinAgeFromRanges()}');
    print('최종 maxAge: ${_noAgeRestriction ? null : _getMaxAgeFromRanges()}');
    print('게스트비용: ${_guestCostController.text}');
    print('메시지: ${_messageController.text}');
    print('=======================');
    
    if (!_formKey.currentState!.validate()) {
      print('폼 유효성 검사 실패');
      return;
    }
    
    print('폼 유효성 검사 통과');

    // 시간 범위 생성
    final timeSlot = '$_selectedStartTime~$_selectedEndTime';

    // 실제 Matching 객체 생성
    final minAge = _noAgeRestriction ? null : _getMinAgeFromRanges();
    final maxAge = _noAgeRestriction ? null : _getMaxAgeFromRanges();
    
    print('🔍 Matching 객체 생성 전 확인:');
    print('  - minAge: $minAge');
    print('  - maxAge: $maxAge');
    print('  - _noAgeRestriction: $_noAgeRestriction');
    print('  - _isFollowersOnly: $_isFollowersOnly');
    
    // 게스트 비용 처리 (입력하지 않으면 0원)
    final guestCost = _guestCostController.text.isNotEmpty 
        ? int.tryParse(_guestCostController.text) ?? 0 
        : 0;

    final newMatching = Matching(
      id: widget.editingMatching?.id ?? DateTime.now().millisecondsSinceEpoch, // 편집 시 기존 ID 유지
      type: 'host',
      courtName: _courtNameController.text,
      courtLat: 37.5665, // 임시 좌표 (서울 시청)
      courtLng: 126.9780,
      date: _selectedDate,
      timeSlot: timeSlot,
      minLevel: _selectedMinLevel,
      maxLevel: _selectedMaxLevel,
      minAge: minAge,
      maxAge: maxAge,
      guestCost: guestCost, // 게스트 비용 추가
      gameType: _selectedGameType,
      maleRecruitCount: _maleRecruitCount,
      femaleRecruitCount: _femaleRecruitCount,
      status: 'recruiting',
      message: _messageController.text,
      isFollowersOnly: _isFollowersOnly,
      host: context.read<AuthProvider>().currentUser!, // 실제 현재 사용자 정보 사용
      guests: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('매칭 생성 정보:');
    print('코트: ${newMatching.courtName}');
    print('날짜: ${newMatching.date.toString().split(' ')[0]}');
    print('시간: ${newMatching.timeSlot}');
    print('구력: ${newMatching.skillRangeText}');
    print('게임 유형: ${newMatching.gameTypeText}');
    print('연령대: ${newMatching.ageRangeText} (minAge: ${newMatching.minAge}, maxAge: ${newMatching.maxAge})');
    
    print('모집 인원: 남${newMatching.maleRecruitCount}명, 여${newMatching.femaleRecruitCount}명');
    print('게스트비용: ${newMatching.guestCost}원');
    print('메시지: ${newMatching.message}');

    try {
      // 실제 백엔드 API로 매칭 생성
      final createdMatching = await MatchingDataService.createMatching(newMatching.toJson());
      
      if (createdMatching != null) {
        // 성공시 생성된 매칭을 홈 화면으로 전달하고 강제 새로고침 요청
        print('✅ 매칭 생성 완료, 홈 화면으로 돌아가며 새로고침 요청');
        
        // 글로벌 이벤트 발생: 매칭 생성 이벤트
        MatchingEventBus.instance.emit(MatchingCreated(createdMatching));
        print('🔄 매칭 생성 이벤트 발생: ${createdMatching.id}');
        
        // 홈 화면으로 돌아가면서 강제 새로고침 플래그와 함께 전달
        Navigator.of(context).pop({'matching': createdMatching, 'needsRefresh': true});
      } else {
        // API 실패시 폴백: 로컬 매칭으로 처리 (개발용)
        print('매칭 생성 API 실패, 로컬로 처리');
        Navigator.of(context).pop(newMatching);
      }
    } catch (e) {
      // API 실패시 폴백: 로컬 매칭으로 처리 (개발용)
      print('매칭 생성 API 실패, 로컬로 처리: $e');
      Navigator.of(context).pop(newMatching);
    }
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 타이틀
                Text(
                  '게스트를 모집해보세요!',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '원하는 조건을 설정하고 게스트를 찾아보세요',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 코트 이름
                Column(
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
                      enabled: true,
                      autofocus: false,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.none,
                      enableSuggestions: true,
                      autocorrect: true,
                      enableIMEPersonalizedLearning: true,
                      enableInteractiveSelection: true,
                      showCursor: true,
                      readOnly: false,
                      style: AppTextStyles.input,
                      strutStyle: const StrutStyle(
                        forceStrutHeight: true,
                      ),
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.center,
                      textDirection: TextDirection.ltr,
                      obscureText: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      minLines: 1,
                      maxLines: 1,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '코트 이름을 입력해주세요';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        print('코트 이름 입력: $value'); // 디버깅용
                        setState(() {
                          // 검색 결과 업데이트 로직
                        });
                      },
                    ),
                    if (_selectedCourt != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 16,
                            ),
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
                ),
                
                const SizedBox(height: 24),
                
                // 날짜 선택
                _buildDateSection(),
                
                const SizedBox(height: 24),
                
                // 시간대 선택
                _buildTimeSection(),
                
                const SizedBox(height: 24),
                
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
                
                const SizedBox(height: 24),
                
                // 게스트비용
                _buildGuestCostSection(),
                
                const SizedBox(height: 24),
                
                // 메시지
                Column(
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
                      enabled: true,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      enableIMEPersonalizedLearning: true,
                      enableSuggestions: true,
                      enableInteractiveSelection: true,
                      showCursor: true,
                      readOnly: false,
                      maxLines: 3,
                      style: AppTextStyles.input,
                      strutStyle: const StrutStyle(
                        forceStrutHeight: true,
                      ),
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.center,
                      textDirection: TextDirection.ltr,
                      obscureText: false,
                      autocorrect: true,
                      smartDashesType: SmartDashesType.enabled,
                      smartQuotesType: SmartQuotesType.enabled,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: '게스트에게 전할 메시지를 입력해주세요',
                        hintStyle: AppTextStyles.placeholder,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        print('메시지 입력: $value'); // 디버깅용
                        setState(() {
                          // 메시지 업데이트 로직
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 팔로워 전용 공개 옵션
                _buildFollowersOnlyOption(),
                
                const SizedBox(height: 32),
                
                // 매칭 생성 버튼
                AppButton(
                  text: '매칭 생성하기',
                  icon: Icons.person_add,
                  onPressed: _createMatching,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              child: _buildDropdownSection(
                '시작',
                _selectedStartTime,
                _timeOptions,
                (value) => setState(() => _selectedStartTime = value!),
                '시작 시간',
                validator: (value) {
                  if (_selectedStartTime.isEmpty) {
                    return '시작 시간을 선택해주세요';
                  }
                  if (_selectedEndTime.isNotEmpty && _selectedStartTime.compareTo(_selectedEndTime) >= 0) {
                    return '시작 시간이 종료 시간보다 늦을 수 없습니다';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownSection(
                '종료',
                _selectedEndTime,
                _timeOptions,
                (value) => setState(() => _selectedEndTime = value!),
                '종료 시간',
                validator: (value) {
                  if (_selectedEndTime.isEmpty) {
                    return '종료 시간을 선택해주세요';
                  }
                  if (_selectedStartTime.isNotEmpty && _selectedStartTime.compareTo(_selectedEndTime) >= 0) {
                    return '종료 시간이 시작 시간보다 빠를 수 없습니다';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedStartTime}~${_selectedEndTime} (${_calculateDuration()}시간)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateDuration() {
    final startHour = int.parse(_selectedStartTime.split(':')[0]);
    final endHour = int.parse(_selectedEndTime.split(':')[0]);
    return (endHour - startHour).toString();
  }

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
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                  style: AppTextStyles.input,
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
              child: _buildDropdownSection(
                '최소',
                _selectedMinLevel?.toString(),
                ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
                (value) => setState(() => _selectedMinLevel = int.tryParse(value!)),
                '최소 구력',
                displayValues: ['1년', '2년', '3년', '4년', '5년', '6년', '7년', '8년', '9년', '10년'],
                validator: (value) {
                  if (_selectedMinLevel == null) {
                    return '최소 구력을 선택해주세요';
                  }
                  if (_selectedMaxLevel != null && _selectedMinLevel! > _selectedMaxLevel!) {
                    return '최소 구력이 최대 구력보다 클 수 없습니다';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownSection(
                '최대',
                _selectedMaxLevel?.toString(),
                ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
                (value) => setState(() => _selectedMaxLevel = int.tryParse(value!)),
                '최대 구력',
                displayValues: ['1년', '2년', '3년', '4년', '5년', '6년', '7년', '8년', '9년', '10년'],
                validator: (value) {
                  if (_selectedMaxLevel == null) {
                    return '최대 구력을 선택해주세요';
                  }
                  if (_selectedMinLevel != null && _selectedMinLevel! > _selectedMaxLevel!) {
                    return '최대 구력이 최소 구력보다 작을 수 없습니다';
                  }
                  return null;
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
        _buildDropdownSection(
          '',
          _selectedGameType,
          _gameTypes.map((e) => e['value']!).toList(),
          (value) => setState(() => _selectedGameType = value!),
          '게임 유형을 선택하세요',
          displayValues: _gameTypes.map((e) => e['label']!).toList(),
        ),
      ],
    );
  }

  Widget _buildGuestCostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1인당 게스트비용',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _guestCostController,
          enabled: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.input,
          decoration: InputDecoration(
            hintText: '입력하지 않으면 0원 (무료)',
            hintStyle: AppTextStyles.placeholder,
            prefixIcon: const Icon(Icons.currency_exchange, color: AppColors.textSecondary),
            suffixText: '원',
            suffixStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '게스트비용을 입력해주세요';
            }
            final cost = int.tryParse(value);
            if (cost == null || cost < 0) {
              return '올바른 금액을 입력해주세요';
            }
            return null;
          },
          onChanged: (value) {
            print('게스트비용 입력: $value'); // 디버깅용
            setState(() {
              // 비용 업데이트 로직
            });
          },
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
              child: _buildGenderRecruitSection('남성', _maleRecruitCount, (value) {
                setState(() => _maleRecruitCount = value);
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGenderRecruitSection('여성', _femaleRecruitCount, (value) {
                setState(() => _femaleRecruitCount = value);
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '총 ${_maleRecruitCount + _femaleRecruitCount}명 모집 (남${_maleRecruitCount}, 여${_femaleRecruitCount})',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowersOnlyOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '공개 설정',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _isFollowersOnly,
            onChanged: (value) {
              setState(() {
                _isFollowersOnly = value ?? false;
                print('🔍 팔로워만 모집 체크박스 변경: $_isFollowersOnly');
              });
            },
            activeColor: AppColors.primary,
            title: Text(
              '팔로워에게만 공개',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '팔로우한 사용자에게만 모집글을 보여줍니다',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderRecruitSection(String gender, int count, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            gender,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (count > 0) {
                    onChanged(count - 1);
                  }
                },
                icon: Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
              ),
              Text(
                '$count명',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (count < 4) {
                    onChanged(count + 1);
                  }
                },
                icon: Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
    String hint, {
    List<String>? displayValues,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          hint: Text(hint, style: AppTextStyles.placeholder),
          items: options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final displayValue = displayValues != null && index < displayValues.length
                ? displayValues[index]
                : option;
            return DropdownMenuItem(
              value: option,
              child: Text(displayValue, style: AppTextStyles.input),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  // 연령대 선택 섹션 (홈화면과 동일한 방식)
  Widget _buildAgeRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '연령대',
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 12),
        
        // 연령 상관없음 체크박스
        Row(
          children: [
            Checkbox(
              value: _noAgeRestriction,
              onChanged: (value) {
                setState(() {
                  _noAgeRestriction = value ?? true;
                  if (_noAgeRestriction) {
                    _selectedAgeRanges.clear();
                  }
                });
              },
              activeColor: AppColors.primary,
            ),
            Text(
              '연령 상관없음',
              style: AppTextStyles.body,
            ),
          ],
        ),
        
        if (!_noAgeRestriction) ...[
          const SizedBox(height: 16),
          Text(
            '원하는 연령대를 여러 개 선택할 수 있습니다',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          
          // 연령대 선택 버튼들
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ageOptions.map((age) {
              final isSelected = _selectedAgeRanges.contains(age);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedAgeRanges.length >= 2) {
                      // 이미 2개 이상 선택된 경우, 모든 선택 해제하고 새로 시작
                      _selectedAgeRanges.clear();
                    }
                    _selectedAgeRanges.add(age);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    age,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          // 선택된 연령대 표시
          if (_selectedAgeRanges.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                                      Text(
                      '선택된 연령대: ${_getAgeRangeDisplayText()}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  // 드롭다운 필드 빌더 메서드
  /*
  Widget _buildDropdownField({ // 사용되지 않음
    required String label,
    required String? value,
    required List<String> options,
    List<String>? displayValues,
    required ValueChanged<String?> onChanged,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          hint: Text(hint ?? '선택하세요', style: AppTextStyles.placeholder),
          items: options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final displayValue = displayValues != null && index < displayValues.length
                ? displayValues[index]
                : option;
            return DropdownMenuItem(
              value: option,
              child: Text(displayValue, style: AppTextStyles.input),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
  */

  // 연령대 범위에서 최소 연령 추출
  int? _getMinAgeFromRanges() {
    try {
      if (_selectedAgeRanges.isEmpty) return null;
      
      int minAge = 100;
      for (String ageRange in _selectedAgeRanges) {
        int age = _getAgeFromRange(ageRange);
        if (age < minAge) {
          minAge = age;
        }
      }
      return minAge == 100 ? null : minAge;
    } catch (e) {
      print('❌ _getMinAgeFromRanges 오류: $e');
      return null;
    }
  }

  // 연령대 범위에서 최대 연령 추출
  int? _getMaxAgeFromRanges() {
    try {
      if (_selectedAgeRanges.isEmpty) return null;
      
      int maxAge = 0;
      for (String ageRange in _selectedAgeRanges) {
        int age = _getAgeFromRange(ageRange, isMax: true);
        if (age > maxAge) {
          maxAge = age;
        }
      }
      return maxAge == 0 ? null : maxAge;
    } catch (e) {
      print('❌ _getMaxAgeFromRanges 오류: $e');
      return null;
    }
  }

  // 연속된 연령대인지 확인 (사용되지 않음)
  /*
  bool _isConsecutiveAges(List<int> ages) {
    if (ages.length <= 1) return true;
    
    for (int i = 1; i < ages.length; i++) {
      if (ages[i] - ages[i-1] != 10) {
        return false;
      }
    }
    return true;
  }
  */

  // 연령대 범위 표시 텍스트 생성
  String _getAgeRangeDisplayText() {
    if (_selectedAgeRanges.isEmpty) return '';
    
    if (_selectedAgeRanges.length == 1) {
      // 하나만 선택된 경우
      return '${_selectedAgeRanges.first}';
    } else {
      // 두 개 선택된 경우 (마지막 두 선택을 기준으로 범위 표시)
      final ages = _selectedAgeRanges.map((range) => _getAgeFromRange(range)).toList();
      ages.sort();
      
      final startAge = ages.first;
      final endAge = ages.last;
      return '${startAge}대~${endAge}대';
    }
  }

  // 연령대 텍스트에서 숫자 값 추출 (홈화면과 동일한 로직)
  int _getAgeFromRange(String ageRange, {bool isMax = false}) {
    switch (ageRange) {
      case '10대':
        return isMax ? 19 : 10;
      case '20대':
        return isMax ? 29 : 20;
      case '30대':
        return isMax ? 39 : 30;
      case '40대':
        return isMax ? 49 : 40;
      case '50대':
        return isMax ? 59 : 50;
      case '60대~':
        return isMax ? 100 : 60;
      default:
        return isMax ? 100 : 0;
    }
  }
} 