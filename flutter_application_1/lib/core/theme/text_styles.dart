import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}
