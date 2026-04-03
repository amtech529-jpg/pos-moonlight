import 'package:flutter/material.dart';

class AppFonts {
  // System font family for consistent typography
  static const String primaryFont = 'SF Pro Display';
  static const String secondaryFont = 'Roboto';
  
  // Display styles (replacing PlayfairDisplay)
  static TextStyle displayLarge({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
      fontFamily: primaryFont,
    );
  }
  
  static TextStyle displayMedium({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing,
      fontFamily: primaryFont,
    );
  }
  
  // Body styles (replacing Inter)
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFamily: primaryFont,
    );
  }
  
  static TextStyle headlineLarge({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing,
      fontFamily: primaryFont,
    );
  }
  
  static TextStyle headlineMedium({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      fontFamily: primaryFont,
    );
  }
  
  static TextStyle titleLarge({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      fontFamily: primaryFont,
    );
  }
  
  static TextStyle bodyLarge({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
      fontFamily: primaryFont,
    );
  }
  
  static TextStyle bodyMedium({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: height,
      fontFamily: primaryFont,
    );
  }
  
  static TextStyle labelLarge({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing,
      fontFamily: primaryFont,
    );
  }
}
