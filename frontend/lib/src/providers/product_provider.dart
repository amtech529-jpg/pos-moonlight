import 'dart:async';

import 'package:flutter/material.dart';

import '../models/category/category_model.dart';
import '../models/product/product_model.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // =============================
  // STATE
  // =============================
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  ProductStatistics? _statistics;

  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasMore = false;

  ProductFilters _currentFilters = const ProductFilters();

  Timer? _searchTimer;
  bool _isDisposed = false;

  // =============================
  // GETTERS
  // =============================
  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  List<CategoryModel> get categories => _categories;
  ProductStatistics? get statistics => _statistics;

  bool get isLoading => _isLoading;
  bool get isLoadingStats => _isLoadingStats;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  ProductFilters get currentFilters => _currentFilters;

  // Available options for filters
  final List<String> availableColors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Pink',
    'Black',
    'White',
    'Brown',
    'Gray',
    'Navy',
    'Maroon',
    'Gold',
    'Silver',
    'Beige',
  ];

  final List<String> availableFabrics = [
    'Cotton',
    'Silk',
    'Chiffon',
    'Georgette',
    'Net',
    'Velvet',
    'Satin',
    'Organza',
    'Crepe',
    'Linen',
    'Jacquard',
    'Brocade',
    'Lawn',
    'Khaddar',
  ];

  // =============================
  // INITIALIZE
  // =============================
  Future<void> initialize() async {
    await Future.wait([loadCategories(), loadProducts(), loadStatistics()]);
  }

  // =============================
  // CATEGORIES
  // =============================
  Future<void> loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      if (response.success && response.data != null) {
        _categories = response.data!.categories;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      debugPrint('Category error: $e');
    }
  }

  // =============================
  // PRODUCTS
  // =============================
  Future<void> loadProducts({int page = 1, bool append = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.getProducts(
        page: page,
        pageSize: 20,
        filters: _currentFilters,
        showInactive: _currentFilters.showInactive ?? false,
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        if (append) {
          _products.addAll(data.products);
        } else {
          _products = data.products;
        }

        _currentPage = data.pagination.currentPage;
        _totalPages = data.pagination.totalPages;
        _totalCount = data.pagination.totalCount;
        _hasMore = data.pagination.hasNext;

        _applyLocalFilters();
      } else {
        _errorMessage = response.message ?? 'Failed to load products';
      }
    } catch (e) {
      _errorMessage = 'Load products failed';
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (_hasMore && !_isLoading) {
      await loadProducts(page: _currentPage + 1, append: true);
    }
  }

  // =============================
  // SEARCH
  // =============================
  void searchProducts(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _currentFilters = _currentFilters.copyWith(
      search: query.isEmpty ? null : query,
    );

    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      loadProducts(page: 1, append: false);
    });
  }

  // =============================
  // FILTER
  // =============================
  void applyFilters(ProductFilters filters) {
    _currentFilters = filters;
    _currentPage = 1;
    loadProducts(page: 1, append: false);
  }

  void clearFilters() {
    _currentFilters = const ProductFilters();
    _searchQuery = '';
    loadProducts(page: 1, append: false);
  }

  void _applyLocalFilters() {
    _filteredProducts = _products.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.detail.toLowerCase().contains(q) ||
          (p.color?.toLowerCase().contains(q) ?? false) ||
          (p.fabric?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (!_isDisposed) notifyListeners();
  }

  // =============================
  // ADD PRODUCT
  // =============================
  Future<ProductModel?> addProduct({
    required String name,
    required String detail,
    required double price,
    double? costPrice,
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
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.createProduct(
        name: name,
        detail: detail,
        price: price,
        costPrice: costPrice ?? 0.0,
        color: color,
        fabric: fabric,
        pieces: pieces,
        quantity: quantity,
        categoryId: categoryId,
        serialNumber: serialNumber,
        warehouseLocation: warehouseLocation,
        pricingType: pricingType,
        isRental: isRental,
        isConsumable: isConsumable,
        barcode: barcode,
        sku: sku,
        minStockThreshold: minStockThreshold,
      );

      if (response.success && response.data != null) {
        _products.insert(0, response.data!);
        _applyLocalFilters();
        await loadStatistics();
        return response.data;
      }

      _errorMessage = response.message ?? 'Add product failed';
      return null;
    } catch (e) {
      _errorMessage = 'Add product failed';
      return null;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // =============================
  // UPDATE PRODUCT
  // =============================
  Future<bool> updateProduct({
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
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.updateProduct(
        id: id,
        name: name,
        detail: detail,
        price: price,
        costPrice: costPrice,
        color: color,
        fabric: fabric,
        pieces: pieces,
        quantity: quantity,
        categoryId: categoryId,
        serialNumber: serialNumber,
        warehouseLocation: warehouseLocation,
        pricingType: pricingType,
        isRental: isRental,
        isConsumable: isConsumable,
        minStockThreshold: minStockThreshold,
      );

      if (response.success && response.data != null) {
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) _products[index] = response.data!;
        _applyLocalFilters();
        await loadStatistics();
        return true;
      }

      _errorMessage = response.message ?? 'Update failed';
      return false;
    } catch (e) {
      _errorMessage = 'Update failed';
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // =============================
  // DELETE PRODUCT
  // =============================
  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.deleteProduct(id);

      if (response.success) {
        _products.removeWhere((p) => p.id == id);
        _applyLocalFilters();
        await loadStatistics();
        return true;
      }

      _errorMessage = response.message ?? 'Delete failed';
      return false;
    } catch (e) {
      _errorMessage = 'Delete failed';
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> softDeleteProduct(String id) async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.softDeleteProduct(id);

      if (response.success) {
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          // Update local status or remove from active list
          _products.removeAt(index);
        }
        _applyLocalFilters();
        await loadStatistics();
        return true;
      }

      _errorMessage = response.message ?? 'Deactivation failed';
      return false;
    } catch (e) {
      _errorMessage = 'Deactivation failed';
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<bool> restoreProduct(String id) async {
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.restoreProduct(id);

      if (response.success && response.data != null) {
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = response.data!;
        } else {
          _products.insert(0, response.data!);
        }
        _applyLocalFilters();
        await loadStatistics();
        return true;
      }

      _errorMessage = response.message ?? 'Restore failed';
      return false;
    } catch (e) {
      _errorMessage = 'Restore failed';
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // =============================
  // AVAILABILITY CHECK
  // =============================
  Future<Map<String, dynamic>?> checkAvailability({
    required List<String> productIds,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeOrderId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.checkDateAvailability(
        productIds: productIds,
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
        excludeOrderId: excludeOrderId,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        if (data.containsKey('availability')) {
          final availabilityList = data['availability'] as List;
          final availabilityMap = <String, dynamic>{};
          for (var item in availabilityList) {
            availabilityMap[item['product_id']] = item;
          }
          return availabilityMap;
        }
        return data; // Fallback if format is different
      } else {
        _errorMessage = response.message;
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to check availability: $e';
      return null;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // =============================
  // STATISTICS
  // =============================
  Future<void> loadStatistics() async {
    _isLoadingStats = true;
    if (!_isDisposed) notifyListeners();

    try {
      final response = await _productService.getProductStatistics();
      if (response.success && response.data != null) {
        _statistics = response.data!;
      }
    } catch (e) {
      debugPrint('Statistics error: $e');
    } finally {
      _isLoadingStats = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  // =============================
  // DISPOSE
  // =============================
  @override
  void dispose() {
    _isDisposed = true;
    _searchTimer?.cancel();
    super.dispose();
  }
}
