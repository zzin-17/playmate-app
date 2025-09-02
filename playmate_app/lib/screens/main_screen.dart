import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'court/court_screen.dart';
import 'community/community_screen.dart';
import 'trade/trade_screen.dart';
import 'profile/profile_screen.dart';
import 'chat/chat_list_screen.dart';
import 'matching/create_matching_screen.dart';
import '../models/matching.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Matching? _newMatching; // 새로 생성된 매칭
  
  // 새 매칭이 생성되면 HomeScreen을 업데이트
  Widget _buildHomeScreen() {
    return HomeScreen(
      newMatching: _newMatching,
      onMatchingAdded: () {
        setState(() {
          _newMatching = null; // 매칭이 추가되면 초기화
        });
      },
    );
  }
  
  final List<Widget> _pages = [
    // index 1: 채팅
    const ChatListScreen(),
    // index 2: 커뮤니티
    const CommunityScreen(),
    // index 3: 마이페이지
    const ProfileScreen(),
  ];

  String _getTabName(int index) {
    switch (index) {
      case 0: return '홈';
      case 1: return '커뮤니티';
      case 2: return '마이페이지';
      default: return '알 수 없음';
    }
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // 홈
        return FloatingActionButton.extended(
          onPressed: () async {
            // 게스트 모집 페이지로 이동
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateMatchingScreen()),
            );
            
            // 매칭이 생성되면 HomeScreen에 알림
            if (result != null && result is Matching) {
              setState(() {
                _newMatching = result; // 새 매칭 상태 업데이트
              });
              print('새 매칭 생성됨: ${result.courtName}');
            }
          },
          backgroundColor: Theme.of(context).primaryColor,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text(
            '게스트 모집',
            style: TextStyle(color: Colors.white),
          ),
        );
      case 2: // 커뮤니티
        return null; // CommunityScreen에서 직접 처리
      default:
        return null; // 다른 탭에서는 플로팅 액션 버튼 숨김
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 ? _buildHomeScreen() : _pages[_currentIndex - 1],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: '커뮤니티',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}
