import 'package:flutter/material.dart';
import 'home/improved_home_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import 'chat/chat_list_screen.dart';
import 'matching/improved_create_matching_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // 화면 인스턴스들 (상태 보존을 위해 한 번만 생성)
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    
    // 모든 페이지 인스턴스 생성
    _pages = [
      const ImprovedHomeScreen(),         // index 0: 홈
      const ChatListScreen(),     // index 1: 채팅
      const CommunityScreen(
        initialTabIndex: 0, 
        showBackButton: false,
      ), // index 2: 커뮤니티
      const ProfileScreen(),      // index 3: 마이페이지
    ];
  }




  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // 홈
        return FloatingActionButton.extended(
          onPressed: () async {
            // 게스트 모집 페이지로 이동
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ImprovedCreateMatchingScreen()),
            );
            // 매칭 생성 후 HomeScreen은 자동으로 새로고침됨
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
      body: _pages[_currentIndex], // 단순한 1:1 인덱스 매칭 (성능 최적화)
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
