import 'package:flutter/material.dart';
import '../utils/storage_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _currentLanguage = 'en'; // Default to English as per recent request
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;
  Locale get locale => Locale(_currentLanguage);

  Future<void> initialize() async {
    final savedLanguage = await StorageService().getAppSetting<String>(
      'language',
    );
    if (savedLanguage != null) {
      _currentLanguage = savedLanguage;
    }

    final savedTheme = await StorageService().getAppSetting<bool>('dark_mode');
    if (savedTheme != null) {
      _isDarkMode = savedTheme;
    }

    _isInitialized = true;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    StorageService().saveAppSetting('dark_mode', _isDarkMode);
    notifyListeners();
  }

  void setLanguage(String language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      StorageService().saveAppSetting('language', language);
      notifyListeners();
    }
  }
}
