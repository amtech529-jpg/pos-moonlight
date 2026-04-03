import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/sales/sale_model.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class TaxRatesService {
  static final TaxRatesService _instance = TaxRatesService._internal();
  factory TaxRatesService() => _instance;
  TaxRatesService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of tax rates with pagination and filtering
  Future<ApiResponse<TaxRatesListResponse>> getTaxRates({TaxRatesListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? TaxRatesListParams().toQueryParameters();

      // Debug: Log the API call
      debugPrint('🚀 Calling API: ${ApiConfig.taxRates}');
      debugPrint('🌐 Query params: $queryParams');

      final response = await _apiClient.get(ApiConfig.taxRates, queryParameters: queryParams);

      // Debug: Log the response
      debugPrint('🌐 Response status: ${response.statusCode}');
      debugPrint('🌐 Response data: ${response.data}');

      DebugHelper.printApiResponse('GET Tax Rates', response.data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<TaxRatesListResponse>.fromJson(response.data, (data) => TaxRatesListResponse.fromJson(data));

        // Cache tax rates if successful
        if (apiResponse.success && apiResponse.data != null) {
          await _cacheTaxRates(apiResponse.data!.taxRates);
        }

        return apiResponse;
      } else {
        return ApiResponse<TaxRatesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get tax rates',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get tax rates DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedTaxRates = await getCachedTaxRates();
        if (cachedTaxRates.isNotEmpty) {
          return ApiResponse<TaxRatesListResponse>(
            success: true,
            message: 'Showing cached data',
            data: TaxRatesListResponse(
              taxRates: cachedTaxRates,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedTaxRates.length,
                totalCount: cachedTaxRates.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<TaxRatesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get tax rates', e);
      return ApiResponse<TaxRatesListResponse>(success: false, message: 'An unexpected error occurred while getting tax rates');
    }
  }

  /// Get active tax rates
  Future<ApiResponse<List<TaxRateModel>>> getActiveTaxRates() async {
    try {
      final response = await _apiClient.get(ApiConfig.activeTaxRates);

      DebugHelper.printApiResponse('GET Active Tax Rates', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<List<TaxRateModel>>.fromJson(response.data, (data) {
          if (data is List) {
            return data.map((json) => TaxRateModel.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        });
      } else {
        return ApiResponse<List<TaxRateModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get active tax rates',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get active tax rates DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<TaxRateModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get active tax rates', e);
      return ApiResponse<List<TaxRateModel>>(success: false, message: 'An unexpected error occurred while getting active tax rates');
    }
  }

  /// Get a specific tax rate by ID
  Future<ApiResponse<TaxRateModel>> getTaxRateById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getTaxRateById(id));

      DebugHelper.printApiResponse('GET Tax Rate by ID', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<TaxRateModel>.fromJson(response.data, (data) => TaxRateModel.fromJson(data));
      } else {
        return ApiResponse<TaxRateModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get tax rate',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get tax rate by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<TaxRateModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get tax rate by ID', e);
      return ApiResponse<TaxRateModel>(success: false, message: 'An unexpected error occurred while getting tax rate');
    }
  }

  /// Create a new tax rate
  Future<ApiResponse<TaxRateModel>> createTaxRate(CreateTaxRateRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.createTaxRate, data: request.toJson());

      DebugHelper.printApiResponse('CREATE Tax Rate', response.data);

      if (response.statusCode == 201) {
        return ApiResponse<TaxRateModel>.fromJson(response.data, (data) => TaxRateModel.fromJson(data));
      } else {
        return ApiResponse<TaxRateModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create tax rate',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create tax rate DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<TaxRateModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create tax rate', e);
      return ApiResponse<TaxRateModel>(success: false, message: 'An unexpected error occurred while creating tax rate');
    }
  }

  /// Update an existing tax rate
  Future<ApiResponse<TaxRateModel>> updateTaxRate(String id, UpdateTaxRateRequest request) async {
    try {
      final response = await _apiClient.patch(ApiConfig.updateTaxRate(id), data: request.toJson());

      DebugHelper.printApiResponse('UPDATE Tax Rate', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<TaxRateModel>.fromJson(response.data, (data) => TaxRateModel.fromJson(data));
      } else {
        return ApiResponse<TaxRateModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update tax rate',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update tax rate DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<TaxRateModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update tax rate', e);
      return ApiResponse<TaxRateModel>(success: false, message: 'An unexpected error occurred while updating tax rate');
    }
  }

  /// Delete a tax rate (soft delete)
  Future<ApiResponse<void>> deleteTaxRate(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteTaxRate(id));

      DebugHelper.printApiResponse('DELETE Tax Rate', response.data);

      if (response.statusCode == 204) {
        return ApiResponse<void>(success: true, message: 'Tax rate deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete tax rate',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete tax rate DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Delete tax rate', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting tax rate');
    }
  }

  /// Search tax rates
  Future<ApiResponse<TaxRatesListResponse>> searchTaxRates(String query, {TaxRatesListParams? params}) async {
    try {
      final queryParams = {'q': query, ...(params?.toQueryParameters() ?? TaxRatesListParams().toQueryParameters())};

      final response = await _apiClient.get(ApiConfig.searchTaxRates, queryParameters: queryParams);

      DebugHelper.printApiResponse('SEARCH Tax Rates', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<TaxRatesListResponse>.fromJson(response.data, (data) => TaxRatesListResponse.fromJson(data));
      } else {
        return ApiResponse<TaxRatesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to search tax rates',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search tax rates DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<TaxRatesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Search tax rates', e);
      return ApiResponse<TaxRatesListResponse>(success: false, message: 'An unexpected error occurred while searching tax rates');
    }
  }

  /// Get tax rates by type
  Future<ApiResponse<List<TaxRateModel>>> getTaxRatesByType(String taxType) async {
    try {
      final response = await _apiClient.get(ApiConfig.taxRatesByType(taxType));

      DebugHelper.printApiResponse('GET Tax Rates by Type', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<List<TaxRateModel>>.fromJson(response.data, (data) {
          if (data is List) {
            return data.map((json) => TaxRateModel.fromJson(json as Map<String, dynamic>)).toList();
          }
          return [];
        });
      } else {
        return ApiResponse<List<TaxRateModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get tax rates by type',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get tax rates by type DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<TaxRateModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get tax rates by type', e);
      return ApiResponse<List<TaxRateModel>>(success: false, message: 'An unexpected error occurred while getting tax rates by type');
    }
  }

  /// Toggle tax rate active status
  Future<ApiResponse<TaxRateModel>> toggleTaxRateStatus(String id) async {
    try {
      // Use the update endpoint to toggle status
      final response = await _apiClient.patch(ApiConfig.updateTaxRate(id), data: {'is_active': null});

      DebugHelper.printApiResponse('TOGGLE Tax Rate Status', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<TaxRateModel>.fromJson(response.data, (data) => TaxRateModel.fromJson(data));
      } else {
        return ApiResponse<TaxRateModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to toggle tax rate status',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Toggle tax rate status DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<TaxRateModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Toggle tax rate status', e);
      return ApiResponse<TaxRateModel>(success: false, message: 'An unexpected error occurred while toggling tax rate status');
    }
  }

  /// Get default tax configuration from active tax rates
  Future<ApiResponse<TaxConfiguration>> getDefaultTaxConfiguration() async {
    try {
      final response = await _apiClient.get(ApiConfig.activeTaxRates);

      DebugHelper.printApiResponse('GET Default Tax Configuration', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<TaxConfiguration>.fromJson(response.data, (data) {
          if (data is List) {
            final List<TaxRateModel> activeRates = data
                .map((json) => TaxRateModel.fromJson(json as Map<String, dynamic>))
                .toList();

            final Map<String, TaxConfigItem> configItems = {};
            for (final rate in activeRates) {
              configItems[rate.taxType] = TaxConfigItem(
                name: rate.name,
                percentage: rate.percentage,
                amount: 0.0,
                description: rate.description,
              );
            }

            return TaxConfiguration(taxes: configItems);
          }
          return TaxConfiguration();
        });
      } else {
        return ApiResponse<TaxConfiguration>(
          success: false,
          message: response.data['message'] ?? 'Failed to get default tax configuration',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get default tax configuration DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<TaxConfiguration>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get default tax configuration', e);
      return ApiResponse<TaxConfiguration>(success: false, message: 'An unexpected error occurred while getting default tax configuration');
    }
  }

  // Private helper methods for caching
  Future<void> _cacheTaxRates(List<TaxRateModel> taxRates) async {
    try {
      final String jsonData = jsonEncode(taxRates.map((t) => t.toJson()).toList());
      await _storageService.setString(ApiConfig.taxRatesCacheKey, jsonData);
    } catch (e) {
      debugPrint('Failed to cache tax rates: $e');
    }
  }

  Future<List<TaxRateModel>> getCachedTaxRates() async {
    try {
      final cachedData = await _storageService.getString(ApiConfig.taxRatesCacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        final dynamic decodedData = jsonDecode(cachedData);
        if (decodedData is List) {
          return decodedData
              .map((json) => TaxRateModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to get cached tax rates: $e');
    }
    return [];
  }

  Future<void> clearTaxRatesCache() async {
    try {
      await _storageService.remove(ApiConfig.taxRatesCacheKey);
    } catch (e) {
      debugPrint('Failed to clear tax rates cache: $e');
    }
  }
}

// Request Models
class CreateTaxRateRequest {
  final String name;
  final String taxType;
  final double percentage;
  final String? description;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  CreateTaxRateRequest({required this.name, required this.taxType, required this.percentage, this.description, this.effectiveFrom, this.effectiveTo});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tax_type': taxType,
      'percentage': percentage.toString(),
      'description': description,
      'effective_from': effectiveFrom?.toIso8601String(),
      'effective_to': effectiveTo?.toIso8601String(),
    };
  }
}

class UpdateTaxRateRequest {
  final String? name;
  final String? taxType;
  final double? percentage;
  final String? description;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool? isActive;

  UpdateTaxRateRequest({this.name, this.taxType, this.percentage, this.description, this.effectiveFrom, this.effectiveTo, this.isActive});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (taxType != null) data['tax_type'] = taxType;
    if (percentage != null) data['percentage'] = percentage.toString();
    if (description != null) data['description'] = description;
    if (effectiveFrom != null) data['effective_from'] = effectiveFrom!.toIso8601String();
    if (effectiveTo != null) data['effective_to'] = effectiveTo!.toIso8601String();
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}

// Response Models
class TaxRatesListResponse {
  final List<TaxRateModel> taxRates;
  final PaginationInfo pagination;

  TaxRatesListResponse({required this.taxRates, required this.pagination});

  factory TaxRatesListResponse.fromJson(Map<String, dynamic> json) {
    return TaxRatesListResponse(
      taxRates: (json['tax_rates'] as List<dynamic>?)?.map((taxRate) => TaxRateModel.fromJson(taxRate as Map<String, dynamic>)).toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

// Parameters Models
class TaxRatesListParams {
  final int? page;
  final int? pageSize;
  final String? taxType;
  final bool? isActive;
  final String? search;
  final String? sortBy;
  final String? sortOrder;

  TaxRatesListParams({this.page, this.pageSize, this.taxType, this.isActive, this.search, this.sortBy, this.sortOrder});

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['page_size'] = pageSize.toString();
    if (taxType != null) params['tax_type'] = taxType;
    if (isActive != null) params['is_active'] = isActive.toString();
    if (search != null) params['search'] = search;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    return params;
  }
}

// Reuse existing models
class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 10,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }
}

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
