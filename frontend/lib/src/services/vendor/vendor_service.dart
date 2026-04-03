import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/api_response.dart';
import '../../models/vendor/vendor_api_responses.dart';
import '../../models/vendor/vendor_model.dart';
import '../../utils/storage_service.dart';
import '../../utils/debug_helper.dart';
import '../api_client.dart';
import 'vendor_service_extended.dart';

class VendorService {
  static final VendorService _instance = VendorService._internal();

  factory VendorService() => _instance;

  VendorService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();
  final VendorServiceExtended _extendedService = VendorServiceExtended();

  /// Get list of vendors with pagination and filtering
  Future<ApiResponse<VendorsListResponse>> getVendors({VendorListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? VendorListParams().toQueryParameters();

      final response = await _apiClient.get(ApiConfig.vendors, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Vendors', response.data);

      if (response.statusCode == 200) {
        // Fix: Handle the response data structure correctly
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final vendorsListData = responseData['data'] as Map<String, dynamic>;
          final vendorsListResponse = VendorsListResponse.fromJson(vendorsListData);

          // Cache vendors if successful
          await _cacheVendors(vendorsListResponse.vendors);

          return ApiResponse<VendorsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Vendors retrieved successfully',
            data: vendorsListResponse,
          );
        } else {
          return ApiResponse<VendorsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get vendors',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<VendorsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get vendors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get vendors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedVendors = await _getCachedVendors();
        if (cachedVendors.isNotEmpty) {
          return ApiResponse<VendorsListResponse>(
            success: true,
            message: 'Showing cached data',
            data: VendorsListResponse(
              vendors: cachedVendors,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedVendors.length,
                totalCount: cachedVendors.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<VendorsListResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Get vendors', e);
      return ApiResponse<VendorsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting vendors',
      );
    }
  }

  /// Get a specific vendor by ID
  Future<ApiResponse<VendorModel>> getVendorById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getVendorById(id));

      DebugHelper.printApiResponse('GET Vendor by ID', response.data);

      if (response.statusCode == 200) {
        // Fix: Handle the response data structure correctly
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final vendorData = responseData['data'] as Map<String, dynamic>;
          final vendor = VendorModel.fromJson(vendorData);

          return ApiResponse<VendorModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Vendor retrieved successfully',
            data: vendor,
          );
        } else {
          return ApiResponse<VendorModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get vendor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<VendorModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get vendor by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get vendor by ID error: ${e.toString()}');
      return ApiResponse<VendorModel>(
        success: false,
        message: 'An unexpected error occurred while getting vendor',
      );
    }
  }

  /// Create a new vendor
  Future<ApiResponse<VendorModel>> createVendor({
    required String name,
    String? businessName,
    String? cnic,
    required String phone,
    String? city,
    String? area,
    DateTime? createdAt,
  }) async {
    try {
      final request = VendorCreateRequest(
        name: name,
        businessName: businessName,
        cnic: cnic,
        phone: phone,
        city: city,
        area: area,
        createdAt: createdAt,
      );

      final requestData = request.toJson();
      
      // Debug: Check if CNIC field is included
      print('🔍 DEBUG: Request JSON keys: ${requestData.keys.toList()}');
      print('🔍 DEBUG: CNIC field present: ${requestData.containsKey('cnic')}');
      print('🔍 DEBUG: CNIC value: "${requestData['cnic']}"');
      
      DebugHelper.printJson('Create Vendor Request', requestData);

      final response = await _apiClient.post(ApiConfig.createVendor, data: requestData);

      DebugHelper.printApiResponse('POST Create Vendor', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Fix: Handle the response data structure correctly
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final vendorData = responseData['data'] as Map<String, dynamic>;
          final vendor = VendorModel.fromJson(vendorData);

          // Update cache with new vendor
          await _addVendorToCache(vendor);

          return ApiResponse<VendorModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Vendor created successfully',
            data: vendor,
          );
        } else {
          return ApiResponse<VendorModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to create vendor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<VendorModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create vendor DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Create vendor', e);
      return ApiResponse<VendorModel>(
        success: false,
        message: 'An unexpected error occurred while creating vendor: ${e.toString()}',
      );
    }
  }

