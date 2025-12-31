import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'transaction.g.dart';

enum TransactionCategory {
  racket,    // 라켓
  clothing,  // 의류
  ball,      // 볼
  other,     // 기타
}

enum TransactionStatus {
  available,    // 판매중
  reserved,     // 예약중
  sold,         // 판매완료
  cancelled,    // 취소됨
}

@JsonSerializable()
class Transaction {
  final int id;
  final String title;
  final String description;
  final String category; // 'racket', 'clothing', 'ball', 'other'
  final int price;
  final int? suggestedPrice; // 제안된 가격
  final List<String> images; // 상품 이미지 URL 목록
  final int sellerId; // 판매자 ID
  final User? seller; // 판매자 정보 (옵션)
  final int? buyerId; // 구매자 ID
  final User? buyer; // 구매자 정보 (옵션)
  final String status; // 'available', 'reserved', 'sold', 'cancelled'
  final String? location; // 거래 희망 지역
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? soldAt; // 판매 완료 시간
  final int? chatRoomId; // 거래 관련 채팅방 ID

  Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.suggestedPrice,
    required this.images,
    required this.sellerId,
    this.seller,
    this.buyerId,
    this.buyer,
    required this.status,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.soldAt,
    this.chatRoomId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  // 카테고리 한글 변환
  String get categoryName {
    switch (category) {
      case 'racket':
        return '라켓';
      case 'clothing':
        return '의류';
      case 'ball':
        return '볼';
      case 'other':
        return '기타';
      default:
        return category;
    }
  }

  // 상태 한글 변환
  String get statusName {
    switch (status) {
      case 'available':
        return '판매중';
      case 'reserved':
        return '예약중';
      case 'sold':
        return '판매완료';
      case 'cancelled':
        return '취소됨';
      default:
        return status;
    }
  }

  // 상태 색상
  String get statusColor {
    switch (status) {
      case 'available':
        return '#4CAF50'; // 초록색
      case 'reserved':
        return '#FF9800'; // 주황색
      case 'sold':
        return '#9E9E9E'; // 회색
      case 'cancelled':
        return '#F44336'; // 빨간색
      default:
        return '#000000';
    }
  }

  // copyWith 메서드
  Transaction copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    int? price,
    int? suggestedPrice,
    List<String>? images,
    int? sellerId,
    User? seller,
    int? buyerId,
    User? buyer,
    String? status,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? soldAt,
    int? chatRoomId,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      seller: seller ?? this.seller,
      buyerId: buyerId ?? this.buyerId,
      buyer: buyer ?? this.buyer,
      status: status ?? this.status,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      soldAt: soldAt ?? this.soldAt,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }
}

