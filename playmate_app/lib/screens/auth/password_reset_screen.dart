import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../constants/app_colors.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  // ApiService는 정적 메서드로 사용
  bool _requested = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.requestPasswordReset(_emailController.text.trim());
      setState(() => _requested = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일로 인증 코드를 전송했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 실패: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.resetPassword(code: _codeController.text.trim(), newPassword: _newPasswordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다.'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변경 실패: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '이메일'),
                validator: (v) => (v == null || v.isEmpty) ? '이메일을 입력해주세요' : null,
              ),
              const SizedBox(height: 12),
              if (_requested) ...[
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: '인증 코드'),
                  validator: (v) => (v == null || v.isEmpty) ? '인증 코드를 입력해주세요' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: '새 비밀번호'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? '비밀번호는 6자 이상' : null,
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : (_requested ? _reset : _request),
                child: Text(_requested ? '비밀번호 변경' : '코드 요청'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


