import 'package:flutter/material.dart';

/// Цветовая палитра приложения Bug Tracker
class AppColors {
  AppColors._();

  // ──────────────────────────────────────────────
  // Брендовые цвета
  // ──────────────────────────────────────────────
  static const Color brandBlue = Color(0xFF1E6FFE);
  static const Color brandBlueLight = Color(0xFFE5ECFF);

  // ──────────────────────────────────────────────
  // Фоны
  // ──────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFECECEC);
  static const Color backgroundDark = Color(0xFF010101);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // ──────────────────────────────────────────────
  // Текст
  // ──────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF979696);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textOnBrand = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF979696);

  // ──────────────────────────────────────────────
  // Статусы задач
  // ──────────────────────────────────────────────
  static const Color statusOpen = Color(0xFFE2F7E1);
  static const Color statusInProgress = Color(0xFFE5ECFF);
  static const Color statusTesting = Color(0xFFFFF4C9);
  static const Color statusClosed = Color(0xFFE9EDF0);

  // ──────────────────────────────────────────────
  // Приоритеты
  // ──────────────────────────────────────────────
  static const Color priorityBlocker = Color(0xFFEA0805);
  static const Color priorityCritical = Color(0xFFC0600F);
  static const Color priorityHigh = Color(0xFFE5890E);
  static const Color priorityMedium = Color(0xFF1E6FFE);
  static const Color priorityLow = Color(0xFFE9EDF0);

  // ──────────────────────────────────────────────
  // Семантические цвета
  // ──────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE2F7E1);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFC0600F);
  static const Color warningLight = Color(0xFFFFF4C9);

  // ──────────────────────────────────────────────
  // Нейтральные / серые
  // ──────────────────────────────────────────────
  static const Color greyLight = Color(0xFFE9EDF0);
  static const Color greyMedium = Color(0xFF979696);
  static const Color greyDark = Color(0xFF616161);
}