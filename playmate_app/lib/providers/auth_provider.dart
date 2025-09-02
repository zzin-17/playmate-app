import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/mock_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // 보안 관련 상수
  static const int _tokenExpiryHours = 24; // 토큰 만료 시간 (24시간)
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
        throw Exception('계정이 잠겼습니다. $remainingMinutes분 후에 다시 시도해주세요.');
      } else {
        // 잠금 해제
        await prefs.remove(lockoutKey);
        await prefs.remove(attemptsKey);
      }
    }
    
    // 로그인 시도 횟수 체크
    final attempts = prefs.getInt(attemptsKey) ?? 0;
    if (attempts >= _maxLoginAttempts) {
      // 계정 잠금
      final lockoutTime = DateTime.now().add(_lockoutDuration);
      await prefs.setString(lockoutKey, lockoutTime.toIso8601String());
      throw Exception('로그인 시도 횟수를 초과했습니다. 30분 후에 다시 시도해주세요.');
    }
    
    return true;
  }
  
  // 로그인 시도 횟수 증가
  Future<void> _incrementLoginAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsKey = 'login_attempts_$email';
    final attempts = (prefs.getInt(attemptsKey) ?? 0) + 1;
    await prefs.setInt(attemptsKey, attempts);
  }
  
  // 로그인 시도 횟수 초기화
  Future<void> _resetLoginAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final attemptsKey = 'login_attempts_$email';
    await prefs.remove(attemptsKey);
  }

  // 로그인
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    // _clearError() 제거 - 에러 메시지가 사라지지 않도록

    try {
      // 로그인 시도 횟수 체크
      await _checkLoginAttempts(email);
      
      // 1) 실제 API 로그인 시도
      try {
        final response = await _apiService.login(email, password);
        final token = response['token'] as String;
        await _saveToken(token);
        _apiService.setAuthToken(token);
        await _loadCurrentUser();
        
        // 로그인 성공 시 시도 횟수 초기화
        await _resetLoginAttempts(email);
        
        _setLoading(false);
        return true;
      } catch (_) {
        // 2) 실패 시 Mock 계정으로 폴백 (개발/테스트 용)
        final res = await MockAuthService.login(email, password);
        await _saveToken(res['token'] as String);
        _apiService.setAuthToken(null);
        _currentUser = res['user'] as User;
        
        // 로그인 성공 시 시도 횟수 초기화
        await _resetLoginAttempts(email);
        
        _setLoading(false);
        notifyListeners();
        return true;
      }
    } catch (e) {
      // 로그인 실패 시 시도 횟수 증가
      await _incrementLoginAttempts(email);
      
      final errorMessage = '로그인 실패: $e';
      print('에러 메시지 설정: $errorMessage');
      _setError(errorMessage);
      _setLoading(false);
      
      // 로그인 실패 시에는 notifyListeners() 호출하지 않음
      // (화면이 새로 로드되는 것을 방지)
      print('로그인 실패 - notifyListeners() 호출하지 않음');
      
      // 로그인 실패 시에도 현재 사용자 상태 유지 (화면 재로드 방지)
      print('현재 사용자 상태 유지: ${_currentUser?.email ?? "null"}');
      
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
    String? startYearMonth,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 실제 API 호출 (백엔드 스펙 확정 시 startYearMonth 전달)
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
      // Mock 환경에서는 startYearMonth를 현재 사용자에 반영
      if (_currentUser != null && startYearMonth != null) {
        _currentUser = User(
          id: _currentUser!.id,
          email: _currentUser!.email,
          nickname: _currentUser!.nickname,
          gender: _currentUser!.gender,
          birthYear: _currentUser!.birthYear,
          region: _currentUser!.region,
          skillLevel: _currentUser!.skillLevel,
          startYearMonth: startYearMonth,
          preferredCourt: _currentUser!.preferredCourt,
          preferredTime: _currentUser!.preferredTime,
          playStyle: _currentUser!.playStyle,
          hasLesson: _currentUser!.hasLesson,
          mannerScore: _currentUser!.mannerScore,
          profileImage: _currentUser!.profileImage,
          createdAt: _currentUser!.createdAt,
          updatedAt: _currentUser!.updatedAt,
        );
      }
      
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
    print('=== AuthProvider.checkAuthStatus 시작 ===');
    final token = await _getToken();
    print('토큰 확인: ${token != null ? "있음" : "없음"}');
    
    if (token != null) {
      print('토큰으로 사용자 정보 로드 시도');
      _apiService.setAuthToken(token);
      await _loadCurrentUser();
      print('토큰으로 사용자 정보 로드 완료: ${_currentUser?.email}');
    } else {
      print('토큰이 없음 - 자동 로그인 시도');
      // 토큰이 없으면 저장된 자격 증명으로 자동 로그인 시도
      await _tryAutoLogin();
      print('자동 로그인 시도 완료: ${_currentUser?.email}');
    }
    print('=== AuthProvider.checkAuthStatus 완료 ===');
  }

  // 자동로그인 보안 검증 (개발/테스트 환경에서는 완화)
  Future<bool> _isAutoLoginSecure(String email) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 개발/테스트 환경에서는 보안 완화
    // TODO: 프로덕션 환경에서는 아래 주석 해제
    
    /*
    // 1. 마지막 자동로그인 시간 체크 (24시간 제한)
    final lastAutoLoginKey = 'last_auto_login_$email';
    final lastAutoLogin = prefs.getString(lastAutoLoginKey);
    
    if (lastAutoLogin != null) {
      final lastLoginTime = DateTime.parse(lastAutoLogin);
      final hoursSinceLastLogin = DateTime.now().difference(lastLoginTime).inHours;
      
      if (hoursSinceLastLogin < 24) {
        print('자동로그인 시간 제한: ${24 - hoursSinceLastLogin}시간 후 가능');
        return false;
      }
    }
    
    // 2. 자동로그인 횟수 제한 (하루 3회)
    final autoLoginCountKey = 'auto_login_count_$email';
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final autoLoginCount = prefs.getInt('${autoLoginCountKey}_$today') ?? 0;
    
    if (autoLoginCount >= 3) {
      print('자동로그인 횟수 제한: 하루 3회 초과');
      return false;
    }
    
    // 3. 보안 검증 통과 시 기록 업데이트
    await prefs.setString(lastAutoLoginKey, DateTime.now().toIso8601String());
    await prefs.setInt('${autoLoginCountKey}_$today', autoLoginCount + 1);
    */
    
    print('개발 환경: 자동 로그인 보안 검증 완화됨');
    return true;
  }

  // 저장된 자격 증명으로 자동 로그인 시도 (보안 강화)
  Future<void> _tryAutoLogin() async {
    try {
      print('=== 자동 로그인 시작 ===');
      final prefs = await SharedPreferences.getInstance();
      
      // SharedPreferences 디버깅
      print('=== SharedPreferences 디버깅 ===');
      final allKeys = prefs.getKeys();
      print('모든 키: $allKeys');
      
      for (final key in allKeys) {
        if (key.startsWith('playmate_')) {
          final value = prefs.get(key);
          print('키: $key, 값: $value');
        }
      }
      
      final rememberMe = prefs.getBool('playmate_rememberMe') ?? false;
      print('rememberMe: $rememberMe');
      
      if (rememberMe) {
        final savedEmail = prefs.getString('playmate_savedEmail');
        print('savedEmail: $savedEmail');
        
        if (savedEmail != null) {
          // 자동로그인 보안 체크
          if (!await _isAutoLoginSecure(savedEmail)) {
            print('자동로그인 보안 검증 실패');
            return;
          }
          
          print('자동 로그인 시도: $savedEmail');
          // Mock 서비스로 자동 로그인 (실제 저장된 비밀번호 사용)
          final savedPassword = prefs.getString('playmate_savedPassword');
          if (savedPassword != null) {
            final res = await MockAuthService.login(savedEmail, savedPassword);
            print('Mock 서비스 응답: $res');
            
            if (res['success'] == true) {
              await _saveToken(res['token'] as String);
              _currentUser = res['user'] as User;
              print('사용자 설정 완료: ${_currentUser?.email}');
              print('자동 로그인 성공: $savedEmail');
              print('현재 사용자 상태: ${_currentUser?.email}');
              print('isLoggedIn 상태: ${_currentUser != null}');
              notifyListeners();
            } else {
              print('Mock 서비스에서 로그인 실패');
            }
          } else {
            print('저장된 비밀번호가 없음');
          }
        } else {
          print('저장된 이메일이 없음');
        }
      } else {
        print('rememberMe가 false');
      }
      print('=== 자동 로그인 종료 ===');
    } catch (e) {
      print('자동 로그인 실패: $e');
      print('에러 상세: ${e.toString()}');
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

  // 비밀번호 해시화
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // 토큰 생성
  String _generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
  
  // 토큰 저장 (만료 시간 포함)
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('auth_token', token);
    await prefs.setString('token_created_at', now.toIso8601String());
    await prefs.setString('token_expires_at', now.add(Duration(hours: _tokenExpiryHours)).toIso8601String());
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) return null;
    
    // 토큰 만료 체크
    final expiresAt = prefs.getString('token_expires_at');
    if (expiresAt != null) {
      final expiryDate = DateTime.parse(expiresAt);
      if (DateTime.now().isAfter(expiryDate)) {
        print('토큰이 만료되었습니다. 자동 로그아웃 처리');
        await _clearToken();
        _currentUser = null;
        notifyListeners();
        return null;
      }
    }
    
    return token;
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
    // 에러 설정 시에는 notifyListeners() 호출하지 않음
    // (화면이 새로 로드되는 것을 방지)
    print('에러 설정: $error (notifyListeners() 호출하지 않음)');
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