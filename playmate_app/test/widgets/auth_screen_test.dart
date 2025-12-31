import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:playmate_app/providers/auth_provider.dart';
import 'package:playmate_app/screens/auth/login_screen.dart';

void main() {
  group('LoginScreen 위젯 테스트', () {
    testWidgets('로그인 화면이 올바르게 렌더링되는지 확인', (WidgetTester tester) async {
      // AuthProvider와 함께 LoginScreen 생성
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // 로그인 화면의 주요 요소들이 존재하는지 확인
      expect(find.text('로그인'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('이메일 입력 필드가 존재하는지 확인', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      // 이메일 입력 필드 찾기
      final emailField = find.byType(TextField).first;
      expect(emailField, findsOneWidget);
    });
  });
}




