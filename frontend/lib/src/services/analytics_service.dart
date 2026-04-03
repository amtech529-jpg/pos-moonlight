import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/analytics/analytics_models.dart';
import '../models/analytics/dashboard_analytics.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final ApiClient _apiClient = ApiClient();

  // ===== SALES ANALYTICS =====

  /// Get comprehensive sales analytics
  Future<ApiResponse<Map<String, dynamic>>> getSalesAnalytics({
    String? dateFrom,
    String? dateTo,
    String? groupBy,
    String? customerId,
    String? productId,
    String? paymentMethod,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (groupBy != null) queryParams['group_by'] = groupBy;
      if (customerId != null) queryParams['customer_id'] = customerId;
      if (productId != null) queryParams['product_id'] = productId;
      if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;

      final response = await _apiClient.get(ApiConfig.getSalesAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Sales Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sales analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sales analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sales analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting sales analytics');
    }
  }

  /// Get sales trends analysis
  Future<ApiResponse<Map<String, dynamic>>> getSalesTrends({String? dateFrom, String? dateTo, String? period, String? metric}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (period != null) queryParams['period'] = period;
      if (metric != null) queryParams['metric'] = metric;

      final response = await _apiClient.get(ApiConfig.getSalesTrends, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Sales Trends', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sales trends',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sales trends DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sales trends', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting sales trends');
    }
  }

  /// Get customer analytics
  Future<ApiResponse<Map<String, dynamic>>> getCustomerAnalytics({String? dateFrom, String? dateTo, String? customerId, String? groupBy}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (customerId != null) queryParams['customer_id'] = customerId;
      if (groupBy != null) queryParams['group_by'] = groupBy;

      final response = await _apiClient.get(ApiConfig.getCustomerAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Customer Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customer analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customer analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get customer analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting customer analytics');
    }
  }

  /// Get product analytics
  Future<ApiResponse<Map<String, dynamic>>> getProductAnalytics({
    String? dateFrom,
    String? dateTo,
    String? productId,
    String? categoryId,
    String? groupBy,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (productId != null) queryParams['product_id'] = productId;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (groupBy != null) queryParams['group_by'] = groupBy;

      final response = await _apiClient.get(ApiConfig.getProductAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Product Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get product analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get product analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get product analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting product analytics');
    }
  }

  // ===== FINANCIAL ANALYTICS =====

  /// Get financial analytics
  Future<ApiResponse<Map<String, dynamic>>> getFinancialAnalytics({String? dateFrom, String? dateTo, String? groupBy, String? currency}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (groupBy != null) queryParams['group_by'] = groupBy;
      if (currency != null) queryParams['currency'] = currency;

      final response = await _apiClient.get(ApiConfig.getFinancialAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Financial Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get financial analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get financial analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get financial analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting financial analytics');
    }
  }

  /// Get revenue analytics
  Future<ApiResponse<Map<String, dynamic>>> getRevenueAnalytics({String? dateFrom, String? dateTo, String? groupBy, String? source}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (groupBy != null) queryParams['group_by'] = groupBy;
      if (source != null) queryParams['source'] = source;

      final response = await _apiClient.get(ApiConfig.getRevenueAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Revenue Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get revenue analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get revenue analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get revenue analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting revenue analytics');
    }
  }

  /// Get profit margin analytics
  Future<ApiResponse<Map<String, dynamic>>> getProfitMarginAnalytics({
    String? dateFrom,
    String? dateTo,
    String? groupBy,
    String? productCategory,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (groupBy != null) queryParams['group_by'] = groupBy;
      if (productCategory != null) queryParams['product_category'] = productCategory;

      final response = await _apiClient.get(ApiConfig.getProfitMarginAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Profit Margin Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get profit margin analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get profit margin analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get profit margin analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting profit margin analytics');
    }
  }

  // ===== TAX ANALYTICS =====

  /// Get tax analytics
  Future<ApiResponse<Map<String, dynamic>>> getTaxAnalytics({String? dateFrom, String? dateTo, String? taxType, String? groupBy}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (taxType != null) queryParams['tax_type'] = taxType;
      if (groupBy != null) queryParams['group_by'] = groupBy;

      final response = await _apiClient.get(ApiConfig.getTaxAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Tax Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get tax analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get tax analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get tax analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting tax analytics');
    }
  }

  // ===== PERFORMANCE ANALYTICS =====

  /// Get performance analytics
  Future<ApiResponse<Map<String, dynamic>>> getPerformanceAnalytics({String? dateFrom, String? dateTo, String? metric, String? groupBy}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (metric != null) queryParams['metric'] = metric;
      if (groupBy != null) queryParams['group_by'] = groupBy;

      final response = await _apiClient.get(ApiConfig.getPerformanceAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Performance Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get performance analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get performance analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get performance analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting performance analytics');
    }
  }

  // ===== REPORTING =====

  /// Generate comprehensive report
  Future<ApiResponse<Map<String, dynamic>>> generateReport({
    required String reportType,
    String? dateFrom,
    String? dateTo,
    Map<String, dynamic>? filters,
    String? format,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.generateReport,
        data: {'report_type': reportType, 'date_from': dateFrom, 'date_to': dateTo, 'filters': filters, 'format': format ?? 'json'},
      );

      DebugHelper.printApiResponse('POST Generate Report', response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to generate report',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Generate report DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Generate report', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while generating report');
    }
  }

  /// Get report templates
  Future<ApiResponse<List<Map<String, dynamic>>>> getReportTemplates() async {
    try {
      final response = await _apiClient.get(ApiConfig.getReportTemplates);

      DebugHelper.printApiResponse('GET Report Templates', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<List<Map<String, dynamic>>>.fromJson(
          response.data,
          (data) => (data['templates'] as List<dynamic>).map((template) => template as Map<String, dynamic>).toList(),
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get report templates',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get report templates DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<Map<String, dynamic>>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get report templates', e);
      return ApiResponse<List<Map<String, dynamic>>>(success: false, message: 'An unexpected error occurred while getting report templates');
    }
  }

  /// Export analytics data
  Future<ApiResponse<Map<String, dynamic>>> exportAnalyticsData({
    required String dataType,
    String? dateFrom,
    String? dateTo,
    Map<String, dynamic>? filters,
    String? format,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.exportAnalyticsData,
        data: {'data_type': dataType, 'date_from': dateFrom, 'date_to': dateTo, 'filters': filters, 'format': format ?? 'csv'},
      );

      DebugHelper.printApiResponse('POST Export Analytics Data', response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to export analytics data',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Export analytics data DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Export analytics data', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while exporting analytics data');
    }
  }

  // ===== DASHBOARD ANALYTICS =====

  /// Get dashboard analytics
  Future<ApiResponse<Map<String, dynamic>>> getDashboardAnalytics({String? dateRange, List<String>? metrics}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (dateRange != null) queryParams['date_range'] = dateRange;
      if (metrics != null) queryParams['metrics'] = metrics.join(',');

      final response = await _apiClient.get(ApiConfig.getDashboardAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Dashboard Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get dashboard analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get dashboard analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get dashboard analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting dashboard analytics');
    }
  }

  /// Get real-time analytics
  Future<ApiResponse<Map<String, dynamic>>> getRealTimeAnalytics({List<String>? metrics, String? interval}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (metrics != null) queryParams['metrics'] = metrics.join(',');
      if (interval != null) queryParams['interval'] = interval;

      final response = await _apiClient.get(ApiConfig.getRealTimeAnalytics, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Real-Time Analytics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get real-time analytics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get real-time analytics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get real-time analytics', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting real-time analytics');
    }
  }
}

// ApiError class for error handling
class ApiError {
  final String type;
  final String displayMessage;
  final Map<String, dynamic>? errors;

  ApiError({required this.type, required this.displayMessage, this.errors});

  factory ApiError.fromDioError(DioException e) {
    String type = 'unknown_error';
    String message = 'An unknown error occurred';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        type = 'timeout_error';
        message = 'Request timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        type = 'network_error';
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          type = 'unauthorized';
          message = 'You are not authorized to perform this action.';
        } else if (e.response?.statusCode == 403) {
          type = 'forbidden';
          message = 'Access forbidden.';
        } else if (e.response?.statusCode == 404) {
          type = 'not_found';
          message = 'Resource not found.';
        } else if (e.response?.statusCode == 422) {
          type = 'validation_error';
          message = 'Please check your input and try again.';
        } else if ((e.response?.statusCode ?? 0) >= 500) {
          type = 'server_error';
          message = 'Server error. Please try again later.';
        } else {
          type = 'http_error';
          message = 'HTTP error ${e.response?.statusCode}.';
        }
        break;
      case DioExceptionType.cancel:
        type = 'cancelled';
        message = 'Request was cancelled.';
        break;
      default:
        type = 'unknown_error';
        message = 'An unexpected error occurred.';
    }

    return ApiError(type: type, displayMessage: message, errors: e.response?.data is Map<String, dynamic> ? e.response?.data['errors'] : null);
  }
}
