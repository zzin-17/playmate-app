import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tennis_court.dart';
import '../constants/app_constants.dart';
import 'kakao_api_service.dart';

class TennisCourtService {
  static final TennisCourtService _instance = TennisCourtService._internal();
  factory TennisCourtService() => _instance;
  TennisCourtService._internal();

  // 실제 테니스장 데이터 (향후 API에서 가져올 예정)
  static final List<TennisCourt> _tennisCourts = [
    TennisCourt(
      id: 1,
      name: '잠실종합운동장',
      address: '서울특별시 송파구 올림픽로 25',
      lat: 37.512,
      lng: 127.102,
      region: '서울',
      district: '송파구',
      courtCount: 12,
      surfaceType: '하드코트',
      hasLighting: true,
      hasParking: true,
      hasShower: true,
      hasLocker: true,
      pricePerHour: 30000,
      operatingHours: '06:00-22:00',
      phoneNumber: '02-2240-8800',
      description: '올림픽공원 내 위치한 대형 테니스장',
      facilities: ['주차장', '샤워실', '락커룸', '조명시설'],
      images: [],
      rating: 4.5,
      reviewCount: 128,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    TennisCourt(
      id: 2,
      name: '양재시민의숲',
      address: '서울특별시 서초구 매헌로 99',
      lat: 37.469,
      lng: 127.038,
      region: '서울',
      district: '서초구',
      courtCount: 8,
      surfaceType: '하드코트',
      hasLighting: true,
      hasParking: true,
      hasShower: true,
      hasLocker: true,
      pricePerHour: 25000,
      operatingHours: '06:00-22:00',
      phoneNumber: '02-2155-6200',
      description: '시민의숲 내 위치한 테니스장',
      facilities: ['주차장', '샤워실', '락커룸', '조명시설'],
      images: [],
      rating: 4.3,
      reviewCount: 95,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    TennisCourt(
      id: 3,
      name: '올림픽공원 테니스장',
      address: '서울특별시 송파구 올림픽로 424',
      lat: 37.516,
      lng: 127.121,
      region: '서울',
      district: '송파구',
      courtCount: 6,
      surfaceType: '하드코트',
      hasLighting: true,
      hasParking: true,
      hasShower: false,
      hasLocker: true,
      pricePerHour: 20000,
      operatingHours: '06:00-21:00',
      phoneNumber: '02-410-1114',
      description: '올림픽공원 내 공원 테니스장',
      facilities: ['주차장', '락커룸', '조명시설'],
      images: [],
      rating: 4.1,
      reviewCount: 67,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    TennisCourt(
      id: 4,
      name: '한강공원 테니스장',
      address: '서울특별시 영등포구 여의도동',
      lat: 37.526,
      lng: 126.896,
      region: '서울',
      district: '영등포구',
      courtCount: 4,
      surfaceType: '하드코트',
      hasLighting: true,
      hasParking: true,
      hasShower: false,
      hasLocker: false,
      pricePerHour: 15000,
      operatingHours: '06:00-22:00',
      phoneNumber: '02-2670-3114',
      description: '한강공원 내 위치한 테니스장',
      facilities: ['주차장', '조명시설'],
      images: [],
      rating: 3.9,
      reviewCount: 43,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    TennisCourt(
      id: 5,
      name: '분당테니스장',
      address: '경기도 성남시 분당구 판교역로 166',
      lat: 37.350,
      lng: 127.108,
      region: '경기',
      district: '성남시 분당구',
      courtCount: 10,
      surfaceType: '하드코트',
      hasLighting: true,
      hasParking: true,
      hasShower: true,
      hasLocker: true,
      pricePerHour: 28000,
      operatingHours: '06:00-22:00',
      phoneNumber: '031-729-8000',
      description: '분당 지역 대형 테니스장',
      facilities: ['주차장', '샤워실', '락커룸', '조명시설'],
      images: [],
      rating: 4.4,
      reviewCount: 156,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    TennisCourt(
      id: 6,
      name: '인천대공원 테니스장',
      address: '인천광역시 남동구 구월동 1234',
      lat: 37.448,
      lng: 126.752,
      region: '인천',
      district: '남동구',
      courtCount: 6,
      surfaceType: '하드코트',
      hasLighting: true,
      hasParking: true,
      hasShower: true,
      hasLocker: true,
      pricePerHour: 22000,
      operatingHours: '06:00-22:00',
      phoneNumber: '032-440-8000',
      description: '인천대공원 내 위치한 테니스장',
      facilities: ['주차장', '샤워실', '락커룸', '조명시설'],
      images: [],
      rating: 4.2,
      reviewCount: 89,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  // 모든 테니스장 조회
  List<TennisCourt> getAllCourts() {
    return List.unmodifiable(_tennisCourts);
  }

  // ID로 테니스장 조회
  TennisCourt? getCourtById(int id) {
    try {
      return _tennisCourts.firstWhere((court) => court.id == id);
    } catch (e) {
      return null;
    }
  }

  // 이름으로 테니스장 검색
  List<TennisCourt> searchCourtsByName(String query) {
    if (query.isEmpty) return getAllCourts();
    
    return _tennisCourts.where((court) => 
      court.name.toLowerCase().contains(query.toLowerCase()) ||
      court.address.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // 지역별 테니스장 조회
  List<TennisCourt> getCourtsByRegion(String region) {
    return _tennisCourts.where((court) => court.region == region).toList();
  }

  // 구별 테니스장 조회
  List<TennisCourt> getCourtsByDistrict(String district) {
    return _tennisCourts.where((court) => court.district == district).toList();
  }

  // 필터링된 테니스장 조회
  List<TennisCourt> getFilteredCourts({
    String? region,
    String? district,
    bool? hasLighting,
    bool? hasParking,
    bool? hasShower,
    bool? hasLocker,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    return _tennisCourts.where((court) {
      if (region != null && court.region != region) return false;
      if (district != null && court.district != district) return false;
      if (hasLighting != null && court.hasLighting != hasLighting) return false;
      if (hasParking != null && court.hasParking != hasParking) return false;
      if (hasShower != null && court.hasShower != hasShower) return false;
      if (hasLocker != null && court.hasLocker != hasLocker) return false;
      if (minPrice != null && court.pricePerHour < minPrice) return false;
      if (maxPrice != null && court.pricePerHour > maxPrice) return false;
      if (minRating != null && court.rating < minRating) return false;
      return true;
    }).toList();
  }

  // 인기 테니스장 조회 (평점 기준)
  List<TennisCourt> getPopularCourts({int limit = 10}) {
    final sortedCourts = List<TennisCourt>.from(_tennisCourts);
    sortedCourts.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedCourts.take(limit).toList();
  }

  // 최근 추가된 테니스장 조회
  List<TennisCourt> getRecentCourts({int limit = 10}) {
    final sortedCourts = List<TennisCourt>.from(_tennisCourts);
    sortedCourts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedCourts.take(limit).toList();
  }

  // 카카오 API를 통한 실제 테니스장 데이터 조회
  Future<List<TennisCourt>> fetchCourtsFromKakaoAPI({
    String? query,
    String? region,
    String? district,
    int page = 1,
    int size = 15, // 카카오 API 최대 허용 개수
  }) async {
    try {
      print('🎾 카카오 API를 통한 테니스장 조회 시작');
      
      final kakaoService = KakaoApiService();
      
      // 키워드 검색과 카테고리 검색을 병렬로 실행
      final futures = <Future<List<TennisCourt>>>[
        kakaoService.searchTennisCourts(
          query: query,
          region: region,
          district: district,
          page: page,
          size: size,
        ),
        kakaoService.searchTennisCourtsByCategory(
          region: region,
          district: district,
          page: page,
          size: size,
        ),
        // 추가 검색: "테니스" 키워드로도 검색
        if (query != null && query.isNotEmpty)
          kakaoService.searchTennisCourts(
            query: '테니스',
            region: region,
            district: district,
            page: page,
            size: size,
          ),
      ];
      
      final results = await Future.wait(futures);
      
      // 결과 합치기 및 중복 제거
      final allCourts = <TennisCourt>[];
      final seenNames = <String>{};
      
      for (final courts in results) {
        for (final court in courts) {
          if (!seenNames.contains(court.name)) {
            seenNames.add(court.name);
            allCourts.add(court);
          }
        }
      }
      
      print('✅ 카카오 API 조회 완료: ${allCourts.length}개 테니스장');
      return allCourts;
    } catch (e) {
      print('❌ 카카오 API 호출 실패: $e');
      // API 실패 시 로컬 데이터 반환
      return getAllCourts();
    }
  }

  // 기존 백엔드 API 연동 메서드 (폴백용)
  Future<List<TennisCourt>> fetchCourtsFromAPI({
    String? region,
    String? district,
    bool? hasLighting,
    bool? hasParking,
    bool? hasShower,
    bool? hasLocker,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (region != null && region != '전체') queryParams['region'] = region;
      if (district != null && district != '전체') queryParams['district'] = district;
      if (hasLighting != null) queryParams['hasLighting'] = hasLighting.toString();
      if (hasParking != null) queryParams['hasParking'] = hasParking.toString();
      if (hasShower != null) queryParams['hasShower'] = hasShower.toString();
      if (hasLocker != null) queryParams['hasLocker'] = hasLocker.toString();
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (minRating != null) queryParams['minRating'] = minRating.toString();

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.apiVersion}/tennis-courts').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final courts = (data['data'] as List)
              .map((json) => TennisCourt.fromJson(json))
              .toList();
          return courts;
        }
      }
      
      // API 실패 시 카카오 API 시도
      return await fetchCourtsFromKakaoAPI(
        region: region,
        district: district,
      );
    } catch (e) {
      print('백엔드 API 호출 실패, 카카오 API로 폴백: $e');
      // API 실패 시 카카오 API 시도
      return await fetchCourtsFromKakaoAPI(
        region: region,
        district: district,
      );
    }
  }

  Future<TennisCourt?> fetchCourtByIdFromAPI(int id) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/tennis-courts/$id'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TennisCourt.fromJson(data['data']);
        }
      }
      
      // API 실패 시 로컬 데이터 반환
      return getCourtById(id);
    } catch (e) {
      print('테니스장 상세 API 호출 실패: $e');
      // API 실패 시 로컬 데이터 반환
      return getCourtById(id);
    }
  }

  Future<List<TennisCourt>> searchCourtsFromAPI(String query) async {
    try {
      if (query.isEmpty) return await fetchCourtsFromAPI();
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/tennis-courts/search').replace(
          queryParameters: {'q': query},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final courts = (data['data'] as List)
              .map((json) => TennisCourt.fromJson(json))
              .toList();
          return courts;
        }
      }
      
      // API 실패 시 로컬 데이터 반환
      return searchCourtsByName(query);
    } catch (e) {
      print('테니스장 검색 API 호출 실패: $e');
      // API 실패 시 로컬 데이터 반환
      return searchCourtsByName(query);
    }
  }
}
