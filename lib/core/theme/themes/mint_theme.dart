import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_theme.dart';

const _mintPrimary = Color(0xFF00BFA6);
const _mintPrimaryDark = Color(0xFF4DD6C1);
const _deepTeal = Color(0xFF0E7C7B);
const _deepTealLight = Color(0xFF4FB3B2);

final mintTheme = AppTheme(
  id: 'mint',
  nameKey: 'theme_mint',
  isPremium: false,
  previewSwatch: const [_mintPrimary, _deepTeal, Color(0xFFF7F8FA)],
  lightColors: const AppColors(
    brightness: Brightness.light,
    primary: _mintPrimary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB8F2E6),
    onPrimaryContainer: Color(0xFF003830),
    secondary: _deepTeal,
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF7F8FA),
    onBackground: Color(0xFF1A1D1F),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A1D1F),
    surfaceVariant: Color(0xFFEEF1F3),
    onSurfaceVariant: Color(0xFF525659),
    outline: Color(0xFFC7CBCE),
    outlineSoft: Color(0xFFE4E7EA),
    income: Color(0xFF22C55E),
    onIncome: Color(0xFFFFFFFF),
    expense: Color(0xFFEF4444),
    onExpense: Color(0xFFFFFFFF),
    warning: Color(0xFFF59E0B),
    onWarning: Color(0xFF3D2A00),
    info: Color(0xFF3B82F6),
    onInfo: Color(0xFFFFFFFF),
    success: Color(0xFF22C55E),
    onSuccess: Color(0xFFFFFFFF),
    error: Color(0xFFEF4444),
    onError: Color(0xFFFFFFFF),
  ),
  darkColors: const AppColors(
    brightness: Brightness.dark,
    primary: _mintPrimaryDark,
    onPrimary: Color(0xFF003830),
    primaryContainer: Color(0xFF005046),
    onPrimaryContainer: Color(0xFFB8F2E6),
    secondary: _deepTealLight,
    onSecondary: Color(0xFF00312F),
    background: Color(0xFF0F1114),
    onBackground: Color(0xFFE6E8EB),
    surface: Color(0xFF16181C),
    onSurface: Color(0xFFE6E8EB),
    surfaceVariant: Color(0xFF1F2227),
    onSurfaceVariant: Color(0xFFB4B8BC),
    outline: Color(0xFF3A3F45),
    outlineSoft: Color(0xFF24282D),
    income: Color(0xFF4ADE80),
    onIncome: Color(0xFF052E16),
    expense: Color(0xFFF87171),
    onExpense: Color(0xFF450A0A),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF3D2A00),
    info: Color(0xFF60A5FA),
    onInfo: Color(0xFF0B2545),
    success: Color(0xFF4ADE80),
    onSuccess: Color(0xFF052E16),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
  ),
);
