import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/api_response.dart';
import '../../models/labor/labor_api_responses.dart';
import '../../models/labor/labor_model.dart';
import '../../models/labor/salary_slip_model.dart';
import '../../utils/storage_service.dart';
import '../../utils/debug_helper.dart';
import '../api_client.dart';
import 'labor_service_extended.dart';

class LaborService {
  static final LaborService _instance = LaborService._internal();

  factory LaborService() => _instance;

  LaborService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();
  final LaborServiceExtended _extendedService = LaborServiceExtended();

  /// Get list of labors with pagination and filtering
  Future<ApiResponse<LaborsListResponse>> getLabors({LaborListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? LaborListParams().toQueryParameters();

      final response = await _apiClient.get(ApiConfig.labors, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Labors', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final laborsListData = responseData['data'] as Map<String, dynamic>;
          final laborsListResponse = LaborsListResponse.fromJson(laborsListData);

          // Cache labors if successful
          await _cacheLabors(laborsListResponse.labors);

          return ApiResponse<LaborsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Labors retrieved successfully',
            data: laborsListResponse,
          );
        } else {
          return ApiResponse<LaborsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get labors',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedLabors = await _getCachedLabors();
        if (cachedLabors.isNotEmpty) {
          return ApiResponse<LaborsListResponse>(
            success: true,
            message: 'Showing cached data',
            data: LaborsListResponse(
              labors: cachedLabors,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedLabors.length,
                totalCount: cachedLabors.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Get labors', e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting labors',
      );
    }
  }

  /// Get a specific labor by ID
  Future<ApiResponse<LaborModel>> getLaborById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getLaborById(id));

      DebugHelper.printApiResponse('GET Labor by ID', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final laborData = responseData['data'] as Map<String, dynamic>;
          final labor = LaborModel.fromJson(laborData);

          return ApiResponse<LaborModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Labor retrieved successfully',
            data: labor,
          );
        } else {
          return ApiResponse<LaborModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get labor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<LaborModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labor by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get labor by ID error: ${e.toString()}');
      return ApiResponse<LaborModel>(
        success: false,
        message: 'An unexpected error occurred while getting labor',
      );
    }
  }

  /// Create a new labor
  Future<ApiResponse<LaborModel>> createLabor({
    required String name,
    required String cnic,
    required String phoneNumber,
    required String designation,
    required DateTime joiningDate,
    required double salary,
    required String area,
    required String city,
    required String gender,
    required int age,
    required double fixedIncentive,
  }) async {
    try {
      final request = LaborCreateRequest(
        name: name,
        cnic: cnic,
        phoneNumber: phoneNumber,
        designation: designation,
        joiningDate: joiningDate.toIso8601String().split('T')[0],
        // YYYY-MM-DD format
        salary: salary,
        area: area,
        city: city,
        gender: gender,
        age: age,
        fixedIncentive: fixedIncentive,
      );

      DebugHelper.printJson('Create Labor Request', request.toJson());

      final response = await _apiClient.post(ApiConfig.createLabor, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Labor', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final laborData = responseData['data'] as Map<String, dynamic>;
          final labor = LaborModel.fromJson(laborData);

          // Update cache with new labor
          await _addLaborToCache(labor);

          return ApiResponse<LaborModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Labor created successfully',
            data: labor,
          );
        } else {
          return ApiResponse<LaborModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to create labor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<LaborModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create labor DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Create labor', e);
      return ApiResponse<LaborModel>(
        success: false,
        message: 'An unexpected error occurred while creating labor: ${e.toString()}',
      );
    }
  }

  /// Update an existing labor
  Future<ApiResponse<LaborModel>> updateLabor({
    required String id,
    required String name,
    required String cnic,
    required String phoneNumber,
    required String designation,
    required DateTime joiningDate,
    required double salary,
    required String area,
    required String city,
    required String gender,
    required int age,
    required double fixedIncentive,
  }) async {
    try {
      final request = LaborUpdateRequest(
        name: name,
        cnic: cnic,
        phoneNumber: phoneNumber,
        designation: designation,
        joiningDate: joiningDate.toIso8601String().split('T')[0],
        // YYYY-MM-DD format
        salary: salary,
        area: area,
        city: city,
        gender: gender,
        age: age,
        fixedIncentive: fixedIncentive,
      );

      DebugHelper.printJson('Update Labor Request', request.toJson());

      final response = await _apiClient.put(ApiConfig.updateLabor(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Labor', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final laborData = responseData['data'] as Map<String, dynamic>;
          final labor = LaborModel.fromJson(laborData);

          // Update cache with updated labor
          await _updateLaborInCache(labor);

          return ApiResponse<LaborModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Labor updated successfully',
            data: labor,
          );
        } else {
          return ApiResponse<LaborModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update labor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<LaborModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update labor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update labor error: ${e.toString()}');
      return ApiResponse<LaborModel>(
        success: false,
        message: 'An unexpected error occurred while updating labor',
      );
    }
  }

  /// Delete a labor permanently (hard delete)
  Future<ApiResponse<void>> deleteLabor(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteLabor(id));

      DebugHelper.printApiResponse('DELETE Labor', response.data);

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeLaborFromCache(id);

        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Labor deleted permanently',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete labor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Delete labor error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting labor');
    }
  }

  /// Soft delete a labor (set is_active=False)
  Future<ApiResponse<void>> softDeleteLabor(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.softDeleteLabor(id));

      DebugHelper.printApiResponse('POST Soft Delete Labor', response.data);

      if (response.statusCode == 200) {
        // Update cache to mark as inactive
        final cachedLabors = await _getCachedLabors();
        final index = cachedLabors.indexWhere((labor) => labor.id == id);
        if (index != -1) {
          final updatedLabor = cachedLabors[index].copyWith(isActive: false);
          cachedLabors[index] = updatedLabor;
          await _cacheLabors(cachedLabors);
        }

        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Labor soft deleted successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to soft delete labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Soft delete labor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Soft delete labor error: ${e.toString()}');
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred while soft deleting labor',
      );
    }
  }

  /// Restore a soft-deleted labor
  Future<ApiResponse<LaborModel>> restoreLabor(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.restoreLabor(id));

      DebugHelper.printApiResponse('POST Restore Labor', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final laborData = responseData['data'] as Map<String, dynamic>;
          final labor = LaborModel.fromJson(laborData);

          // Update cache with restored labor
          await _updateLaborInCache(labor);

          return ApiResponse<LaborModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Labor restored successfully',
            data: labor,
          );
        } else {
          return ApiResponse<LaborModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to restore labor',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<LaborModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Restore labor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Restore labor error: ${e.toString()}');
      return ApiResponse<LaborModel>(
        success: false,
        message: 'An unexpected error occurred while restoring labor',
      );
    }
  }

  // Delegate extended service methods to the _extendedService instance
  Future<ApiResponse<LaborStatisticsResponse>> getLaborStatistics() => _extendedService.getLaborStatistics();

  Future<ApiResponse<LaborsListResponse>> getLaborsByCity({
    required String city,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getLaborsByCity(city: city, page: page, pageSize: pageSize);

  Future<ApiResponse<LaborsListResponse>> getLaborsByArea({
    required String area,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getLaborsByArea(area: area, page: page, pageSize: pageSize);

  Future<ApiResponse<LaborsListResponse>> getLaborsByDesignation({
    required String designation,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getLaborsByDesignation(designation: designation, page: page, pageSize: pageSize);

  Future<ApiResponse<LaborsListResponse>> getNewLabors({int days = 30, int page = 1, int pageSize = 20}) =>
      _extendedService.getNewLabors(days: days, page: page, pageSize: pageSize);

  Future<ApiResponse<LaborsListResponse>> getRecentLabors({int days = 7, int page = 1, int pageSize = 20}) =>
      _extendedService.getRecentLabors(days: days, page: page, pageSize: pageSize);

  Future<ApiResponse<LaborsListResponse>> searchLabors({
    required String query,
    String? city,
    String? area,
    String? designation,
    String? caste,
    String? gender,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.searchLabors(
    query: query,
    city: city,
    area: area,
    designation: designation,
    caste: caste,
    gender: gender,
    page: page,
    pageSize: pageSize,
  );

  Future<ApiResponse<LaborSalaryReportResponse>> getSalaryReport() => _extendedService.getSalaryReport();

  Future<ApiResponse<LaborDemographicsReportResponse>> getDemographicsReport() =>
      _extendedService.getDemographicsReport();

  Future<ApiResponse<Map<String, dynamic>>> bulkLaborActions({
    required List<String> laborIds,
    required String action,
    double? salaryAmount,
    double? salaryPercentage,
  }) => _extendedService.bulkLaborActions(
    laborIds: laborIds,
    action: action,
    salaryAmount: salaryAmount,
    salaryPercentage: salaryPercentage,
  );

  Future<ApiResponse<LaborModel>> duplicateLabor({
    required String id,
    required String newName,
    required String newPhone,
    required String newCnic,
    int? newAge,
  }) => _extendedService.duplicateLabor(
    id: id,
    newName: newName,
    newPhone: newPhone,
    newCnic: newCnic,
    newAge: newAge,
  );

  Future<ApiResponse<LaborModel>> updateLaborContact({
    required String id,
    String? phoneNumber,
    String? city,
    String? area,
  }) => _extendedService.updateLaborContact(id: id, phoneNumber: phoneNumber, city: city, area: area);

  Future<ApiResponse<LaborModel>> updateLaborSalary({
    required String id,
    double? salary,
    String? designation,
  }) => _extendedService.updateLaborSalary(id: id, salary: salary, designation: designation);

  Future<ApiResponse<LaborPaymentsResponse>> getLaborPayments({
    required String laborId,
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getLaborPayments(laborId: laborId, page: page, pageSize: pageSize);

  Future<ApiResponse<LaborsListResponse>> getLaborsAdvanced({
    String? search,
    String? city,
    String? area,
    String? designation,
    String? caste,
    String? gender,
    String? minSalary,
    String? maxSalary,
    String? minAge,
    String? maxAge,
    DateTime? joinedAfter,
    DateTime? joinedBefore,
    bool showInactive = false,
    String sortBy = 'name',
    String sortOrder = 'asc',
    int page = 1,
    int pageSize = 20,
  }) => _extendedService.getLaborsAdvanced(
    search: search,
    city: city,
    area: area,
    designation: designation,
    caste: caste,
    gender: gender,
    minSalary: minSalary,
    maxSalary: maxSalary,
    minAge: minAge,
    maxAge: maxAge,
    joinedAfter: joinedAfter,
    joinedBefore: joinedBefore,
    showInactive: showInactive,
    sortBy: sortBy,
    sortOrder: sortOrder,
    page: page,
    pageSize: pageSize,
  );

  // Cache management methods
  Future<void> _cacheLabors(List<LaborModel> labors) async {
    try {
      final laborsJson = labors.map((labor) => labor.toJson()).toList();
      await _storageService.saveData(ApiConfig.laborsCacheKey, laborsJson);
    } catch (e) {
      debugPrint('Error caching labors: $e');
    }
  }

  Future<List<LaborModel>> _getCachedLabors() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.laborsCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => LaborModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached labors: $e');
    }
    return [];
  }

  Future<void> _addLaborToCache(LaborModel labor) async {
    try {
      final cachedLabors = await _getCachedLabors();
      cachedLabors.add(labor);
      await _cacheLabors(cachedLabors);
    } catch (e) {
      debugPrint('Error adding labor to cache: $e');
    }
  }

  Future<void> _updateLaborInCache(LaborModel updatedLabor) async {
    try {
      final cachedLabors = await _getCachedLabors();
      final index = cachedLabors.indexWhere((labor) => labor.id == updatedLabor.id);
      if (index != -1) {
        cachedLabors[index] = updatedLabor;
        await _cacheLabors(cachedLabors);
      }
    } catch (e) {
      debugPrint('Error updating labor in cache: $e');
    }
  }

  Future<void> _removeLaborFromCache(String laborId) async {
    try {
      final cachedLabors = await _getCachedLabors();
      cachedLabors.removeWhere((labor) => labor.id == laborId);
      await _cacheLabors(cachedLabors);
    } catch (e) {
      debugPrint('Error removing labor from cache: $e');
    }
  }

  Future<ApiResponse<List<SalarySlip>>> generateSalarySlips({
    required int month,
    required int year,
    bool force = false,
  }) => _extendedService.generateSalarySlips(month: month, year: year, force: force);

  Future<ApiResponse<SalarySlipListResponse>> getSalarySlips({
    int? month,
    int? year,
    String? status,
    String? laborId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _extendedService.getSalarySlips(
      month: month,
      year: year,
      status: status,
      laborId: laborId,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<ApiResponse<SalarySlip>> updateSalarySlipStatus({
    required String slipId,
    required String status,
  }) => _extendedService.updateSalarySlipStatus(slipId: slipId, status: status);
}

