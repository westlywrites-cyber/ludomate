import 'package:flutter/material.dart';
import 'app_colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      color: AppColors.textDark,
      fontWeight: FontWeight.w800,
    ),
    bodyMedium: TextStyle(color: AppColors.textDark),
  ),
);
