import 'package:flutter/material.dart';

class AppColors {
  // Asosiy ranglar - BREND
  static const Color primaryBrown = Color.fromARGB(
    255,
    108,
    43,
    20,
  ); // Jigarrang (Asosiy)
  static const Color successGreen = Color(
    0xFF388E3C,
  ); // Yashil (Daromad/Ijobiy)
  static const Color accentBlue = Color(0xFF03A9F4); // Ko'k (Aksent)
  static const Color errorRed = Color(0xFFD32F2F); // Qizil (Xarajat/Xato)

  // Fon va Surface ranglari
  static const Color backgroundLight = Color(
    0xFFFAFAFA,
  ); // Sut rang (Sahifa foni)
  static const Color surfaceLight = Colors.white; // Oq rang (Karta/Input foni)
  static const Color softBorder = Color.fromARGB(
    255,
    108,
    43,
    20,
  ); // Yumshoq Jigarrang (Border/Shadow)

  // Matn ranglari
  static const Color onPrimary = Colors.white; // Oq matn
  static const Color onBackground = Color(0xFF212121); // Qora/To'q matn

  // Eski nomlar (kompatibillik uchun)
  static const Color primaryGreen = successGreen;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // 1. Ranglar Palitrasi
      primaryColor: const Color.fromARGB(255, 134, 223, 134),
      //  primaryColor: const Color.fromARGB(255, 108, 43, 20),
      colorScheme: const ColorScheme.light(
        //  primary: Color.fromARGB(255, 108, 43, 20), // Jigarrang (Asosiy)
        secondary: AppColors.accentBlue,
        error: AppColors.errorRed,
        surface: AppColors.surfaceLight,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onBackground,

        primary: Color.fromARGB(255, 134, 129, 129),
      ),

      // 2. Scaffold (Sahifa) Foni
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // 3. App Bar (Yuqori Qism)
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 108, 43, 20), // Jigarrang
        foregroundColor: AppColors.onPrimary, // Oq matn
        elevation: 0,
      ),

      // 4. Floating Action Button (FAB)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.successGreen, // Yashil (Ijobiy)
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

      // 6. Input Decoration Theme (Yumshoq Dizayn)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        // Yumshoq bordyur
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.softBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.softBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 108, 43, 20), // Jigarrang fokusda
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // 7. Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 108, 43, 20),
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
