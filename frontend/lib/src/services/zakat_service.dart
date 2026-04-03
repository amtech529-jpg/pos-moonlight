import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/zakat/zakat_api_responses.dart';
import '../models/zakat/zakat_model.dart';
import '../utils/debug_helper.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class ZakatService {
  static final ZakatService _instance = ZakatService._internal();

  factory ZakatService() => _instance;

  ZakatService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of zakats with pagination and filtering
  Future<ApiResponse<ZakatsListResponse>> getZakats({ZakatListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? ZakatListParams().toQueryParameters();

      final response = await _apiClient.get(ApiConfig.zakats, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Zakats', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatListData = responseData['data'] as Map<String, dynamic>;

          // Handle the API response structure from Django views
          final zakatsListResponse = ZakatsListResponse(
            zakats: (zakatListData['zakat_entries'] as List).map((zakatJson) => Zakat.fromJson(zakatJson)).toList(),
            pagination: PaginationInfo.fromJson(zakatListData['pagination']),
            filtersApplied: zakatListData['filters_applied'] as Map<String, dynamic>?,
          );

          // Cache zakats if successful
          await _cacheZakats(zakatsListResponse.zakats);

          return ApiResponse<ZakatsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Zakats retrieved successfully',
            data: zakatsListResponse,
          );
        } else {
          return ApiResponse<ZakatsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get zakats',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ZakatsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get zakats',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get zakats DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedZakats = await _getCachedZakats();
        if (cachedZakats.isNotEmpty) {
          return ApiResponse<ZakatsListResponse>(
            success: true,
            message: 'Showing cached data',
            data: ZakatsListResponse(
              zakats: cachedZakats,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedZakats.length,
                totalCount: cachedZakats.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<ZakatsListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get zakats', e);
      return ApiResponse<ZakatsListResponse>(success: false, message: 'An unexpected error occurred while getting zakats');
    }
  }

  /// Get a specific zakat by ID
  Future<ApiResponse<Zakat>> getZakatById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getZakatById(id));

      DebugHelper.printApiResponse('GET Zakat by ID', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat retrieved successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to get zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get zakat by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get zakat by ID error: ${e.toString()}');
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while getting zakat');
    }
  }

  /// Create a new zakat
  Future<ApiResponse<Zakat>> createZakat({
    required String name,
    required String description,
    required DateTime date,
    required String time, // HH:MM format
    required double amount,
    required String beneficiaryName,
    String? beneficiaryContact,
    String? notes,
    required String authorizedBy,
  }) async {
    try {
      final request = ZakatCreateRequest(
        name: name,
        description: description,
        date: date,
        time: time,
        amount: amount,
        beneficiaryName: beneficiaryName,
        beneficiaryContact: beneficiaryContact,
        notes: notes,
        authorizedBy: authorizedBy,
      );

      DebugHelper.printJson('Create Zakat Request', request.toJson());

      final response = await _apiClient.post(ApiConfig.createZakat, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Zakat', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          // Update cache with new zakat
          await _addZakatToCache(zakat);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat created successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to create zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to create zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create zakat DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create zakat', e);
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while creating zakat: ${e.toString()}');
    }
  }

  /// Update an existing zakat
  Future<ApiResponse<Zakat>> updateZakat({
    required String id,
    required String name,
    required String description,
    required DateTime date,
    required String time, // HH:MM format
    required double amount,
    required String beneficiaryName,
    String? beneficiaryContact,
    String? notes,
    required String authorizedBy,
  }) async {
    try {
      final request = ZakatUpdateRequest(
        name: name,
        description: description,
        date: date,
        time: time,
        amount: amount,
        beneficiaryName: beneficiaryName,
        beneficiaryContact: beneficiaryContact,
        notes: notes,
        authorizedBy: authorizedBy,
      );

      DebugHelper.printJson('Update Zakat Request', request.toJson());

      final response = await _apiClient.put(ApiConfig.updateZakat(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Zakat', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          // Update cache with updated zakat
          await _updateZakatInCache(zakat);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat updated successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to update zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update zakat DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Update zakat error: ${e.toString()}');
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while updating zakat');
    }
  }

  /// Delete a zakat (soft delete)
  Future<ApiResponse<void>> deleteZakat(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteZakat(id));

      DebugHelper.printApiResponse('DELETE Zakat', response.data);

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeZakatFromCache(id);

        return ApiResponse<void>(success: true, message: response.data['message'] ?? 'Zakat deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete zakat DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Delete zakat error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting zakat');
    }
  }

  /// Get zakat statistics
  Future<ApiResponse<ZakatStatisticsResponse>> getZakatStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.zakatStatistics);

      DebugHelper.printApiResponse('GET Zakat Statistics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<ZakatStatisticsResponse>.fromJson(response.data, (data) => ZakatStatisticsResponse.fromJson(data as Map<String, dynamic>));
      } else {
        return ApiResponse<ZakatStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get zakat statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get zakat statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ZakatStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get zakat statistics error: ${e.toString()}');
      return ApiResponse<ZakatStatisticsResponse>(success: false, message: 'An unexpected error occurred while getting zakat statistics');
    }
  }

  /// Search zakats
  Future<ApiResponse<ZakatsListResponse>> searchZakats({
    required String query,
    String? beneficiaryName,
    String? authorizedBy,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {'search': query, 'page': page.toString(), 'page_size': pageSize.toString()};

      if (beneficiaryName != null && beneficiaryName.isNotEmpty) {
        queryParams['beneficiary'] = beneficiaryName;
      }
      if (authorizedBy != null && authorizedBy.isNotEmpty) {
        queryParams['authorized_by'] = authorizedBy;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(ApiConfig.searchZakats, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Search Zakats', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatListData = responseData['data'] as Map<String, dynamic>;

          final zakatsListResponse = ZakatsListResponse(
            zakats: (zakatListData['zakat_entries'] as List).map((zakatJson) => Zakat.fromJson(zakatJson)).toList(),
            pagination: PaginationInfo.fromJson(zakatListData['pagination']),
          );

          return ApiResponse<ZakatsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Search completed successfully',
            data: zakatsListResponse,
          );
        } else {
          return ApiResponse<ZakatsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to search zakats',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ZakatsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to search zakats',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search zakats DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ZakatsListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Search zakats error: ${e.toString()}');
      return ApiResponse<ZakatsListResponse>(success: false, message: 'An unexpected error occurred while searching zakats');
    }
  }

  /// Get zakats by date range
  Future<ApiResponse<ZakatsListResponse>> getZakatsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(ApiConfig.zakatsByDateRange, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Zakats by Date Range', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatListData = responseData['data'] as Map<String, dynamic>;

          final zakatsListResponse = ZakatsListResponse(
            zakats: (zakatListData['zakat_entries'] as List).map((zakatJson) => Zakat.fromJson(zakatJson)).toList(),
            pagination: PaginationInfo(
              currentPage: page,
              pageSize: pageSize,
              totalCount: zakatListData['count'] as int,
              totalPages: ((zakatListData['count'] as int) / pageSize).ceil(),
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ZakatsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Date range search completed successfully',
            data: zakatsListResponse,
          );
        } else {
          return ApiResponse<ZakatsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get zakats by date range',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ZakatsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get zakats by date range',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get zakats by date range DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ZakatsListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get zakats by date range error: ${e.toString()}');
      return ApiResponse<ZakatsListResponse>(success: false, message: 'An unexpected error occurred while getting zakats by date range');
    }
  }

  /// Bulk actions on zakats
  Future<ApiResponse<Map<String, dynamic>>> bulkZakatActions({required List<String> zakatIds, required String action}) async {
    try {
      final request = ZakatBulkActionRequest(zakatIds: zakatIds, action: action);

      DebugHelper.printJson('Bulk Zakat Actions Request', request.toJson());

      final response = await _apiClient.post(ApiConfig.bulkZakatActions, data: request.toJson());

      DebugHelper.printApiResponse('POST Bulk Zakat Actions', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Bulk action completed successfully',
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
      debugPrint('Bulk zakat actions DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Bulk zakat actions error: ${e.toString()}');
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while performing bulk action');
    }
  }

  /// Get recent zakats
  Future<ApiResponse<ZakatsListResponse>> getRecentZakats({int limit = 10}) async {
    try {
      final queryParams = {'limit': limit.toString()};

      final response = await _apiClient.get(ApiConfig.recentZakats, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Recent Zakats', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatListData = responseData['data'] as Map<String, dynamic>;

          final zakatsListResponse = ZakatsListResponse(
            zakats: (zakatListData['zakat_entries'] as List).map((zakatJson) => Zakat.fromJson(zakatJson)).toList(),
            pagination: PaginationInfo(
              currentPage: 1,
              pageSize: limit,
              totalCount: zakatListData['count'] as int,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ZakatsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Recent zakats retrieved successfully',
            data: zakatsListResponse,
          );
        } else {
          return ApiResponse<ZakatsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get recent zakats',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ZakatsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get recent zakats',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get recent zakats DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ZakatsListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get recent zakats error: ${e.toString()}');
      return ApiResponse<ZakatsListResponse>(success: false, message: 'An unexpected error occurred while getting recent zakats');
    }
  }

  /// Get zakats by beneficiary
  Future<ApiResponse<ZakatsListResponse>> getZakatsByBeneficiary({required String beneficiaryName, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final queryParams = <String, String>{};

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        ApiConfig.zakatsByBeneficiary(beneficiaryName),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      DebugHelper.printApiResponse('GET Zakats by Beneficiary', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatListData = responseData['data'] as Map<String, dynamic>;

          final zakatsListResponse = ZakatsListResponse(
            zakats: (zakatListData['zakat_entries'] as List).map((zakatJson) => Zakat.fromJson(zakatJson)).toList(),
            pagination: PaginationInfo(
              currentPage: 1,
              pageSize: zakatListData['count'] as int,
              totalCount: zakatListData['count'] as int,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ZakatsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Zakats by beneficiary retrieved successfully',
            data: zakatsListResponse,
          );
        } else {
          return ApiResponse<ZakatsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get zakats by beneficiary',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ZakatsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get zakats by beneficiary',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get zakats by beneficiary DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ZakatsListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get zakats by beneficiary error: ${e.toString()}');
      return ApiResponse<ZakatsListResponse>(success: false, message: 'An unexpected error occurred while getting zakats by beneficiary');
    }
  }

  /// Get zakats by authority
  Future<ApiResponse<ZakatsListResponse>> getZakatsByAuthority({required String authority, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final queryParams = <String, String>{};

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(ApiConfig.zakatsByAuthority(authority), queryParameters: queryParams.isNotEmpty ? queryParams : null);

      DebugHelper.printApiResponse('GET Zakats by Authority', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatListData = responseData['data'] as Map<String, dynamic>;

          final zakatsListResponse = ZakatsListResponse(
            zakats: (zakatListData['zakat_entries'] as List).map((zakatJson) => Zakat.fromJson(zakatJson)).toList(),
            pagination: PaginationInfo(
              currentPage: 1,
              pageSize: zakatListData['count'] as int,
              totalCount: zakatListData['count'] as int,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ZakatsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Zakats by authority retrieved successfully',
            data: zakatsListResponse,
          );
        } else {
          return ApiResponse<ZakatsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get zakats by authority',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ZakatsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get zakats by authority',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get zakats by authority DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ZakatsListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get zakats by authority error: ${e.toString()}');
      return ApiResponse<ZakatsListResponse>(success: false, message: 'An unexpected error occurred while getting zakats by authority');
    }
  }

  /// Get beneficiary report
  Future<ApiResponse<ZakatBeneficiaryReportResponse>> getBeneficiaryReport({required String beneficiaryName}) async {
    try {
      final queryParams = {'beneficiary_name': beneficiaryName};

      final response = await _apiClient.get(ApiConfig.zakatBeneficiaryReport, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Beneficiary Report', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<ZakatBeneficiaryReportResponse>.fromJson(
          response.data,
          (data) => ZakatBeneficiaryReportResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<ZakatBeneficiaryReportResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get beneficiary report',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get beneficiary report DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ZakatBeneficiaryReportResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get beneficiary report error: ${e.toString()}');
      return ApiResponse<ZakatBeneficiaryReportResponse>(success: false, message: 'An unexpected error occurred while getting beneficiary report');
    }
  }

  /// Duplicate zakat record
  Future<ApiResponse<Zakat>> duplicateZakat(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.duplicateZakat(id));

      DebugHelper.printApiResponse('POST Duplicate Zakat', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          // Add duplicated zakat to cache
          await _addZakatToCache(zakat);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat duplicated successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to duplicate zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to duplicate zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Duplicate zakat DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Duplicate zakat error: ${e.toString()}');
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while duplicating zakat');
    }
  }

  /// Verify zakat record
  Future<ApiResponse<Zakat>> verifyZakat(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.verifyZakat(id));

      DebugHelper.printApiResponse('POST Verify Zakat', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          // Update cache with verified zakat
          await _updateZakatInCache(zakat);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat verified successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to verify zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to verify zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Verify zakat DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Verify zakat error: ${e.toString()}');
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while verifying zakat');
    }
  }

  /// Unverify zakat record
  Future<ApiResponse<Zakat>> unverifyZakat(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.unverifyZakat(id));

      DebugHelper.printApiResponse('POST Unverify Zakat', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          // Update cache with unverified zakat
          await _updateZakatInCache(zakat);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat unverified successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to unverify zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to unverify zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Unverify zakat DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Unverify zakat error: ${e.toString()}');
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while unverifying zakat');
    }
  }

  /// Archive zakat record
  Future<ApiResponse<Zakat>> archiveZakat(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.archiveZakat(id));

      DebugHelper.printApiResponse('POST Archive Zakat', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          // Update cache with archived zakat
          await _updateZakatInCache(zakat);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat archived successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to archive zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to archive zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Archive zakat DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Archive zakat error: ${e.toString()}');
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while archiving zakat');
    }
  }

  /// Unarchive zakat record
  Future<ApiResponse<Zakat>> unarchiveZakat(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.unarchiveZakat(id));

      DebugHelper.printApiResponse('POST Unarchive Zakat', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final zakatData = responseData['data'] as Map<String, dynamic>;
          final zakat = Zakat.fromJson(zakatData);

          // Update cache with unarchived zakat
          await _updateZakatInCache(zakat);

          return ApiResponse<Zakat>(success: true, message: responseData['message'] as String? ?? 'Zakat unarchived successfully', data: zakat);
        } else {
          return ApiResponse<Zakat>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to unarchive zakat',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Zakat>(
          success: false,
          message: response.data['message'] ?? 'Failed to unarchive zakat',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Unarchive zakat DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Zakat>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Unarchive zakat error: ${e.toString()}');
      return ApiResponse<Zakat>(success: false, message: 'An unexpected error occurred while unarchiving zakat');
    }
  }

  // Cache management methods
  Future<void> _cacheZakats(List<Zakat> zakats) async {
    try {
      final zakatsJson = zakats.map((zakat) => zakat.toJson()).toList();
      await _storageService.saveData(ApiConfig.zakatsCacheKey, zakatsJson);
    } catch (e) {
      debugPrint('Error caching zakats: $e');
    }
  }

  Future<List<Zakat>> _getCachedZakats() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.zakatsCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => Zakat.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached zakats: $e');
    }
    return [];
  }

  Future<void> _addZakatToCache(Zakat zakat) async {
    try {
      final cachedZakats = await _getCachedZakats();
      cachedZakats.add(zakat);
      await _cacheZakats(cachedZakats);
    } catch (e) {
      debugPrint('Error adding zakat to cache: $e');
    }
  }

  Future<void> _updateZakatInCache(Zakat updatedZakat) async {
    try {
      final cachedZakats = await _getCachedZakats();
      final index = cachedZakats.indexWhere((zakat) => zakat.id == updatedZakat.id);
      if (index != -1) {
        cachedZakats[index] = updatedZakat;
        await _cacheZakats(cachedZakats);
      }
    } catch (e) {
      debugPrint('Error updating zakat in cache: $e');
    }
  }

  Future<void> _removeZakatFromCache(String zakatId) async {
    try {
      final cachedZakats = await _getCachedZakats();
      cachedZakats.removeWhere((zakat) => zakat.id == zakatId);
      await _cacheZakats(cachedZakats);
    } catch (e) {
      debugPrint('Error removing zakat from cache: $e');
    }
  }

  /// Refresh zakat records (for pull-to-refresh functionality)
  Future<ApiResponse<ZakatsListResponse>> refreshZakatRecords() async {
    return getZakats();
  }
}
