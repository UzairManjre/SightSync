import 'package:flutter/material.dart';

class AppRadius {
  static const double card = 24.0;
}

class AppGradients {
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
    ],
  );
}

class AppColors {
  // Primary purple/blue gradient colors from design
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryPurple = Color(0xFF6B4CE6);
  static const Color primaryBlue = Color(0xFF4E73DF);
  static const Color accentPink = Color(0xFFE94560);
  
  // Background colors
  static const Color backgroundDark = Color(0xFF000000); // Updated to pitch black for new design
  static const Color cardBackground = Color(0xFF1E1E2E);
  
  // Specific Auth Redesign Colors
  static const Color authGradientTop = primaryBlue; // Reverted to original shade
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white for borders
  static const Color glassFill = Color(0x19FFFFFF); // 10% white for fills
  
  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0C0);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE94560);
  static const Color deepBlack = Color(0xFF030712);
}

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primaryPurple,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryPurple,
      secondary: AppColors.accentPink,
      surface: AppColors.cardBackground,
      background: AppColors.backgroundDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),
  );
}
