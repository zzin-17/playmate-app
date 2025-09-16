import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  AuthProvider() {
    // 앱 시작 시 현재 사용자 정보 로드
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    print('🔍 AuthProvider 초기화 시작');
    try {
      await loadCurrentUser();
      print('🔍 AuthProvider 초기화 완료');
    } catch (e) {
      print('🔍 AuthProvider 초기화 실패: $e');
    }
  }
  
  // 보안 관련 상수
  static const int _maxLoginAttempts = 5; // 최대 로그인 시도 횟수
  static const Duration _lockoutDuration = Duration(minutes: 30); // 계정 잠금 시간

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // 로그인 시도 횟수 체크
  Future<bool> _checkLoginAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsKey = 'login_attempts_$email';
    final lockoutKey = 'lockout_until_$email';
    
    // 계정 잠금 상태 체크
    final lockoutUntil = prefs.getString(lockoutKey);
    if (lockoutUntil != null) {
      final lockoutTime = DateTime.parse(lockoutUntil);
      if (DateTime.now().isBefore(lockoutTime)) {
        final remainingMinutes = lockoutTime.difference(DateTime.now()).inMinutes;
        _setError('로그인 시도 횟수를 초과했습니다. ${remainingMinutes}분 후에 다시 시도해주세요.');
        return false;
      } else {
        // 잠금 시간이 지났으면 잠금 해제
        await prefs.remove(lockoutKey);
        await prefs.remove(attemptsKey);
      }
    }
    
    return true;
  }

  // 로그인 시도 횟수 증가
  Future<void> _incrementLoginAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsKey = 'login_attempts_$email';
    final lockoutKey = 'lockout_until_$email';
    
    final currentAttempts = prefs.getInt(attemptsKey) ?? 0;
    final newAttempts = currentAttempts + 1;
    
    await prefs.setInt(attemptsKey, newAttempts);
    
    if (newAttempts >= _maxLoginAttempts) {
      // 계정 잠금
      final lockoutUntil = DateTime.now().add(_lockoutDuration);
      await prefs.setString(lockoutKey, lockoutUntil.toIso8601String());
    }
  }

  // 로그인 시도 횟수 초기화
  Future<void> _resetLoginAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsKey = 'login_attempts_$email';
    final lockoutKey = 'lockout_until_$email';
    
    await prefs.remove(attemptsKey);
    await prefs.remove(lockoutKey);
  }

  // 로그인 시도 횟수 초기화 (공개 메서드)
  Future<void> resetLoginAttempts(String email) async {
    await _resetLoginAttempts(email);
  }

  // 모든 로그인 시도 횟수 초기화 (개발용)
  Future<void> resetAllLoginAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (String key in keys) {
      if (key.startsWith('login_attempts_') || key.startsWith('lockout_until_')) {
        await prefs.remove(key);
      }
    }
  }

  // 토큰 저장
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playmate_auth_token', token);
  }

  // 토큰 가져오기
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('playmate_auth_token');
  }

  // 토큰 제거
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('playmate_auth_token');
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 에러 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // 에러 제거
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // 로그인
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // 로그인 시도 횟수 체크
      if (!await _checkLoginAttempts(email)) {
        _setLoading(false);
        return false;
      }

      // 실제 API 호출
      final response = await ApiService.login(email, password);
      
      // API 응답 구조에 맞게 수정
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        
        await _saveToken(data['token'] as String);
        
        // API 응답에 누락된 필드 추가
        final userData = Map<String, dynamic>.from(data);
        userData['createdAt'] = userData['createdAt'] ?? DateTime.now().toIso8601String();
        userData['updatedAt'] = userData['updatedAt'] ?? DateTime.now().toIso8601String();
        
        _currentUser = User.fromJson(userData);
      } else {
        throw Exception('로그인 실패: ${response['message'] ?? '알 수 없는 오류'}');
      }
      
      // 로그인 성공 시 시도 횟수 초기화
      await _resetLoginAttempts(email);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      // 로그인 실패 시 시도 횟수 증가
      await _incrementLoginAttempts(email);
      
      final errorMessage = '로그인 실패: $e';
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // 회원가입
  Future<bool> register({
    required String email,
    required String password,
    required String nickname,
    required String gender,
    required int birthYear,
    String? startYearMonth,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 실제 API 호출
      final response = await ApiService.register(
        email: email,
        password: password,
        nickname: nickname,
        gender: gender,
        birthYear: birthYear,
      );
      
      // 회원가입 후 자동 로그인
      await _saveToken(response['token'] as String);
      await loadCurrentUser();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _clearToken();
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // 현재 사용자 정보 로드
  Future<void> loadCurrentUser() async {
    try {
      final token = await _getToken();
      if (token != null) {
        // 실제 JWT 토큰 사용
        _currentUser = await ApiService.getCurrentUser(token);
        notifyListeners();
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _currentUser = null;
    }
  }

  // 카카오 로그인 (임시 구현)
  Future<bool> loginWithKakao() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: 실제 카카오 로그인 구현
      await Future.delayed(const Duration(seconds: 1));
      _setError('카카오 로그인은 아직 구현되지 않았습니다.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 애플 로그인 (임시 구현)
  Future<bool> loginWithApple() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: 실제 애플 로그인 구현
      await Future.delayed(const Duration(seconds: 1));
      _setError('애플 로그인은 아직 구현되지 않았습니다.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 프로필 업데이트 (임시 구현)
  Future<bool> updateProfile({
    String? nickname,
    String? location,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: 실제 프로필 업데이트 구현
      await Future.delayed(const Duration(seconds: 1));
      _setError('프로필 업데이트는 아직 구현되지 않았습니다.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}