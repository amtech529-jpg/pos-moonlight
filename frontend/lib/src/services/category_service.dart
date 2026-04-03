import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/category/category_api_responses.dart';
import '../models/category/category_model.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart'; // Add this import
import 'api_client.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of categories with pagination and filtering
  Future<ApiResponse<CategoriesListResponse>> getCategories({
    CategoryListParams? params,
  }) async {
    try {
      final queryParams = params?.toQueryParameters() ?? CategoryListParams().toQueryParameters();

      final response = await _apiClient.get(
        ApiConfig.categories,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Categories', response.data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<CategoriesListResponse>.fromJson(
          response.data,
              (data) => CategoriesListResponse.fromJson(data),
        );

        // Cache categories if successful
        if (apiResponse.success && apiResponse.data != null) {
          await _cacheCategories(apiResponse.data!.categories);
        }

        return apiResponse;
      } else {
        return ApiResponse<CategoriesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get categories',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get categories DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedCategories = await _getCachedCategories();
        if (cachedCategories.isNotEmpty) {
          return ApiResponse<CategoriesListResponse>(
            success: true,
            message: 'Showing cached data',
            data: CategoriesListResponse(
              categories: cachedCategories,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedCategories.length,
                totalCount: cachedCategories.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<CategoriesListResponse>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Get categories', e);
      return ApiResponse<CategoriesListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting categories',
      );
    }
  }

  /// Get a specific category by ID
  Future<ApiResponse<CategoryModel>> getCategoryById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getCategoryById(id));

      if (response.statusCode == 200) {
        return ApiResponse<CategoryModel>.fromJson(
          response.data,
              (data) => CategoryModel.fromJson(data),
        );
      } else {
        return ApiResponse<CategoryModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get category by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CategoryModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get category by ID error: ${e.toString()}');
      return ApiResponse<CategoryModel>(
        success: false,
        message: 'An unexpected error occurred while getting category',
      );
    }
  }

  /// Create a new category
  Future<ApiResponse<CategoryModel>> createCategory({
    required String name,
    required String description,
  }) async {
    try {
      final request = CategoryCreateRequest(
        name: name,
        description: description,
      );

      DebugHelper.printJson('Create Category Request', request.toJson());

      final response = await _apiClient.post(
        ApiConfig.createCategory,
        data: request.toJson(),
      );

      DebugHelper.printApiResponse('POST Create Category', response.data);

      if (response.statusCode == 201) {
        final apiResponse = ApiResponse<CategoryModel>.fromJson(
          response.data,
              (data) {
            DebugHelper.printCategoryModel('Category Data Before Parse', data);
            return CategoryModel.fromJson(data);
          },
        );

        // Update cache with new category
        if (apiResponse.success && apiResponse.data != null) {
          await _addCategoryToCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CategoryModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create category DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CategoryModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Create category', e);
      return ApiResponse<CategoryModel>(
        success: false,
        message: 'An unexpected error occurred while creating category: ${e.toString()}',
      );
    }
  }

  /// Update an existing category
  Future<ApiResponse<CategoryModel>> updateCategory({
    required String id,
    required String name,
    required String description,
  }) async {
    try {
      final request = CategoryUpdateRequest(
        name: name,
        description: description,
      );

      final response = await _apiClient.put(
        ApiConfig.updateCategory(id),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<CategoryModel>.fromJson(
          response.data,
              (data) => CategoryModel.fromJson(data),
        );

        // Update cache with updated category
        if (apiResponse.success && apiResponse.data != null) {
          await _updateCategoryInCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CategoryModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update category DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CategoryModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update category error: ${e.toString()}');
      return ApiResponse<CategoryModel>(
        success: false,
        message: 'An unexpected error occurred while updating category',
      );
    }
  }

  /// Delete a category permanently (hard delete)
  Future<ApiResponse<void>> deleteCategory(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteCategory(id));

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeCategoryFromCache(id);

        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Category deleted permanently',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete category DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Delete category error: ${e.toString()}');
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred while deleting category',
      );
    }
  }

  /// Soft delete a category (set is_active=False) - Alternative option
  Future<ApiResponse<void>> softDeleteCategory(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.softDeleteCategory(id));

      if (response.statusCode == 200) {
        // Update cache to mark as inactive
        final cachedCategories = await _getCachedCategories();
        final index = cachedCategories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          final updatedCategory = cachedCategories[index].copyWith(isActive: false);
          cachedCategories[index] = updatedCategory;
          await _cacheCategories(cachedCategories);
        }

        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Category soft deleted successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to soft delete category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Soft delete category DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Soft delete category error: ${e.toString()}');
      return ApiResponse<void>(
        success: false,
        message: 'An unexpected error occurred while soft deleting category',
      );
    }
  }

  /// Restore a soft-deleted category
  Future<ApiResponse<CategoryModel>> restoreCategory(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.restoreCategory(id));

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<CategoryModel>.fromJson(
          response.data,
              (data) => CategoryModel.fromJson(data),
        );

        // Update cache with restored category
        if (apiResponse.success && apiResponse.data != null) {
          await _updateCategoryInCache(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<CategoryModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Restore category DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<CategoryModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Restore category error: ${e.toString()}');
      return ApiResponse<CategoryModel>(
        success: false,
        message: 'An unexpected error occurred while restoring category',
      );
    }
  }

  /// Search categories with debouncing support
  Future<ApiResponse<CategoriesListResponse>> searchCategories({
    required String query,
    int page = 1,
    int pageSize = 20,
    bool showInactive = false,
  }) async {
    final params = CategoryListParams(
      page: page,
      pageSize: pageSize,
      search: query,
      showInactive: showInactive,
    );

    return await getCategories(params: params);
  }

  // Cache management methods
  Future<void> _cacheCategories(List<CategoryModel> categories) async {
    try {
      final categoriesJson = categories.map((category) => category.toJson()).toList();
      await _storageService.saveData(ApiConfig.categoriesCacheKey, categoriesJson);
    } catch (e) {
      debugPrint('Error caching categories: $e');
    }
  }

  Future<List<CategoryModel>> _getCachedCategories() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.categoriesCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting cached categories: $e');
    }
    return [];
  }

  Future<void> _addCategoryToCache(CategoryModel category) async {
    try {
      final cachedCategories = await _getCachedCategories();
      cachedCategories.add(category);
      await _cacheCategories(cachedCategories);
    } catch (e) {
      debugPrint('Error adding category to cache: $e');
    }
  }

  Future<void> _updateCategoryInCache(CategoryModel updatedCategory) async {
    try {
      final cachedCategories = await _getCachedCategories();
      final index = cachedCategories.indexWhere((cat) => cat.id == updatedCategory.id);
      if (index != -1) {
        cachedCategories[index] = updatedCategory;
        await _cacheCategories(cachedCategories);
      }
    } catch (e) {
      debugPrint('Error updating category in cache: $e');
    }
  }

  Future<void> _removeCategoryFromCache(String categoryId) async {
    try {
      final cachedCategories = await _getCachedCategories();
      cachedCategories.removeWhere((cat) => cat.id == categoryId);
      await _cacheCategories(cachedCategories);
    } catch (e) {
      debugPrint('Error removing category from cache: $e');
    }
  }

  /// Clear categories cache
  Future<void> clearCache() async {
    try {
      await _storageService.removeData(ApiConfig.categoriesCacheKey);
    } catch (e) {
      debugPrint('Error clearing categories cache: $e');
    }
  }

  /// Get cached categories count
  Future<int> getCachedCategoriesCount() async {
    final cachedCategories = await _getCachedCategories();
    return cachedCategories.length;
  }

  /// Check if categories are cached
  Future<bool> hasCachedCategories() async {
    final count = await getCachedCategoriesCount();
    return count > 0;
  }
}