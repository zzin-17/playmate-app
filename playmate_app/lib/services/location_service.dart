import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // 위도/경도를 시군구로 변환
  Future<String> getDistrictFromCoordinates(double lat, double lng) async {
    try {
      // 카카오 API를 사용하여 역지오코딩
      final response = await http.get(
        Uri.parse('https://dapi.kakao.com/v2/local/geo/coord2regioncode.json?x=$lng&y=$lat'),
        headers: {
          'Authorization': 'KakaoAK YOUR_KAKAO_API_KEY', // 실제 API 키로 교체 필요
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List;
        
        if (documents.isNotEmpty) {
          final region = documents.first;
          final address = region['address_name'] as String;
          
          // 주소 파싱하여 시도/시군구 정보 추출
          return _parseAddress(address);
        }
      }
    } catch (e) {
      print('위치 변환 실패: $e');
    }
    
    // API 실패 시 기본값 반환
    return _getDefaultDistrict(lat, lng);
  }

  // 주소를 파싱하여 적절한 형태로 변환
  String _parseAddress(String address) {
    final parts = address.split(' ');
    
    if (parts.length >= 2) {
      final sido = parts[0]; // 시도 (서울특별시, 경기도, 부산광역시 등)
      final sigungu = parts[1]; // 시군구 (강남구, 수원시, 의정부시 등)
      
      // 구가 있는 경우 (서울, 부산, 대구, 인천, 광주, 대전, 울산)
      if (sido.contains('특별시') || sido.contains('광역시')) {
        return '$sido $sigungu';
      }
      
      // 구가 없는 경우 (경기도, 충청남도 등)
      if (sido.contains('도')) {
        return '$sido $sigungu';
      }
      
      // 기타 경우
      return '$sido $sigungu';
    }
    
    return address;
  }

  // 기본 지역 정보 반환 (API 실패 시)
  String _getDefaultDistrict(double lat, double lng) {
    // 서울 지역 좌표 범위 체크
    if (lat >= 37.4 && lat <= 37.7 && lng >= 126.7 && lng <= 127.2) {
      // 간단한 구역별 분류
      if (lat >= 37.5 && lng >= 127.0) return '서울특별시 강남구';
      if (lat >= 37.5 && lng < 127.0) return '서울특별시 서초구';
      if (lat < 37.5 && lng >= 127.0) return '서울특별시 송파구';
      if (lat < 37.5 && lng < 127.0) return '서울특별시 강동구';
      return '서울특별시';
    }
    
    // 경기도 지역
    if (lat >= 37.2 && lat <= 37.8 && lng >= 126.5 && lng <= 127.5) {
      // 경기도 내 세부 지역 분류
      if (lat >= 37.6 && lng >= 127.0) return '경기도 수원시';
      if (lat >= 37.6 && lng < 127.0) return '경기도 의정부시';
      if (lat < 37.6 && lng >= 127.0) return '경기도 성남시';
      if (lat < 37.6 && lng < 127.0) return '경기도 고양시';
      return '경기도';
    }
    
    // 부산 지역
    if (lat >= 35.0 && lat <= 35.5 && lng >= 128.8 && lng <= 129.3) {
      return '부산광역시';
    }
    
    // 대구 지역
    if (lat >= 35.7 && lat <= 36.0 && lng >= 128.4 && lng <= 128.8) {
      return '대구광역시';
    }
    
    // 인천 지역
    if (lat >= 37.3 && lat <= 37.6 && lng >= 126.4 && lng <= 126.8) {
      return '인천광역시';
    }
    
    // 기타 지역
    return '기타 지역';
  }

  // 간단한 지역명 반환 (API 없이)
  String getSimpleDistrict(double lat, double lng) {
    return _getDefaultDistrict(lat, lng);
  }
}
