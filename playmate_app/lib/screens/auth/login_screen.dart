import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 추가
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'register_screen.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialError;
  final bool preserveState;
  
  const LoginScreen({
    super.key,
    this.initialError,
    this.preserveState = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false; // 추가: 아이디/비번 저장 체크박스
  bool _isLoading = false; // 추가: 로딩 상태
  String? _errorMessage; // 추가: 로컬 에러 메시지

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // 추가: 저장된 자격 증명 로드
    
    // 초기 에러 상태는 사용하지 않음 (화면 재생성 방지)
    // 대신 SharedPreferences에서 저장된 에러 메시지 로드
    _loadSavedError();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 추가: 저장된 자격 증명 로드
  void _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('playmate_savedEmail');
      final rememberMe = prefs.getBool('playmate_rememberMe') ?? false;
      
      if (savedEmail != null && rememberMe) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = rememberMe;
        });
      }
    } catch (e) {

    }
  }

  // 에러 메시지를 다음 화면 로드 시 표시하기 위해 저장
  Future<void> _saveErrorForNextScreen(String error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('playmate_lastError', error);
    } catch (e) {
      // 에러 메시지 저장 실패
    }
  }
  
  // 저장된 에러 메시지 로드
  Future<void> _loadSavedError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedError = prefs.getString('playmate_lastError');
      
      if (savedError != null && mounted) {
        setState(() {
          _errorMessage = savedError;
        });
        // 에러 메시지 로드 후 SharedPreferences에서 제거
        await prefs.remove('playmate_lastError');
      }
    } catch (e) {
      // 저장된 에러 메시지 로드 실패
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberMe) {
        await prefs.setString('playmate_savedEmail', _emailController.text.trim());
        await prefs.setString('playmate_savedPassword', _passwordController.text);
        await prefs.setBool('playmate_rememberMe', true);
      } else {
        await prefs.remove('playmate_savedEmail');
        await prefs.setBool('playmate_rememberMe', false);
      }
    } catch (e) {
      // 자격 증명 저장 실패
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;



    // 로딩 상태 설정
    setState(() {
      _isLoading = true;
    });

    try {
      // 추가: 자격 증명 저장
      await _saveCredentials();

      final authProvider = context.read<AuthProvider>();

      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );



      if (success && mounted) {
        // 자격 증명 저장 (자동 로그인을 위해)
        await _saveCredentials();
        
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.surface),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '로그인 성공! 홈 화면으로 이동합니다.',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 잠시 후 메인 화면으로 이동
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
                    } else {
        // 로컬 에러 상태 설정 (안전하게)
        if (mounted) {
          setState(() {
            _errorMessage = authProvider.error ?? '로그인에 실패했습니다.';
            // 비밀번호만 초기화 (아이디는 유지)
            _passwordController.clear();
          });
        } else {
          // 에러 메시지를 SharedPreferences에 저장하여 다음 화면 로드 시 표시
          _saveErrorForNextScreen(authProvider.error ?? '로그인에 실패했습니다.');
        }
      }
    } catch (e) {
      if (mounted) {
        // 예외 발생 시에도 에러 메시지를 로컬 상태로 설정
        setState(() {
          _errorMessage = '로그인 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      // 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _navigateToResetPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PasswordResetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100), // Spacer 대신 고정 높이 사용
                
                  // 로고 및 타이틀
                  Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.sports_tennis,
                          color: AppColors.surface,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '플메',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '테니스 동호인 매칭',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // 로그인 폼
                  AppTextField(
                    label: '이메일',
                    hint: '이메일을 입력해주세요',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return '올바른 이메일 형식을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    label: '비밀번호',
                    hint: '비밀번호를 입력해주세요',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  
                  // 추가: 아이디/비번 저장 체크박스
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        // 아이디/비밀번호 저장 체크박스 (텍스트 클릭으로도 체크 가능)
                        CheckboxListTile(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                        
                          },
                          title: Text(
                            '아이디/비밀번호 저장',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // 저장된 정보 삭제 버튼
                        if (_rememberMe)
                          TextButton(
                            onPressed: () async {
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('playmate_savedEmail');
                                await prefs.remove('playmate_savedPassword');
                                await prefs.setBool('playmate_rememberMe', false);
                                
                                setState(() {
                                  _emailController.clear();
                                  _rememberMe = false;
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('저장된 정보가 삭제되었습니다.'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              } catch (e) {
                                // 에러 처리 로직 추가 (빈 catch 블록 방지)
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('저장된 정보 삭제 중 오류가 발생했습니다: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '저장된 정보 삭제',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 에러 메시지 표시
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _errorMessage = null;
                                    // 에러 메시지 닫기 시에도 비밀번호만 초기화
                                    _passwordController.clear();
                                  });
                                  
                                },
                                child: Icon(
                                  Icons.close,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          // 로그인 시도 횟수 초과 오류인 경우 초기화 버튼 표시
                          if (_errorMessage!.contains('로그인 시도 횟수를 초과했습니다'))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton(
                                onPressed: () async {
                                  try {
                                    final authProvider = context.read<AuthProvider>();
                                    await authProvider.resetLoginAttempts(_emailController.text.trim());
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('로그인 시도 횟수가 초기화되었습니다.'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('초기화 중 오류가 발생했습니다: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '시도 횟수 초기화',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                    ),
                  ),
                  
                  // 로그인 버튼
                  AppButton(
                    text: '로그인',
                    onPressed: _isLoading ? null : _login,
                    isLoading: _isLoading,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // SNS 로그인 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) => AppButton(
                            text: '카카오 로그인',
                            type: ButtonType.secondary,
                            icon: Icons.chat_bubble_outline,
                            isLoading: auth.isLoading,
                                                      onPressed: () async {
                            final ok = await context.read<AuthProvider>().loginWithKakao();
                            if (ok && mounted) {
                              Navigator.of(context).pushReplacementNamed('/main');
                            }
                          },
                          ),
                        ),
                      ),
                      const SizedBox(width: 50),
                      Expanded(
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) => AppButton(
                            text: 'Apple 로그인',
                            type: ButtonType.secondary,
                            icon: Icons.apple,
                            isLoading: auth.isLoading,
                                                      onPressed: () async {
                            final ok = await context.read<AuthProvider>().loginWithApple();
                            if (ok && mounted) {
                              Navigator.of(context).pushReplacementNamed('/main');
                            }
                          },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 회원가입 링크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요? ',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          '회원가입',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _navigateToResetPassword,
                    child: Center(
                      child: Text(
                        '비밀번호를 잊으셨나요?',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  
                  // 하단 여백 조정 (오버플로우 방지)
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}