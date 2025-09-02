import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final Color? color;
  final bool showText;

  const AppLogo({
    super.key,
    this.height = 32,
    this.color,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 테니스 공 아이콘
          Container(
            width: height * 0.6,
            height: height * 0.6,
            decoration: BoxDecoration(
              color: color ?? AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.sports_tennis,
                color: Colors.white,
                size: height * 0.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 플메 텍스트
          Text(
            '플메',
            style: TextStyle(
              fontSize: height * 0.6,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
          // 장식 요소
          const SizedBox(width: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 2),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    } else {
      // 아이콘만 표시
      return Container(
        width: height,
        height: height,
        decoration: BoxDecoration(
          color: color ?? AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.sports_tennis,
            color: Colors.white,
            size: height * 0.6,
          ),
        ),
      );
    }
  }
} 