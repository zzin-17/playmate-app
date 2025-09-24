import 'dart:convert';
import '../models/tennis_court.dart';
import 'kakao_api_service.dart';
import 'api_service.dart';

class TennisCourtService {
  static final TennisCourtService _instance = TennisCourtService._internal();
  factory TennisCourtService() => _instance;
  TennisCourtService._internal();

  // 모든 테니스장 조회 (백엔드 API → 카카오 API 순서)
  Future<List<TennisCourt>> getAllCourts() async {
    try {
      // 1. 백엔드 API에서 데이터 가져오기
      print('🎾 백엔드 API에서 테니스장 데이터 조회 시도');
      return await fetchCourtsFromAPI();
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      // 2. 백엔드 API 실패 시 카카오 API 사용
      try {
        return await fetchCourtsFromKakaoAPI();
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // ID로 테니스장 조회 (백엔드 API → 카카오 API 순서)
  Future<TennisCourt?> getCourtById(int id) async {
    try {
      // 1. 백엔드 API에서 데이터 가져오기
      print('🎾 백엔드 API에서 테니스장 상세 조회 시도: ID $id');
      return await fetchCourtByIdFromAPI(id);
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      // 2. 백엔드 API 실패 시 카카오 API에서 검색
      try {
        final courts = await fetchCourtsFromKakaoAPI();
        return courts.isNotEmpty ? courts.first : null;
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // 이름으로 테니스장 검색 (백엔드 API → 카카오 API 순서)
  Future<List<TennisCourt>> searchCourtsByName(String query) async {
    if (query.isEmpty) return await getAllCourts();
    
    try {
      // 1. 백엔드 API에서 검색
      print('🎾 백엔드 API에서 테니스장 검색 시도: "$query"');
      return await searchCourtsFromAPI(query);
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      // 2. 백엔드 API 실패 시 카카오 API에서 검색
      try {
        return await fetchCourtsFromKakaoAPI(query: query);
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // 지역별 테니스장 조회 (백엔드 API → 카카오 API 순서)
  Future<List<TennisCourt>> getCourtsByRegion(String region) async {
    try {
      print('🎾 백엔드 API에서 지역별 테니스장 조회 시도: $region');
      return await fetchCourtsFromAPI(region: region);
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      try {
        return await fetchCourtsFromKakaoAPI(region: region);
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // 구별 테니스장 조회 (백엔드 API → 카카오 API 순서)
  Future<List<TennisCourt>> getCourtsByDistrict(String district) async {
    try {
      print('🎾 백엔드 API에서 구별 테니스장 조회 시도: $district');
      return await fetchCourtsFromAPI(district: district);
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      try {
        return await fetchCourtsFromKakaoAPI(district: district);
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // 필터링된 테니스장 조회 (백엔드 API → 카카오 API 순서)
  Future<List<TennisCourt>> getFilteredCourts({
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
      print('🎾 백엔드 API에서 필터링된 테니스장 조회 시도');
      return await fetchCourtsFromAPI(
        region: region,
        district: district,
        hasLighting: hasLighting,
        hasParking: hasParking,
        hasShower: hasShower,
        hasLocker: hasLocker,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
      );
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      try {
        return await fetchCourtsFromKakaoAPI(
          region: region,
          district: district,
        );
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // 인기 테니스장 조회 (백엔드 API → 카카오 API 순서)
  Future<List<TennisCourt>> getPopularCourts({int limit = 10}) async {
    try {
      print('🎾 백엔드 API에서 인기 테니스장 조회 시도');
      return await fetchPopularCourtsFromAPI(limit: limit);
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      try {
        final courts = await fetchCourtsFromKakaoAPI();
        // 평점 기준으로 정렬하여 상위 limit개 반환
        courts.sort((a, b) => b.rating.compareTo(a.rating));
        return courts.take(limit).toList();
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // 최근 추가된 테니스장 조회 (백엔드 API → 카카오 API 순서)
  Future<List<TennisCourt>> getRecentCourts({int limit = 10}) async {
    try {
      print('🎾 백엔드 API에서 최근 테니스장 조회 시도');
      return await fetchCourtsFromAPI(sortBy: 'createdAt', limit: limit);
    } catch (e) {
      print('❌ 백엔드 API 실패: $e');
      print('🔄 카카오 API로 폴백 시도');
      
      try {
        final courts = await fetchCourtsFromKakaoAPI();
        // 생성일 기준으로 정렬하여 상위 limit개 반환
        courts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return courts.take(limit).toList();
      } catch (kakaoError) {
        print('❌ 카카오 API도 실패: $kakaoError');
        throw Exception('모든 API 호출 실패 - 백엔드: $e, 카카오: $kakaoError');
      }
    }
  }

  // 백엔드 API를 통한 테니스장 데이터 조회
  Future<List<TennisCourt>> fetchCourtsFromAPI({
    String? query,
    String? region,
    String? district,
    bool? hasLighting,
    bool? hasParking,
    bool? hasShower,
    bool? hasLocker,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    int? limit,
  }) async {
    try {
      final response = await ApiService.get('/api/tennis-courts');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> courtsData = responseData['data'] ?? [];
          return courtsData.map((data) => TennisCourt.fromJson(data)).toList();
        } else {
          throw Exception('백엔드 API 응답 오류: ${responseData['message']}');
        }
      } else {
        throw Exception('백엔드 API HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('백엔드 API 호출 실패: $e');
    }
  }

  // 백엔드 API를 통한 특정 테니스장 조회
  Future<TennisCourt?> fetchCourtByIdFromAPI(int id) async {
    try {
      final response = await ApiService.get('/api/tennis-courts/$id');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return TennisCourt.fromJson(responseData['data']);
        } else {
          return null;
        }
      } else {
        throw Exception('백엔드 API HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('백엔드 API 호출 실패: $e');
    }
  }

  // 백엔드 API를 통한 테니스장 검색
  Future<List<TennisCourt>> searchCourtsFromAPI(String query) async {
    try {
      final response = await ApiService.get('/api/tennis-courts/search?q=$query');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> courtsData = responseData['data'] ?? [];
          return courtsData.map((data) => TennisCourt.fromJson(data)).toList();
        } else {
          throw Exception('백엔드 API 응답 오류: ${responseData['message']}');
        }
      } else {
        throw Exception('백엔드 API HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('백엔드 API 호출 실패: $e');
    }
  }

  // 백엔드 API를 통한 인기 테니스장 조회
  Future<List<TennisCourt>> fetchPopularCourtsFromAPI({int limit = 10}) async {
    try {
      final response = await ApiService.get('/api/tennis-courts/popular?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> courtsData = responseData['data'] ?? [];
          return courtsData.map((data) => TennisCourt.fromJson(data)).toList();
        } else {
          throw Exception('백엔드 API 응답 오류: ${responseData['message']}');
        }
      } else {
        throw Exception('백엔드 API HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('백엔드 API 호출 실패: $e');
    }
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
      
      print('🎾 카카오 API 조회 완료: ${allCourts.length}개 테니스장 발견');
      return allCourts;
    } catch (e) {
      print('❌ 카카오 API 호출 실패: $e');
      throw Exception('카카오 API 호출 실패: $e');
    }
  }
}