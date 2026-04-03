import 'package:flutter/material.dart';
import '../models/category/category_api_responses.dart';
import '../models/category/category_model.dart';
import '../services/category_service.dart';

// Compatibility adapter to convert between CategoryModel and your existing Category class
class Category {
  final String id;
  final String name;
  final String description;
  final DateTime dateCreated;
  final DateTime lastEdited;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.dateCreated,
    required this.lastEdited,
  });

  // Convert from CategoryModel (API) to Category (UI)
  factory Category.fromCategoryModel(CategoryModel model) {
    return Category(
      id: model.id,
      name: model.name,
      description: model.description,
      dateCreated: model.createdAt,
      lastEdited: model.updatedAt,
    );
  }

  // Formatted date for display
  String get formattedDateCreated {
    return '${dateCreated.day.toString().padLeft(2, '0')}/${dateCreated.month.toString().padLeft(2, '0')}/${dateCreated.year}';
  }

  String get formattedLastEdited {
    return '${lastEdited.day.toString().padLeft(2, '0')}/${lastEdited.month.toString().padLeft(2, '0')}/${lastEdited.year}';
  }

  // Relative date (e.g., "Today", "Yesterday", "2 days ago")
  String get relativeDateCreated {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dateCreated.year, dateCreated.month, dateCreated.day);
    final difference = today.difference(recordDate).inDays;

    return _getRelativeDateString(difference);
  }

  String get relativeLastEdited {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(lastEdited.year, lastEdited.month, lastEdited.day);
    final difference = today.difference(recordDate).inDays;

    return _getRelativeDateString(difference);
  }

  String _getRelativeDateString(int difference) {
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? dateCreated,
    DateTime? lastEdited,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dateCreated: dateCreated ?? this.dateCreated,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dateCreated': dateCreated.toIso8601String(),
      'lastEdited': lastEdited.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dateCreated: DateTime.parse(json['dateCreated']),
      lastEdited: DateTime.parse(json['lastEdited']),
    );
  }
}

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasError = false;

  // Pagination
  PaginationInfo? _paginationInfo;
  int _currentPage = 1;
  int _pageSize = 20;
  bool _showInactive = false;

  // Additional properties
  String _sortBy = 'dateCreated'; // 'dateCreated', 'lastEdited', 'name', 'id'
  bool _sortAscending = false;

  // Getters
  List<Category> get categories => _filteredCategories;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  PaginationInfo? get paginationInfo => _paginationInfo;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get showInactive => _showInactive;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  CategoryProvider() {
    loadCategories();
  }

  /// Load categories from API
  Future<void> loadCategories({
    int? page,
    int? pageSize,
    String? search,
    bool? showInactive,
    bool showLoadingIndicator = true,
  }) async {
    if (showLoadingIndicator) {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final params = CategoryListParams(
        page: page ?? _currentPage,
        pageSize: pageSize ?? _pageSize,
        search: search ?? _searchQuery,
        showInactive: showInactive ?? _showInactive,
      );

      final response = await _categoryService.getCategories(params: params);

      if (response.success && response.data != null) {
        final categoriesData = response.data!;

        // Convert CategoryModel to Category for UI compatibility
        _categories = categoriesData.categories
            .map((categoryModel) => Category.fromCategoryModel(categoryModel))
            .toList();

        _filteredCategories = List.from(_categories);
        _paginationInfo = categoriesData.pagination;

        // Update pagination state
        _currentPage = params.page;
        _pageSize = params.pageSize;
        _searchQuery = params.search ?? '';
        _showInactive = params.showInactive;

        _sortCategories();
        _hasError = false;
        _errorMessage = null;
      } else {
        _hasError = true;
        _errorMessage = response.message;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load categories: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh categories (pull-to-refresh)
  Future<void> refreshCategories() async {
    _currentPage = 1; // Reset to first page
    await loadCategories(page: 1, showLoadingIndicator: false);
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_paginationInfo?.hasNext == true) {
      await loadCategories(page: _currentPage + 1, showLoadingIndicator: false);
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_paginationInfo?.hasPrevious == true) {
      await loadCategories(page: _currentPage - 1, showLoadingIndicator: false);
    }
  }

  /// Search categories
  Future<void> searchCategories(String query) async {
    _searchQuery = query.toLowerCase();
    _currentPage = 1; // Reset to first page when searching
    await loadCategories(search: _searchQuery, page: 1);
  }

  /// Clear search
  Future<void> clearSearch() async {
    _searchQuery = '';
    _currentPage = 1;
    await loadCategories(search: '', page: 1);
  }

  /// Toggle show inactive categories
  Future<void> toggleShowInactive() async {
    _showInactive = !_showInactive;
    _currentPage = 1;
    await loadCategories(showInactive: _showInactive, page: 1);
  }

  /// Sort categories
  void setSortBy(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      // Toggle if same field, otherwise default to descending for dates, ascending for text
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortAscending = (sortBy == 'name' || sortBy == 'id');
      }
    }
    _sortCategories();
    notifyListeners();
  }

  /// Apply sorting to current categories
  void _sortCategories() {
    _filteredCategories.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'id':
          comparison = a.id.compareTo(b.id);
          break;
        case 'lastEdited':
          comparison = a.lastEdited.compareTo(b.lastEdited);
          break;
        case 'dateCreated':
        default:
          comparison = a.dateCreated.compareTo(b.dateCreated);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  /// Add new category
  Future<bool> addCategory(String name, String description) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _categoryService.createCategory(
        name: name,
        description: description,
      );

      if (response.success && response.data != null) {
        // Add the new category to local list immediately
        final newCategory = Category.fromCategoryModel(response.data!);
        _categories.add(newCategory);
        _applyFilters();

        // Also refresh from server to ensure consistency
        await loadCategories(showLoadingIndicator: false);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to create category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing category
  Future<bool> updateCategory(String id, String name, String description) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _categoryService.updateCategory(
        id: id,
        name: name,
        description: description,
      );

      if (response.success && response.data != null) {
        // Update the category in local list
        final updatedCategory = Category.fromCategoryModel(response.data!);
        final index = _categories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          _categories[index] = updatedCategory;
          _applyFilters();
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to update category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete category permanently (hard delete)
  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _categoryService.deleteCategory(id);

      if (response.success) {
        // Remove category from local list permanently
        _categories.removeWhere((cat) => cat.id == id);
        _applyFilters();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to delete category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Soft delete category (set as inactive) - Alternative option
  Future<bool> softDeleteCategory(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _categoryService.softDeleteCategory(id);

      if (response.success) {
        // Update category in local list to mark as inactive
        final index = _categories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          // Since Category class doesn't have isActive, we'll remove it from the list
          // In a real implementation, you might want to add isActive to Category class
          _categories.removeAt(index);
          _applyFilters();
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to soft delete category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Restore category
  Future<bool> restoreCategory(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _categoryService.restoreCategory(id);

      if (response.success && response.data != null) {
        // Update the category in local list
        final restoredCategory = Category.fromCategoryModel(response.data!);
        final index = _categories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          _categories[index] = restoredCategory;
        } else {
          _categories.add(restoredCategory);
        }
        _applyFilters();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to restore category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get category by ID
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Apply search filters to local data
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      _filteredCategories = _categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery) ||
            category.description.toLowerCase().contains(_searchQuery) ||
            category.id.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    _sortCategories();
  }

  /// Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Enhanced statistics for dashboard
  Map<String, dynamic> get categoryStats {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    final totalCategories = _categories.length;

    final recentlyAdded = _categories.where((cat) =>
    DateTime.now().difference(cat.dateCreated).inDays <= 7
    ).length;

    final recentlyUpdated = _categories.where((cat) =>
    DateTime.now().difference(cat.lastEdited).inDays <= 3
    ).length;

    final thisYearCategories = _categories.where((cat) {
      return cat.dateCreated.year == currentYear;
    }).length;

    final thisMonthCategories = _categories.where((cat) {
      return cat.dateCreated.year == currentYear &&
          cat.dateCreated.month == currentMonth;
    }).length;

    // Most popular could be based on usage, for now using most recently updated
    final mostPopular = _categories.isEmpty
        ? 'N/A'
        : _categories
        .reduce((a, b) => a.lastEdited.isAfter(b.lastEdited) ? a : b)
        .name;

    return {
      'total': totalCategories,
      'recentlyAdded': recentlyAdded,
      'recentlyUpdated': recentlyUpdated,
      'mostPopular': mostPopular,
      'thisYear': thisYearCategories,
      'thisMonth': thisMonthCategories,
    };
  }

  /// Get categories by year
  List<Category> getCategoriesByYear(int year) {
    return _categories.where((cat) => cat.dateCreated.year == year).toList();
  }

  /// Get categories by month
  List<Category> getCategoriesByMonth(int year, int month) {
    return _categories
        .where((cat) =>
    cat.dateCreated.year == year && cat.dateCreated.month == month)
        .toList();
  }

  /// Get recently updated categories
  List<Category> getRecentlyUpdated({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _categories
        .where((cat) => cat.lastEdited.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
  }

  /// Get recently created categories
  List<Category> getRecentlyCreated({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _categories
        .where((cat) => cat.dateCreated.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
  }

  /// Export data (placeholder for future implementation)
  Future<void> exportData() async {
    // Implementation for exporting category data
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Clear all categories cache
  Future<void> clearCache() async {
    await _categoryService.clearCache();
  }

  /// Check if has cached data
  Future<bool> hasCachedData() async {
    return await _categoryService.hasCachedCategories();
  }

  /// Bulk operations
  Future<bool> deleteMultipleCategories(List<String> ids) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool allSuccess = true;
      for (String id in ids) {
        final response = await _categoryService.deleteCategory(id);
        if (!response.success) {
          allSuccess = false;
          _errorMessage = response.message;
        }
      }

      if (allSuccess) {
        // Remove categories from local list
        _categories.removeWhere((cat) => ids.contains(cat.id));
        _applyFilters();
      }

      _isLoading = false;
      notifyListeners();
      return allSuccess;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to delete categories: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Duplicate category
  Future<bool> duplicateCategory(String id) async {
    final originalCategory = getCategoryById(id);
    if (originalCategory == null) return false;

    return await addCategory(
      '${originalCategory.name} (Copy)',
      originalCategory.description,
    );
  }

  /// Set page size
  Future<void> setPageSize(int pageSize) async {
    if (_pageSize != pageSize) {
      _pageSize = pageSize;
      _currentPage = 1; // Reset to first page
      await loadCategories(pageSize: _pageSize, page: 1);
    }
  }
}