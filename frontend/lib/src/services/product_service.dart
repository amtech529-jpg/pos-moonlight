import 'dart:core';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/product/product_model.dart';
import '../utils/debug_helper.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();

  factory ProductService() => _instance;

  ProductService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of products with pagination and filtering - FIXED
  Future<ApiResponse<ProductsListResponse>> getProducts({
    int page = 1,
    int pageSize = 20,
    ProductFilters? filters,
    bool showInactive = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'show_inactive': showInactive.toString(),
      };

      // Add filters if provided
      if (filters != null) {
        queryParams.addAll(filters.toQueryParameters());
      }

      final response = await _apiClient.get(
        ApiConfig.products,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Products', response.data);

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] instead of response.data
        final ProductsListResponse productsResponse =
            ProductsListResponse.fromJson(response.data['data']);

        final apiResponse = ApiResponse<ProductsListResponse>(
          success: true,
          message: 'Products loaded successfully',
          data: productsResponse,
        );

        // Cache products if successful
        if (apiResponse.data != null) {
          await _cacheProducts(apiResponse.data!.products);
        }

        return apiResponse;
      } else {
        return ApiResponse<ProductsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get products',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get products DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedProducts = await _getCachedProducts();
        if (cachedProducts.isNotEmpty) {
          return ApiResponse<ProductsListResponse>(
            success: true,
            message: 'Showing cached data',
            data: ProductsListResponse(
              products: cachedProducts,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedProducts.length,
                totalCount: cachedProducts.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<ProductsListResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Get products', e);
      return ApiResponse<ProductsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting products',
      );
    }
  }

  /// Get a specific product by ID - FIXED
  Future<ApiResponse<ProductModel>> getProductById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getProductById(id));

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] or response.data['product']
        final ProductModel product = ProductModel.fromJson(
          response.data['data'] ?? response.data['product'],
        );

        return ApiResponse<ProductModel>(
          success: true,
          message: 'Product loaded successfully',
          data: product,
        );
      } else {
        return ApiResponse<ProductModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get product',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get product by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProductModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('Get product by ID error: ${e.toString()}');
      return ApiResponse<ProductModel>(
        success: false,
        message: 'An unexpected error occurred while getting product',
      );
    }
  }

  /// Create a new product - FIXED
  Future<ApiResponse<ProductModel>> createProduct({
    required String name,
    required String detail,
    required double price,
    required double costPrice,
    String? color,
    String? fabric,
    List<String>? pieces,
    required int quantity,
    required String categoryId,
    String? serialNumber,
    String? warehouseLocation,
    String? pricingType,
    bool? isRental,
    bool? isConsumable,
    String? barcode,
    String? sku,
    int? minStockThreshold,
  }) async {
    try {
      final request = ProductCreateRequest(
        name: name,
        detail: detail,
        price: price,
        costPrice: costPrice,
        color: color,
        fabric: fabric,
        pieces: pieces,
        quantity: quantity,
        category: categoryId,
        serialNumber: serialNumber,
        warehouseLocation: warehouseLocation,
        pricingType: pricingType,
        isRental: isRental,
        isConsumable: isConsumable,
        barcode: barcode,
        sku: sku,
        minStockThreshold: minStockThreshold,
      );

      final response = await _apiClient.post(
        ApiConfig.createProduct,
        data: request.toJson(),
      );

      DebugHelper.printApiResponse('POST Create Product', response.data);

      if (response.statusCode == 201) {
        // FIXED: Parse from response.data['data'] or response.data['product']
        final ProductModel product = ProductModel.fromJson(
          response.data['data'] ?? response.data['product'],
        );

        final apiResponse = ApiResponse<ProductModel>(
          success: true,
          message: response.data['message'] ?? 'Product created successfully',
          data: product,
        );

        // Update cache with new product
        if (apiResponse.data != null) {
          await _addProductToCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<ProductModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create product',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create product DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProductModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Create product', e);
      return ApiResponse<ProductModel>(
        success: false,
        message:
            'An unexpected error occurred while creating product: ${e.toString()}',
      );
    }
  }

  /// Update an existing product - FIXED
  Future<ApiResponse<ProductModel>> updateProduct({
    required String id,
    String? name,
    String? detail,
    double? price,
    double? costPrice,
    String? color,
    String? fabric,
    List<String>? pieces,
    int? quantity,
    String? categoryId,
    String? serialNumber,
    String? warehouseLocation,
    String? pricingType,
    bool? isRental,
    bool? isConsumable,
    int? minStockThreshold,
  }) async {
    try {
      final request = ProductUpdateRequest(
        name: name,
        detail: detail,
        price: price,
        costPrice: costPrice,
        color: color,
        fabric: fabric,
        pieces: pieces ?? [], // ✅ pass the list or empty list

        quantity: quantity,
        category: categoryId,
        serialNumber: serialNumber,
        warehouseLocation: warehouseLocation,
        pricingType: pricingType,
        isRental: isRental,
        isConsumable: isConsumable,
        minStockThreshold: minStockThreshold,
      );

      final response = await _apiClient.put(
        ApiConfig.updateProduct(id),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] or response.data['product']
        final ProductModel product = ProductModel.fromJson(
          response.data['data'] ?? response.data['product'],
        );

        final apiResponse = ApiResponse<ProductModel>(
          success: true,
          message: response.data['message'] ?? 'Product updated successfully',
          data: product,
        );

        // Update cache with updated product
        if (apiResponse.data != null) {
          await _updateProductInCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<ProductModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update product',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update product DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProductModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update product error: ${e.toString()}');
      return ApiResponse<ProductModel>(
        success: false,
        message: 'An unexpected error occurred while updating product',
      );
    }
  }

  /// Delete a product permanently (hard delete)
  Future<ApiResponse<void>> deleteProduct(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteProduct(id));

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeProductFromCache(id);

        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Product deleted permanently',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete product',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete product DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Delete product error: ${e.toString()}');
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred while deleting product',
      );
    }
  }

  /// Soft delete a product (deactivate)
  Future<ApiResponse<void>> softDeleteProduct(String id) async {
    try {
      final response = await _apiClient.patch(ApiConfig.softDeleteProduct(id));

      if (response.statusCode == 200) {
        // Remove from cache since it's now inactive
        await _removeProductFromCache(id);

        return ApiResponse<void>(
          success: true,
          message:
              response.data['message'] ?? 'Product deactivated successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to deactivate product',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Soft delete product DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Soft delete product error: ${e.toString()}');
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred while deactivating product',
      );
    }
  }

  /// Restore a soft deleted product - FIXED
  Future<ApiResponse<ProductModel>> restoreProduct(String id) async {
    try {
      final response = await _apiClient.patch(ApiConfig.restoreProduct(id));

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] or response.data['product']
        final ProductModel product = ProductModel.fromJson(
          response.data['data'] ?? response.data['product'],
        );

        final apiResponse = ApiResponse<ProductModel>(
          success: true,
          message: response.data['message'] ?? 'Product restored successfully',
          data: product,
        );

        // Add restored product back to cache
        if (apiResponse.data != null) {
          await _addProductToCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<ProductModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore product',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Restore product DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProductModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Restore product error: ${e.toString()}');
      return ApiResponse<ProductModel>(
        success: false,
        message: 'An unexpected error occurred while restoring product',
      );
    }
  }

  /// Search products - FIXED
  Future<ApiResponse<ProductsListResponse>> searchProducts({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.searchProducts,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] instead of response.data
        final ProductsListResponse productsResponse =
            ProductsListResponse.fromJson(response.data['data']);

        return ApiResponse<ProductsListResponse>(
          success: true,
          message: 'Search completed successfully',
          data: productsResponse,
        );
      } else {
        return ApiResponse<ProductsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to search products',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search products DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProductsListResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Search products error: ${e.toString()}');
      return ApiResponse<ProductsListResponse>(
        success: false,
        message: 'An unexpected error occurred while searching products',
      );
    }
  }

  /// Get products by category - FIXED
  Future<ApiResponse<ProductsListResponse>> getProductsByCategory({
    required String categoryId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.productsByCategory(categoryId),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] instead of response.data
        final ProductsListResponse productsResponse =
            ProductsListResponse.fromJson(response.data['data']);

        return ApiResponse<ProductsListResponse>(
          success: true,
          message: 'Products loaded successfully',
          data: productsResponse,
        );
      } else {
        return ApiResponse<ProductsListResponse>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to get products by category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get products by category DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProductsListResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get products by category error: ${e.toString()}');
      return ApiResponse<ProductsListResponse>(
        success: false,
        message:
            'An unexpected error occurred while getting products by category',
      );
    }
  }

  /// Get low stock products - FIXED
  Future<ApiResponse<ProductsListResponse>> getLowStockProducts({
    int threshold = 5,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'threshold': threshold.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.lowStockProducts,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] instead of response.data
        final ProductsListResponse productsResponse =
            ProductsListResponse.fromJson(response.data['data']);

        return ApiResponse<ProductsListResponse>(
          success: true,
          message: 'Low stock products loaded successfully',
          data: productsResponse,
        );
      } else {
        return ApiResponse<ProductsListResponse>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to get low stock products',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get low stock products DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProductsListResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get low stock products error: ${e.toString()}');
      return ApiResponse<ProductsListResponse>(
        success: false,
        message:
            'An unexpected error occurred while getting low stock products',
      );
    }

  }

  /// Check product availability for a date range
  Future<ApiResponse<Map<String, dynamic>>> checkDateAvailability({
    required List<String> productIds,
    required String startDate,
    required String endDate,
    String? excludeOrderId,
  }) async {
    try {
      final data = {
        'product_ids': productIds,
        'start_date': startDate,
        'end_date': endDate,
        'exclude_order_id': excludeOrderId,
      };

      final response = await _apiClient.post(
        ApiConfig.checkDateAvailability,
        data: data,
      );

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Availability checked successfully',
          data: response.data['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to check availability',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Check date availability DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Check date availability error: ${e.toString()}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred while checking availability',
      );
    }
  }

  /// Get product statistics - FIXED
  Future<ApiResponse<ProductStatistics>> getProductStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.productStatistics);

      if (response.statusCode == 200) {
        // FIXED: Parse from response.data['data'] instead of response.data
        final ProductStatistics statistics = ProductStatistics.fromJson(
          response.data['data'],
        );

        final apiResponse = ApiResponse<ProductStatistics>(
          success: true,
          message: 'Statistics loaded successfully',
          data: statistics,
        );

        // Cache statistics
        if (apiResponse.data != null) {
          await _cacheProductStats(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<ProductStatistics>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to get product statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get product statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedStats = await _getCachedProductStats();
        if (cachedStats != null) {
          return ApiResponse<ProductStatistics>(
            success: true,
            message: 'Showing cached data',
            data: cachedStats,
          );
        }
      }

      return ApiResponse<ProductStatistics>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get product statistics error: ${e.toString()}');
      return ApiResponse<ProductStatistics>(
        success: false,
        message:
            'An unexpected error occurred while getting product statistics',
      );
    }
  }

  /// Update product quantity
  Future<ApiResponse<Map<String, dynamic>>> updateProductQuantity({
    required String productId,
    required int newQuantity,
  }) async {
    try {
      final data = {'quantity': newQuantity};

      final response = await _apiClient.post(
        ApiConfig.updateProductQuantity(productId),
        data: data,
      );

      if (response.statusCode == 200) {
        // Update cache
        await _updateProductQuantityInCache(productId, newQuantity);

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Quantity updated successfully',
          data: response.data['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to update quantity',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update product quantity DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update product quantity error: ${e.toString()}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred while updating quantity',
      );
    }
  }

  // Cache management methods
  Future<void> _cacheProducts(List<ProductModel> products) async {
    try {
      final productsJson = products.map((product) => product.toJson()).toList();
      await _storageService.saveData(ApiConfig.productsCacheKey, productsJson);
    } catch (e) {
      debugPrint('Error caching products: $e');
    }
  }

  Future<List<ProductModel>> _getCachedProducts() async {
    try {
      final cachedData = await _storageService.getData(
        ApiConfig.productsCacheKey,
      );
      if (cachedData != null && cachedData is List) {
        return cachedData
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting cached products: $e');
    }
    return [];
  }

  Future<void> _addProductToCache(ProductModel product) async {
    try {
      final cachedProducts = await _getCachedProducts();
      cachedProducts.add(product);
      await _cacheProducts(cachedProducts);
    } catch (e) {
      debugPrint('Error adding product to cache: $e');
    }
  }

  Future<void> _updateProductInCache(ProductModel updatedProduct) async {
    try {
      final cachedProducts = await _getCachedProducts();
      final index = cachedProducts.indexWhere(
        (product) => product.id == updatedProduct.id,
      );
      if (index != -1) {
        cachedProducts[index] = updatedProduct;
        await _cacheProducts(cachedProducts);
      }
    } catch (e) {
      debugPrint('Error updating product in cache: $e');
    }
  }

  Future<void> _removeProductFromCache(String productId) async {
    try {
      final cachedProducts = await _getCachedProducts();
      cachedProducts.removeWhere((product) => product.id == productId);
      await _cacheProducts(cachedProducts);
    } catch (e) {
      debugPrint('Error removing product from cache: $e');
    }
  }

  Future<void> _updateProductQuantityInCache(
    String productId,
    int newQuantity,
  ) async {
    try {
      final cachedProducts = await _getCachedProducts();
      final index = cachedProducts.indexWhere(
        (product) => product.id == productId,
      );
      if (index != -1) {
        final updatedProduct = cachedProducts[index].copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );
        cachedProducts[index] = updatedProduct;
        await _cacheProducts(cachedProducts);
      }
    } catch (e) {
      debugPrint('Error updating product quantity in cache: $e');
    }
  }

  Future<void> _cacheProductStats(ProductStatistics stats) async {
    try {
      await _storageService.saveData(
        ApiConfig.productStatsCacheKey,
        stats.toJson(),
      );
    } catch (e) {
      debugPrint('Error caching product stats: $e');
    }
  }

  Future<ProductStatistics?> _getCachedProductStats() async {
    try {
      final cachedData = await _storageService.getData(
        ApiConfig.productStatsCacheKey,
      );
      if (cachedData != null && cachedData is Map<String, dynamic>) {
        return ProductStatistics.fromJson(cachedData);
      }
    } catch (e) {
      debugPrint('Error getting cached product stats: $e');
    }
    return null;
  }

  /// Clear products cache
  Future<void> clearCache() async {
    try {
      await _storageService.removeData(ApiConfig.productsCacheKey);
      await _storageService.removeData(ApiConfig.productStatsCacheKey);
    } catch (e) {
      debugPrint('Error clearing products cache: $e');
    }
  }

  /// Get cached products count
  Future<int> getCachedProductsCount() async {
    final cachedProducts = await _getCachedProducts();
    return cachedProducts.length;
  }

  /// Check if products are cached
  Future<bool> hasCachedProducts() async {
    final count = await getCachedProductsCount();
    return count > 0;
  }
}
