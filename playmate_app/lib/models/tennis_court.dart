import 'dart:math';

class TennisCourt {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String region;
  final String district;
  final int courtCount;
  final String surfaceType;
  final bool hasLighting;
  final bool hasParking;
  final bool hasShower;
  final bool hasLocker;
  final int pricePerHour;
  final String operatingHours;
  final String phoneNumber;
  final String description;
  final List<String> facilities;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TennisCourt({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.region,
    required this.district,
    required this.courtCount,
    required this.surfaceType,
    required this.hasLighting,
    required this.hasParking,
    required this.hasShower,
    required this.hasLocker,
    required this.pricePerHour,
    required this.operatingHours,
    required this.phoneNumber,
    required this.description,
    required this.facilities,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'region': region,
      'district': district,
      'courtCount': courtCount,
      'surfaceType': surfaceType,
      'hasLighting': hasLighting,
      'hasParking': hasParking,
      'hasShower': hasShower,
      'hasLocker': hasLocker,
      'pricePerHour': pricePerHour,
      'operatingHours': operatingHours,
      'phoneNumber': phoneNumber,
      'description': description,
      'facilities': facilities,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TennisCourt.fromJson(Map<String, dynamic> json) {
    return TennisCourt(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      region: json['region'],
      district: json['district'],
      courtCount: json['courtCount'],
      surfaceType: json['surfaceType'],
      hasLighting: json['hasLighting'],
      hasParking: json['hasParking'],
      hasShower: json['hasShower'],
      hasLocker: json['hasLocker'],
      pricePerHour: json['pricePerHour'],
      operatingHours: json['operatingHours'],
      phoneNumber: json['phoneNumber'],
      description: json['description'],
      facilities: List<String>.from(json['facilities']),
      images: List<String>.from(json['images']),
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // 복사 생성자
  TennisCourt copyWith({
    int? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    String? region,
    String? district,
    int? courtCount,
    String? surfaceType,
    bool? hasLighting,
    bool? hasParking,
    bool? hasShower,
    bool? hasLocker,
    int? pricePerHour,
    String? operatingHours,
    String? phoneNumber,
    String? description,
    List<String>? facilities,
    List<String>? images,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TennisCourt(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      region: region ?? this.region,
      district: district ?? this.district,
      courtCount: courtCount ?? this.courtCount,
      surfaceType: surfaceType ?? this.surfaceType,
      hasLighting: hasLighting ?? this.hasLighting,
      hasParking: hasParking ?? this.hasParking,
      hasShower: hasShower ?? this.hasShower,
      hasLocker: hasLocker ?? this.hasLocker,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      operatingHours: operatingHours ?? this.operatingHours,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      facilities: facilities ?? this.facilities,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 편의 메서드들
  String get priceText => '${pricePerHour.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원/시간';
  
  String get ratingText => '${rating.toStringAsFixed(1)} (${reviewCount}개 리뷰)';
  
  String get facilitiesText => facilities.join(', ');
  
  bool get isOpen {
    final now = DateTime.now();
    final currentHour = now.hour;
    final operatingHoursList = operatingHours.split('-');
    if (operatingHoursList.length != 2) return true;
    
    final openHour = int.parse(operatingHoursList[0].split(':')[0]);
    final closeHour = int.parse(operatingHoursList[1].split(':')[0]);
    
    return currentHour >= openHour && currentHour < closeHour;
  }
  
  String get operatingStatus => isOpen ? '운영중' : '운영종료';
  
  // 거리 계산 (단순화된 버전)
  double calculateDistance(double userLat, double userLng) {
    const double earthRadius = 6371; // 지구 반지름 (km)
    
    final dLat = _degreesToRadians(lat - userLat);
    final dLng = _degreesToRadians(lng - userLng);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userLat)) * cos(_degreesToRadians(lat)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
  
  String getDistanceText(double userLat, double userLng) {
    final distance = calculateDistance(userLat, userLng);
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }
}
