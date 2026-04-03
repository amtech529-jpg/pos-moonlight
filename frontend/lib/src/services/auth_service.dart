import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  Future<ApiResponse<AuthResponse>> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirm,
    required bool agreedToTerms,
  }) async {
    try {
      final data = {
        'full_name': fullName,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
        'agreed_to_terms': agreedToTerms,
      };

      final response = await _apiClient.post(ApiConfig.register, data: data);

      if (response.statusCode == 201) {
        final apiResponse = ApiResponse<AuthResponse>.fromJson(
          response.data,
              (data) => AuthResponse.fromJson(data),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _storageService.saveToken(apiResponse.data!.token);
          await _storageService.saveUser(apiResponse.data!.user);
        }

        return apiResponse;
      } else {
        return ApiResponse<AuthResponse>(
          success: false,
          message: response.data['message'] ?? 'Registration failed',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<AuthResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'An unexpected error occurred during registration',
      );
    }
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = {
        'email': email,
        'password': password,
      };

      final response = await _apiClient.post(ApiConfig.login, data: data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<AuthResponse>.fromJson(
          response.data,
              (data) => AuthResponse.fromJson(data),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _storageService.saveToken(apiResponse.data!.token);
          await _storageService.saveUser(apiResponse.data!.user);
        }

        return apiResponse;
      } else {
        return ApiResponse<AuthResponse>(
          success: false,
          message: response.data['message'] ?? 'Login failed',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<AuthResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'An unexpected error occurred during login',
      );
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      try {
        await _apiClient.post(ApiConfig.logout);
      } catch (e) {
        debugPrint('Server logout failed: $e');
      }

      await _storageService.clearAll();

      return ApiResponse<void>(
        success: true,
        message: 'Logged out successfully',
      );
    } catch (e) {
      try {
        await _storageService.clearAll();
      } catch (clearError) {
        debugPrint('Failed to clear storage: $clearError');
      }

      return ApiResponse<void>(
        success: true,
        message: 'Logged out locally',
      );
    }
  }

  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConfig.profile);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<UserModel>.fromJson(
          response.data,
              (data) => UserModel.fromJson(data),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _storageService.saveUser(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<UserModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get profile',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<UserModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'An unexpected error occurred while getting profile',
      );
    }
  }

  Future<ApiResponse<UserModel>> updateProfile({
    required String fullName,
    required String email,
  }) async {
    try {
      final data = {
        'full_name': fullName,
        'email': email,
      };

      final response = await _apiClient.put(ApiConfig.updateProfile, data: data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<UserModel>.fromJson(
          response.data,
              (data) => UserModel.fromJson(data['data']),
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _storageService.saveUser(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<UserModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update profile',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<UserModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      return ApiResponse<UserModel>(
        success: false,
        message: 'An unexpected error occurred while updating profile',
      );
    }
  }

  Future<ApiResponse<String>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final data = {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      };

      final response = await _apiClient.post(ApiConfig.changePassword, data: data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<String>.fromJson(
          response.data,
              (data) => data['token'] as String,
        );

        if (apiResponse.success && apiResponse.data != null) {
          await _storageService.saveToken(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<String>(
          success: false,
          message: response.data['message'] ?? 'Failed to change password',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<String>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      return ApiResponse<String>(
        success: false,
        message: 'An unexpected error occurred while changing password',
      );
    }
  }

  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  Future<UserModel?> getCurrentUser() async {
    return await _storageService.getUser();
  }

  Future<String?> getCurrentToken() async {
    return await _storageService.getToken();
  }
}
