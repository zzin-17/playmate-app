import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  
  String? _selectedRegion;
  int? _selectedSkillLevel;
  String? _selectedPlayStyle;
  List<String> _selectedPreferredTimes = [];
  String? _selectedPreferredCourt;
  bool _hasLesson = false;

  final List<String> _regions = [
    '서울시 강남구', '서울시 서초구', '서울시 송파구', '서울시 마포구',
    '서울시 영등포구', '서울시 용산구', '서울시 중구', '서울시 종로구',
    '경기도 성남시', '경기도 수원시', '경기도 고양시', '경기도 부천시',
    '인천시', '부산시', '대구시', '대전시', '광주시', '울산시'
  ];

  final List<String> _skillLevels = [
    '입문자 (1년 미만)',
    '초급자 (1-3년)',
    '중급자 (3-5년)',
    '고급자 (5-10년)',
    '전문가 (10년 이상)'
  ];

  final List<String> _playStyles = [
    '싱글스',
    '복식',
    '싱글스/복식 모두'
  ];

  final List<String> _preferredTimes = [
    '평일 오전 (09:00-12:00)',
    '평일 오후 (12:00-18:00)',
    '평일 저녁 (18:00-22:00)',
    '주말 오전 (09:00-12:00)',
    '주말 오후 (12:00-18:00)',
    '주말 저녁 (18:00-22:00)'
  ];

  final List<String> _preferredCourts = [
    '잠실종합운동장',
    '양재시민의숲',
    '탄천종합운동장',
    '올림픽공원',
    '한강공원',
    '기타 (직접 입력)'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _selectedRegion = user.region;
      _selectedSkillLevel = user.skillLevel;
      _selectedPreferredCourt = user.preferredCourt;
      _selectedPreferredTimes = user.preferredTime ?? [];
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      nickname: _nicknameController.text.trim(),
      location: _selectedRegion,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 저장되었습니다.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? '프로필 저장에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('프로필 설정'),
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
                  '테니스 프로필을\n완성해주세요!',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '더 정확한 매칭을 위해 정보를 입력해주세요',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 닉네임
                AppTextField(
                  label: '닉네임 *',
                  hint: '닉네임을 입력해주세요',
                  controller: _nicknameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    if (value.length < 2) {
                      return '닉네임은 2자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 지역 선택
                _buildDropdownSection(
                  '활동 지역 *',
                  _selectedRegion,
                  _regions,
                  (value) => setState(() => _selectedRegion = value),
                  '활동 지역을 선택해주세요',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '활동 지역을 선택해주세요';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 구력 선택
                _buildDropdownSection(
                  '테니스 구력 *',
                  _selectedSkillLevel?.toString(),
                  _skillLevels,
                  (value) => setState(() => _selectedSkillLevel = _skillLevels.indexOf(value!) + 1),
                  '테니스 구력을 선택해주세요',
                  validator: (value) {
                    if (_selectedSkillLevel == null) {
                      return '테니스 구력을 선택해주세요';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 플레이 스타일
                _buildDropdownSection(
                  '선호 플레이 스타일',
                  _selectedPlayStyle,
                  _playStyles,
                  (value) => setState(() => _selectedPlayStyle = value),
                  '선호하는 플레이 스타일을 선택해주세요',
                ),
                
                const SizedBox(height: 24),
                
                // 선호 시간대
                _buildMultiSelectSection(
                  '선호 시간대',
                  _selectedPreferredTimes,
                  _preferredTimes,
                  (value) {
                    setState(() {
                      if (_selectedPreferredTimes.contains(value)) {
                        _selectedPreferredTimes.remove(value);
                      } else {
                        _selectedPreferredTimes.add(value);
                      }
                    });
                  },
                  '선호하는 시간대를 선택해주세요',
                ),
                
                const SizedBox(height: 24),
                
                // 선호 코트
                _buildDropdownSection(
                  '선호 코트',
                  _selectedPreferredCourt,
                  _preferredCourts,
                  (value) => setState(() => _selectedPreferredCourt = value),
                  '선호하는 코트를 선택해주세요',
                ),
                
                const SizedBox(height: 24),
                
                // 레슨 여부
                _buildSwitchSection(
                  '레슨 경험',
                  '테니스 레슨을 받은 적이 있나요?',
                  _hasLesson,
                  (value) => setState(() => _hasLesson = value),
                ),
                
                const SizedBox(height: 32),
                
                // 저장 버튼
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return AppButton(
                      text: '프로필 저장',
                      onPressed: _saveProfile,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
    String hint, {
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
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option, style: AppTextStyles.input),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildMultiSelectSection(
    String label,
    List<String> selectedValues,
    List<String> options,
    Function(String) onChanged,
    String hint,
  ) {
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);
              return CheckboxListTile(
                title: Text(option, style: AppTextStyles.input),
                value: isSelected,
                onChanged: (_) => onChanged(option),
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSection(
    String label,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
} 