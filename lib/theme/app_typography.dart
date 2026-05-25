import 'package:flutter/material.dart';

/// Стили текста для приложения Bug Tracker
class AppTypography {
  AppTypography._();

  /// Базовая текстовая тема Material 3
  static const TextTheme textTheme = TextTheme(
    // ── Дисплей (крупные заголовки) ──
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),

    // ── Заголовки ──
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),

    // ── Заголовки карточек / секций ──
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),

    // ── Основной текст ──
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),

    // ── Метки / чипсы / кнопки ──
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.25,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.25,
    ),
  );

  // ── Кастомные стили для проекта ──

  /// Стиль для ID задачи (крупный жирный)
  static const TextStyle issueId = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  /// Стиль для названия задачи
  static const TextStyle issueSummary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// Стиль для описания задачи
  static const TextStyle issueDescription = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  /// Стиль для текста внутри чипса статуса
  static const TextStyle chipText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  /// Стиль для метки (например, "Приоритет:", "Название:")
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  /// Стиль для второстепенного текста (дата, автор)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Color(0xFF979696),
  );
}