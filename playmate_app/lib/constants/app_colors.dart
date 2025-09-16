import 'package:flutter/material.dart';

class AppColors {
  // Energetic Mint Palette (기획문서 v1.4 기준)
  static const Color primary = Color(0xFF00C49A); // Mint Green - 메인 컬러
  static const Color secondary = Color(0xFFFFB347); // Light Orange - 강조 버튼
  static const Color accent = Color(0xFF1890FF); // Blue - 정보 강조
  static const Color textSurface = Color(0xFF2F3E46); // Charcoal Navy - 기본 텍스트
  
  // Background Colors
  static const Color background = Color(0xFFF8F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = textSurface; // Charcoal Navy 사용
  static const Color textSecondary = Color(0xFF777777);
  
  // Status Colors
  static const Color error = Color(0xFFFF4D4F);
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color info = Color(0xFF1890FF);
  
  // Button Colors
  static const Color buttonPrimary = primary; // Mint Green
  static const Color buttonSecondary = surface; // White
  static const Color buttonChat = secondary; // Light Orange - 채팅하기 버튼
  static const Color buttonDisabled = Color(0xFFE0E0E0); // Gray 300
  
  // Card Colors
  static const Color cardBackground = surface;
  static const Color cardBorder = Color(0xFFE8E8E8);
  
  // Rating Colors
  static const Color ratingStar = Color(0xFFFFD700);
  static const Color ratingEmpty = Color(0xFFE8E8E8);
} 