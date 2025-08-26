import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const String _bookmarkKey = 'user_bookmarks';
  
  // 북마크 추가/제거 토글
  static Future<bool> toggleBookmark(int userId, int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks(userId);
    
    final bookmarkKey = '$userId:$postId';
    if (bookmarks.contains(postId)) {
      // 북마크 제거
      bookmarks.remove(postId);
      await prefs.remove(bookmarkKey);
    } else {
      // 북마크 추가
      bookmarks.add(postId);
      await prefs.setString(bookmarkKey, postId.toString());
    }
    
    // 전체 북마크 목록 업데이트
    await _saveBookmarkList(userId, bookmarks);
    return bookmarks.contains(postId);
  }
  
  // 사용자의 북마크 목록 가져오기
  static Future<Set<int>> getBookmarks(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkList = prefs.getStringList('${_bookmarkKey}_$userId') ?? [];
    return bookmarkList.map((e) => int.parse(e)).toSet();
  }
  
  // 특정 게시글 북마크 여부 확인
  static Future<bool> isBookmarked(int userId, int postId) async {
    final bookmarks = await getBookmarks(userId);
    return bookmarks.contains(postId);
  }
  
  // 북마크 목록 저장
  static Future<void> _saveBookmarkList(int userId, Set<int> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkList = bookmarks.map((e) => e.toString()).toList();
    await prefs.setStringList('${_bookmarkKey}_$userId', bookmarkList);
  }
  
  // 북마크 개수 가져오기
  static Future<int> getBookmarkCount(int userId) async {
    final bookmarks = await getBookmarks(userId);
    return bookmarks.length;
  }
}
