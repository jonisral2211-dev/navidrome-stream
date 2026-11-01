import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF121212);
  static const spotifyGreen = Color(0xFF1DB954);
  static const card = Color(0xFF282828);
  static const subtitle = Color(0xFFB3B3B3);
  static const divider = Color(0xFF535353);
}

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.spotifyGreen,
        secondary: AppColors.spotifyGreen,
        surface: AppColors.background,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF000000),
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.subtitle,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Colors.white,
        inactiveTrackColor: AppColors.divider,
        thumbColor: Colors.white,
        trackHeight: 4,
      ),
    );
  }
}
