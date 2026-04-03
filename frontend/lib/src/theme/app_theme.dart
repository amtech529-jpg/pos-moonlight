import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppTheme {
  // Color Palette - Moon Light (Maroon/Red)
  static const Color primaryMaroon = Color(0xFFBD0D1D);
  static const Color secondaryMaroon = Color(0xFF333333);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color creamWhite = Color(0xFFF2EAE7); // Matches AppColors.background
  static const Color charcoalGray = Color(0xFF1A1A1A);
  static const Color lightGray = Color(0xFFE5E5E5);
  static const Color shadowColor = Color(0x0D000000);

  //
  // static const Color primaryMaroon = Color(0xFFD32F2F);
  // static const Color secondaryMaroon = Color(0xFF5D4037);
  // static const Color accentGold = Color(0xFFD4AF37);
  // static const Color pureWhite = Color(0xFFFFFFFF);
  // static const Color creamWhite = Color(0xFFFFFBF5);
  // static const Color charcoalGray = Color(0xFF3E2723);
  // static const Color lightGray = Color(0xFFF5F5F5);
  // static const Color shadowColor = Color(0x1A000000);


  //





  // Font Configuration
  static const String englishFontFamily = 'Inter';
  static const String urduFontFamily = 'Jameel Noori Nastaleeq';
  static const String fallbackUrduFont = 'Noto Nastaliq Urdu';

  // Get font family based on locale
  static String getFontFamily(Locale locale) {
    if (locale.languageCode == 'ur') {
      return urduFontFamily;
    }
    return englishFontFamily;
  }

  // Light Theme with Locale Support
  static ThemeData getLightTheme(Locale locale) {
    final String fontFamily = getFontFamily(locale);
    final bool isUrdu = locale.languageCode == 'ur';

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryMaroon,
      scaffoldBackgroundColor: creamWhite,
      fontFamily: fontFamily,
      fontFamilyFallback: isUrdu ? [fallbackUrduFont] : null,

      colorScheme: const ColorScheme.light(
        primary: primaryMaroon,
        secondary: accentGold,
        surface: pureWhite,
        background: creamWhite,
        onPrimary: pureWhite,
        onSecondary: charcoalGray,
        onSurface: charcoalGray,
        onBackground: charcoalGray,
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: isUrdu ? [fallbackUrduFont] : null,
          fontSize: 4.sp,
          fontWeight: FontWeight.w700,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: isUrdu ? [fallbackUrduFont] : null,
          fontSize: 3.5.sp,
          fontWeight: FontWeight.w600,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : -0.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 3.sp,
          fontWeight: FontWeight.w600,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : -0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.5.sp,
          fontWeight: FontWeight.w500,
          color: charcoalGray,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.2.sp,
          fontWeight: FontWeight.w500,
          color: charcoalGray,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.sp,
          fontWeight: FontWeight.w400,
          color: charcoalGray,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w400,
          color: charcoalGray,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w500,
          color: charcoalGray,
          letterSpacing: isUrdu ? 0 : 0.1,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: pureWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1.5.w),
          ),
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 3.w),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 1.8.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: isUrdu ? 0 : 0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1.5.w),
          borderSide: BorderSide(color: const Color(0xFFE0E0E0), width: 0.1.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1.5.w),
          borderSide: BorderSide(color: const Color(0xFFE0E0E0), width: 0.1.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1.5.w),
          borderSide: BorderSide(color: primaryMaroon, width: 0.2.w),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(1.5.w),
          borderSide: BorderSide(color: Colors.red, width: 0.1.w),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: const Color(0xFF9E9E9E),
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: charcoalGray,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
        color: pureWhite,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: pureWhite,
        surfaceTintColor: pureWhite,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.2.sp,
          fontWeight: FontWeight.bold,
          color: charcoalGray,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          color: charcoalGray,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryMaroon,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 1.8.sp,
          ),
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 6,
      ),
    );
  }

  // Dark Theme with Locale Support
  static ThemeData getDarkTheme(Locale locale) {
    final String fontFamily = getFontFamily(locale);
    final bool isUrdu = locale.languageCode == 'ur';

    return getLightTheme(locale).copyWith(
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: const ColorScheme.dark(
        primary: primaryMaroon,
        secondary: accentGold,
        surface: Color(0xFF2C2C2C),
        background: Color(0xFF1A1A1A),
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: pureWhite,
        onBackground: pureWhite,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 4.sp,
          fontWeight: FontWeight.w700,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 3.5.sp,
          fontWeight: FontWeight.w600,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : -0.3,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 3.sp,
          fontWeight: FontWeight.w600,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : -0.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.5.sp,
          fontWeight: FontWeight.w500,
          color: pureWhite,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.2.sp,
          fontWeight: FontWeight.w500,
          color: pureWhite,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.sp,
          fontWeight: FontWeight.w400,
          color: pureWhite,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w400,
          color: pureWhite,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          fontWeight: FontWeight.w500,
          color: pureWhite,
          letterSpacing: isUrdu ? 0 : 0.1,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        surfaceTintColor: const Color(0xFF2C2C2C),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 2.2.sp,
          fontWeight: FontWeight.bold,
          color: pureWhite,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 1.8.sp,
          color: pureWhite,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.w)),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGold,
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 1.8.sp,
          ),
        ),
      ),
    );
  }

  // Backward compatibility - use Urdu by default
  static ThemeData get lightTheme => getLightTheme(const Locale('ur'));
  static ThemeData get darkTheme => getDarkTheme(const Locale('ur'));
}
