import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/customer/customer_api_responses.dart';
import '../models/customer/customer_model.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of customers with pagination and filtering
  Future<ApiResponse<CustomersListResponse>> getCustomers({CustomerListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? CustomerListParams().toQueryParameters();

      debugPrint('🚀 [CustomerService] GET ${ApiConfig.customers}');

      final response = await _apiClient.get(ApiConfig.customers, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 🔍 DEBUG: Print raw structure keys
        debugPrint('📦 [CustomerService] Response Keys: ${responseData.keys.toList()}');

        // ✅ FIX: Robust Parsing Logic for Nested Structure
        List<CustomerModel> customers = [];
        PaginationInfo pagination;

        // Check if 'data' is a Map (which contains 'customers' list) or a List directly
        dynamic dataField = responseData['data'];
        List<dynamic> listData = [];

        if (dataField is Map) {
          // Scenario A: data: { "customers": [...], "pagination": {...} }
          debugPrint('📄 [CustomerService] Data is a Map. Looking for "customers" key.');
          if (dataField['customers'] != null && dataField['customers'] is List) {
            listData = dataField['customers'];
          }

          // Extract Pagination from inside 'data' if present
          if (dataField['pagination'] != null) {
            pagination = PaginationInfo.fromJson(dataField['pagination']);
          } else {
            // Fallback if pagination is at root level or missing
            pagination = PaginationInfo(
                currentPage: 1,
                pageSize: listData.length > 0 ? listData.length : 20,
                totalCount: listData.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false
            );
          }
        } else if (dataField is List) {
          // Scenario B: data: [ ... customers ... ]
          debugPrint('📄 [CustomerService] Data is a List directly.');
          listData = dataField;

          // Look for pagination at root level
          if (responseData['pagination'] != null) {
            pagination = PaginationInfo.fromJson(responseData['pagination']);
          } else {
            pagination = PaginationInfo(
                currentPage: 1,
                pageSize: listData.length > 0 ? listData.length : 20,
                totalCount: listData.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false
            );
          }
        } else {
          // Fallback empty
          listData = [];
          pagination = PaginationInfo(currentPage: 1, pageSize: 20, totalCount: 0, totalPages: 1, hasNext: false, hasPrevious: false);
        }

        // Parse the list
        customers = listData.map((json) {
          try {
            return CustomerModel.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            debugPrint('⚠️ [CustomerService] Error parsing customer item: $e');
            return null;
          }
        }).whereType<CustomerModel>().toList();

        debugPrint('✅ [CustomerService] Successfully parsed ${customers.length} customers.');

        final listResponse = CustomersListResponse(
            customers: customers,
            pagination: pagination
        );

        // Cache if we got data
        if (customers.isNotEmpty) {
          await _cacheCustomers(customers);
        }

        return ApiResponse<CustomersListResponse>(
          success: responseData['success'] ?? true,
          message: responseData['message'] ?? 'Customers retrieved',
          data: listResponse,
        );
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customers (Status ${response.statusCode})',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [CustomerService] DioException: ${e.message}');
      final apiError = ApiError.fromDioError(e);

      // Try cache on network error
      if (apiError.type == 'network_error') {
        final cachedCustomers = await getCachedCustomers();
        if (cachedCustomers.isNotEmpty) {
          debugPrint('📂 [CustomerService] Returning cached data due to network error.');
          return ApiResponse<CustomersListResponse>(
            success: true,
            message: 'Showing cached data (Offline)',
            data: CustomersListResponse(
              customers: cachedCustomers,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedCustomers.length,
                totalCount: cachedCustomers.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e, stack) {
      debugPrint('💥 [CustomerService] UNCAUGHT EXCEPTION: $e');
      debugPrint(stack.toString());
      return ApiResponse<CustomersListResponse>(success: false, message: 'Unexpected error: $e');
    }
  }

  // ... (Rest of the file remains exactly the same) ...

  /// Get a specific customer by ID
  Future<ApiResponse<CustomerModel>> getCustomerById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getCustomerById(id));

      DebugHelper.printApiResponse('GET Customer by ID', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<CustomerModel>.fromJson(response.data, (data) => CustomerModel.fromJson(data));
      } else {
        return ApiResponse<CustomerModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customer',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customer by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomerModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get customer by ID error: ${e.toString()}');
      return ApiResponse<CustomerModel>(success: false, message: 'An unexpected error occurred while getting customer');
    }
  }

  /// Create a new customer
  Future<ApiResponse<CustomerModel>> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? city,
    String? country,
    String? customerType,
    String? businessName,
    String? taxNumber,
    String? notes,
  }) async {
    try {
      final request = CustomerCreateRequest(
        name: name,
        phone: phone,
        email: email,
        address: address,
        city: city,
        country: country,
        customerType: customerType,
        businessName: businessName,
        taxNumber: taxNumber,
        notes: notes,
      );

      DebugHelper.printJson('Create Customer Request', request.toJson());

      final response = await _apiClient.post(ApiConfig.createCustomer, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Customer', response.data);

      if (response.statusCode == 201) {
        final apiResponse = ApiResponse<CustomerModel>.fromJson(response.data, (data) => CustomerModel.fromJson(data));

        // Update cache with new customer
        if (apiResponse.success && apiResponse.data != null) {
          await _addCustomerToCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CustomerModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create customer',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create customer DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomerModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create customer', e);
      return ApiResponse<CustomerModel>(success: false, message: 'An unexpected error occurred while creating customer: ${e.toString()}');
    }
  }

  /// Update an existing customer
  Future<ApiResponse<CustomerModel>> updateCustomer({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? address,
    String? city,
    String? country,
    String? customerType,
    String? status,
    String? businessName,
    String? taxNumber,
    String? notes,
    bool? phoneVerified,
    bool? emailVerified,
  }) async {
    try {
      final request = CustomerUpdateRequest(
        name: name,
        phone: phone,
        email: email,
        address: address,
        city: city,
        country: country,
        customerType: customerType,
        status: status,
        businessName: businessName,
        taxNumber: taxNumber,
        notes: notes,
        phoneVerified: phoneVerified,
        emailVerified: emailVerified,
      );

      DebugHelper.printJson('Update Customer Request', request.toJson());

      final response = await _apiClient.put(ApiConfig.updateCustomer(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Customer', response.data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<CustomerModel>.fromJson(response.data, (data) => CustomerModel.fromJson(data));

        // Update cache with updated customer
        if (apiResponse.success && apiResponse.data != null) {
          await _updateCustomerInCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CustomerModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update customer',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update customer DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomerModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Update customer error: ${e.toString()}');
      return ApiResponse<CustomerModel>(success: false, message: 'An unexpected error occurred while updating customer');
    }
  }

  /// Delete a customer permanently (hard delete)
  Future<ApiResponse<void>> deleteCustomer(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteCustomer(id));

      DebugHelper.printApiResponse('DELETE Customer', response.data);

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeCustomerFromCache(id);

        return ApiResponse<void>(success: true, message: response.data['message'] ?? 'Customer deleted permanently');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete customer',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete customer DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Delete customer error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting customer');
    }
  }

  /// Soft delete a customer (set is_active=False)
  Future<ApiResponse<void>> softDeleteCustomer(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.softDeleteCustomer(id));

      DebugHelper.printApiResponse('POST Soft Delete Customer', response.data);

      if (response.statusCode == 200) {
        // Update cache to mark as inactive
        final cachedCustomers = await getCachedCustomers();
        final index = cachedCustomers.indexWhere((customer) => customer.id == id);
        if (index != -1) {
          final updatedCustomer = cachedCustomers[index].copyWith(isActive: false);
          cachedCustomers[index] = updatedCustomer;
          await _cacheCustomers(cachedCustomers);
        }

        return ApiResponse<void>(success: true, message: response.data['message'] ?? 'Customer soft deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to soft delete customer',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Soft delete customer DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Soft delete customer error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while soft deleting customer');
    }
  }

  /// Restore a soft-deleted customer
  Future<ApiResponse<CustomerModel>> restoreCustomer(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.restoreCustomer(id));

      DebugHelper.printApiResponse('POST Restore Customer', response.data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<CustomerModel>.fromJson(response.data, (data) => CustomerModel.fromJson(data));

        // Update cache with restored customer
        if (apiResponse.success && apiResponse.data != null) {
          await _updateCustomerInCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CustomerModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore customer',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Restore customer DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomerModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Restore customer error: ${e.toString()}');
      return ApiResponse<CustomerModel>(success: false, message: 'An unexpected error occurred while restoring customer');
    }
  }

  /// Search customers
  Future<ApiResponse<CustomersListResponse>> searchCustomers({
    required String query,
    int page = 1,
    int pageSize = 20,
    bool showInactive = false,
    String? customerType,
    String? status,
    String? city,
    String? country,
  }) async {
    final params = CustomerListParams(
      page: page,
      pageSize: pageSize,
      search: query,
      showInactive: showInactive,
      customerType: customerType,
      status: status,
      city: city,
      country: country,
    );

    return await getCustomers(params: params);
  }

  /// Get customers by status
  Future<ApiResponse<CustomersListResponse>> getCustomersByStatus({required String status, int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.customersByStatus(status), queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Customers by Status', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customers by status',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customers by status DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get customers by status error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting customers by status');
    }
  }

  /// Get customer statistics
  Future<ApiResponse<CustomerStatisticsResponse>> getCustomerStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.customerStatistics);

      DebugHelper.printApiResponse('GET Customer Statistics', response.data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<CustomerStatisticsResponse>.fromJson(response.data, (data) => CustomerStatisticsResponse.fromJson(data));

        // Cache statistics if successful
        if (apiResponse.success && apiResponse.data != null) {
          await _cacheCustomerStatistics(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CustomerStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customer statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customer statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached statistics if network error
      if (apiError.type == 'network_error') {
        final cachedStats = await _getCachedCustomerStatistics();
        if (cachedStats != null) {
          return ApiResponse<CustomerStatisticsResponse>(success: true, message: 'Showing cached statistics', data: cachedStats);
        }
      }

      return ApiResponse<CustomerStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get customer statistics error: ${e.toString()}');
      return ApiResponse<CustomerStatisticsResponse>(success: false, message: 'An unexpected error occurred while getting customer statistics');
    }
  }

  /// Update customer contact information
  Future<ApiResponse<CustomerModel>> updateCustomerContact({
    required String id,
    required String phone,
    required String email,
    String? address,
    String? city,
    String? country,
  }) async {
    try {
      final request = CustomerContactUpdateRequest(phone: phone, email: email, address: address, city: city, country: country);

      final response = await _apiClient.put(ApiConfig.updateCustomerContact(id), data: request.toJson());

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<CustomerModel>.fromJson(response.data, (data) => CustomerModel.fromJson(data));

        // Update cache with updated customer
        if (apiResponse.success && apiResponse.data != null) {
          await _updateCustomerInCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CustomerModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update customer contact',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update customer contact DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomerModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Update customer contact error: ${e.toString()}');
      return ApiResponse<CustomerModel>(success: false, message: 'An unexpected error occurred while updating customer contact');
    }
  }

  /// Verify customer contact (phone or email)
  Future<ApiResponse<void>> verifyCustomerContact({
    required String id,
    required String verificationType, // 'phone' or 'email'
    bool verified = true,
  }) async {
    try {
      final request = CustomerVerificationRequest(verificationType: verificationType, verified: verified);

      final response = await _apiClient.post(ApiConfig.verifyCustomerContact(id), data: request.toJson());

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: response.data['message'] ?? 'Customer contact verified successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to verify customer contact',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Verify customer contact DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Verify customer contact error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while verifying customer contact');
    }
  }

  /// Update customer activity (last order/contact date)
  Future<ApiResponse<void>> updateCustomerActivity({
    required String id,
    required String activityType, // 'order' or 'contact'
    String? activityDate, // ISO format datetime string
  }) async {
    try {
      final request = CustomerActivityUpdateRequest(activityType: activityType, activityDate: activityDate);

      final response = await _apiClient.post(ApiConfig.updateCustomerActivity(id), data: request.toJson());

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: response.data['message'] ?? 'Customer activity updated successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to update customer activity',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update customer activity DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Update customer activity error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while updating customer activity');
    }
  }

  /// Bulk customer actions
  Future<ApiResponse<Map<String, dynamic>>> bulkCustomerActions({required List<String> customerIds, required String action}) async {
    try {
      final request = CustomerBulkActionRequest(customerIds: customerIds, action: action);

      final response = await _apiClient.post(ApiConfig.bulkCustomerActions, data: request.toJson());

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
      debugPrint('Bulk customer actions DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Bulk customer actions error: ${e.toString()}');
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while performing bulk action');
    }
  }

  /// Duplicate customer
  Future<ApiResponse<CustomerModel>> duplicateCustomer({required String id, required String name, required String phone, String? email}) async {
    try {
      final request = CustomerDuplicateRequest(name: name, phone: phone, email: email);

      final response = await _apiClient.post(ApiConfig.duplicateCustomer(id), data: request.toJson());

      if (response.statusCode == 201) {
        final apiResponse = ApiResponse<CustomerModel>.fromJson(response.data, (data) => CustomerModel.fromJson(data));

        // Update cache with new customer
        if (apiResponse.success && apiResponse.data != null) {
          await _addCustomerToCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CustomerModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to duplicate customer',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Duplicate customer DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomerModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Duplicate customer error: ${e.toString()}');
      return ApiResponse<CustomerModel>(success: false, message: 'An unexpected error occurred while duplicating customer');
    }
  }

  // Cache management methods
  Future<void> _cacheCustomers(List<CustomerModel> customers) async {
    try {
      final customersJson = customers.map((customer) => customer.toJson()).toList();
      await _storageService.saveData(ApiConfig.customersCacheKey, customersJson);
    } catch (e) {
      debugPrint('Error caching customers: $e');
    }
  }

  /// Get cached customers from local storage
  Future<List<CustomerModel>> getCachedCustomers() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.customersCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => CustomerModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached customers: $e');
    }
    return [];
  }

  Future<void> _addCustomerToCache(CustomerModel customer) async {
    try {
      final cachedCustomers = await getCachedCustomers();
      cachedCustomers.add(customer);
      await _cacheCustomers(cachedCustomers);
    } catch (e) {
      debugPrint('Error adding customer to cache: $e');
    }
  }

  Future<void> _updateCustomerInCache(CustomerModel updatedCustomer) async {
    try {
      final cachedCustomers = await getCachedCustomers();
      final index = cachedCustomers.indexWhere((customer) => customer.id == updatedCustomer.id);
      if (index != -1) {
        cachedCustomers[index] = updatedCustomer;
        await _cacheCustomers(cachedCustomers);
      }
    } catch (e) {
      debugPrint('Error updating customer in cache: $e');
    }
  }

  Future<void> _removeCustomerFromCache(String customerId) async {
    try {
      final cachedCustomers = await getCachedCustomers();
      cachedCustomers.removeWhere((customer) => customer.id == customerId);
      await _cacheCustomers(cachedCustomers);
    } catch (e) {
      debugPrint('Error removing customer from cache: $e');
    }
  }

  Future<void> _cacheCustomerStatistics(CustomerStatisticsResponse statistics) async {
    try {
      await _storageService.saveData(ApiConfig.customerStatsCacheKey, statistics.toJson());
    } catch (e) {
      debugPrint('Error caching customer statistics: $e');
    }
  }

  Future<CustomerStatisticsResponse?> _getCachedCustomerStatistics() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.customerStatsCacheKey);
      if (cachedData != null) {
        return CustomerStatisticsResponse.fromJson(cachedData as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error getting cached customer statistics: $e');
    }
    return null;
  }

  /// Clear customers cache
  Future<void> clearCache() async {
    try {
      await _storageService.removeData(ApiConfig.customersCacheKey);
      await _storageService.removeData(ApiConfig.customerStatsCacheKey);
    } catch (e) {
      debugPrint('Error clearing customers cache: $e');
    }
  }

  /// Get cached customers count
  Future<int> getCachedCustomersCount() async {
    final cachedCustomers = await getCachedCustomers();
    return cachedCustomers.length;
  }

  /// Check if customers are cached
  Future<bool> hasCachedCustomers() async {
    final count = await getCachedCustomersCount();
    return count > 0;
  }

  /// Check if customer statistics are cached
  Future<bool> hasCachedStatistics() async {
    final stats = await _getCachedCustomerStatistics();
    return stats != null;
  }

  /// Get customers by type
  Future<ApiResponse<CustomersListResponse>> getCustomersByType({required String type, int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.customersByType(type), queryParameters: queryParams);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customers by type',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customers by type DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get customers by type error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting customers by type');
    }
  }

  /// Get customers by city
  Future<ApiResponse<CustomersListResponse>> getCustomersByCity({required String city, int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.customersByCity(city), queryParameters: queryParams);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customers by city',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customers by city DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get customers by city error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting customers by city');
    }
  }

  /// Get customers by country
  Future<ApiResponse<CustomersListResponse>> getCustomersByCountry({required String country, int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.customersByCountry(country), queryParameters: queryParams);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customers by country',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customers by country DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get customers by country error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting customers by country');
    }
  }

  /// Get Pakistani customers
  Future<ApiResponse<CustomersListResponse>> getPakistaniCustomers({int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.pakistaniCustomers, queryParameters: queryParams);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get Pakistani customers',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get Pakistani customers DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get Pakistani customers error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting Pakistani customers');
    }
  }

  /// Get international customers
  Future<ApiResponse<CustomersListResponse>> getInternationalCustomers({int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.internationalCustomers, queryParameters: queryParams);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get international customers',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get international customers DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get international customers error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting international customers');
    }
  }

  /// Get new customers
  Future<ApiResponse<CustomersListResponse>> getNewCustomers({int days = 30, int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'days': days.toString(), 'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.newCustomers, queryParameters: queryParams);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get new customers',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get new customers DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get new customers error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting new customers');
    }
  }

  /// Get recent customers
  Future<ApiResponse<CustomersListResponse>> getRecentCustomers({int days = 7, int page = 1, int pageSize = 20}) async {
    try {
      final queryParams = {'days': days.toString(), 'page': page.toString(), 'page_size': pageSize.toString()};

      final response = await _apiClient.get(ApiConfig.recentCustomers, queryParameters: queryParams);

      if (response.statusCode == 200) {
        return ApiResponse<CustomersListResponse>.fromJson(response.data, (data) => CustomersListResponse.fromJson(data));
      } else {
        return ApiResponse<CustomersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get recent customers',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get recent customers DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CustomersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get recent customers error: ${e.toString()}');
      return ApiResponse<CustomersListResponse>(success: false, message: 'An unexpected error occurred while getting recent customers');
    }
  }

  /// Quick customer lookup by phone or name (for POS)
  Future<ApiResponse<List<CustomerModel>>> quickCustomerLookup({required String query, int limit = 10, bool includeInactive = false}) async {
    try {
      final queryParams = {'query': query, 'limit': limit.toString(), 'include_inactive': includeInactive.toString(), 'quick_lookup': 'true'};

      DebugHelper.printApiResponse('GET Quick Customer Lookup', queryParams);

      final response = await _apiClient.get(ApiConfig.quickCustomerLookup, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Quick Customer Lookup Response', response.data);

      if (response.statusCode == 200) {
        final customers = (response.data['data'] as List?)?.map((json) => CustomerModel.fromJson(json as Map<String, dynamic>)).toList() ?? [];

        return ApiResponse<List<CustomerModel>>(
          success: true,
          data: customers,
          message: response.data['message'] ?? 'Customer lookup completed successfully',
        );
      } else {
        return ApiResponse<List<CustomerModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to perform customer lookup',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Quick customer lookup DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<CustomerModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Quick customer lookup', e);
      return ApiResponse<List<CustomerModel>>(success: false, message: 'An unexpected error occurred during customer lookup');
    }
  }

  /// Get customer history (orders, sales, payments)
  Future<ApiResponse<Map<String, dynamic>>> getCustomerHistory({
    required String customerId,
    String? historyType, // 'all', 'orders', 'sales', 'payments'
    int limit = 50,
  }) async {
    try {
      final queryParams = {'history_type': historyType ?? 'all', 'limit': limit.toString()};

      DebugHelper.printApiResponse('GET Customer History', {'customer_id': customerId, ...queryParams});

      final response = await _apiClient.get(ApiConfig.getCustomerHistory(customerId), queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Customer History Response', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'] as Map<String, dynamic>? ?? {},
          message: response.data['message'] ?? 'Customer history retrieved successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customer history',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Get customer history DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get customer history', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting customer history');
    }
  }

  /// Get customer summary (quick stats for POS)
  Future<ApiResponse<Map<String, dynamic>>> getCustomerSummary(String customerId) async {
    try {
      DebugHelper.printApiResponse('GET Customer Summary', {'customer_id': customerId});

      final response = await _apiClient.get(ApiConfig.getCustomerSummary(customerId));

      DebugHelper.printApiResponse('GET Customer Summary Response', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'] as Map<String, dynamic>? ?? {},
          message: response.data['message'] ?? 'Customer summary retrieved successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customer summary',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Get customer summary DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get customer summary', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting customer summary');
    }
  }

  /// Search customers with advanced filters (for POS)
  Future<ApiResponse<List<CustomerModel>>> searchCustomersAdvanced({
    String? query,
    String? phone,
    String? email,
    String? city,
    String? customerType,
    String? status,
    bool? hasRecentActivity,
    int? minOrderCount,
    double? minTotalSpent,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (query != null && query.isNotEmpty) queryParams['query'] = query;
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;
      if (email != null && email.isNotEmpty) queryParams['email'] = email;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (customerType != null && customerType.isNotEmpty) queryParams['customer_type'] = customerType;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (hasRecentActivity != null) queryParams['has_recent_activity'] = hasRecentActivity.toString();
      if (minOrderCount != null) queryParams['min_order_count'] = minOrderCount.toString();
      if (minTotalSpent != null) queryParams['min_total_spent'] = minTotalSpent.toString();

      queryParams['limit'] = limit.toString();

      DebugHelper.printApiResponse('GET Advanced Customer Search', queryParams);

      final response = await _apiClient.get(ApiConfig.searchCustomersAdvanced, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Advanced Customer Search Response', response.data);

      if (response.statusCode == 200) {
        final customers = (response.data['data'] as List?)?.map((json) => CustomerModel.fromJson(json as Map<String, dynamic>)).toList() ?? [];

        return ApiResponse<List<CustomerModel>>(
          success: true,
          data: customers,
          message: response.data['message'] ?? 'Advanced customer search completed successfully',
        );
      } else {
        return ApiResponse<List<CustomerModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to perform advanced customer search',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Advanced customer search DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<CustomerModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Advanced customer search', e);
      return ApiResponse<List<CustomerModel>>(success: false, message: 'An unexpected error occurred during advanced customer search');
    }
  }
}