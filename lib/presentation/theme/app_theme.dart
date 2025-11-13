import 'package:flutter/material.dart';

class AppColors {
  // Asosiy ranglar
  static const Color primaryGreen = Color(0xFF388E3C);
  static const Color accentBlue = Color(0xFF03A9F4);
  static const Color errorRed = Color(0xFFD32F2F);

  // Fon ranglari
  static const Color backgroundLight = Color(0xFFFAFAFA); // Sut rang
  static const Color surfaceLight = Color(
    0xFFE0B387,
  ); // Ochroq Jigarrang (yengilroq)

  // Matn ranglari
  static const Color onPrimary = Colors.white;
  static const Color onBackground = Color(0xFF212121);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // 1. Ranglar Palitrasi
      primaryColor: AppColors.primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentBlue,
        error: AppColors.errorRed,
        surface: AppColors.surfaceLight,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onBackground,
      ),

      // 2. Scaffold (Sahifa) Foni
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // 3. App Bar (Yuqori Qism)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen, // Yashil
        foregroundColor: AppColors.onPrimary, // Oq matn
        elevation: 0,
      ),

      // 4. Floating Action Button (FAB)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentBlue, // Ko'k rang
      ),

      // 5. Matn Stillari
      textTheme: const TextTheme(
        // Katta sarlavhalar
        displayLarge: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.bold,
        ),
        // Oddiy matnlar
        bodyLarge: TextStyle(color: AppColors.onBackground),
      ),
    );
  }
}
