import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  String _selectedCategory = '전체';

  final List<String> _categories = [
    '전체',
    '라켓',
    '신발',
    '의류',
    '가방',
    '기타',
  ];

  @override
  Widget build(BuildContext context) {
    print('TradeScreen 빌드됨');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('중고거래'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 검색 페이지로 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // 필터 페이지로 이동
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12, top: 12),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 상품 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredItems().length,
              itemBuilder: (context, index) {
                final item = _getFilteredItems()[index];
                return _buildProductCard(item);
              },
            ),
          ),
        ],
      ),
      // 플로팅 액션 버튼 제거 (MainScreen에서 관리)
    );
  }

  List<ProductItem> _getFilteredItems() {
    if (_selectedCategory == '전체') {
      return _allProducts;
    }
    return _allProducts.where((item) => item.category == _selectedCategory).toList();
  }

  Widget _buildProductCard(ProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          // 상품 이미지
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.network(
              item.imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          
          // 상품 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.category,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.timeAgo,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${item.price.toStringAsFixed(0)}원',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            item.likes.toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductItem {
  final String title;
  final String description;
  final String category;
  final double price;
  final int likes;
  final String timeAgo;
  final String imageUrl;

  ProductItem({
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.likes,
    required this.timeAgo,
    required this.imageUrl,
  });
}

// 샘플 데이터
final List<ProductItem> _allProducts = [
  ProductItem(
    title: '윌슨 프로스태프 라켓',
    description: '1년 사용, 상태 양호',
    category: '라켓',
    price: 150000,
    likes: 23,
    timeAgo: '1시간 전',
    imageUrl: 'https://via.placeholder.com/300x300',
  ),
  ProductItem(
    title: '나이키 에어 줌 베이퍼 프로',
    description: '사이즈 270, 거의 새상품',
    category: '신발',
    price: 80000,
    likes: 45,
    timeAgo: '3시간 전',
    imageUrl: 'https://via.placeholder.com/300x300',
  ),
  ProductItem(
    title: '테니스 가방',
    description: '6포켓, 깨끗한 상태',
    category: '가방',
    price: 40000,
    likes: 12,
    timeAgo: '5시간 전',
    imageUrl: 'https://via.placeholder.com/300x300',
  ),
  ProductItem(
    title: '테니스 셔츠',
    description: 'L 사이즈, 흰색',
    category: '의류',
    price: 25000,
    likes: 8,
    timeAgo: '1일 전',
    imageUrl: 'https://via.placeholder.com/300x300',
  ),
  ProductItem(
    title: '테니스 공 3개',
    description: '윌슨 공, 새상품',
    category: '기타',
    price: 15000,
    likes: 31,
    timeAgo: '2일 전',
    imageUrl: 'https://via.placeholder.com/300x300',
  ),
];
