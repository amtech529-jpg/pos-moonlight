import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/principal_account/principal_account_model.dart';
import '../models/common_models.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class PrincipalAccountService {
  static final PrincipalAccountService _instance = PrincipalAccountService._internal();
  factory PrincipalAccountService() => _instance;
  PrincipalAccountService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of principal account transactions with pagination and filtering
  Future<ApiResponse<PrincipalAccountListResponse>> getTransactions({PrincipalAccountListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? PrincipalAccountListParams().toQueryParameters();

      // Debug: Log the API call
      debugPrint('🚀 Calling API: ${ApiConfig.principalAccount}');
      debugPrint('🌐 Query params: $queryParams');

      final response = await _apiClient.get(ApiConfig.principalAccount, queryParameters: queryParams);

      // Debug: Log the response
      debugPrint('🌐 Response status: ${response.statusCode}');
      debugPrint('🌐 Response data: ${response.data}');

      DebugHelper.printApiResponse('GET Principal Account Transactions', response.data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<PrincipalAccountListResponse>.fromJson(response.data, (data) => PrincipalAccountListResponse.fromJson(data));

        // Cache transactions if successful
        if (apiResponse.success && apiResponse.data != null) {
          await _cacheTransactions(apiResponse.data!.transactions);
        }

        return apiResponse;
      } else {
        return ApiResponse<PrincipalAccountListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get principal account transactions',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get principal account transactions DioException: ${e.toString()}');
      final apiError = CommonApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedTransactions = await getCachedTransactions();
        if (cachedTransactions.isNotEmpty) {
          return ApiResponse<PrincipalAccountListResponse>(
            success: true,
            message: 'Showing cached data',
            data: PrincipalAccountListResponse(
              transactions: cachedTransactions,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedTransactions.length,
                totalCount: cachedTransactions.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<PrincipalAccountListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get principal account transactions', e);
      return ApiResponse<PrincipalAccountListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting principal account transactions',
      );
    }
  }

  /// Get a specific transaction by ID
  Future<ApiResponse<PrincipalAccount>> getTransactionById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getPrincipalAccountById(id));

      DebugHelper.printApiResponse('GET Principal Account Transaction by ID', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<PrincipalAccount>.fromJson(response.data, (data) => PrincipalAccount.fromJson(data));
      } else {
        return ApiResponse<PrincipalAccount>(
          success: false,
          message: response.data['message'] ?? 'Failed to get principal account transaction',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get principal account transaction by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PrincipalAccount>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get principal account transaction by ID', e);
      return ApiResponse<PrincipalAccount>(success: false, message: 'An unexpected error occurred while getting principal account transaction');
    }
  }

  /// Create a new principal account transaction
  Future<ApiResponse<PrincipalAccount>> createTransaction(PrincipalAccountCreateRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.principalAccount, data: request.toJson());

      DebugHelper.printApiResponse('CREATE Principal Account Transaction', response.data);

      if (response.statusCode == 201) {
        return ApiResponse<PrincipalAccount>.fromJson(response.data, (data) => PrincipalAccount.fromJson(data));
      } else {
        return ApiResponse<PrincipalAccount>(
          success: false,
          message: response.data['message'] ?? 'Failed to create principal account transaction',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create principal account transaction DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PrincipalAccount>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create principal account transaction', e);
      return ApiResponse<PrincipalAccount>(success: false, message: 'An unexpected error occurred while creating principal account transaction');
    }
  }

  /// Update an existing principal account transaction
  Future<ApiResponse<PrincipalAccount>> updateTransaction(String id, PrincipalAccountUpdateRequest request) async {
    try {
      final response = await _apiClient.put(ApiConfig.updatePrincipalAccount(id), data: request.toJson());

      DebugHelper.printApiResponse('UPDATE Principal Account Transaction', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<PrincipalAccount>.fromJson(response.data, (data) => PrincipalAccount.fromJson(data));
      } else {
        return ApiResponse<PrincipalAccount>(
          success: false,
          message: response.data['message'] ?? 'Failed to update principal account transaction',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update principal account transaction DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PrincipalAccount>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update principal account transaction', e);
      return ApiResponse<PrincipalAccount>(success: false, message: 'An unexpected error occurred while updating principal account transaction');
    }
  }

  /// Delete a principal account transaction (soft delete)
  Future<ApiResponse<void>> deleteTransaction(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deletePrincipalAccount(id));

      DebugHelper.printApiResponse('DELETE Principal Account Transaction', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Principal account transaction deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete principal account transaction',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete principal account transaction DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Delete principal account transaction', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting principal account transaction');
    }
  }

  /// Get current principal account balance
  Future<ApiResponse<PrincipalAccountBalance>> getBalance() async {
    try {
      final response = await _apiClient.get(ApiConfig.principalAccountBalance);

      DebugHelper.printApiResponse('GET Principal Account Balance', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<PrincipalAccountBalance>.fromJson(response.data, (data) => PrincipalAccountBalance.fromJson(data));
      } else {
        return ApiResponse<PrincipalAccountBalance>(
          success: false,
          message: response.data['message'] ?? 'Failed to get principal account balance',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get principal account balance DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PrincipalAccountBalance>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get principal account balance', e);
      return ApiResponse<PrincipalAccountBalance>(success: false, message: 'An unexpected error occurred while getting principal account balance');
    }
  }

  /// Get principal account statistics and analytics
  Future<ApiResponse<PrincipalAccountStatistics>> getStatistics({int days = 30}) async {
    try {
      final response = await _apiClient.get(ApiConfig.principalAccountStatistics, queryParameters: {'days': days.toString()});

      DebugHelper.printApiResponse('GET Principal Account Statistics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<PrincipalAccountStatistics>.fromJson(response.data, (data) => PrincipalAccountStatistics.fromJson(data));
      } else {
        return ApiResponse<PrincipalAccountStatistics>(
          success: false,
          message: response.data['message'] ?? 'Failed to get principal account statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get principal account statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PrincipalAccountStatistics>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get principal account statistics', e);
      return ApiResponse<PrincipalAccountStatistics>(
        success: false,
        message: 'An unexpected error occurred while getting principal account statistics',
      );
    }
  }

  /// Create transaction from other modules
  Future<ApiResponse<ModuleTransactionResponse>> createTransactionFromModule(PrincipalAccountCreateRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.createPrincipalAccountFromModule, data: request.toJson());

      DebugHelper.printApiResponse('CREATE Principal Account Transaction from Module', response.data);

      if (response.statusCode == 201) {
        return ApiResponse<ModuleTransactionResponse>.fromJson(response.data, (data) => ModuleTransactionResponse.fromJson(data));
      } else {
        return ApiResponse<ModuleTransactionResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to create transaction from module',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create transaction from module DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ModuleTransactionResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create transaction from module', e);
      return ApiResponse<ModuleTransactionResponse>(success: false, message: 'An unexpected error occurred while creating transaction from module');
    }
  }

  // Cache management methods
  Future<void> _cacheTransactions(List<PrincipalAccount> transactions) async {
    try {
      final cacheKey = 'principal_account_transactions';
      final cacheData = transactions.map((t) => t.toJson()).toList();
      await _storageService.saveData(cacheKey, cacheData);
    } catch (e) {
      debugPrint('Failed to cache principal account transactions: $e');
    }
  }

  Future<List<PrincipalAccount>> getCachedTransactions() async {
    try {
      final cacheKey = 'principal_account_transactions';
      final cachedData = await _storageService.getData(cacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => PrincipalAccount.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached principal account transactions: $e');
    }
    return [];
  }

  Future<void> clearCache() async {
    try {
      final cacheKey = 'principal_account_transactions';
      await _storageService.removeData(cacheKey);
    } catch (e) {
      debugPrint('Failed to clear principal account transactions cache: $e');
    }
  }
}
