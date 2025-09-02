import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/community/create_post_screen.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';

import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  try {
    await Firebase.initializeApp();
    
    // FCM 서비스 초기화
    final fcmService = FCMService();
    await fcmService.initialize();
  } catch (e) {
    // Firebase 초기화 실패 시에도 앱은 계속 실행
  }
  

  
  runApp(const PlayMateApp());
}

class PlayMateApp extends StatelessWidget {
  const PlayMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: '플메 - 테니스 동호인 매칭',
        theme: ThemeData(
          // 색상 테마
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.surface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            background: AppColors.background,
            surface: AppColors.surface,
            error: AppColors.error,
          ),
          
          // 텍스트 테마
          textTheme: const TextTheme(
            headlineLarge: AppTextStyles.h1,
            headlineMedium: AppTextStyles.h2,
            bodyLarge: AppTextStyles.body,
            bodySmall: AppTextStyles.caption,
          ),
          
          // 앱바 테마
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: AppTextStyles.h2,
          ),
          
          // 카드 테마
          cardTheme: CardThemeData(
            color: AppColors.cardBackground,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          // 입력 필드 테마
          inputDecorationTheme: InputDecorationTheme(
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          
          // 버튼 테마
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          
          // 탭바 테마
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainScreen(),
          '/home': (context) => const HomeScreen(),
          '/write-post': (context) => const CreatePostScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingAuth = true;  // 인증 확인 중 상태 추가
  
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // 1. 저장된 자격 증명 확인
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('playmate_savedEmail');
      final rememberMe = prefs.getBool('playmate_rememberMe') ?? false;
      
      if (savedEmail != null && rememberMe) {
        print('저장된 자격 증명으로 자동 로그인 시도');
      }
    } catch (e) {
      print('저장된 자격 증명 로드 실패: $e');
    }
    
    // 2. AuthProvider 인증 상태 확인
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();
    
    // 3. 인증 확인 완료 후 상태 업데이트
    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer 제거하여 불필요한 리빌드 방지
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 인증 확인이 완료될 때까지 로딩 화면 표시
    if (_isCheckingAuth || authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (authProvider.isLoggedIn) {
      return const MainScreen();
    } else {
      // LoginScreen을 항상 동일한 인스턴스로 유지
      // (로그인 실패 시에도 화면이 새로 생성되지 않도록)
      return LoginScreen(
        key: const ValueKey('login_screen'),
        // 에러 상태를 전달하지 않음 (화면 재생성 방지)
        initialError: null,
        // 로그인 실패 시에도 화면 유지
        preserveState: true,
      );
    }
  }
}


