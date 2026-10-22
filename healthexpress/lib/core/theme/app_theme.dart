import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamilyFallback: const ['Noto Sans Telugu', 'Noto Sans', 'Roboto', 'sans-serif'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryAccent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        displaySmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamilyFallback: ['Roboto', 'Noto Sans Telugu', 'Noto Sans', 'sans-serif'],
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
