import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  
  // 미디어 관련 상태
  List<String> _selectedMedia = []; // 선택된 미디어 파일 경로들
  bool _isLoadingMedia = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: Text(
              _isSubmitting ? '작성 중...' : '게시',
              style: AppTextStyles.body.copyWith(
                color: _isSubmitting ? AppColors.textSecondary : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 구분선
          Container(
            height: 1,
            color: AppColors.cardBorder,
          ),
          
          // 내용 입력 영역
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 정보 (스레드 스타일)
                  _buildUserInfo(),
                  const SizedBox(height: 16),
                  
                  // 내용 입력
                  _buildContentSection(),
                  const SizedBox(height: 16),
                  
                  // 미디어 추가 버튼
                  _buildMediaAddButton(),
                  
                  // 선택된 미디어 표시
                  if (_selectedMedia.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSelectedMedia(),
                  ],
                  
                  const Spacer(),
                  
                  // 작성 가이드
                  _buildWritingGuide(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final currentUser = context.read<AuthProvider>().currentUser;
    
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            currentUser?.nickname?.substring(0, 1) ?? 'U',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.nickname ?? '사용자',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '지금',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildContentSection() {
    return Expanded(
      child: TextField(
        controller: _contentController,
        maxLines: null,
        maxLength: 500,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: '무슨 생각을 하고 계신가요?\n\n#해시태그를 사용하면 검색이 쉬워집니다\n예시: #테니스초보 #모임 #잠실코트',
          hintStyle: AppTextStyles.placeholder.copyWith(
            fontSize: 16,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.body.copyWith(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMediaAddButton() {
    return Row(
      children: [
        // 이미지 추가 버튼
        _buildMediaButton(
          icon: Icons.photo_library,
          label: '사진',
          onTap: () => _addImage(),
        ),
        const SizedBox(width: 12),
        // 영상 추가 버튼
        _buildMediaButton(
          icon: Icons.videocam,
          label: '영상',
          onTap: () => _addVideo(),
        ),
        const SizedBox(width: 12),
        // 카메라 버튼
        _buildMediaButton(
          icon: Icons.camera_alt,
          label: '카메라',
          onTap: () => _takePhoto(),
        ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMedia() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        itemBuilder: (context, index) {
          final mediaPath = _selectedMedia[index];
          final isVideo = mediaPath.toLowerCase().contains('.mp4') || 
                          mediaPath.toLowerCase().contains('.mov') ||
                          mediaPath.toLowerCase().contains('.avi');
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                // 미디어 썸네일
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isVideo
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.file(
                                File(mediaPath),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.surface,
                                    child: Icon(
                                      Icons.video_file,
                                      color: AppColors.textSecondary,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          )
                        : Image.file(
                            File(mediaPath),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.surface,
                                child: Icon(
                                  Icons.image,
                                  color: AppColors.textSecondary,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                
                // 삭제 버튼
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeMedia(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 미디어 추가 메서드들
  void _addImage() {
    // TODO: 실제 이미지 피커 구현
    print('이미지 추가 기능 - 실제 구현 필요');
    _showMediaPickerDialog('이미지');
  }

  void _addVideo() {
    // TODO: 실제 영상 피커 구현
    print('영상 추가 기능 - 실제 구현 필요');
    _showMediaPickerDialog('영상');
  }

  void _takePhoto() {
    // TODO: 실제 카메라 구현
    print('카메라 기능 - 실제 구현 필요');
    _showMediaPickerDialog('카메라');
  }

  void _showMediaPickerDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type 추가'),
        content: Text('$type 추가 기능은 실제 구현이 필요합니다.\n\n현재는 Mock 데이터로 테스트할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addMockMedia(type);
            },
            child: const Text('Mock 추가'),
          ),
        ],
      ),
    );
  }

  void _addMockMedia(String type) {
    setState(() {
      if (type == '이미지') {
        _selectedMedia.add('mock_image_${_selectedMedia.length + 1}.jpg');
      } else if (type == '영상') {
        _selectedMedia.add('mock_video_${_selectedMedia.length + 1}.mp4');
      } else if (type == '카메라') {
        _selectedMedia.add('mock_photo_${_selectedMedia.length + 1}.jpg');
      }
    });
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Widget _buildWritingGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '테니스 관련 내용을 중심으로 작성해주세요. #해시태그를 사용하면 검색이 쉬워집니다.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내용이나 미디어를 추가해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: 실제 API 호출로 변경
      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이

      if (mounted) {
        final mediaCount = _selectedMedia.length;
        final message = mediaCount > 0 
            ? '글이 성공적으로 게시되었습니다! (미디어 ${mediaCount}개 포함)'
            : '글이 성공적으로 게시되었습니다!';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop(true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('글 게시에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
