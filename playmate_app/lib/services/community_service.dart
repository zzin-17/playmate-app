import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/comment.dart';
import 'api_service.dart';
import '../utils/logger.dart';

/// 커뮤니티 관련 API 서비스
/// 게시글, 댓글, 좋아요 등의 기능을 제공
class CommunityService {
  
  /// 인증 토큰 가져오기
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      return null;
    }
  }

  /// 게시글 목록 조회
  Future<List<Post>> getPosts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // 쿼리 파라미터를 URL에 직접 추가
      final uri = Uri.parse('${ApiService.baseUrl}/community/posts').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => _convertApiPostToPost(json)).toList();
        } else {
          throw Exception('게시글 목록 조회 실패: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('게시글 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('게시글 목록 조회 오류: $e');
      return [];
    }
  }

  /// 게시글 상세 조회
  Future<Post?> getPost(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/community/posts/$postId'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Post.fromJson(data['data']);
        }
      }
      
      throw Exception('게시글 조회 실패: ${response.statusCode}');
    } catch (e) {
      print('게시글 조회 오류: $e');
      return null;
    }
  }

  /// 게시글 작성
  Future<Post?> createPost({
    required String content,
    List<String>? hashtags,
    List<String>? imageUrls,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final postData = {
        'content': content,
        if (hashtags != null) 'hashtags': hashtags,
        if (imageUrls != null) 'image_urls': imageUrls,
      };

      final response = await ApiService.post(
        '/community/posts',
        body: json.encode(postData),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return _convertApiPostToPost(responseData['data']);
        } else {
          throw Exception('게시글 작성 응답 형식 오류');
        }
      } else {
        throw Exception('게시글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('게시글 작성 오류: $e');
      return null;
    }
  }


  /// 게시글 좋아요/좋아요 취소
  Future<bool> toggleLike(int postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.post(
        '/community/posts/$postId/like',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('좋아요 토글 오류: $e');
      return false;
    }
  }

  /// 게시글 북마크/북마크 취소
  Future<bool> toggleBookmark(int postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.post(
        '/posts/$postId/bookmark',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('북마크 토글 오류: $e');
      return false;
    }
  }

  /// 댓글 목록 조회
  Future<List<Comment>> getComments(int postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/community/posts/$postId/comments',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'] as List;
          return data.map((json) => Comment.fromJson(json)).toList();
        } else {
          throw Exception('댓글 목록 조회 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('댓글 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 목록 조회 오류: $e');
      return [];
    }
  }

  /// 댓글 작성
  Future<Comment?> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final commentData = {
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      };

      final response = await ApiService.post(
        '/community/posts/$postId/comments',
        body: json.encode(commentData),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return Comment.fromJson(responseData['data']);
        } else {
          throw Exception('댓글 작성 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('댓글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('댓글 작성 오류', tag: 'CommunityService', error: e);
      return null;
    }
  }

  /// 댓글 수정
  Future<Comment?> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final commentData = {
        'content': content,
      };

      final response = await ApiService.put(
        '/community/comments/$commentId',
        body: json.encode(commentData),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return Comment.fromJson(responseData['data']);
        } else {
          throw Exception('댓글 수정 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('댓글 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('댓글 수정 오류', tag: 'CommunityService', error: e);
      return null;
    }
  }

  /// 댓글 삭제
  Future<bool> deleteComment(int commentId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.delete(
        '/community/comments/$commentId',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.error('댓글 삭제 오류', tag: 'CommunityService', error: e);
      return false;
    }
  }

  /// 댓글 좋아요/좋아요 취소
  Future<bool> toggleCommentLike(int commentId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.post(
        '/community/comments/$commentId/like',
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.error('댓글 좋아요 토글 오류', tag: 'CommunityService', error: e);
      return false;
    }
  }

  /// 해시태그 검색
  Future<List<String>> searchHashtags(String query) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/hashtags/search?q=${Uri.encodeComponent(query)}',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).cast<String>();
      } else {
        throw Exception('해시태그 검색 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('해시태그 검색 오류: $e');
      return [];
    }
  }

  /// 인기 해시태그 조회
  Future<List<String>> getPopularHashtags() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/hashtags/popular',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data as List).cast<String>();
      } else {
        throw Exception('인기 해시태그 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('인기 해시태그 조회 오류: $e');
      return [];
    }
  }


  /// 내 게시글 조회
  Future<List<Post>> getMyPosts() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/community/posts/my-posts',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map((json) => _convertApiPostToPost(json)).toList();
        } else {
          throw Exception('내 게시글 조회 실패: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('내 게시글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('내 게시글 조회 오류: $e');
      return [];
    }
  }

  /// API 응답을 Post 모델로 변환
  Post _convertApiPostToPost(Map<String, dynamic> apiData) {
    print('🔍 _convertApiPostToPost 호출됨: ${apiData['id']} - ${apiData['content']}');
    
    final post = Post(
      id: apiData['id'] ?? 0,
      authorId: apiData['authorId'] ?? 0,
      authorNickname: apiData['authorNickname'] ?? '',
      authorProfileImage: apiData['authorProfileImage'],
      content: apiData['content'] ?? '',
      images: apiData['images'] != null ? List<String>.from(apiData['images']) : null,
      videoUrl: apiData['videoUrl'],
      hashtags: apiData['hashtags'] != null ? List<String>.from(apiData['hashtags']) : null,
      location: apiData['location'],
      category: apiData['category'] ?? 'general',
      likeCount: apiData['likes'] ?? 0,
      commentCount: apiData['comments'] ?? 0,
      shareCount: apiData['shares'] ?? 0,
      isLikedByCurrentUser: apiData['isLiked'] ?? false,
      isBookmarkedByCurrentUser: apiData['isBookmarked'] ?? false,
      isSharedByCurrentUser: apiData['isShared'] ?? false,
      comments: null, // API에서 댓글 목록을 별도로 가져와야 함
      createdAt: DateTime.parse(apiData['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(apiData['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
    
    print('🔍 Post 객체 생성 완료: ${post.id} - ${post.content}');
    return post;
  }

  /// 이미지 업로드
  Future<String?> uploadImage(String imagePath) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      // 실제 구현에서는 multipart/form-data로 이미지 업로드
      // 여기서는 임시로 성공 응답 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));
      return 'https://example.com/images/uploaded-image.jpg';
    } catch (e) {
      print('이미지 업로드 오류: $e');
      return null;
    }
  }

  /// 게시글 수정
  Future<bool> updatePost(int postId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/community/posts/$postId'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('게시글 수정 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('게시글 수정 오류: $e');
      return false;
    }
  }

  /// 게시글 삭제
  Future<bool> deletePost(int postId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/api/community/posts/$postId'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('게시글 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('게시글 삭제 오류: $e');
      return false;
    }
  }

  /// 특정 사용자의 게시글 조회
  Future<List<Post>> getUserPosts(int userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get(
        '/community/posts/user/$userId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'] as List;
          return data.map((json) => Post.fromJson(json)).toList();
        } else {
          throw Exception('사용자 게시글 조회 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('사용자 게시글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 게시글 조회 오류: $e');
      return [];
    }
  }

  /// 내가 북마크한 게시글 조회
  Future<List<Post>> getMyBookmarks() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get('/api/community/posts/my-bookmarks');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> postsData = responseData['data'] ?? [];
          return postsData.map((data) => Post.fromJson(data)).toList();
        } else {
          throw Exception('북마크한 게시글 조회 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('북마크한 게시글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('북마크한 게시글 조회 오류: $e');
      return [];
    }
  }

  /// 내가 좋아요한 게시글 조회
  Future<List<Post>> getMyLikes() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get('/api/community/posts/my-likes');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> postsData = responseData['data'] ?? [];
          return postsData.map((data) => Post.fromJson(data)).toList();
        } else {
          throw Exception('좋아요한 게시글 조회 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('좋아요한 게시글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('좋아요한 게시글 조회 오류: $e');
      return [];
    }
  }

  /// 내가 댓글단 게시글 조회
  Future<List<Post>> getMyCommentedPosts() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('인증 토큰이 없습니다');

      final response = await ApiService.get('/api/community/posts/my-comments');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> postsData = responseData['data'] ?? [];
          return postsData.map((data) => Post.fromJson(data)).toList();
        } else {
          throw Exception('댓글단 게시글 조회 실패: ${responseData['message']}');
        }
      } else {
        throw Exception('댓글단 게시글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글단 게시글 조회 오류: $e');
      return [];
    }
  }
}
