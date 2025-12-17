import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home/improved_home_screen.dart';
import 'screens/community/create_post_screen.dart';
import 'screens/matching/edit_matching_screen.dart';
import 'screens/matching/improved_create_matching_screen.dart';
import 'models/matching.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';

import 'services/fcm_service.dart';
import 'services/connection_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FCM 서비스 초기화 (Firebase 초기화와 무관하게 먼저 실행)
  // 이렇게 하면 Firebase 초기화 실패해도 알림 권한은 요청됨
  final fcmService = FCMService();
  await fcmService.initialize();
  
  // 연결 상태 모니터링 시작
  ConnectionMonitorService().startMonitoring();
  

  
  runApp(const PlayMateApp());
}

class PlayMateApp extends StatelessWidget {
  const PlayMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: MaterialApp(
        title: '플메 - 테니스 동호인 매칭',
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          // 색상 테마
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.surface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
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
          '/home': (context) => const ImprovedHomeScreen(),
          '/write-post': (context) => const CreatePostScreen(),
          '/create-matching': (context) => const ImprovedCreateMatchingScreen(),
          '/edit-matching': (context) {
            final matching = ModalRoute.of(context)!.settings.arguments as Matching;
            return EditMatchingScreen(matching: matching);
          },
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.loadCurrentUser();
      print('🔍 인증 초기화 완료');
    } catch (e) {
      print('🔍 인증 초기화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 로딩 중일 때만 로딩 화면 표시
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 로그인 상태에 따라 화면 분기
        return authProvider.isLoggedIn 
          ? const MainScreen()
          : const LoginScreen();
      },
    );
  }
}


