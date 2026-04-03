import 'package:flutter/material.dart';

/// SightSync Design System — Premium "Aetheric" Style
/// Matched exactly to "Sight Sink Final.pdf" with enhanced vibrancy.

class AppColors {
  // --- Backgrounds ---
  static const Color background     = Color(0xFF080B14); // Deep night
  static const Color surface        = Color(0xFF121829); // Card layer
  static const Color surfaceContainer = Color(0xFF1A2138); // Raised card
  static const Color surfaceContainerHigh = Color(0xFF232B45);

  // --- Brand ---
  static const Color primary        = Color(0xFF4D85FF); // Electric blue
  static const Color secondary      = Color(0xFF2E6FF2);
  static const Color accent         = Color(0xFFFAB0FF); // Astral Pink (subtle accents)
  static const Color electricBlue   = Color(0xFF00E5FF); // Vibrant highlight

  // --- Text ---
  static const Color textPrimary    = Colors.white;
  static const Color textSecondary  = Color(0xFF94A3B8);
  static const Color textTertiary   = Color(0xFF64748B);

  // --- Glass ---
  static const Color glassBorder    = Color(0x33FFFFFF);
  static const Color glassFill      = Color(0x1AFFFFFF);

  // --- Semantic ---
  static const Color success        = Color(0xFF10B981);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color error          = Color(0xFFEF4444);

  // Aliases for compatibility
  static const Color surfaceBright  = surfaceContainerHigh;
  static const Color highlightBlue  = electricBlue;
  static const Color deepBlack      = background; // Fix for spot_glow_background.dart
}

class AppGradients {
  /// Premium 3-stop gradient (Matches "Deep Navy → Electric Blue" request)
  static const LinearGradient mainBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A1227), // Deepest Navy
      Color(0xFF111D3F), // Mid Navy
      Color(0xFF1B3162), // Lighter Navy with a hint of blue
    ],
  );

  /// Vibrant electric blue button gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4D85FF), Color(0xFF1E56D8)],
  );

  /// Subtle glow for cards
  static const LinearGradient glassOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x22FFFFFF), Color(0x05FFFFFF)],
  );
}

class AppTheme {
  // Static radii for consistency
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    fontFamily: 'SpaceGrotesk',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        fontFamily: 'SpaceGrotesk',
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.1,
        fontFamily: 'SpaceGrotesk',
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        fontFamily: 'SpaceGrotesk',
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontFamily: 'SpaceGrotesk',
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 18,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        height: 1.6,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
    ),
  );

  static BoxDecoration cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder.withOpacity(0.1), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration glassDecoration({
    double radius = 24,
    double opacity = 0.08,
    bool showBorder = true,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: showBorder
          ? Border.all(color: Colors.white.withOpacity(0.1), width: 1.5)
          : null,
    );
  }
}

// Support for AppRadius alias
class AppRadius {
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double card = 24.0;
}
