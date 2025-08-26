import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockService {
  static final BlockService _instance = BlockService._internal();
  factory BlockService() => _instance;
  BlockService._internal();

  static const String _blockedUsersKey = 'blocked_users';
  static const String _hiddenPostsKey = 'hidden_posts';

  /// 사용자 차단
  Future<void> blockUser(int userId, String userNickname, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedUsers = prefs.getStringList(_blockedUsersKey) ?? [];
      
      if (!blockedUsers.contains(userId.toString())) {
        blockedUsers.add(userId.toString());
        await prefs.setStringList(_blockedUsersKey, blockedUsers);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$userNickname님을 차단했습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('사용자 차단 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 차단에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 사용자 차단 해제
  Future<void> unblockUser(int userId, String userNickname, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedUsers = prefs.getStringList(_blockedUsersKey) ?? [];
      
      blockedUsers.remove(userId.toString());
      await prefs.setStringList(_blockedUsersKey, blockedUsers);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userNickname님의 차단을 해제했습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('사용자 차단 해제 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사용자 차단 해제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 사용자가 차단되었는지 확인
  Future<bool> isUserBlocked(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedUsers = prefs.getStringList(_blockedUsersKey) ?? [];
      return blockedUsers.contains(userId.toString());
    } catch (e) {
      print('차단 상태 확인 실패: $e');
      return false;
    }
  }

  /// 차단된 사용자 목록 가져오기
  Future<List<int>> getBlockedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedUsers = prefs.getStringList(_blockedUsersKey) ?? [];
      return blockedUsers.map((id) => int.parse(id)).toList();
    } catch (e) {
      print('차단된 사용자 목록 가져오기 실패: $e');
      return [];
    }
  }

  /// 게시글 숨기기
  Future<void> hidePost(int postId, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hiddenPosts = prefs.getStringList(_hiddenPostsKey) ?? [];
      
      if (!hiddenPosts.contains(postId.toString())) {
        hiddenPosts.add(postId.toString());
        await prefs.setStringList(_hiddenPostsKey, hiddenPosts);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('게시글이 숨겨졌습니다.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print('게시글 숨기기 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글 숨기기에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 숨겨진 게시글인지 확인
  Future<bool> isPostHidden(int postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hiddenPosts = prefs.getStringList(_hiddenPostsKey) ?? [];
      return hiddenPosts.contains(postId.toString());
    } catch (e) {
      print('게시글 숨김 상태 확인 실패: $e');
      return false;
    }
  }

  /// 차단 확인 다이얼로그 표시
  Future<bool> showBlockConfirmDialog(
    BuildContext context,
    int userId,
    String userNickname,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 차단'),
        content: Text(
          '$userNickname님을 차단하시겠습니까?\n\n'
          '차단된 사용자의 게시글과 댓글은 더 이상 보이지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('차단하기'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 차단 해제 확인 다이얼로그 표시
  Future<bool> showUnblockConfirmDialog(
    BuildContext context,
    int userId,
    String userNickname,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 차단 해제'),
        content: Text(
          '$userNickname님의 차단을 해제하시겠습니까?\n\n'
          '차단 해제 후 해당 사용자의 게시글과 댓글을 다시 볼 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('차단 해제'),
          ),
        ],
      ),
    ) ?? false;
  }
}