  /// Update an existing vendor
  Future<ApiResponse<VendorModel>> updateVendor({
    required String id,
    required String name,
    required String businessName,
    String? cnic,
    required String phone,
    required String city,
    required String area,
  }) async {
    try {
      final request = VendorUpdateRequest(
        name: name,
        businessName: businessName,
        cnic: cnic,
        phone: phone,
        city: city,
        area: area,
      );

      DebugHelper.printJson('Update Vendor Request', request.toJson());

      final response = await _apiClient.put(ApiConfig.updateVendor(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Vendor', response.data);

      if (response.statusCode == 200) {
        // Fix: Handle the response data structure correctly
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final vendorData = responseData['data'] as Map<String, dynamic>;
          final vendor = VendorModel.fromJson(vendorData);

          // Update cache with updated vendor
          await _updateVendorInCache(vendor);

          return ApiResponse<VendorModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Vendor updated successfully',
            data: vendor,
          );
        } else {
          return ApiResponse<VendorModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update vendor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<VendorModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update vendor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update vendor error: ${e.toString()}');
      return ApiResponse<VendorModel>(
        success: false,
        message: 'An unexpected error occurred while updating vendor',
      );
    }
  }

  /// Delete a vendor permanently (hard delete)
  Future<ApiResponse<void>> deleteVendor(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteVendor(id));

      DebugHelper.printApiResponse('DELETE Vendor', response.data);

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeVendorFromCache(id);

        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Vendor deleted permanently',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete vendor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Delete vendor error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting vendor');
    }
  }

  /// Soft delete a vendor (set is_active=False)
  Future<ApiResponse<void>> softDeleteVendor(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.softDeleteVendor(id));

      DebugHelper.printApiResponse('POST Soft Delete Vendor', response.data);

      if (response.statusCode == 200) {
        // Update cache to mark as inactive
        final cachedVendors = await _getCachedVendors();
        final index = cachedVendors.indexWhere((vendor) => vendor.id == id);
        if (index != -1) {
          final updatedVendor = cachedVendors[index].copyWith(isActive: false);
          cachedVendors[index] = updatedVendor;
          await _cacheVendors(cachedVendors);
        }

        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Vendor soft deleted successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to soft delete vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Soft delete vendor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Soft delete vendor error: ${e.toString()}');
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred while soft deleting vendor',
      );
    }
  }

  /// Restore a soft-deleted vendor
  Future<ApiResponse<VendorModel>> restoreVendor(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.restoreVendor(id));

      DebugHelper.printApiResponse('POST Restore Vendor', response.data);

      if (response.statusCode == 200) {
        // Fix: Handle the response data structure correctly
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final vendorData = responseData['data'] as Map<String, dynamic>;
          final vendor = VendorModel.fromJson(vendorData);

          // Update cache with restored vendor
          await _updateVendorInCache(vendor);

          return ApiResponse<VendorModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Vendor restored successfully',
            data: vendor,
          );
        } else {
          return ApiResponse<VendorModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to restore vendor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<VendorModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Restore vendor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<VendorModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Restore vendor error: ${e.toString()}');
      return ApiResponse<VendorModel>(
        success: false,
        message: 'An unexpected error occurred while restoring vendor',
      );
    }
  }

  // Delegate extended service methods to the _extendedService instance
  Future<ApiResponse<VendorStatisticsResponse>> getVendorStatistics() => _extendedService.getVendorStatistics();

  Future<ApiResponse<VendorsListResponse>> getVendorsByCity({
    required String city,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getVendorsByCity(city: city, page: page, pageSize: pageSize);

  Future<ApiResponse<VendorsListResponse>> getVendorsByArea({
    required String area,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getVendorsByArea(area: area, page: page, pageSize: pageSize);

  Future<ApiResponse<VendorsListResponse>> getNewVendors({
    int days = 30,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getNewVendors(days: days, page: page, pageSize: pageSize);

  Future<ApiResponse<VendorsListResponse>> getRecentVendors({
    int days = 7,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getRecentVendors(days: days, page: page, pageSize: pageSize);

  Future<ApiResponse<VendorsListResponse>> searchVendors({
    required String query,
    String? city,
    String? area,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.searchVendors(
    query: query,
    city: city,
    area: area,
    page: page,
    pageSize: pageSize,
  );

  Future<ApiResponse<Map<String, dynamic>>> bulkVendorActions({
    required List<String> vendorIds,
    required String action,
  }) => _extendedService.bulkVendorActions(vendorIds: vendorIds, action: action);

  Future<ApiResponse<List<VendorCityCount>>> getVendorCities() => _extendedService.getVendorCities();

  Future<ApiResponse<List<VendorAreaCount>>> getVendorAreas({String? city}) => _extendedService.getVendorAreas(city: city);

  Future<ApiResponse<VendorPaymentsResponse>> getVendorPayments({
    required String vendorId,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getVendorPayments(vendorId: vendorId, page: page, pageSize: pageSize);

  Future<ApiResponse<VendorTransactionsResponse>> getVendorTransactions({
    required String vendorId,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getVendorTransactions(vendorId: vendorId, page: page, pageSize: pageSize);

  Future<ApiResponse<VendorModel>> updateVendorContact({
    required String id,
    String? phone,
    String? city,
    String? area,
  }) => _extendedService.updateVendorContact(id: id, phone: phone, city: city, area: area);

  Future<ApiResponse<VendorModel>> duplicateVendor({
    required String id,
    required String newName,
    required String newPhone,
    required String newCnic,
  }) => _extendedService.duplicateVendor(
    id: id,
    newName: newName,
    newPhone: newPhone,
    newCnic: newCnic,
  );

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
  }) => _extendedService.getVendorsAdvanced(
    search: search,
    city: city,
    area: area,
    createdAfter: createdAfter,
    createdBefore: createdBefore,
    showInactive: showInactive,
    sortBy: sortBy,
    sortOrder: sortOrder,
    page: page,
    pageSize: pageSize,
  );

  // Cache management methods
  Future<void> _cacheVendors(List<VendorModel> vendors) async {
    try {
      final vendorsJson = vendors.map((vendor) => vendor.toJson()).toList();
      await _storageService.saveData(ApiConfig.vendorsCacheKey, vendorsJson);
    } catch (e) {
      debugPrint('Error caching vendors: $e');
    }
  }

  Future<List<VendorModel>> _getCachedVendors() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.vendorsCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => VendorModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached vendors: $e');
    }
    return [];
  }

  Future<void> _addVendorToCache(VendorModel vendor) async {
    try {
      final cachedVendors = await _getCachedVendors();
      cachedVendors.add(vendor);
      await _cacheVendors(cachedVendors);
    } catch (e) {
      debugPrint('Error adding vendor to cache: $e');
    }
  }

  Future<void> _updateVendorInCache(VendorModel updatedVendor) async {
    try {
      final cachedVendors = await _getCachedVendors();
      final index = cachedVendors.indexWhere((vendor) => vendor.id == updatedVendor.id);
      if (index != -1) {
        cachedVendors[index] = updatedVendor;
        await _cacheVendors(cachedVendors);
      }
    } catch (e) {
      debugPrint('Error updating vendor in cache: $e');
    }
  }

  Future<void> _removeVendorFromCache(String vendorId) async {
    try {
      final cachedVendors = await _getCachedVendors();
      cachedVendors.removeWhere((vendor) => vendor.id == vendorId);
      await _cacheVendors(cachedVendors);
    } catch (e) {
      debugPrint('Error removing vendor from cache: $e');
    }
  }
}