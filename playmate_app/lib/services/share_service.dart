import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// 게시글 공유하기
  Future<void> sharePost(Post post, BuildContext context) async {
    try {
      // 공유 옵션 표시
      final result = await _showShareOptions(context, post);
      
      if (result != null) {
        // 공유 성공 시 카운트 증가
        _incrementShareCount(post);
        
        // 성공 메시지 표시
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('게시글이 공유되었습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('공유 실패', tag: 'ShareService', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('공유에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 공유 옵션 표시
  Future<String?> _showShareOptions(BuildContext context, Post post) async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '공유하기',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 카카오톡 공유
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE500),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: Color(0xFF3C1E1E),
                ),
              ),
              title: const Text('카카오톡'),
              subtitle: const Text('카카오톡으로 공유'),
              onTap: () async {
                Navigator.pop(context, 'kakao');
                await _shareToKakaoTalk(post);
              },
            ),
            
            // 링크 복사
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link,
                  color: Colors.white,
                ),
              ),
              title: const Text('링크 복사'),
              subtitle: const Text('게시글 링크를 클립보드에 복사'),
              onTap: () async {
                Navigator.pop(context, 'link');
                await _copyLinkToClipboard(post);
              },
            ),
            
            // 기타 앱으로 공유
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                ),
              ),
              title: const Text('기타 앱'),
              subtitle: const Text('다른 앱으로 공유'),
              onTap: () async {
                Navigator.pop(context, 'other');
                await _shareToOtherApps(post);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 카카오톡으로 공유
  Future<void> _shareToKakaoTalk(Post post) async {
    final text = '${post.content}\n\n#플메 #테니스';
    final url = 'https://playmate.app/post/${post.id}';
    
    // 카카오톡 URL 스킴으로 공유
    final kakaoUrl = Uri.parse(
      'kakaotalk://send?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(url)}'
    );
    
    if (await canLaunchUrl(kakaoUrl)) {
      await launchUrl(kakaoUrl);
    } else {
      // 카카오톡이 설치되지 않은 경우 웹으로 공유
      final webUrl = Uri.parse(
        'https://story.kakao.com/share?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(url)}'
      );
      await launchUrl(webUrl);
    }
  }

  /// 링크를 클립보드에 복사
  Future<void> _copyLinkToClipboard(Post post) async {
    try {
      final url = 'https://playmate.app/post/${post.id}';
      await Clipboard.setData(ClipboardData(text: url));
      Logger.info('링크 클립보드에 복사됨: $url', tag: 'ShareService');
    } catch (e) {
      Logger.error('클립보드 복사 실패', tag: 'ShareService', error: e);
      rethrow;
    }
  }

  /// 기타 앱으로 공유
  Future<void> _shareToOtherApps(Post post) async {
    try {
      final text = '${post.content}\n\n#플메 #테니스';
      final url = 'https://playmate.app/post/${post.id}';
      final shareText = '$text\n$url';
      
      await Share.share(shareText);
      Logger.info('시스템 공유 완료', tag: 'ShareService');
    } catch (e) {
      Logger.error('시스템 공유 실패', tag: 'ShareService', error: e);
      rethrow;
    }
  }

  /// 공유 카운트 증가
  void _incrementShareCount(Post post) {
    // TODO: 실제 API 호출로 공유 카운트 증가
    Logger.debug('공유 카운트 증가: ${post.id}', tag: 'ShareService');
  }

  /// 공유 통계 가져오기
  Future<Map<String, dynamic>> getShareStatistics(int postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      return await ApiService.getPostShareStatistics(postId, token);
    } catch (e) {
      Logger.error('공유 통계 조회 실패', tag: 'ShareService', error: e);
      // 에러 발생 시 기본값 반환
      return {
        'totalShares': 0,
        'kakaoShares': 0,
        'linkCopies': 0,
        'otherShares': 0,
        'trendingRank': 0,
      };
    }
  }

  /// 인증 토큰 가져오기
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      Logger.error('토큰 가져오기 오류', tag: 'ShareService', error: e);
      return null;
    }
  }
}
