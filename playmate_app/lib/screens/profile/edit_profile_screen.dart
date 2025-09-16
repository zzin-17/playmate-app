import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/user.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentUser.nickname;
    _bioController.text = widget.currentUser.bio ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('프로필 편집'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              '저장',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 프로필 이미지 편집
              _buildProfileImageSection(),
              
              const SizedBox(height: 32),
              
              // 기본 정보 편집
              _buildBasicInfoSection(),
              
              const SizedBox(height: 32),
              
              // 추가 정보 편집
              _buildAdditionalInfoSection(),
              
              const SizedBox(height: 32),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  text: '프로필 저장',
                  type: ButtonType.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          // 프로필 이미지
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _selectedImagePath != null
                    ? FileImage(File(_selectedImagePath!))
                    : null,
                child: _selectedImagePath == null
                    ? Text(
                        widget.currentUser.nickname.substring(0, 1),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: _showImagePicker,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '프로필 이미지 변경',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 정보',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 닉네임
          AppTextField(
            controller: _nicknameController,
            label: '닉네임',
            hint: '닉네임을 입력하세요',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '닉네임을 입력해주세요';
              }
              if (value.trim().length < 2) {
                return '닉네임은 2자 이상이어야 합니다';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 이메일 (읽기 전용)
          AppTextField(
            label: '이메일',
            hint: widget.currentUser.email,
            enabled: false,
            suffixIcon: const Icon(Icons.lock),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추가 정보',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 자기소개
          AppTextField(
            controller: _bioController,
            label: '자기소개',
            hint: '자기소개를 입력하세요 (선택사항)',
            maxLines: 3,
            maxLength: 200,
          ),
          
          const SizedBox(height: 16),
          
          // 테니스 구력
          _buildSkillLevelSelector(),
          
          const SizedBox(height: 16),
          
          // 선호 게임 타입
          _buildGameTypeSelector(),
        ],
      ),
    );
  }

  Widget _buildSkillLevelSelector() {
    final skillLevels = [
      {'value': 'beginner', 'label': '초급 (1-2년)'},
      {'value': 'intermediate', 'label': '중급 (3-5년)'},
      {'value': 'advanced', 'label': '고급 (6년 이상)'},
      {'value': 'expert', 'label': '전문가 (10년 이상)'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '테니스 구력',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: widget.currentUser.skillLevel?.toString() ?? 'beginner',
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            items: skillLevels.map((level) {
              return DropdownMenuItem(
                value: level['value'],
                child: Text(level['label']!),
              );
            }).toList(),
            onChanged: (value) {
              // TODO: 사용자 정보 업데이트
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameTypeSelector() {
    final gameTypes = [
      {'value': 'singles', 'label': '싱글스'},
      {'value': 'doubles', 'label': '더블스'},
      {'value': 'both', 'label': '둘 다'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호 게임 타입',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: widget.currentUser.preferredGameType ?? 'both',
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            items: gameTypes.map((type) {
              return DropdownMenuItem(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
            onChanged: (value) {
              // TODO: 사용자 정보 업데이트
            },
          ),
        ),
      ],
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = UserService();
      String? profileImageUrl;

      // 프로필 이미지 업로드
      if (_selectedImagePath != null) {
        profileImageUrl = await userService.uploadProfileImage(_selectedImagePath!);
      }

      // 프로필 업데이트 데이터 준비
      final updateData = {
        'nickname': _nicknameController.text.trim(),
        'bio': _bioController.text.trim(),
        if (profileImageUrl != null) 'profileImage': profileImageUrl,
      };

      // API 호출
      final success = await userService.updateProfile(updateData);
      
      if (success) {
        // AuthProvider 업데이트
        final authProvider = context.read<AuthProvider>();
        await authProvider.loadCurrentUser();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필이 성공적으로 저장되었습니다!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('프로필 업데이트에 실패했습니다.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 저장에 실패했습니다: $e'),
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
}


