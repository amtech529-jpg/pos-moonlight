
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:frontend/src/providers/app_provider.dart';
// import 'package:frontend/src/theme/app_theme.dart';
//
// void main() {
//   group('Theme Functionality Tests', () {
//     test('AppProvider should toggle theme correctly', () {
//       final appProvider = AppProvider();
//
//       // Initially should be light mode
//       expect(appProvider.isDarkMode, false);
//
//       // Toggle to dark mode
//       appProvider.toggleTheme();
//       expect(appProvider.isDarkMode, true);
//
//       // Toggle back to light mode
//       appProvider.toggleTheme();
//       expect(appProvider.isDarkMode, false);
//     });
//
//     test('AppProvider should handle language changes', () {
//       final appProvider = AppProvider();
//
//       // Initially should be Urdu
//       expect(appProvider.currentLanguage, 'ur');
//       expect(appProvider.locale.languageCode, 'ur');
//
//       // Change to English
//       appProvider.setLanguage('en');
//       expect(appProvider.currentLanguage, 'en');
//       expect(appProvider.locale.languageCode, 'en');
//
//       // Change back to Urdu
//       appProvider.setLanguage('ur');
//       expect(appProvider.currentLanguage, 'ur');
//       expect(appProvider.locale.languageCode, 'ur');
//     });
//
//     test('Theme generation should work correctly', () {
//       // Test light theme generation
//       final lightTheme = AppTheme.getLightTheme(const Locale('en'));
//       expect(lightTheme.brightness, Brightness.light);
//       expect(lightTheme.primaryColor, AppTheme.primaryMaroon);
//
//       // Test dark theme generation
//       final darkTheme = AppTheme.getDarkTheme(const Locale('en'));
//       expect(darkTheme.brightness, Brightness.dark);
//       expect(darkTheme.primaryColor, AppTheme.primaryMaroon);
//
//       // Test Urdu locale theme
//       final urduLightTheme = AppTheme.getLightTheme(const Locale('ur'));
//       expect(urduLightTheme.fontFamily, 'Jameel Noori Nastaleeq');
//
//       final englishLightTheme = AppTheme.getLightTheme(const Locale('en'));
//       expect(englishLightTheme.fontFamily, 'Inter');
//     });
//   });
// }
