import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';
import 'user.dart';

part 'matching.g.dart';

enum MatchingType { host, guest }
enum MatchingStatus { recruiting, confirmed, completed, cancelled }

@JsonSerializable()
class Matching {
  final int id;
  final String type; // 'host' or 'guest'
  final String courtName;
  final double courtLat;
  final double courtLng;
  final DateTime date;
  final String timeSlot;
  final int? minLevel;
  final int? maxLevel;
  final int? minAge; // 최소 연령대 (10, 20, 30, 40, 50, 60)
  final int? maxAge; // 최대 연령대 (10, 20, 30, 40, 50, 60)

  final String gameType; // 'mixed', 'male_doubles', 'female_doubles', 'singles', 'rally'
  final int maleRecruitCount;
  final int femaleRecruitCount;
  final String status;
  final String? message;
  final int? guestCost;
  final bool isFollowersOnly; // 팔로워 전용 공개 여부
  final User host;
  final List<User>? guests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? recoveryCount; // 취소된 매칭을 모집중으로 복구한 횟수
  
  // 신청 상태 관련 필드들 추가
  final List<int>? appliedUserIds; // 신청한 사용자 ID 목록
  final List<int>? confirmedUserIds; // 확정된 사용자 ID 목록
  
  // 상태 변경 시간 기록
  final DateTime? completedAt; // 완료된 시간
  final DateTime? cancelledAt; // 취소된 시간

  Matching({
    required this.id,
    required this.type,
    required this.courtName,
    required this.courtLat,
    required this.courtLng,
    required this.date,
    required this.timeSlot,
    this.minLevel,
    this.maxLevel,
    this.minAge,
    this.maxAge,

    required this.gameType,
    required this.maleRecruitCount,
    required this.femaleRecruitCount,
    required this.status,
    this.message,
    this.guestCost,
    this.isFollowersOnly = false,
    required this.host,
    this.guests,
    required this.createdAt,
    required this.updatedAt,
    this.recoveryCount,
    this.appliedUserIds, // 신청한 사용자 ID 목록
    this.confirmedUserIds, // 확정된 사용자 ID 목록
    this.completedAt, // 완료된 시간
    this.cancelledAt, // 취소된 시간
  });

