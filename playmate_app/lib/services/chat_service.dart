import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import '../models/matching.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'matching_service.dart';
import 'chat_local_store.dart';
import 'chat_event_bus.dart';

/// 채팅 목록/방 관련 서비스
/// 실제 백엔드 API를 우선으로 하고, 실패시에만 폴백 처리
class ChatService {
  final MatchingService _matchingService = MatchingService();
  final ChatLocalStore _localStore = ChatLocalStore();

  /// 인증 토큰 가져오기
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('playmate_auth_token');
    } catch (e) {
      return null;
    }
  }

  /// 내 채팅방 목록을 조회한다.
  /// 1순위: 백엔드 API (/chat/rooms/my)
  /// 2순위: 매칭 기반 채팅방 구성 (/matchings/my)
  /// 3순위: 빈 목록 반환 (Mock 데이터 제거)
  Future<List<ChatRoom>> getMyChatRooms(User currentUser) async {
    try {
      // 1순위: 실제 채팅방 API 호출
      final apiRooms = await _getChatRoomsFromAPI(currentUser);
      if (apiRooms.isNotEmpty) return apiRooms;
      // 빈 목록이면 폴백 시도
      if (kDebugMode) {
        print('채팅방 API 반환이 비어 있음 → 매칭 기반 폴백 시도');
      }
    } catch (e) {
      if (kDebugMode) {
        print('채팅방 API 실패, 매칭 기반으로 폴백: $e');
      }
    }

    try {
      // 2순위: 매칭 기반 채팅방 구성
      final mRooms = await _getChatRoomsFromMatchings(currentUser);
      if (mRooms.isNotEmpty) return mRooms;
    } catch (e2) {
      if (kDebugMode) {
        print('매칭 API도 실패: $e2');
      }
    }

    // 3순위: 빈 목록 반환 (실제 채팅방이 없으면 표시하지 않음)
    return [];
  }

  /// 백엔드 채팅방 데이터를 ChatRoom 모델로 변환
  ChatRoom _convertBackendRoomToChatRoom(Map<String, dynamic> json, User currentUser) {
    // 매칭 정보를 가져와서 필요한 데이터 구성
    final matchingId = json['matchingId'] as int;
    
    print('🔍 _convertBackendRoomToChatRoom - matchingId: $matchingId');
    
    // 임시 데이터 (실제로는 매칭 정보를 조회해야 함)
    return ChatRoom(
      matchingId: matchingId,
      courtName: '테니스장', // 실제로는 매칭 정보에서 가져와야 함
      date: DateTime.now(),
      timeSlot: '18:00~20:00',
      myRole: 'guest', // 실제로는 참여자 정보에서 확인해야 함
      partner: User(
        id: 1,
        email: 'partner@example.com',
        nickname: '상대방',
        gender: 'male',
        birthYear: 1990,
        region: '서울',
        skillLevel: 3,
        startYearMonth: '2020-01',
        preferredCourt: '실내',
        preferredTime: ['18:00~20:00'],
        playStyle: '공격적',
        hasLesson: false,
        mannerScore: 4.0,
        profileImage: null,
        followingIds: [],
        followerIds: [],
        reviewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
      status: 'recruiting',
    );
  }

  /// 실제 채팅방 API에서 조회
  Future<List<ChatRoom>> _getChatRoomsFromAPI(User currentUser) async {
    try {
      print('🔍 채팅방 API 호출 시작');
      final response = await http.get(
        Uri.parse('http://192.168.6.100:3000/api/chat/rooms'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );
      
      print('🔍 채팅방 API 응답: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 채팅방 API 데이터: $data');
        if (data['success'] == true) {
          final rooms = (data['data'] as List)
              .map((json) => _convertBackendRoomToChatRoom(json, currentUser))
              .toList();
          
          // 서버 방 목록을 로컬에도 저장 (UX 향상)
          for (final r in rooms) {
            await _localStore.upsertRoom(currentUser.id, r);
          }
          
          return rooms;
        }
      }
      
      // API 실패시 로컬 캐시 반환
      final localRooms = await _localStore.loadRooms(currentUser.id);
      return localRooms;
    } catch (e) {
      print('채팅방 API 호출 실패: $e');
      // API 실패시 로컬 캐시 반환
      final localRooms = await _localStore.loadRooms(currentUser.id);
      return localRooms;
    }
  }

  /// 매칭 기반으로 채팅방 구성
  Future<List<ChatRoom>> _getChatRoomsFromMatchings(User currentUser) async {
    final token = await _getAuthToken();
    if (token == null) {
      return [];
    }
    
    try {
      final matchings = await ApiService.getMyMatchings(token);
      return _toChatRooms(matchings, currentUser);
    } catch (e) {
      return [];
    }
  }

  // 실시간 생성된 채팅방들을 임시 저장 (실제로는 백엔드에서 관리)
  static final List<ChatRoom> _activeChatRooms = [];

  /// 메시지가 오간 채팅방을 임시 등록 (실제로는 백엔드 API가 처리)
  static void addActiveChatRoom(ChatRoom room) {
    // 중복 방지 (같은 매칭 + 같은 상대방)
    _activeChatRooms.removeWhere((r) => 
        r.matchingId == room.matchingId && 
        r.partner.id == room.partner.id);
    _activeChatRooms.add(room);
  }

  /// Mock 데이터 (개발/테스트용)
  /*
  Future<List<ChatRoom>> _getMockChatRooms(User currentUser) async { // 사용되지 않음
    // 로컬 저장된 채팅방 반환 → 없으면 메모리 활성 목록
    final saved = await _localStore.loadRooms(currentUser.id);
    if (saved.isNotEmpty) return saved;
    return _activeChatRooms;
  }
  */

  /// 매칭 참여시 백엔드에 채팅방 생성 요청
  Future<bool> createChatRoom(int matchingId, User host, User guest) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/chat/rooms/direct'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'targetUserId': guest.id,
          'matchingId': matchingId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // 채팅방 생성 이벤트 전파 (리스트 즉시 갱신)
          ChatEventBus.instance.emit(ChatRoomCreated(matchingId));
          return true;
        }
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('채팅방 생성 실패: $e');
      }
      return false;
    }
  }

  /// 채팅 진입을 위해 매칭 상세를 가져온다
  Future<Matching?> getMatchingForRoom(int matchingId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return _matchingService.getMatchingById(matchingId);
      }
      
      return await ApiService.getMatchingDetail(matchingId, token);
    } catch (e) {
      if (kDebugMode) {
        print('매칭 조회 실패, Mock으로 폴백: $e');
      }
      return _matchingService.getMatchingById(matchingId);
    }
  }

  /// 매칭 리스트를 채팅방 리스트로 변환
  List<ChatRoom> _toChatRooms(List<Matching> list, User me) {
    final rooms = <ChatRoom>[];
    for (final m in list) {
      // 채팅 가능한 상태만 포함 (recruiting, confirmed, completed)
      if (!{'recruiting', 'confirmed', 'completed'}.contains(m.status)) continue;

      final isHost = m.host.id == me.id;
      
      if (isHost) {
        // 호스트인 경우: 각 게스트와 개별 채팅방 생성
        if (m.guests != null && m.guests!.isNotEmpty) {
          for (final guest in m.guests!) {
            rooms.add(
              ChatRoom(
                matchingId: m.id,
                courtName: m.courtName,
                date: m.date,
                timeSlot: m.timeSlot,
                myRole: 'host',
                partner: guest,
                lastMessageAt: m.updatedAt,
                unreadCount: 0,
                status: m.status,
              ),
            );
          }
        }
      } else {
        // 게스트인 경우: 호스트와만 채팅방 생성
        rooms.add(
          ChatRoom(
            matchingId: m.id,
            courtName: m.courtName,
            date: m.date,
            timeSlot: m.timeSlot,
            myRole: 'guest',
            partner: m.host,
            lastMessageAt: m.updatedAt,
            unreadCount: 0,
            status: m.status,
          ),
        );
      }
    }
    
    // 최신순 정렬
    rooms.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return rooms;
  }

  /// 채팅 메시지 조회
  Future<List<ChatMessage>> getChatMessages({
    required int roomId,
    int? lastMessageId,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/chat/rooms/$roomId/messages').replace(
          queryParameters: {
            'page': '1',
            'limit': limit.toString(),
          },
        ),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final messages = (data['data'] as List)
              .map((json) => ChatMessage.fromJson(json))
              .toList();
          
          // 로컬 캐시에도 저장
          for (final message in messages) {
            await _localStore.saveMessage(roomId, message);
          }

          return messages;
        }
      }

      // API 실패 시 로컬 캐시에서 조회
      return await _localStore.loadMessages(roomId, limit: limit);
    } catch (e) {
      print('메시지 조회 실패: $e');
      // API 실패 시 로컬 캐시에서 조회
      return await _localStore.loadMessages(roomId, limit: limit);
    }
  }

  /// 메시지 전송
  Future<ChatMessage?> sendMessage({
    required int roomId,
    required String content,
    String? messageType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/chat/rooms/$roomId/messages'),
        headers: {
          'Authorization': 'Bearer ${await _getAuthToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
          'type': messageType ?? 'text',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final message = ChatMessage.fromJson(data['data']);
          
          // 로컬 캐시에도 저장
          await _localStore.saveMessage(roomId, message);

          return message;
        }
      }

      throw Exception('메시지 전송 실패: ${response.statusCode}');
    } catch (e) {
      print('메시지 전송 실패: $e');
      return null;
    }
  }

  /// 채팅방 참여자 조회
  Future<List<User>> getChatRoomMembers(int roomId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return [];
      }

      // 실제 API 호출
      final members = await ApiService.getChatRoomMembers(
        roomId: roomId,
        token: token,
      );

      // API 응답을 User로 변환
      return members.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('채팅방 참여자 조회 실패: $e');
      return [];
    }
  }

  /// 채팅방 나가기
  Future<bool> leaveChatRoom(int roomId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      // 실제 API 호출
      await ApiService.leaveChatRoom(
        roomId: roomId,
        token: token,
      );

      // 로컬 캐시에서도 제거 (메서드가 구현되면 활성화)
      // await _localStore.removeRoom(roomId);

      return true;
    } catch (e) {
      print('채팅방 나가기 실패: $e');
      return false;
    }
  }

  /// 메시지 읽음 처리
  Future<bool> markMessagesAsRead({
    required int roomId,
    int? lastReadMessageId,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }

      // 실제 API 호출
      await ApiService.markMessagesAsRead(
        roomId: roomId,
        token: token,
        lastReadMessageId: lastReadMessageId,
      );

      return true;
    } catch (e) {
      print('메시지 읽음 처리 실패: $e');
      return false;
    }
  }
}