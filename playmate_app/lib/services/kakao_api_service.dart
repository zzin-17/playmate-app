import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/tennis_court.dart';

/// 카카오 API를 통한 테니스장 데이터 조회 서비스
class KakaoApiService {
  static final KakaoApiService _instance = KakaoApiService._internal();
  factory KakaoApiService() => _instance;
  KakaoApiService._internal();

  /// 카카오 API 헤더
  Map<String, String> get _headers => {
    'Authorization': 'KakaoAK ${AppConstants.kakaoApiKey}',
    'Content-Type': 'application/json',
  };

  /// 키워드로 테니스장 검색
  Future<List<TennisCourt>> searchTennisCourts({
    String? query,
    String? region,
    String? district,
    int page = 1,
    int size = 15,
  }) async {
    try {
      print('🔍 카카오 API 테니스장 검색 시작: $query');
      
      // 검색 쿼리 구성
      String searchQuery = query ?? '테니스장';
      if (region != null && region != '전체') {
        searchQuery += ' $region';
      }
      if (district != null && district != '전체') {
        searchQuery += ' $district';
      }
      
      // 검색어가 너무 구체적이면 일반화
      if (searchQuery.length > 10) {
        searchQuery = '테니스장';
        if (region != null && region != '전체') {
          searchQuery += ' $region';
        }
        if (district != null && district != '전체') {
          searchQuery += ' $district';
        }
      }

      final uri = Uri.parse(AppConstants.kakaoLocalSearchUrl).replace(
        queryParameters: {
          'query': searchQuery,
          'page': page.toString(),
          'size': size.toString(),
          'sort': 'accuracy', // 정확도순 정렬
        },
      );

      print('🌐 카카오 API 요청: $uri');

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>;
        
        print('✅ 카카오 API 응답 성공: ${documents.length}개 결과');

        final tennisCourts = <TennisCourt>[];
        int courtId = 1;

        for (final doc in documents) {
          try {
            final court = _parseKakaoDocument(doc, courtId++);
            if (court != null) {
              tennisCourts.add(court);
            }
          } catch (e) {
            print('⚠️ 카카오 데이터 파싱 오류: $e');
            continue;
          }
        }

        print('🎾 파싱된 테니스장 수: ${tennisCourts.length}개');
        return tennisCourts;
      } else {
        print('❌ 카카오 API 오류: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ 카카오 API 호출 실패: $e');
      return [];
    }
  }

  /// 카테고리로 테니스장 검색 (스포츠 시설)
  Future<List<TennisCourt>> searchTennisCourtsByCategory({
    String? region,
    String? district,
    int page = 1,
    int size = 15,
  }) async {
    try {
      print('🔍 카카오 API 카테고리 검색 시작: 스포츠 시설');
      
      // 지역 필터링
      String rect = '';
      if (region != null && region != '전체') {
        // 서울시 경계 좌표 (대략적)
        if (region == '서울') {
          rect = '126.734086,37.413294,127.269311,37.715133';
        }
        // 다른 지역도 추가 가능
      }

      final queryParams = <String, String>{
        'category_group_code': 'CT1', // 문화시설 > 스포츠시설
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'accuracy',
      };

      if (rect.isNotEmpty) {
        queryParams['rect'] = rect;
      }

      final uri = Uri.parse(AppConstants.kakaoCategorySearchUrl).replace(
        queryParameters: queryParams,
      );

      print('🌐 카카오 API 요청: $uri');

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>;
        
        print('✅ 카카오 API 응답 성공: ${documents.length}개 결과');

        final tennisCourts = <TennisCourt>[];
        int courtId = 1;

        for (final doc in documents) {
          try {
            // 테니스장 관련 키워드 필터링
            final placeName = doc['place_name']?.toString().toLowerCase() ?? '';
            final categoryName = doc['category_name']?.toString().toLowerCase() ?? '';
            
            if (placeName.contains('테니스') || 
                placeName.contains('tennis') ||
                categoryName.contains('테니스') ||
                categoryName.contains('tennis')) {
              
              final court = _parseKakaoDocument(doc, courtId++);
              if (court != null) {
                tennisCourts.add(court);
              }
            }
          } catch (e) {
            print('⚠️ 카카오 데이터 파싱 오류: $e');
            continue;
          }
        }

        print('🎾 필터링된 테니스장 수: ${tennisCourts.length}개');
        return tennisCourts;
      } else {
        print('❌ 카카오 API 오류: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ 카카오 API 호출 실패: $e');
      return [];
    }
  }

