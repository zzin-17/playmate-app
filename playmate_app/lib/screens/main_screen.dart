import 'package:flutter/material.dart';
import '../../models/matching.dart';
import 'home/home_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import 'chat/chat_list_screen.dart';
import 'matching/create_matching_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Matching? _newMatching; // 새로 생성된 매칭
  int _communityTabIndex = 0; // 커뮤니티 탭 인덱스 (0: All, 1: My)
  
  // 화면 인스턴스들 (상태 보존을 위해 한 번만 생성)
  late final List<Widget> _pages;
  late final HomeScreen _homeScreen;
  
  // HomeScreen 새로고침 콜백
  VoidCallback? _homeScreenRefreshCallback;
  
  @override
  void initState() {
    super.initState();
    
    // HomeScreen 인스턴스 생성 (상태 보존)
    _homeScreen = HomeScreen(
      newMatching: _newMatching,
      onMatchingAdded: _onMatchingAdded,
      onRefreshCallbackSet: (callback) {
        _homeScreenRefreshCallback = callback;
      },
    );
    
    // 모든 페이지 인스턴스 생성 (메모리 효율 + 빠른 탭 전환)
    _pages = [
      _homeScreen,                // index 0: 홈
      const ChatListScreen(),     // index 1: 채팅
      CommunityScreen(
        initialTabIndex: _communityTabIndex, 
        showBackButton: false, // 메인 화면에서는 뒤로가기 버튼 숨김
      ), // index 2: 커뮤니티
      const ProfileScreen(),      // index 3: 마이페이지
    ];
  }
  
  // 매칭 추가 콜백 (성능 최적화)
  void _onMatchingAdded() {
    if (mounted) {
      setState(() {
        _newMatching = null;
      });
      // HomeScreen에 직접 알림 (불필요한 rebuild 방지)
      // 추후 Provider나 다른 상태 관리로 개선 가능
    }
  }

  // 커뮤니티 My 탭으로 이동
  void navigateToCommunityMyTab() {
    setState(() {
      _currentIndex = 2; // 커뮤니티 탭
      _communityTabIndex = 1; // My 탭
      // 페이지 다시 생성하여 새로운 탭 인덱스 적용
      _pages[2] = CommunityScreen(
        initialTabIndex: _communityTabIndex,
        showBackButton: false,
      );
    });
  }

  // HomeScreen 강제 새로고침
  void _refreshHomeScreen() {
    if (_homeScreenRefreshCallback != null) {
      print('🔄 MainScreen: HomeScreen 콜백을 통한 새로고침 호출');
      _homeScreenRefreshCallback!();
    } else {
      print('❌ MainScreen: HomeScreen 새로고침 콜백 없음');
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
            if (result != null) {
              Matching? createdMatching;
              bool needsRefresh = false;
              
              // 반환 타입에 따른 처리
              if (result is Matching) {
                createdMatching = result;
                needsRefresh = true;
              } else if (result is Map<String, dynamic>) {
                createdMatching = result['matching'] as Matching?;
                needsRefresh = result['needsRefresh'] == true;
              }
              
              if (createdMatching != null) {
                setState(() {
                  _newMatching = createdMatching; // 새 매칭 상태 업데이트
                });
                
                // HomeScreen에 즉시 새로고침 요청
                if (needsRefresh) {
                  print('🔄 MainScreen: 매칭 생성 완료, HomeScreen 강제 새로고침 요청');
                  // HomeScreen의 GlobalKey를 통한 직접 새로고침 호출
                  _refreshHomeScreen();
                }
              }
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
