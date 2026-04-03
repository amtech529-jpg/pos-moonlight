import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print("SharedPreferences initialization failed: $e");
    }
  }

  // Token management
  Future<void> saveToken(String token) async {
    await init();
    await _prefs?.setString(ApiConfig.tokenKey, token);
  }

  Future<String?> getToken() async {
    await init();
    return _prefs?.getString(ApiConfig.tokenKey);
  }

  Future<void> removeToken() async {
    await init();
    await _prefs?.remove(ApiConfig.tokenKey);
  }

  // User data management
  Future<void> saveUser(UserModel user) async {
    await init();
    await _prefs?.setString(ApiConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    await init();
    final userString = _prefs?.getString(ApiConfig.userKey);
    if (userString != null) {
      try {
        return UserModel.fromJson(jsonDecode(userString));
      } catch (e) {
        // If there's an error parsing the user data, remove it
        await removeUser();
        return null;
      }
    }
    return null;
  }

  Future<void> removeUser() async {
    await init();
    await _prefs?.remove(ApiConfig.userKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final user = await getUser();
    return token != null && token.isNotEmpty && user != null;
  }

  // Clear all stored data
  Future<void> clearAll() async {
    await init();
    await _prefs?.clear();
  }

  // Generic methods for storing any data
  Future<void> setString(String key, String value) async {
    await init();
    await _prefs?.setString(key, value);
  }

  Future<String?> getString(String key) async {
    await init();
    return _prefs?.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await init();
    await _prefs?.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    await init();
    return _prefs?.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await init();
    await _prefs?.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    await init();
    return _prefs?.getInt(key);
  }

  Future<void> remove(String key) async {
    await init();
    await _prefs?.remove(key);
  }

  // ===== NEW CATEGORY-SPECIFIC METHODS =====

  // Generic data storage methods (for categories cache, etc.)
  Future<void> saveData(String key, dynamic data) async {
    await init();
    final dataJson = jsonEncode(data);
    await _prefs?.setString(key, dataJson);
  }

  Future<dynamic> getData(String key) async {
    await init();
    final dataJson = _prefs?.getString(key);
    if (dataJson != null) {
      try {
        return jsonDecode(dataJson);
      } catch (e) {
        // If there's an error parsing the data, remove it
        await removeData(key);
        return null;
      }
    }
    return null;
  }

  Future<void> removeData(String key) async {
    await init();
    await _prefs?.remove(key);
  }

  Future<bool> hasData(String key) async {
    await init();
    return _prefs?.containsKey(key) ?? false;
  }

  // Categories specific methods
  Future<void> saveCategoriesCache(List<Map<String, dynamic>> categories) async {
    await saveData(ApiConfig.categoriesCacheKey, categories);
  }

  Future<List<Map<String, dynamic>>?> getCategoriesCache() async {
    final data = await getData(ApiConfig.categoriesCacheKey);
    if (data != null && data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return null;
  }

  Future<void> clearCategoriesCache() async {
    await removeData(ApiConfig.categoriesCacheKey);
  }

  // Category view preferences
  Future<void> saveCategoryViewPreferences({
    int? pageSize,
    String? sortBy,
    bool? sortAscending,
    bool? showInactive,
  }) async {
    if (pageSize != null) {
      await setInt('category_page_size', pageSize);
    }
    if (sortBy != null) {
      await setString('category_sort_by', sortBy);
    }
    if (sortAscending != null) {
      await setBool('category_sort_ascending', sortAscending);
    }
    if (showInactive != null) {
      await setBool('category_show_inactive', showInactive);
    }
  }

  Future<Map<String, dynamic>> getCategoryViewPreferences() async {
    return {
      'pageSize': await getInt('category_page_size') ?? 20,
      'sortBy': await getString('category_sort_by') ?? 'dateCreated',
      'sortAscending': await getBool('category_sort_ascending') ?? false,
      'showInactive': await getBool('category_show_inactive') ?? false,
    };
  }

  // App settings methods
  Future<void> saveAppSetting(String key, dynamic value) async {
    if (value is String) {
      await setString('app_$key', value);
    } else if (value is int) {
      await setInt('app_$key', value);
    } else if (value is bool) {
      await setBool('app_$key', value);
    } else {
      // For complex objects, store as JSON
      await saveData('app_$key', value);
    }
  }

  Future<T?> getAppSetting<T>(String key, {T? defaultValue}) async {
    if (T == String) {
      return await getString('app_$key') as T? ?? defaultValue;
    } else if (T == int) {
      return await getInt('app_$key') as T? ?? defaultValue;
    } else if (T == bool) {
      return await getBool('app_$key') as T? ?? defaultValue;
    } else {
      // For complex objects, get from JSON
      final data = await getData('app_$key');
      return data as T? ?? defaultValue;
    }
  }

  Future<void> removeAppSetting(String key) async {
    await remove('app_$key');
  }

  // Clear all app data except auth
  Future<void> clearAllExceptAuth() async {
    final token = await getToken();
    final user = await getUser();

    await clearAll();

    if (token != null) await saveToken(token);
    if (user != null) await saveUser(user);
  }

  // Get all stored keys (for debugging)
  Future<Set<String>> getAllKeys() async {
    await init();
    return _prefs?.getKeys() ?? {};
  }

  // Check storage size (approximate)
  Future<int> getStorageSize() async {
    await init();
    final keys = _prefs?.getKeys() ?? {};
    int totalSize = 0;
    if (_prefs == null) return 0;

    for (String key in keys) {
      final value = _prefs!.get(key);
      if (value is String) {
        totalSize += value.length;
      } else {
        totalSize += value.toString().length;
      }
    }

    return totalSize;
  }

  // Theme and UI preferences
  Future<void> saveThemePreferences({
    bool? isDarkMode,
    String? primaryColor,
    double? fontSize,
  }) async {
    if (isDarkMode != null) {
      await setBool('theme_dark_mode', isDarkMode);
    }
    if (primaryColor != null) {
      await setString('theme_primary_color', primaryColor);
    }
    if (fontSize != null) {
      await setString('theme_font_size', fontSize.toString());
    }
  }

  Future<Map<String, dynamic>> getThemePreferences() async {
    final fontSizeString = await getString('theme_font_size');
    return {
      'isDarkMode': await getBool('theme_dark_mode') ?? false,
      'primaryColor': await getString('theme_primary_color') ?? '#8B1538',
      'fontSize': fontSizeString != null ? double.tryParse(fontSizeString) ?? 14.0 : 14.0,
    };
  }

  // Backup and restore functionality
  Future<Map<String, dynamic>> backupUserData() async {
    await init();
    final keys = _prefs?.getKeys() ?? {};
    final backup = <String, dynamic>{};

    // Only backup non-sensitive data
    final sensitiveKeys = [ApiConfig.tokenKey];

    for (String key in keys) {
      if (!sensitiveKeys.contains(key)) {
        backup[key] = _prefs!.get(key);
      }
    }

    return backup;
  }

  Future<void> restoreUserData(Map<String, dynamic> backup) async {
    await init();

    if (_prefs == null) return;

    for (String key in backup.keys) {
      final value = backup[key];

      if (value is String) {
        await _prefs!.setString(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        await _prefs!.setBool(key, value);
      } else if (value is List) {
        await _prefs!.setStringList(key, value.cast<String>());
      }
    }
  }

  // Cache management
  Future<void> clearAllCaches() async {
    await clearCategoriesCache();
    // Add other cache clearing methods here as you add more modules
  }

  Future<bool> hasCachedData() async {
    return await hasData(ApiConfig.categoriesCacheKey);
  }

  // Session management
  Future<void> clearSession() async {
    await removeToken();
    await removeUser();
    // Keep user preferences but clear session data
  }

  // Get storage stats
  Future<Map<String, dynamic>> getStorageStats() async {
    await init();
    final keys = _prefs?.getKeys() ?? {};
    if (_prefs == null) {
      return {
        'totalKeys': 0,
        'totalSize': 0,
        'authDataSize': 0,
        'cacheDataSize': 0,
        'settingsDataSize': 0,
        'otherDataSize': 0,
      };
    }

    int authDataSize = 0;
    int cacheDataSize = 0;
    int settingsDataSize = 0;
    int otherDataSize = 0;

    for (String key in keys) {
      final value = _prefs!.get(key);
      final size = value is String ? value.length : value.toString().length;

      if (key == ApiConfig.tokenKey || key == ApiConfig.userKey) {
        authDataSize += size;
      } else if (key.endsWith('_cache') || key == ApiConfig.categoriesCacheKey) {
        cacheDataSize += size;
      } else if (key.startsWith('app_') || key.startsWith('theme_') || key.startsWith('category_')) {
        settingsDataSize += size;
      } else {
        otherDataSize += size;
      }
    }

    return {
      'totalKeys': keys.length,
      'totalSize': authDataSize + cacheDataSize + settingsDataSize + otherDataSize,
      'authDataSize': authDataSize,
      'cacheDataSize': cacheDataSize,
      'settingsDataSize': settingsDataSize,
      'otherDataSize': otherDataSize,
    };
  }
}