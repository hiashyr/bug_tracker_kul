import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Полная тема приложения Bug Tracker
class AppTheme {
  AppTheme._();

  /// Светлая тема
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // ── Цветовая схема ──
        colorScheme: ColorScheme.light(
          primary: AppColors.brandBlue,
          onPrimary: AppColors.textOnBrand,
          primaryContainer: AppColors.brandBlueLight,
          onPrimaryContainer: AppColors.brandBlue,
          secondary: AppColors.brandBlue,
          onSecondary: AppColors.textOnBrand,
          secondaryContainer: AppColors.brandBlueLight,
          onSecondaryContainer: AppColors.brandBlue,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimaryLight,
          surfaceContainerHighest: AppColors.backgroundLight,
          onSurfaceVariant: AppColors.textSecondary,
          error: AppColors.error,
          onError: AppColors.surfaceLight,
          errorContainer: AppColors.errorLight,
          onErrorContainer: AppColors.error,
          outline: AppColors.greyLight,
        ),

        // ── Шрифты ──
        textTheme: AppTypography.textTheme,

        // ── Scaffold ──
        scaffoldBackgroundColor: AppColors.backgroundLight,

        // ── AppBar ──
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.textOnBrand,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: AppColors.textOnBrand,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // ── Card ──
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),

        // ── ElevatedButton ──
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: AppColors.textOnBrand,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── TextButton ──
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandBlue,
            textStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // ── IconButton ──
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textOnBrand,
          ),
        ),

        // ── SnackBar ──
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.greyDark,
          contentTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: AppColors.textPrimaryDark,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // ── BottomSheet ──
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
        ),

        // ── Divider ──
        dividerTheme: const DividerThemeData(
          color: AppColors.greyLight,
          thickness: 1,
          space: 1,
        ),

        // ── CircularProgressIndicator ──
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.brandBlue,
        ),
      );

  /// Тёмная тема (заготовка для будущего)
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        colorScheme: ColorScheme.dark(
          primary: AppColors.brandBlue,
          onPrimary: AppColors.textOnBrand,
          primaryContainer: AppColors.brandBlue.withValues(alpha: 0.2),
          onPrimaryContainer: AppColors.brandBlueLight,
          secondary: AppColors.brandBlue,
          onSecondary: AppColors.textOnBrand,
          secondaryContainer: AppColors.brandBlue.withValues(alpha: 0.2),
          onSecondaryContainer: AppColors.brandBlueLight,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
          surfaceContainerHighest: const Color(0xFF2D2D2D),
          onSurfaceVariant: const Color(0xFFBDBDBD),
          error: AppColors.error,
          onError: AppColors.surfaceLight,
          errorContainer: AppColors.errorLight,
          onErrorContainer: AppColors.error,
          outline: const Color(0xFF424242),
        ),

        textTheme: AppTypography.textTheme.apply(
          bodyColor: AppColors.textPrimaryDark,
          displayColor: AppColors.textPrimaryDark,
        ),

        scaffoldBackgroundColor: AppColors.backgroundDark,

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          centerTitle: true,
        ),

        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: AppColors.textOnBrand,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.brandBlue,
        ),
      );
}