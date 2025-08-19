class Location {
  final String id;
  final String name;
  final String? parentId;
  final List<Location>? subLocations;
  final bool isSelected;

  Location({
    required this.id,
    required this.name,
    this.parentId,
    this.subLocations,
    this.isSelected = false,
  });

  Location copyWith({
    String? id,
    String? name,
    String? parentId,
    List<Location>? subLocations,
    bool? isSelected,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      subLocations: subLocations ?? this.subLocations,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // 전체 선택 여부 확인 (서브 로케이션이 있는 경우)
  bool get isAllSelected {
    if (subLocations == null || subLocations!.isEmpty) return isSelected;
    return subLocations!.every((location) => location.isSelected);
  }

  // 부분 선택 여부 확인
  bool get isPartiallySelected {
    if (subLocations == null || subLocations!.isEmpty) return false;
    final selectedCount = subLocations!.where((location) => location.isSelected).length;
    return selectedCount > 0 && selectedCount < subLocations!.length;
  }
}

// 한국 주요 도시 및 구 데이터
class LocationData {
  static List<Location> get cities {
    return [
      Location(
        id: 'seoul',
        name: '서울',
        subLocations: [
          Location(id: 'seoul_all', name: '서울 전체', parentId: 'seoul'),
          Location(id: 'gangnam', name: '강남구', parentId: 'seoul'),
          Location(id: 'gangdong', name: '강동구', parentId: 'seoul'),
          Location(id: 'gangbuk', name: '강북구', parentId: 'seoul'),
          Location(id: 'gangseo', name: '강서구', parentId: 'seoul'),
          Location(id: 'gwanak', name: '관악구', parentId: 'seoul'),
          Location(id: 'gwangjin', name: '광진구', parentId: 'seoul'),
          Location(id: 'guro', name: '구로구', parentId: 'seoul'),
          Location(id: 'geumcheon', name: '금천구', parentId: 'seoul'),
          Location(id: 'nowon', name: '노원구', parentId: 'seoul'),
          Location(id: 'dobong', name: '도봉구', parentId: 'seoul'),
          Location(id: 'dongdaemun', name: '동대문구', parentId: 'seoul'),
          Location(id: 'dongjak', name: '동작구', parentId: 'seoul'),
          Location(id: 'mapo', name: '마포구', parentId: 'seoul'),
          Location(id: 'seodaemun', name: '서대문구', parentId: 'seoul'),
          Location(id: 'seocho', name: '서초구', parentId: 'seoul'),
          Location(id: 'seongbuk', name: '성북구', parentId: 'seoul'),
          Location(id: 'songpa', name: '송파구', parentId: 'seoul'),
          Location(id: 'yangcheon', name: '양천구', parentId: 'seoul'),
          Location(id: 'yeongdeungpo', name: '영등포구', parentId: 'seoul'),
          Location(id: 'yongsan', name: '용산구', parentId: 'seoul'),
          Location(id: 'eunpyeong', name: '은평구', parentId: 'seoul'),
          Location(id: 'jongno', name: '종로구', parentId: 'seoul'),
          Location(id: 'jung', name: '중구', parentId: 'seoul'),
          Location(id: 'jungnang', name: '중랑구', parentId: 'seoul'),
        ],
      ),
      Location(
        id: 'gyeonggi',
        name: '경기도',
        subLocations: [
          Location(id: 'gyeonggi_all', name: '경기도 전체', parentId: 'gyeonggi'),
          Location(id: 'suwon', name: '수원시', parentId: 'gyeonggi'),
          Location(id: 'seongnam', name: '성남시', parentId: 'gyeonggi'),
          Location(id: 'bucheon', name: '부천시', parentId: 'gyeonggi'),
          Location(id: 'anyang', name: '안양시', parentId: 'gyeonggi'),
          Location(id: 'ansan', name: '안산시', parentId: 'gyeonggi'),
          Location(id: 'pyeongtaek', name: '평택시', parentId: 'gyeonggi'),
          Location(id: 'siheung', name: '시흥시', parentId: 'gyeonggi'),
          Location(id: 'gwangmyeong', name: '광명시', parentId: 'gyeonggi'),
          Location(id: 'gwangju_gyeonggi', name: '광주시', parentId: 'gyeonggi'),
          Location(id: 'yongin', name: '용인시', parentId: 'gyeonggi'),
          Location(id: 'gunpo', name: '군포시', parentId: 'gyeonggi'),
          Location(id: 'uijeongbu', name: '의정부시', parentId: 'gyeonggi'),
          Location(id: 'goyang', name: '고양시', parentId: 'gyeonggi'),
          Location(id: 'namyangju', name: '남양주시', parentId: 'gyeonggi'),
          Location(id: 'osan', name: '오산시', parentId: 'gyeonggi'),
          Location(id: 'hanam', name: '하남시', parentId: 'gyeonggi'),
          Location(id: 'paju', name: '파주시', parentId: 'gyeonggi'),
          Location(id: 'icheon', name: '이천시', parentId: 'gyeonggi'),
          Location(id: 'anseong', name: '안성시', parentId: 'gyeonggi'),
          Location(id: 'gimpo', name: '김포시', parentId: 'gyeonggi'),
          Location(id: 'hwaseong', name: '화성시', parentId: 'gyeonggi'),
          Location(id: 'pocheon', name: '포천시', parentId: 'gyeonggi'),
          Location(id: 'yeoju', name: '여주시', parentId: 'gyeonggi'),
        ],
      ),
      Location(
        id: 'incheon',
        name: '인천',
        subLocations: [
          Location(id: 'incheon_all', name: '인천 전체', parentId: 'incheon'),
          Location(id: 'jung_gu_incheon', name: '중구', parentId: 'incheon'),
          Location(id: 'dong_gu_incheon', name: '동구', parentId: 'incheon'),
          Location(id: 'michuhol', name: '미추홀구', parentId: 'incheon'),
          Location(id: 'yeonsu', name: '연수구', parentId: 'incheon'),
          Location(id: 'namdong', name: '남동구', parentId: 'incheon'),
          Location(id: 'bupyeong', name: '부평구', parentId: 'incheon'),
          Location(id: 'gyeyang', name: '계양구', parentId: 'incheon'),
          Location(id: 'seo_gu_incheon', name: '서구', parentId: 'incheon'),
          Location(id: 'ganghwa', name: '강화군', parentId: 'incheon'),
          Location(id: 'ongjin', name: '옹진군', parentId: 'incheon'),
        ],
      ),
      Location(
        id: 'daejeon',
        name: '대전',
        subLocations: [
          Location(id: 'daejeon_all', name: '대전 전체', parentId: 'daejeon'),
          Location(id: 'jung_gu_daejeon', name: '중구', parentId: 'daejeon'),
          Location(id: 'dong_gu_daejeon', name: '동구', parentId: 'daejeon'),
          Location(id: 'seo_gu_daejeon', name: '서구', parentId: 'daejeon'),
          Location(id: 'yuseong', name: '유성구', parentId: 'daejeon'),
          Location(id: 'daedeok', name: '대덕구', parentId: 'daejeon'),
        ],
      ),
      Location(
        id: 'sejong',
        name: '세종',
        subLocations: [
          Location(id: 'sejong_all', name: '세종 전체', parentId: 'sejong'),
        ],
      ),
      Location(
        id: 'chungnam',
        name: '충청남도',
        subLocations: [
          Location(id: 'chungnam_all', name: '충청남도 전체', parentId: 'chungnam'),
          Location(id: 'cheonan', name: '천안시', parentId: 'chungnam'),
          Location(id: 'asan', name: '아산시', parentId: 'chungnam'),
          Location(id: 'gongju', name: '공주시', parentId: 'chungnam'),
          Location(id: 'seosan', name: '서산시', parentId: 'chungnam'),
          Location(id: 'nonsan', name: '논산시', parentId: 'chungnam'),
          Location(id: 'gyeryong', name: '계룡시', parentId: 'chungnam'),
          Location(id: 'dangjin', name: '당진시', parentId: 'chungnam'),
        ],
      ),
      Location(
        id: 'chungbuk',
        name: '충청북도',
        subLocations: [
          Location(id: 'chungbuk_all', name: '충청북도 전체', parentId: 'chungbuk'),
          Location(id: 'cheongju', name: '청주시', parentId: 'chungbuk'),
          Location(id: 'chungju', name: '충주시', parentId: 'chungbuk'),
          Location(id: 'jecheon', name: '제천시', parentId: 'chungbuk'),
          Location(id: 'boeun', name: '보은군', parentId: 'chungbuk'),
          Location(id: 'okcheon', name: '옥천군', parentId: 'chungbuk'),
          Location(id: 'yeongdong', name: '영동군', parentId: 'chungbuk'),
          Location(id: 'jincheon', name: '진천군', parentId: 'chungbuk'),
          Location(id: 'goesan', name: '괴산군', parentId: 'chungbuk'),
          Location(id: 'eumseong', name: '음성군', parentId: 'chungbuk'),
          Location(id: 'jeungpyeong', name: '증평군', parentId: 'chungbuk'),
        ],
      ),
      Location(
        id: 'gangwon',
        name: '강원도',
        subLocations: [
          Location(id: 'gangwon_all', name: '강원도 전체', parentId: 'gangwon'),
          Location(id: 'chuncheon', name: '춘천시', parentId: 'gangwon'),
          Location(id: 'wonju', name: '원주시', parentId: 'gangwon'),
          Location(id: 'gangneung', name: '강릉시', parentId: 'gangwon'),
          Location(id: 'donghae', name: '동해시', parentId: 'gangwon'),
          Location(id: 'taebaek', name: '태백시', parentId: 'gangwon'),
          Location(id: 'sokcho', name: '속초시', parentId: 'gangwon'),
          Location(id: 'samcheok', name: '삼척시', parentId: 'gangwon'),
          Location(id: 'hongcheon', name: '홍천군', parentId: 'gangwon'),
          Location(id: 'hoengseong', name: '횡성군', parentId: 'gangwon'),
          Location(id: 'yeongwol', name: '영월군', parentId: 'gangwon'),
          Location(id: 'pyeongchang', name: '평창군', parentId: 'gangwon'),
          Location(id: 'jeongseon', name: '정선군', parentId: 'gangwon'),
          Location(id: 'cheorwon', name: '철원군', parentId: 'gangwon'),
          Location(id: 'hwacheon', name: '화천군', parentId: 'gangwon'),
          Location(id: 'yanggu', name: '양구군', parentId: 'gangwon'),
          Location(id: 'inje', name: '인제군', parentId: 'gangwon'),
          Location(id: 'goseong', name: '고성군', parentId: 'gangwon'),
          Location(id: 'yangyang', name: '양양군', parentId: 'gangwon'),
        ],
      ),
    ];
  }
}
