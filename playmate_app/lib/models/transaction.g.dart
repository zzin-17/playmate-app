// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  price: (json['price'] as num).toInt(),
  suggestedPrice: (json['suggestedPrice'] as num?)?.toInt(),
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  sellerId: (json['sellerId'] as num).toInt(),
  seller: json['seller'] == null
      ? null
      : User.fromJson(json['seller'] as Map<String, dynamic>),
  buyerId: (json['buyerId'] as num?)?.toInt(),
  buyer: json['buyer'] == null
      ? null
      : User.fromJson(json['buyer'] as Map<String, dynamic>),
  status: json['status'] as String,
  location: json['location'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  soldAt: json['soldAt'] == null
      ? null
      : DateTime.parse(json['soldAt'] as String),
  chatRoomId: (json['chatRoomId'] as num?)?.toInt(),
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'price': instance.price,
      'suggestedPrice': instance.suggestedPrice,
      'images': instance.images,
      'sellerId': instance.sellerId,
      'seller': instance.seller,
      'buyerId': instance.buyerId,
      'buyer': instance.buyer,
      'status': instance.status,
      'location': instance.location,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'soldAt': instance.soldAt?.toIso8601String(),
      'chatRoomId': instance.chatRoomId,
    };
