import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class CourtScreen extends StatefulWidget {
  const CourtScreen({super.key});

  @override
  State<CourtScreen> createState() => _CourtScreenState();
}

class _CourtScreenState extends State<CourtScreen> {
  @override
  Widget build(BuildContext context) {
    print('CourtScreen 빌드됨');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('테니스 코트'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '코트명, 지역으로 검색',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 인기 코트
            Text(
              '인기 코트',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 코트 카드들
            _buildCourtCard(
              name: '올림픽공원 테니스장',
              location: '송파구 올림픽로 25',
              rating: 4.8,
              price: '20,000원/시간',
              imageUrl: 'https://via.placeholder.com/300x200',
            ),
            
            const SizedBox(height: 16),
            
            _buildCourtCard(
              name: '잠실실내테니스장',
              location: '송파구 올림픽로 25',
              rating: 4.6,
              price: '25,000원/시간',
              imageUrl: 'https://via.placeholder.com/300x200',
            ),
            
            const SizedBox(height: 16),
            
            _buildCourtCard(
              name: '한강공원 테니스장',
              location: '영등포구 여의대로',
              rating: 4.5,
              price: '15,000원/시간',
              imageUrl: 'https://via.placeholder.com/300x200',
            ),
            
            const SizedBox(height: 24),
            
            // 지역별 코트
            Text(
              '지역별 코트',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 지역 그리드
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildRegionCard('강남구', '12개 코트'),
                _buildRegionCard('송파구', '8개 코트'),
                _buildRegionCard('마포구', '6개 코트'),
                _buildRegionCard('영등포구', '5개 코트'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtCard({
    required String name,
    required String location,
    required double rating,
    required String price,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(String region, String courtCount) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          // 지역별 코트 목록 페이지로 이동
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                region,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                courtCount,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
