const fs = require('fs');
const path = require('path');

// 테니스장 데이터 파일 경로
const TENNIS_COURTS_FILE = path.join(__dirname, '../data/tennis_courts.json');

// 메모리 스토어
let memoryStore = [];

// 파일에서 데이터 로드
function loadFromFile() {
  try {
    if (fs.existsSync(TENNIS_COURTS_FILE)) {
      const data = fs.readFileSync(TENNIS_COURTS_FILE, 'utf8');
      memoryStore = JSON.parse(data);
      console.log(`테니스장 데이터 로드 완료: ${memoryStore.length}개`);
    } else {
      // 기본 데이터 생성
      memoryStore = getDefaultTennisCourts();
      saveToFile();
      console.log('기본 테니스장 데이터 생성 완료');
    }
  } catch (error) {
    console.error('테니스장 데이터 로드 실패:', error);
    memoryStore = getDefaultTennisCourts();
  }
}

// 파일에 데이터 저장
function saveToFile() {
  try {
    const data = JSON.stringify(memoryStore, null, 2);
    fs.writeFileSync(TENNIS_COURTS_FILE, data, 'utf8');
    console.log('테니스장 데이터 저장 완료');
  } catch (error) {
    console.error('테니스장 데이터 저장 실패:', error);
  }
}

// 기본 테니스장 데이터
function getDefaultTennisCourts() {
  return [
    {
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
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    {
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
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    {
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
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    {
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
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    {
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
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    {
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
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
  ];
}

// 모든 테니스장 조회
const getTennisCourts = (req, res) => {
  try {
    console.log('테니스장 목록 조회 요청');
    
    const { region, district, search, hasLighting, hasParking, hasShower, hasLocker, minPrice, maxPrice, minRating } = req.query;
    
    let filteredCourts = [...memoryStore];
    
    // 지역 필터링
    if (region && region !== '전체') {
      filteredCourts = filteredCourts.filter(court => court.region === region);
    }
    
    // 구/군 필터링
    if (district && district !== '전체') {
      filteredCourts = filteredCourts.filter(court => court.district === district);
    }
    
    // 검색어 필터링
    if (search) {
      const searchLower = search.toLowerCase();
      filteredCourts = filteredCourts.filter(court => 
        court.name.toLowerCase().includes(searchLower) ||
        court.address.toLowerCase().includes(searchLower)
      );
    }
    
    // 시설 필터링
    if (hasLighting !== undefined) {
      filteredCourts = filteredCourts.filter(court => court.hasLighting === (hasLighting === 'true'));
    }
    if (hasParking !== undefined) {
      filteredCourts = filteredCourts.filter(court => court.hasParking === (hasParking === 'true'));
    }
    if (hasShower !== undefined) {
      filteredCourts = filteredCourts.filter(court => court.hasShower === (hasShower === 'true'));
    }
    if (hasLocker !== undefined) {
      filteredCourts = filteredCourts.filter(court => court.hasLocker === (hasLocker === 'true'));
    }
    
    // 가격 필터링
    if (minPrice) {
      filteredCourts = filteredCourts.filter(court => court.pricePerHour >= parseInt(minPrice));
    }
    if (maxPrice) {
      filteredCourts = filteredCourts.filter(court => court.pricePerHour <= parseInt(maxPrice));
    }
    
    // 평점 필터링
    if (minRating) {
      filteredCourts = filteredCourts.filter(court => court.rating >= parseFloat(minRating));
    }
    
    console.log(`필터링된 테니스장 수: ${filteredCourts.length}개`);
    
    res.json({
      success: true,
      data: filteredCourts,
      count: filteredCourts.length
    });
  } catch (error) {
    console.error('테니스장 목록 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '테니스장 목록 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// ID로 테니스장 조회
const getTennisCourtById = (req, res) => {
  try {
    const { id } = req.params;
    const courtId = parseInt(id);
    
    console.log(`테니스장 상세 조회 요청: ID ${courtId}`);
    
    const court = memoryStore.find(c => c.id === courtId);
    
    if (!court) {
      return res.status(404).json({
        success: false,
        message: '테니스장을 찾을 수 없습니다.'
      });
    }
    
    console.log(`테니스장 조회 성공: ${court.name}`);
    
    res.json({
      success: true,
      data: court
    });
  } catch (error) {
    console.error('테니스장 상세 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '테니스장 상세 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 테니스장 검색
const searchTennisCourts = (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q || q.trim().length < 2) {
      return res.json({
        success: true,
        data: [],
        count: 0,
        message: '검색어는 2자 이상이어야 합니다.'
      });
    }
    
    console.log(`테니스장 검색 요청: "${q}"`);
    
    const searchLower = q.toLowerCase();
    const results = memoryStore.filter(court => 
      court.name.toLowerCase().includes(searchLower) ||
      court.address.toLowerCase().includes(searchLower) ||
      court.description.toLowerCase().includes(searchLower)
    );
    
    console.log(`검색 결과: ${results.length}개`);
    
    res.json({
      success: true,
      data: results,
      count: results.length
    });
  } catch (error) {
    console.error('테니스장 검색 오류:', error);
    res.status(500).json({
      success: false,
      message: '테니스장 검색에 실패했습니다.',
      error: error.message
    });
  }
};

// 인기 테니스장 조회
const getPopularTennisCourts = (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const limitNum = parseInt(limit);
    
    console.log(`인기 테니스장 조회 요청: 상위 ${limitNum}개`);
    
    const popularCourts = [...memoryStore]
      .sort((a, b) => b.rating - a.rating)
      .slice(0, limitNum);
    
    res.json({
      success: true,
      data: popularCourts,
      count: popularCourts.length
    });
  } catch (error) {
    console.error('인기 테니스장 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '인기 테니스장 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 지역별 테니스장 조회
const getTennisCourtsByRegion = (req, res) => {
  try {
    const { region } = req.params;
    
    console.log(`지역별 테니스장 조회 요청: ${region}`);
    
    const courts = memoryStore.filter(court => court.region === region);
    
    res.json({
      success: true,
      data: courts,
      count: courts.length
    });
  } catch (error) {
    console.error('지역별 테니스장 조회 오류:', error);
    res.status(500).json({
      success: false,
      message: '지역별 테니스장 조회에 실패했습니다.',
      error: error.message
    });
  }
};

// 서버 시작 시 데이터 로드
loadFromFile();

module.exports = {
  getTennisCourts,
  getTennisCourtById,
  searchTennisCourts,
  getPopularTennisCourts,
  getTennisCourtsByRegion,
  loadFromFile,
  saveToFile
};
