import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  String? _selectedGender;
  int? _selectedBirthYear;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _selectedGender = user.gender == 'male'
          ? '남성'
          : user.gender == 'female'
              ? '여성'
              : null;
      _selectedBirthYear = user.birthYear;
      if (user.profileImage != null && user.profileImage!.isNotEmpty) {
        _localImagePath = user.profileImage;
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final ok = await auth.updateProfile({
      'nickname': _nicknameController.text.trim(),
      'gender': _selectedGender == '남성'
          ? 'male'
          : _selectedGender == '여성'
              ? 'female'
              : null,
      'birthYear': _selectedBirthYear,
      if (_localImagePath != null) 'profileImage': _localImagePath,
    });

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다.'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? '저장 실패'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _localImagePath = 'file://' + picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(60, (i) => DateTime.now().year - i);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('저장', style: AppTextStyles.body.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 프로필 이미지
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.surface,
                        backgroundImage: _localImagePath == null
                            ? null
                            : (_localImagePath!.startsWith('http')
                                ? NetworkImage(_localImagePath!) as ImageProvider
                                : FileImage(File(_localImagePath!.replaceFirst('file://', '')))),
                        child: _localImagePath == null
                            ? const Icon(Icons.person, size: 44, color: AppColors.textSecondary)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              builder: (ctx) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('갤러리에서 선택'),
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        await _pickImage(ImageSource.gallery);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo_camera),
                                      title: const Text('카메라로 촬영'),
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        await _pickImage(ImageSource.camera);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: '닉네임'),
                  validator: (v) => (v == null || v.trim().length < 2) ? '닉네임은 2자 이상' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: const [
                    DropdownMenuItem(value: '남성', child: Text('남성')),
                    DropdownMenuItem(value: '여성', child: Text('여성')),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v),
                  decoration: const InputDecoration(labelText: '성별'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedBirthYear,
                  items: years
                      .map((y) => DropdownMenuItem<int>(value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBirthYear = v),
                  decoration: const InputDecoration(labelText: '출생년도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