  factory Matching.fromJson(Map<String, dynamic> json) {
    try {
      // 완전한 null 안전성을 위한 데이터 정제
      final safeJson = Map<String, dynamic>.from(json);
      
      // 숫자 필드들 안전하게 처리 (null → 기본값)
      safeJson['minLevel'] = safeJson['minLevel'] ?? 1;
      safeJson['maxLevel'] = safeJson['maxLevel'] ?? 5;
      safeJson['minAge'] = safeJson['minAge'] ?? 20;
      safeJson['maxAge'] = safeJson['maxAge'] ?? 60;
      safeJson['maleRecruitCount'] = safeJson['maleRecruitCount'] ?? 0;
      safeJson['femaleRecruitCount'] = safeJson['femaleRecruitCount'] ?? 0;
      safeJson['guestCost'] = safeJson['guestCost'] ?? 0;
      safeJson['recoveryCount'] = safeJson['recoveryCount'] ?? 0;
      
      // 배열 필드들 안전하게 처리 (null → 빈 배열)
      safeJson['appliedUserIds'] = safeJson['appliedUserIds'] ?? [];
      safeJson['confirmedUserIds'] = safeJson['confirmedUserIds'] ?? [];
      safeJson['guests'] = safeJson['guests'] ?? [];
      
      // DateTime 필드들 안전하게 처리 (null → null 유지, 올바른 타입)
      if (safeJson['completedAt'] != null && safeJson['completedAt'] != 'null') {
        safeJson['completedAt'] = DateTime.tryParse(safeJson['completedAt'].toString())?.toIso8601String();
      } else {
        safeJson['completedAt'] = null;
      }
      
      if (safeJson['cancelledAt'] != null && safeJson['cancelledAt'] != 'null') {
        safeJson['cancelledAt'] = DateTime.tryParse(safeJson['cancelledAt'].toString())?.toIso8601String();
      } else {
        safeJson['cancelledAt'] = null;
      }
      
      // Boolean 필드들 안전하게 처리
      safeJson['isFollowersOnly'] = safeJson['isFollowersOnly'] ?? false;
      
      // String 필드들 기본값 처리
      safeJson['type'] = safeJson['type'] ?? 'host';
      safeJson['courtName'] = safeJson['courtName'] ?? '테니스장';
      safeJson['timeSlot'] = safeJson['timeSlot'] ?? '18:00~20:00';
      safeJson['gameType'] = safeJson['gameType'] ?? 'mixed';
      safeJson['status'] = safeJson['status'] ?? 'recruiting';
      
      // Double 필드들 기본값 처리
      safeJson['courtLat'] = safeJson['courtLat'] ?? 37.5665;
      safeJson['courtLng'] = safeJson['courtLng'] ?? 126.978;
      
      // host 객체 안전성 검증
      if (safeJson['host'] != null) {
        final hostData = Map<String, dynamic>.from(safeJson['host']);
        
        // User 모델에 필요한 필수 필드들 확인 및 기본값 추가
        hostData['id'] = hostData['id'] ?? 0;
        hostData['nickname'] = hostData['nickname'] ?? 'Unknown';
        hostData['email'] = hostData['email'] ?? 'unknown@example.com';
        hostData['createdAt'] = hostData['createdAt'] ?? DateTime.now().toIso8601String();
        hostData['updatedAt'] = hostData['updatedAt'] ?? DateTime.now().toIso8601String();
        
        safeJson['host'] = hostData;
      } else {
        // host가 null인 경우 기본 host 생성
        safeJson['host'] = {
          'id': 0,
          'nickname': 'Unknown Host',
          'email': 'unknown@example.com',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
      }
      
      print('✅ Matching.fromJson 안전 처리 완료: ${safeJson['courtName']} (ID: ${safeJson['id']})');
      return _$MatchingFromJson(safeJson);
    } catch (e) {
      print('❌ Matching.fromJson 실패: $e');
      print('📦 원본 JSON: ${json.toString().substring(0, 500)}...');
      
      // 최후의 수단: 최소한의 Matching 객체 생성
      // API 응답이 {success: true, data: {...}} 구조인 경우 처리
      final actualData = json['data'] ?? json;
      
      return Matching(
        id: actualData['id'] ?? DateTime.now().millisecondsSinceEpoch,
        type: 'host',
        courtName: actualData['courtName'] ?? '알 수 없는 테니스장',
        courtLat: 37.5665,
        courtLng: 126.978,
        date: DateTime.tryParse(actualData['date']?.toString() ?? '') ?? DateTime.now(),
        timeSlot: actualData['timeSlot'] ?? '18:00~20:00',
        gameType: 'mixed',
        maleRecruitCount: 1,
        femaleRecruitCount: 1,
        status: 'recruiting',
        host: User(
          id: actualData['host']?['id'] ?? 0,
          nickname: actualData['host']?['nickname'] ?? 'Unknown',
          email: actualData['host']?['email'] ?? 'unknown@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  Map<String, dynamic> toJson() => _$MatchingToJson(this);

  // 복사 및 수정 메서드
  Matching copyWith({
    int? id,
    String? type,
    String? courtName,
    double? courtLat,
    double? courtLng,
    DateTime? date,
    String? timeSlot,
    int? minLevel,
    int? maxLevel,
    int? minAge,
    int? maxAge,
    String? gameType,
    int? maleRecruitCount,
    int? femaleRecruitCount,
    String? status,
    String? message,
    int? guestCost,
    bool? isFollowersOnly,
    User? host,
    List<User>? guests,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? recoveryCount,
    List<int>? appliedUserIds, // 신청한 사용자 ID 목록
    List<int>? confirmedUserIds, // 확정된 사용자 ID 목록
    DateTime? completedAt, // 완료된 시간
    DateTime? cancelledAt, // 취소된 시간
  }) {
    return Matching(
      id: id ?? this.id,
      type: type ?? this.type,
      courtName: courtName ?? this.courtName,
      courtLat: courtLat ?? this.courtLat,
      courtLng: courtLng ?? this.courtLng,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      minLevel: minLevel ?? this.minLevel,
      maxLevel: maxLevel ?? this.maxLevel,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gameType: gameType ?? this.gameType,
      maleRecruitCount: maleRecruitCount ?? this.maleRecruitCount,
      femaleRecruitCount: femaleRecruitCount ?? this.femaleRecruitCount,
      status: status ?? this.status,
      message: message ?? this.message,
      guestCost: guestCost ?? this.guestCost,
      isFollowersOnly: isFollowersOnly ?? this.isFollowersOnly,
      host: host ?? this.host,
      guests: guests ?? this.guests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recoveryCount: recoveryCount ?? this.recoveryCount,
      appliedUserIds: appliedUserIds ?? this.appliedUserIds, // 신청한 사용자 ID 목록
      confirmedUserIds: confirmedUserIds ?? this.confirmedUserIds, // 확정된 사용자 ID 목록
      completedAt: completedAt ?? this.completedAt, // 완료된 시간
      cancelledAt: cancelledAt ?? this.cancelledAt, // 취소된 시간
    );
  }

  // 구력 범위 텍스트
  String get skillRangeText {
    if (minLevel == null && maxLevel == null) return '제한없음';
    if (minLevel == null) return '~$maxLevel년';
    if (maxLevel == null) return '$minLevel년~';
    if (minLevel == maxLevel) return '$minLevel년';
    return '$minLevel년-$maxLevel년';
  }

  // 연령대 범위 텍스트
  String get ageRangeText {
    if (minAge == null && maxAge == null) {
      return '연령대 제한없음';
    }
    
    // 연령을 10대 단위로 변환
    String _getAgeGroup(int age) {
      if (age < 20) return '10대';
      if (age < 30) return '20대';
      if (age < 40) return '30대';
      if (age < 50) return '40대';
      if (age < 60) return '50대';
      return '60대 이상';
    }
    
    if (minAge == null) {
      return '~${_getAgeGroup(maxAge!)}';
    }
    if (maxAge == null) {
      return '${_getAgeGroup(minAge!)}~';
    }
    
    // 연령대 범위 표시
    final minGroup = _getAgeGroup(minAge!);
    final maxGroup = _getAgeGroup(maxAge!);
    
    if (minGroup == maxGroup) {
      return minGroup;
    } else {
      // 범위 표시 (예: 20-49 → 20대-40대)
      return '${minGroup}-${maxGroup}';
    }
  }

  // 게임 유형 텍스트
  String get gameTypeText {
    switch (gameType) {
      case 'mixed':
        return '혼복';
      case 'male_doubles':
        return '남복';
      case 'female_doubles':
        return '여복';
      case 'singles':
        return '단식';
      case 'rally':
        return '랠리';
      default:
        return '알 수 없음';
    }
  }



  // 상태 텍스트
  String get statusText {
    switch (status) {
      case 'recruiting':
        return '모집중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      case 'deleted':
        return '삭제됨';
      default:
        return '알 수 없음';
    }
  }

  // 복구 횟수 표시 텍스트
  String get recoveryCountText {
    if (recoveryCount == null || recoveryCount == 0) return '';
    return ' (${recoveryCount}회 복구)';
  }

  // 날짜 포맷팅
  String get formattedDate {
    return '${date.month}월 ${date.day}일';
  }

  // 시간대 포맷팅
  String get formattedTime {
    return timeSlot;
  }

  // 모집인원 텍스트 (성별 구분)
  String get recruitCountText {
    final total = maleRecruitCount + femaleRecruitCount;
    if (maleRecruitCount > 0 && femaleRecruitCount > 0) {
      return '${total}명 (남$maleRecruitCount, 여$femaleRecruitCount)';
    } else if (maleRecruitCount > 0) {
      return '${total}명 (남$maleRecruitCount)';
    } else if (femaleRecruitCount > 0) {
      return '${total}명 (여$femaleRecruitCount)';
    } else {
      return '${total}명';
    }
  }

  // 신청 상태 관련 getter 메서드들
  
  // 특정 사용자가 신청했는지 확인
  bool isAppliedBy(int userId) {
    return appliedUserIds?.contains(userId) ?? false;
  }
  
  // 특정 사용자가 확정되었는지 확인
  bool isConfirmedBy(int userId) {
    return confirmedUserIds?.contains(userId) ?? false;
  }
  
  // 신청 가능한지 확인 (모집중 상태이고 신청하지 않은 경우)
  bool get canApply {
    return status == 'recruiting';
  }
  
  // 신청 취소 가능한지 확인 (신청한 상태인 경우)
  bool canCancel(int userId) {
    return isAppliedBy(userId) && !isConfirmedBy(userId);
  }
  
  // 신청자 수
  int get appliedCount {
    return appliedUserIds?.length ?? 0;
  }
  
  // 확정된 신청자 수
  int get confirmedCount {
    return confirmedUserIds?.length ?? 0;
  }
  
  // 남은 모집 인원
  int get remainingCount {
    final total = maleRecruitCount + femaleRecruitCount;
    return total - confirmedCount;
  }

  // 게스트 비용 표시 텍스트
  String get guestCostText {
    if (guestCost == null || guestCost == 0) {
      return '무료';
    }
    return '${NumberFormat('#,###').format(guestCost)}원';
  }
  
  // 모집 완료 여부
  bool get isFullyBooked {
    return remainingCount <= 0;
  }

  // 실제 매칭 상태 (백엔드 status 우선, 모집 완료 여부는 보조)
  String get actualStatus {
    // 백엔드에서 설정된 상태가 있으면 우선 사용 (cancelled, deleted 등)
    if (status == 'cancelled' || status == 'deleted' || status == 'completed') {
      return status;
    }
    
    // 모집 완료 여부에 따라 동적 계산 (recruiting, confirmed만)
    if (isFullyBooked) {
      return 'confirmed'; // 모든 인원이 확정되면 '확정' 상태
    } else {
      return 'recruiting'; // 아직 모집 가능하면 '모집중' 상태
    }
  }

  // 실제 상태 텍스트 (동적 계산된 상태 기반)
  String get actualStatusText {
    switch (actualStatus) {
      case 'recruiting':
        return '모집중';
      case 'confirmed':
        return '확정';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      case 'deleted':
        return '삭제됨';
      default:
        return '알 수 없음';
    }
  }

  // 확정된 사용자들의 성별별 인원 수 (guests 리스트에서 계산)
  Map<String, int> get confirmedGenderCount {
    if (guests == null || guests!.isEmpty) {
      return {'male': 0, 'female': 0};
    }
    
    int maleCount = 0;
    int femaleCount = 0;
    
    for (final guest in guests!) {
      if (guest.gender == 'male') {
        maleCount++;
      } else if (guest.gender == 'female') {
        femaleCount++;
      }
    }
    
    return {'male': maleCount, 'female': femaleCount};
  }

  // 확정된 사용자들의 성별별 인원 수 텍스트
  String get confirmedGenderCountText {
    final genderCount = confirmedGenderCount;
    final maleCount = genderCount['male'] ?? 0;
    final femaleCount = genderCount['female'] ?? 0;
    
    if (maleCount > 0 && femaleCount > 0) {
      return '남$maleCount, 여$femaleCount';
    } else if (maleCount > 0) {
      return '남$maleCount';
    } else if (femaleCount > 0) {
      return '여$femaleCount';
    } else {
      return '';
    }
  }
} 