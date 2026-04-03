import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../utils/storage_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  String? _errorMessage;
  bool _isLoading = false;
  UserModel? _currentUser;

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  // Getters
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _state == AuthState.authenticated;

  // Initialize auth provider
  Future<void> initialize() async {
    _setState(AuthState.loading);

    try {
      // Initialize API client
      ApiClient().init();

      // Check if user is already logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _setState(AuthState.unauthenticated);
    }
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    _setState(AuthState.loading);

    try {
      debugPrint('🔵 Starting login for: $email');

      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _setUser(response.data!.user);
        _setState(AuthState.authenticated);
        debugPrint('✅ Login successful for: $email');
      } else {
        _setError(response.message);
        _setState(AuthState.error);
        debugPrint('❌ Login failed: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Login error in provider: $e');
      _setError('An unexpected error occurred during login');
      _setState(AuthState.error);
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user (WITHOUT auto-login)
  /// Returns true if signup is successful
  /// User must manually log in after signup
  Future<bool> signup(
      String name,
      String email,
      String password,
      String confirmPassword,
      bool agreedToTerms,
      ) async {
    _setLoading(true);
    _setError(null);
    _setState(AuthState.loading);

    try {
      debugPrint('🔵 Starting signup for: $email');

      final response = await _authService.register(
        fullName: name,
        email: email,
        password: password,
        passwordConfirm: confirmPassword,
        agreedToTerms: agreedToTerms,
      );

      if (response.success) {
        // ✅ Signup successful - DO NOT auto-login
        // Set state to unauthenticated so user must log in manually
        _setState(AuthState.unauthenticated);
        _setError(null);
        debugPrint('✅ Signup successful for: $email - User should now log in');
        return true;
      } else {
        _setError(response.message);
        _setState(AuthState.error);
        debugPrint('❌ Signup failed: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Signup error in provider: $e');
      _setError('An unexpected error occurred during registration');
      _setState(AuthState.error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user and automatically log them in
  /// Use this if you want auto-login after signup (optional)
  Future<bool> signupAndLogin(
      String name,
      String email,
      String password,
      String confirmPassword,
      bool agreedToTerms,
      ) async {
    _setLoading(true);
    _setError(null);
    _setState(AuthState.loading);

    try {
      debugPrint('🔵 Starting signup with auto-login for: $email');

      final response = await _authService.register(
        fullName: name,
        email: email,
        password: password,
        passwordConfirm: confirmPassword,
        agreedToTerms: agreedToTerms,
      );

      if (response.success && response.data != null) {
        // ✅ Signup successful - Auto-login the user
        _setUser(response.data!.user);
        _setState(AuthState.authenticated);
        debugPrint('✅ Signup and auto-login successful for: $email');
        return true;
      } else if (response.success) {
        // Signup successful but no user data - manually login
        debugPrint('⚠️ Signup successful but no user data, logging in manually...');
        await login(email, password);
        return _state == AuthState.authenticated;
      } else {
        _setError(response.message);
        _setState(AuthState.error);
        debugPrint('❌ Signup failed: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Signup with auto-login error in provider: $e');
      _setError('An unexpected error occurred during registration');
      _setState(AuthState.error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('🔵 Starting logout...');
      await _authService.logout();
      _setUser(null);
      _setState(AuthState.unauthenticated);
      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('❌ Logout error in provider: $e');
      // Even if logout fails, clear local state
      _setUser(null);
      _setState(AuthState.unauthenticated);
      debugPrint('⚠️ Logout completed locally despite error');
    } finally {
      _setLoading(false);
    }
  }

  /// Get user profile
  Future<void> getProfile() async {
    try {
      debugPrint('🔵 Fetching user profile...');
      final response = await _authService.getProfile();
      if (response.success && response.data != null) {
        _setUser(response.data!);
        debugPrint('✅ Profile fetched successfully');
      } else {
        debugPrint('❌ Failed to fetch profile: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Get profile error in provider: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile(String fullName, String email) async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('🔵 Updating profile for: $email');
      final response = await _authService.updateProfile(
        fullName: fullName,
        email: email,
      );

      if (response.success && response.data != null) {
        _setUser(response.data!);
        debugPrint('✅ Profile updated successfully');
        return true;
      } else {
        _setError(response.message);
        debugPrint('❌ Profile update failed: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Update profile error in provider: $e');
      _setError('An unexpected error occurred while updating profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change password
  Future<bool> changePassword(
      String oldPassword,
      String newPassword,
      String confirmPassword,
      ) async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('🔵 Changing password...');
      final response = await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirm: confirmPassword,
      );

      if (response.success) {
        debugPrint('✅ Password changed successfully');
        return true;
      } else {
        _setError(response.message);
        debugPrint('❌ Password change failed: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Change password error in provider: $e');
      _setError('An unexpected error occurred while changing password');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _setError(null);
  }

  /// Refresh authentication state
  Future<void> refresh() async {
    debugPrint('🔄 Refreshing authentication state...');
    await initialize();
  }

  /// Check if user session is still valid
  Future<bool> checkSession() async {
    try {
      debugPrint('🔵 Checking session validity...');
      final isLoggedIn = await _authService.isLoggedIn();

      if (!isLoggedIn && _state == AuthState.authenticated) {
        // Session expired
        debugPrint('⚠️ Session expired, logging out...');
        _setUser(null);
        _setState(AuthState.unauthenticated);
        return false;
      }

      debugPrint('✅ Session is valid');
      return isLoggedIn;
    } catch (e) {
      debugPrint('❌ Session check error: $e');
      return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    debugPrint('🔄 Disposing AuthProvider...');
    super.dispose();
  }
}
