import 'package:flutter/material.dart';

/// Brand colors shared across the app — a premium deep-blue + gold look.
class AppColors {
  static const Color dark = Color(0xFF0B1E3F);
  static const Color blue = Color(0xFF1C3C78);
  static const Color gold = Color(0xFFF2C14E);
  static const Color loss = Color(0xFFE57373);
}

/// A vertical dark-blue gradient used as the background on every screen.
const BoxDecoration appBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.dark, AppColors.blue, AppColors.dark],
  ),
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.gold,
      onPrimary: AppColors.dark,
      surface: AppColors.blue,
    ),
    scaffoldBackgroundColor: AppColors.dark,
  );
  return base;
}
