import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// 실제 채팅방 API에서 조회
  Future<List<ChatRoom>> _getChatRoomsFromAPI(User currentUser) async {
    final token = await _getAuthToken();
    if (token == null) {
      // 토큰이 없으면 로컬 캐시 반환
      final localRooms = await _localStore.loadRooms(currentUser.id);
      return localRooms;
    }
    
    try {
      final rooms = await ApiService.getMyChatRooms(token);
      // 서버 방 목록을 로컬에도 저장 (UX 향상)
      for (final r in rooms) {
        await _localStore.upsertRoom(currentUser.id, r);
      }
      if (rooms.isEmpty) {
        // 서버가 비었으면 로컬 캐시 반환
        final localRooms = await _localStore.loadRooms(currentUser.id);
        return localRooms;
      }
      return rooms.map((r) => ChatRoom.fromJson(r)).toList();
    } catch (e) {
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
  Future<List<ChatRoom>> _getMockChatRooms(User currentUser) async {
    // 로컬 저장된 채팅방 반환 → 없으면 메모리 활성 목록
    final saved = await _localStore.loadRooms(currentUser.id);
    if (saved.isNotEmpty) return saved;
    return _activeChatRooms;
  }

  /// 매칭 참여시 백엔드에 채팅방 생성 요청
  Future<bool> createChatRoom(int matchingId, User host, User guest) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return false;
      }
      
      await ApiService.createChatRoom(
        matchingId: matchingId, 
        hostId: host.id, 
        guestId: guest.id,
        token: token,
      );
      // 채팅방 생성 이벤트 전파 (리스트 즉시 갱신)
      ChatEventBus.instance.emit(ChatRoomCreated(matchingId));
      return true;
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
                lastMessageAt: m.updatedAt ?? m.createdAt,
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
            lastMessageAt: m.updatedAt ?? m.createdAt,
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
      final token = await _getAuthToken();
      if (token == null) {
        // 토큰이 없으면 로컬 캐시에서 조회
        // return await _localStore.loadMessages(roomId, limit: limit);
        return []; // 임시로 빈 목록 반환
      }

      // 실제 API 호출
      final messages = await ApiService.getChatMessages(
        roomId: roomId,
        token: token,
        lastMessageId: lastMessageId,
        limit: limit,
      );

      // API 응답을 ChatMessage로 변환
      final chatMessages = messages.map((json) => ChatMessage.fromJson(json)).toList();
      
      // 로컬 캐시에도 저장 (메서드가 구현되면 활성화)
      // for (final message in chatMessages) {
      //   await _localStore.saveMessage(roomId, message);
      // }

      return chatMessages;
    } catch (e) {
      print('메시지 조회 실패, 로컬 캐시 사용: $e');
      // API 실패 시 로컬 캐시에서 조회
      // return await _localStore.loadMessages(roomId, limit: limit);
      return []; // 임시로 빈 목록 반환
    }
  }

  /// 메시지 전송
  Future<ChatMessage?> sendMessage({
    required int roomId,
    required String content,
    String? messageType,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 실제 API 호출
      final response = await ApiService.sendMessage(
        roomId: roomId,
        content: content,
        token: token,
        messageType: messageType,
      );

      // 응답을 ChatMessage로 변환
      final message = ChatMessage.fromJson(response);
      
      // 로컬 캐시에도 저장 (메서드가 구현되면 활성화)
      // await _localStore.saveMessage(roomId, message);

      return message;
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