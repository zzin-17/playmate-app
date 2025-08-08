import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/mock_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // 로그인
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // 1) 실제 API 로그인 시도
      try {
        final response = await _apiService.login(email, password);
        final token = response['token'] as String;
        await _saveToken(token);
        _apiService.setAuthToken(token);
        await _loadCurrentUser();
        _setLoading(false);
        return true;
      } catch (_) {
        // 2) 실패 시 Mock 계정으로 폴백 (개발/테스트 용)
        final res = await MockAuthService.login(email, password);
        await _saveToken(res['token'] as String);
        _apiService.setAuthToken(null);
        _currentUser = res['user'] as User;
        _setLoading(false);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('로그인 실패: $e');
      _setLoading(false);
      return false;
    }
  }

  // 회원가입
  Future<bool> register({
    required String email,
    required String password,
    required String nickname,
    String? gender,
    int? birthYear,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 실제 API 호출
      final response = await _apiService.register(
        email: email,
        password: password,
        nickname: nickname,
        gender: gender,
        birthYear: birthYear,
      );
      
      // 회원가입 후 자동 로그인
      await _saveToken(response['token'] as String);
      _apiService.setAuthToken(response['token'] as String);
      await _loadCurrentUser();
      
      _setLoading(false);
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
      _apiService.setAuthToken(null);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // 현재 사용자 정보 로드
  Future<void> loadCurrentUser() async {
    if (!isLoggedIn) return;
    
    try {
      final token = await _getToken();
      if (token != null) {
        if (token.startsWith('mock_token_')) {
          // 데모/소셜(Mock) 토큰인 경우 Mock 서비스로 유저 로드
          final user = await MockAuthService.getCurrentUser(token);
          _currentUser = user;
          notifyListeners();
        } else {
          _apiService.setAuthToken(token);
          final user = await _apiService.getCurrentUser();
          _currentUser = user;
          notifyListeners();
        }
      }
    } catch (e) {
      // 토큰이 만료되었을 수 있음
      await logout();
    }
  }

  // 프로필 업데이트
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      final token = await _getToken();
      if (token != null) {
        _apiService.setAuthToken(token);
        final updatedUser = await _apiService.updateProfile(profileData);
        _currentUser = updatedUser;
        _setLoading(false);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 앱 시작 시 토큰 확인
  Future<void> checkAuthStatus() async {
    final token = await _getToken();
    if (token != null) {
      _apiService.setAuthToken(token);
      await _loadCurrentUser();
    }
  }

  // Private methods
  Future<void> _loadCurrentUser() async {
    try {
      final token = await _getToken();
      if (token != null) {
        final user = await MockAuthService.getCurrentUser(token);
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // 소셜 로그인 (Mock 기반) - 향후 실제 SDK 연동 시 교체
  Future<bool> loginWithKakao() async {
    _setLoading(true);
    _clearError();
    try {
      // TODO: 실제 Kakao SDK 연동으로 교체
      final res = await MockAuthService.loginWithKakao();
      await _saveToken(res['token'] as String);
      _currentUser = res['user'] as User;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    _setLoading(true);
    _clearError();
    try {
      // TODO: 실제 Apple Sign-In 연동으로 교체
      final res = await MockAuthService.loginWithApple();
      await _saveToken(res['token'] as String);
      _currentUser = res['user'] as User;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
} 