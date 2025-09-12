import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../models/tennis_court.dart';
import '../../services/tennis_court_service.dart';

class CourtSelectionScreen extends StatefulWidget {
  final TennisCourt? selectedCourt;
  final String? initialSearchQuery;
  final Function(TennisCourt) onCourtSelected;

  const CourtSelectionScreen({
    super.key,
    this.selectedCourt,
    this.initialSearchQuery,
    required this.onCourtSelected,
  });

  @override
  State<CourtSelectionScreen> createState() => _CourtSelectionScreenState();
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  final TennisCourtService _courtService = TennisCourtService();
  final TextEditingController _searchController = TextEditingController();
  
  List<TennisCourt> _courts = [];
  List<TennisCourt> _filteredCourts = [];
  bool _isLoading = true;
  String _selectedRegion = '전체';
  String _selectedDistrict = '전체';
  
  @override
  void initState() {
    super.initState();
    
    // 초기 검색어 설정
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    
    _loadCourts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 초기 검색어가 있으면 검색 실행
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterCourts();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 카카오 API를 통한 실제 테니스장 데이터 가져오기
      _courts = await _courtService.fetchCourtsFromKakaoAPI(
        region: _selectedRegion != '전체' ? _selectedRegion : null,
        district: _selectedDistrict != '전체' ? _selectedDistrict : null,
        size: 15, // 카카오 API 최대 허용 개수
      );
      _filteredCourts = List.from(_courts);
      
      print('🎾 카카오 API 테니스장 로드 완료: ${_courts.length}개');
    } catch (e) {
      print('❌ 카카오 API 테니스장 로드 실패: $e');
      // API 실패 시 로컬 데이터 사용
      _courts = _courtService.getAllCourts();
      _filteredCourts = List.from(_courts);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCourts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 카카오 API를 통한 필터링 및 검색
      _filteredCourts = await _courtService.fetchCourtsFromKakaoAPI(
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
        region: _selectedRegion != '전체' ? _selectedRegion : null,
        district: _selectedDistrict != '전체' ? _selectedDistrict : null,
        size: 15, // 카카오 API 최대 허용 개수
      );
      
      print('🔍 카카오 API 필터링 완료: ${_filteredCourts.length}개');
    } catch (e) {
      print('❌ 카카오 API 필터링 실패: $e');
      // API 실패 시 로컬 필터링
      _filteredCourts = _courts.where((court) {
        final matchesSearch = _searchController.text.isEmpty ||
            court.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            court.address.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesRegion = _selectedRegion == '전체' || court.region == _selectedRegion;
        final matchesDistrict = _selectedDistrict == '전체' || court.district == _selectedDistrict;
        
        return matchesSearch && matchesRegion && matchesDistrict;
      }).toList();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('테니스장 선택'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색 및 필터 영역
          _buildSearchAndFilter(),
          
          // 테니스장 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourts.isEmpty
                    ? _buildEmptyState()
                    : _buildCourtList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // 검색창
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '테니스장 이름 또는 주소로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterCourts();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (value) => _filterCourts(),
          ),
          
          const SizedBox(height: 12),
          
          // 지역 필터
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: '지역',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['전체', ...AppConstants.regions].map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value!;
                      _selectedDistrict = '전체';
                    });
                    _filterCourts();
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: '구/군',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _getDistrictOptions().map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value!;
                    });
                    _filterCourts();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _getDistrictOptions() {
    if (_selectedRegion == '전체' || _selectedRegion == '서울') {
      return ['전체', ...AppConstants.seoulDistricts];
    }
    return ['전체'];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: AppTextStyles.h3.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어나 필터를 시도해보세요',
            style: AppTextStyles.body2.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCourts.length,
      itemBuilder: (context, index) {
        final court = _filteredCourts[index];
        final isSelected = widget.selectedCourt?.id == court.id;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              widget.onCourtSelected(court);
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 테니스장 이름과 선택 표시
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          court.name,
                          style: AppTextStyles.h3.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 주소
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          court.address,
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 기본 정보
                  Row(
                    children: [
                      _buildInfoChip('코트 ${court.courtCount}개'),
                      const SizedBox(width: 8),
                      _buildInfoChip(court.surfaceType),
                      const SizedBox(width: 8),
                      _buildInfoChip(court.priceText),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 시설 정보
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: court.facilities.take(4).map((facility) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          facility,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 평점과 운영 상태
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        court.ratingText,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: court.isOpen ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          court.operatingStatus,
                          style: AppTextStyles.caption.copyWith(
                            color: court.isOpen ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