  /// 카카오 API 응답을 TennisCourt 모델로 변환
  TennisCourt? _parseKakaoDocument(Map<String, dynamic> doc, int id) {
    try {
      final placeName = doc['place_name']?.toString() ?? '';
      final addressName = doc['address_name']?.toString() ?? '';
      final roadAddressName = doc['road_address_name']?.toString() ?? '';
      final phone = doc['phone']?.toString() ?? '';
      final categoryName = doc['category_name']?.toString() ?? '';
      // final placeUrl = doc['place_url']?.toString() ?? '';
      
      // 좌표 정보
      final x = double.tryParse(doc['x']?.toString() ?? '0') ?? 0.0;
      final y = double.tryParse(doc['y']?.toString() ?? '0') ?? 0.0;
      
      // 주소에서 지역, 구/군 추출
      final address = roadAddressName.isNotEmpty ? roadAddressName : addressName;
      final region = _extractRegion(address);
      final district = _extractDistrict(address);
      
      // 기본값 설정
      final courtCount = _extractCourtCount(placeName, categoryName);
      final pricePerHour = _estimatePrice(region, district);
      final facilities = _extractFacilities(placeName, categoryName);
      
      return TennisCourt(
        id: id,
        name: placeName,
        address: address,
        lat: y,
        lng: x,
        region: region,
        district: district,
        courtCount: courtCount,
        surfaceType: '하드코트', // 기본값
        hasLighting: _hasLighting(placeName, categoryName),
        hasParking: _hasParking(placeName, categoryName),
        hasShower: _hasShower(placeName, categoryName),
        hasLocker: _hasLocker(placeName, categoryName),
        pricePerHour: pricePerHour,
        operatingHours: '06:00-22:00', // 기본값
        phoneNumber: phone,
        description: categoryName,
        facilities: facilities,
        images: [],
        rating: 4.0, // 기본값
        reviewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ 카카오 데이터 파싱 실패: $e');
      return null;
    }
  }

  /// 주소에서 지역 추출
  String _extractRegion(String address) {
    if (address.contains('서울')) return '서울';
    if (address.contains('경기')) return '경기';
    if (address.contains('인천')) return '인천';
    if (address.contains('부산')) return '부산';
    if (address.contains('대구')) return '대구';
    if (address.contains('광주')) return '광주';
    if (address.contains('대전')) return '대전';
    if (address.contains('울산')) return '울산';
    if (address.contains('세종')) return '세종';
    if (address.contains('강원')) return '강원';
    if (address.contains('충북')) return '충북';
    if (address.contains('충남')) return '충남';
    if (address.contains('전북')) return '전북';
    if (address.contains('전남')) return '전남';
    if (address.contains('경북')) return '경북';
    if (address.contains('경남')) return '경남';
    if (address.contains('제주')) return '제주';
    return '기타';
  }

  /// 주소에서 구/군 추출
  String _extractDistrict(String address) {
    final districts = AppConstants.seoulDistricts;
    for (final district in districts) {
      if (address.contains(district)) {
        return district;
      }
    }
    return '기타';
  }

  /// 코트 수 추출 (이름과 카테고리에서)
  int _extractCourtCount(String placeName, String categoryName) {
    final text = '$placeName $categoryName'.toLowerCase();
    
    // 숫자 패턴 찾기
    final regex = RegExp(r'(\d+)개?코트|코트\s*(\d+)개?|(\d+)면');
    final match = regex.firstMatch(text);
    
    if (match != null) {
      final count = int.tryParse(match.group(1) ?? match.group(2) ?? match.group(3) ?? '0') ?? 0;
      return count > 0 ? count : 2; // 기본값 2개
    }
    
    return 2; // 기본값
  }

  /// 가격 추정
  int _estimatePrice(String region, String district) {
    if (region == '서울') {
      if (['강남구', '서초구', '송파구'].contains(district)) {
        return 30000;
      } else if (['마포구', '영등포구', '용산구'].contains(district)) {
        return 25000;
      } else {
        return 20000;
      }
    } else if (region == '경기') {
      return 20000;
    } else {
      return 15000;
    }
  }

  /// 시설 정보 추출
  List<String> _extractFacilities(String placeName, String categoryName) {
    final facilities = <String>[];
    final text = '$placeName $categoryName'.toLowerCase();
    
    if (text.contains('주차') || text.contains('parking')) {
      facilities.add('주차장');
    }
    if (text.contains('샤워') || text.contains('shower')) {
      facilities.add('샤워실');
    }
    if (text.contains('락커') || text.contains('locker')) {
      facilities.add('락커룸');
    }
    if (text.contains('조명') || text.contains('light')) {
      facilities.add('조명시설');
    }
    if (text.contains('매점') || text.contains('shop')) {
      facilities.add('매점');
    }
    
    // 기본 시설
    if (facilities.isEmpty) {
      facilities.addAll(['주차장', '조명시설']);
    }
    
    return facilities;
  }

  /// 조명 시설 여부
  bool _hasLighting(String placeName, String categoryName) {
    final text = '$placeName $categoryName'.toLowerCase();
    return text.contains('조명') || text.contains('light') || text.contains('야간');
  }

  /// 주차장 여부
  bool _hasParking(String placeName, String categoryName) {
    final text = '$placeName $categoryName'.toLowerCase();
    return text.contains('주차') || text.contains('parking');
  }

  /// 샤워실 여부
  bool _hasShower(String placeName, String categoryName) {
    final text = '$placeName $categoryName'.toLowerCase();
    return text.contains('샤워') || text.contains('shower');
  }

  /// 락커룸 여부
  bool _hasLocker(String placeName, String categoryName) {
    final text = '$placeName $categoryName'.toLowerCase();
    return text.contains('락커') || text.contains('locker');
  }
}
