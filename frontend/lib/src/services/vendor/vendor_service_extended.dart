import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/api_response.dart';
import '../../models/vendor/vendor_api_responses.dart';
import '../../models/vendor/vendor_model.dart';
import '../../utils/storage_service.dart';
import '../../utils/debug_helper.dart';
import '../api_client.dart';

class VendorServiceExtended {
  static final VendorServiceExtended _instance =
      VendorServiceExtended._internal();

  factory VendorServiceExtended() => _instance;

  VendorServiceExtended._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get vendor statistics
  Future<ApiResponse<VendorStatisticsResponse>> getVendorStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.vendorStatistics);

      DebugHelper.printApiResponse('GET Vendor Statistics', response.data);

      if (response.statusCode == 200) {
        // Use your existing ApiResponse.fromJson method with the correct data structure
        return ApiResponse<VendorStatisticsResponse>.fromJson(
          response.data,
          (data) =>
              VendorStatisticsResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorStatisticsResponse>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to get vendor statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get vendor statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorStatisticsResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get vendor statistics error: ${e.toString()}');
      return ApiResponse<VendorStatisticsResponse>(
        success: false,
        message: 'An unexpected error occurred while getting vendor statistics',
      );
    }
  }

  /// Get vendors by city
  Future<ApiResponse<VendorsListResponse>> getVendorsByCity({
    required String city,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.vendorsByCity(city),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Vendors by City', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorsListResponse>.fromJson(
          response.data,
          (data) => VendorsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get vendors by city',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get vendors by city DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get vendors by city error: ${e.toString()}');
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting vendors by city',
      );
    }
  }

  /// Get vendors by area
  Future<ApiResponse<VendorsListResponse>> getVendorsByArea({
    required String area,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.vendorsByArea(area),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Vendors by Area', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorsListResponse>.fromJson(
          response.data,
          (data) => VendorsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get vendors by area',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get vendors by area DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get vendors by area error: ${e.toString()}');
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting vendors by area',
      );
    }
  }

  /// Get new vendors
  Future<ApiResponse<VendorsListResponse>> getNewVendors({
    int days = 30,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'days': days.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.newVendors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET New Vendors', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorsListResponse>.fromJson(
          response.data,
          (data) => VendorsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get new vendors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get new vendors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get new vendors error: ${e.toString()}');
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting new vendors',
      );
    }
  }

  /// Get recent vendors
  Future<ApiResponse<VendorsListResponse>> getRecentVendors({
    int days = 7,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'days': days.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.recentVendors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Recent Vendors', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorsListResponse>.fromJson(
          response.data,
          (data) => VendorsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get recent vendors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get recent vendors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get recent vendors error: ${e.toString()}');
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting recent vendors',
      );
    }
  }

  /// Search vendors
  Future<ApiResponse<VendorsListResponse>> searchVendors({
    required String query,
    String? city,
    String? area,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }

      final response = await _apiClient.get(
        ApiConfig.searchVendors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Search Vendors', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorsListResponse>.fromJson(
          response.data,
          (data) => VendorsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to search vendors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search vendors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Search vendors error: ${e.toString()}');
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: 'An unexpected error occurred while searching vendors',
      );
    }
  }

  /// Bulk vendor actions
  Future<ApiResponse<Map<String, dynamic>>> bulkVendorActions({
    required List<String> vendorIds,
    required String action,
  }) async {
    try {
      final request = VendorBulkActionRequest(
        vendorIds: vendorIds,
        action: action,
      );

      DebugHelper.printJson('Bulk Vendor Actions Request', request.toJson());

      final response = await _apiClient.post(
        ApiConfig.bulkVendorActions,
        data: request.toJson(),
      );

      DebugHelper.printApiResponse('POST Bulk Vendor Actions', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message:
              response.data['message'] ?? 'Bulk action completed successfully',
          data: response.data['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to perform bulk action',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Bulk vendor actions DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Bulk vendor actions error: ${e.toString()}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred while performing bulk action',
      );
    }
  }

  /// Get vendor cities
  Future<ApiResponse<List<VendorCityCount>>> getVendorCities() async {
    try {
      // Since there's no direct endpoint for cities, we'll get it from statistics
      final statsResponse = await getVendorStatistics();
      if (statsResponse.success && statsResponse.data != null) {
        return ApiResponse<List<VendorCityCount>>(
          success: true,
          message: 'Cities retrieved successfully',
          data: statsResponse.data!.topCities,
        );
      } else {
        return ApiResponse<List<VendorCityCount>>(
          success: false,
          message: 'Failed to get vendor cities',
        );
      }
    } catch (e) {
      debugPrint('Get vendor cities error: ${e.toString()}');
      return ApiResponse<List<VendorCityCount>>(
        success: false,
        message: 'An unexpected error occurred while getting vendor cities',
      );
    }
  }

  /// Get vendor areas
  Future<ApiResponse<List<VendorAreaCount>>> getVendorAreas({
    String? city,
  }) async {
    try {
      // Since there's no direct endpoint for areas, we'll get it from statistics
      final statsResponse = await getVendorStatistics();
      if (statsResponse.success && statsResponse.data != null) {
        var areas = statsResponse.data!.topAreas;

        // Filter by city if provided
        if (city != null && city.isNotEmpty) {
          areas = areas
              .where((area) => area.city.toLowerCase() == city.toLowerCase())
              .toList();
        }

        return ApiResponse<List<VendorAreaCount>>(
          success: true,
          message: 'Areas retrieved successfully',
          data: areas,
        );
      } else {
        return ApiResponse<List<VendorAreaCount>>(
          success: false,
          message: 'Failed to get vendor areas',
        );
      }
    } catch (e) {
      debugPrint('Get vendor areas error: ${e.toString()}');
      return ApiResponse<List<VendorAreaCount>>(
        success: false,
        message: 'An unexpected error occurred while getting vendor areas',
      );
    }
  }

  /// Get vendor payments (placeholder)
  Future<ApiResponse<VendorPaymentsResponse>> getVendorPayments({
    required String vendorId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.vendorPayments(vendorId),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Vendor Payments', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorPaymentsResponse>.fromJson(
          response.data,
          (data) =>
              VendorPaymentsResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorPaymentsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get vendor payments',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get vendor payments DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorPaymentsResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get vendor payments error: ${e.toString()}');
      return ApiResponse<VendorPaymentsResponse>(
        success: false,
        message: 'An unexpected error occurred while getting vendor payments',
      );
    }
  }

  /// Get vendor transactions (placeholder)
  Future<ApiResponse<VendorTransactionsResponse>> getVendorTransactions({
    required String vendorId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Since there's no endpoint for transactions yet, return a placeholder response
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.vendorTransactions(vendorId),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Vendor Transactions', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorTransactionsResponse>.fromJson(
          response.data,
          (data) =>
              VendorTransactionsResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorTransactionsResponse>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to get vendor transactions',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      debugPrint('Get vendor transactions error: ${e.toString()}');
      return ApiResponse<VendorTransactionsResponse>(
        success: false,
        message:
            'An unexpected error occurred while getting vendor transactions',
      );
    }
  }

  /// Update vendor contact information
  Future<ApiResponse<VendorModel>> updateVendorContact({
    required String id,
    String? phone,
    String? city,
    String? area,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (phone != null) requestData['phone'] = phone;
      if (city != null) requestData['city'] = city;
      if (area != null) requestData['area'] = area;

      DebugHelper.printJson('Update Vendor Contact Request', requestData);

      final response = await _apiClient.put(
        ApiConfig.updateVendorContact(id),
        data: requestData,
      );

      DebugHelper.printApiResponse('PUT Update Vendor Contact', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorModel>.fromJson(
          response.data,
          (data) => VendorModel.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorModel>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to update vendor contact',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update vendor contact DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorModel>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update vendor contact error: ${e.toString()}');
      return ApiResponse<VendorModel>(
        success: false,
        message: 'An unexpected error occurred while updating vendor contact',
      );
    }
  }

  /// Duplicate vendor
  Future<ApiResponse<VendorModel>> duplicateVendor({
    required String id,
    required String newName,
    required String newPhone,
    required String newCnic,
  }) async {
    try {
      final requestData = {'name': newName, 'phone': newPhone, 'cnic': newCnic};

      DebugHelper.printJson('Duplicate Vendor Request', requestData);

      final response = await _apiClient.post(
        ApiConfig.duplicateVendor(id),
        data: requestData,
      );

      DebugHelper.printApiResponse('POST Duplicate Vendor', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<VendorModel>.fromJson(
          response.data,
          (data) => VendorModel.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to duplicate vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Duplicate vendor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorModel>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Duplicate vendor error: ${e.toString()}');
      return ApiResponse<VendorModel>(
        success: false,
        message: 'An unexpected error occurred while duplicating vendor',
      );
    }
  }

  /// Get vendors with advanced search parameters
  Future<ApiResponse<VendorsListResponse>> getVendorsAdvanced({
    String? search,
    String? city,
    String? area,
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool showInactive = false,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'show_inactive': showInactive.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (createdAfter != null) {
        queryParams['created_after'] = createdAfter.toIso8601String().split(
          'T',
        )[0];
      }
      if (createdBefore != null) {
        queryParams['created_before'] = createdBefore.toIso8601String().split(
          'T',
        )[0];
      }

      final response = await _apiClient.get(
        ApiConfig.vendors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Vendors Advanced', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<VendorsListResponse>.fromJson(
          response.data,
          (data) => VendorsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<VendorsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get vendors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get vendors advanced DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get vendors advanced error: ${e.toString()}');
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting vendors',
      );
    }
  }
}
