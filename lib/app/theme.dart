import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';

class GrowboxTheme {
  GrowboxTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(height: 1.15, letterSpacing: -0.02),
        headlineMedium: TextStyle(height: 1.15, letterSpacing: -0.02),
        headlineSmall: TextStyle(height: 1.15, letterSpacing: -0.02),
        titleLarge: TextStyle(height: 1.15, letterSpacing: -0.02),
        titleMedium: TextStyle(height: 1.15, letterSpacing: -0.02),
        titleSmall: TextStyle(height: 1.15, letterSpacing: -0.02),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.brandOrange,
        surface: AppColors.secondarySurface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondarySurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        // 30% secondary — soft sage surface for cards
        color: AppColors.secondarySurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.secondaryBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shadowColor: AppColors.primary.withAlpha(40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 0.5,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
      ),
      timePickerTheme: const TimePickerThemeData(
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        hourMinuteTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.0),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(height: 1.15, letterSpacing: -0.02),
        headlineMedium: TextStyle(height: 1.15, letterSpacing: -0.02),
        headlineSmall: TextStyle(height: 1.15, letterSpacing: -0.02),
        titleLarge: TextStyle(height: 1.15, letterSpacing: -0.02),
        titleMedium: TextStyle(height: 1.15, letterSpacing: -0.02),
        titleSmall: TextStyle(height: 1.15, letterSpacing: -0.02),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        brightness: Brightness.dark,
        primary: AppColors.darkPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.brandOrange,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        // Depth via lighter surface color + subtle shadow, not borders alone
        color: AppColors.darkSurface,
        elevation: 1,
        shadowColor: AppColors.darkCardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.darkPrimary.withAlpha(50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.darkPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.5,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
      ),
      timePickerTheme: const TimePickerThemeData(
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        hourMinuteTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.0),
      ),
    );
  }
}