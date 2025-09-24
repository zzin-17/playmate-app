import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // 프로필 자동 동기화 타이머
  Timer? _profileSyncTimer;
  final Duration _syncInterval = const Duration(minutes: 5); // 5분마다 동기화
  
  AuthProvider() {
    // 생성자에서는 자동 로딩하지 않음
    // main.dart에서 명시적으로 loadCurrentUser() 호출
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
    final token = prefs.getString('playmate_auth_token');
    
    if (token == null) {
      print('🔍 저장된 토큰이 없음');
      return null;
    }
    
    print('🔍 저장된 토큰: ${token.substring(0, 20)}...');
    return token;
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
      
      // 프로필 자동 동기화 시작
      _startProfileSync();
      
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
      
      // 저장된 에러 메시지도 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('playmate_lastError');
      
      // 프로필 자동 동기화 중지
      _stopProfileSync();
      
      _currentUser = null;
      _error = null; // 현재 에러 상태도 초기화
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // 현재 사용자 정보 로드
  Future<void> loadCurrentUser() async {
    _setLoading(true);
    
    try {
      final token = await _getToken();
      print('🔍 loadCurrentUser - 토큰: ${token != null ? token.substring(0, 20) + "..." : "null"}');
      
      if (token != null) {
        // 실제 JWT 토큰 사용
        print('🔍 API에서 사용자 정보 조회 시작');
        _currentUser = await ApiService.getCurrentUser(token);
        print('🔍 사용자 정보 로드 성공: ${_currentUser?.email}');
        
        // 로그인 성공 시 프로필 자동 동기화 시작
        if (_currentUser != null) {
          _startProfileSync();
        }
      } else {
        print('🔍 저장된 토큰이 없음');
        _currentUser = null;
        _stopProfileSync();
      }
    } catch (e) {
      print('🔍 사용자 정보 로드 실패: $e');
      // 401 오류인 경우 토큰이 만료되었을 가능성이 높으므로 로그아웃 처리
      if (e.toString().contains('401')) {
        print('🔍 토큰 만료로 인한 자동 로그아웃');
        await _clearToken();
      }
      
      _currentUser = null;
    } finally {
      _setLoading(false);
      notifyListeners();
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
  
  // 프로필 자동 동기화 시작
  void _startProfileSync() {
    _stopProfileSync(); // 기존 타이머 정리
    
    print('🔄 프로필 자동 동기화 활성화');
    _profileSyncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_currentUser != null) {
        _syncProfileData();
      } else {
        timer.cancel();
      }
    });
  }
  
  // 프로필 자동 동기화 중지
  void _stopProfileSync() {
    _profileSyncTimer?.cancel();
    _profileSyncTimer = null;
  }
  
  // 프로필 데이터 동기화 (백그라운드에서 실행)
  Future<void> _syncProfileData() async {
    try {
      print('🔄 프로필 데이터 동기화 시작');
      
      final token = await _getToken();
      if (token != null) {
        final updatedUser = await ApiService.getCurrentUser(token);
        
        // 프로필 정보가 변경된 경우에만 업데이트
        if (_hasProfileChanged(_currentUser, updatedUser)) {
          _currentUser = updatedUser;
          print('🔄 프로필 정보 업데이트됨: ${updatedUser.nickname}');
          notifyListeners(); // UI 업데이트 알림
        }
      }
    } catch (e) {
      print('프로필 동기화 실패: $e');
      // 동기화 실패는 조용히 처리 (사용자에게 알리지 않음)
    }
  }
  
  // 프로필 변경 여부 확인
  bool _hasProfileChanged(User? oldUser, User newUser) {
    if (oldUser == null) return true;
    
    return oldUser.nickname != newUser.nickname ||
           oldUser.profileImage != newUser.profileImage ||
           oldUser.bio != newUser.bio ||
           oldUser.mannerScore != newUser.mannerScore;
  }
  
  @override
  void dispose() {
    _stopProfileSync();
    super.dispose();
  }
}