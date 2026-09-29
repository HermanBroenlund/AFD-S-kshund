import 'package:flutter/material.dart';

class AppColors {
  static const afdYellow = Color(0xFFFFD500);
  static const black = Color(0xFF111111);
  static const surface = Color(0xFFF7F7F5);
  static const border = Color(0xFFE2E2DE);
}

ThemeData buildAfdTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.afdYellow,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.black,
    onPrimary: Colors.white,
    secondary: AppColors.afdYellow,
    onSecondary: AppColors.black,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.afdYellow,
      foregroundColor: AppColors.black,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: AppColors.black, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.afdYellow,
        foregroundColor: AppColors.black,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.afdYellow,
        foregroundColor: AppColors.black,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.afdYellow,
      foregroundColor: AppColors.black,
    ),
  );
}
