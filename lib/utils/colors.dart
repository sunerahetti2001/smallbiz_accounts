import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1A4D8C);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryDarker = Color(0xFF1E1B4B);

  // Secondary Colors
  static const Color secondary = Color(0xFF2E7D32);
  static const Color secondaryLight = Color(0xFF4CAF50);

  // Status Colors
  static const Color income = Color(0xFF2E7D32);
  static const Color expense = Color(0xFFDC2626);
  static const Color credit = Color(0xFFF97316);

  // Neutral Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF97316);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A4D8C), Color(0xFF1E3A8A), Color(0xFF1E1B4B)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );

  static const LinearGradient creditGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
  );
}