import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/src/models/analytics/dashboard_analytics.dart';
import 'package:frontend/src/models/analytics/reminder_model.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get dashboard analytics
  Future<ApiResponse<DashboardAnalyticsModel>> getDashboardAnalytics() async {
    try {
      // Optional: debugPrint('🚀 Calling API: ${ApiConfig.dashboardAnalytics}');

      final response = await _apiClient.get(ApiConfig.dashboardAnalytics);

      DebugHelper.printApiResponse('GET Dashboard Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<DashboardAnalyticsModel>.fromJson(
          response.data,
              (data) => DashboardAnalyticsModel.fromJson(data),
        );
      } else {
        return ApiResponse<DashboardAnalyticsModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to load dashboard analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Dashboard analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      return ApiResponse<DashboardAnalyticsModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Dashboard analytics', e);
      return ApiResponse<DashboardAnalyticsModel>(
        success: false,
        message: 'An unexpected error occurred while loading dashboard analytics',
      );
    }
  }

  /// Get dashboard reminders
  Future<ApiResponse<List<ReminderModel>>> getReminders() async {
    try {
      final response = await _apiClient.get(ApiConfig.reminders);

      if (response.statusCode == 200) {
        return ApiResponse<List<ReminderModel>>.fromJson(
          response.data,
          (data) => (data as List).map((e) => ReminderModel.fromJson(e)).toList(),
        );
      } else {
        return ApiResponse<List<ReminderModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to load reminders',
        );
      }
    } catch (e) {
      debugPrint('Reminders exception: ${e.toString()}');
      return ApiResponse<List<ReminderModel>>(
        success: false,
        message: 'Failed to load reminders',
      );
    }
  }
}