import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Palette
  static const Color primary = Color(0xFF1E60F6);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFEBF2FF);
  static const Color primarySurface = Color(0xFFF4F8FF);
  static const Color primaryAccent = Color(0xFF2563EB);

  // Status & Actions
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color emergency = Color(0xFFFF3B30);
  static const Color emergencyBg = Color(0xFFFFECEB);

  // Neutrals & Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiAssistantGradient = LinearGradient(
    colors: [Color(0xFF1E60F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
