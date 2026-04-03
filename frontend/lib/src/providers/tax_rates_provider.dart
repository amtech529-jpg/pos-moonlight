import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/sales/sale_model.dart';
import '../services/tax_rates_service.dart';
import '../utils/debug_helper.dart';

class TaxRatesProvider extends ChangeNotifier {
  final TaxRatesService _taxRatesService = TaxRatesService();

  // State variables
  List<TaxRateModel> _taxRates = [];
  TaxRateModel? _selectedTaxRate;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 1;
  bool _hasNext = false;
  bool _hasPrevious = false;

  // Filters
  String? _taxTypeFilter;
  bool? _isActiveFilter;
  String? _searchQuery;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  // Active tax rates for quick access
  List<TaxRateModel> _activeTaxRates = [];
  TaxConfiguration? _defaultTaxConfiguration;

  // Getters
  List<TaxRateModel> get taxRates => _taxRates;
  TaxRateModel? get selectedTaxRate => _selectedTaxRate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Pagination getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  bool get hasNext => _hasNext;
  bool get hasPrevious => _hasPrevious;

  // Filter getters
  String? get taxTypeFilter => _taxTypeFilter;
  bool? get isActiveFilter => _isActiveFilter;
  String? get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  // Active tax rates getters
  List<TaxRateModel> get activeTaxRates => _activeTaxRates;
  TaxConfiguration? get defaultTaxConfiguration => _defaultTaxConfiguration;

  // Computed getters
  bool get hasTaxRates => _taxRates.isNotEmpty;
  int get taxRatesCount => _taxRates.length;
  bool get hasActiveTaxRates => _activeTaxRates.isNotEmpty;
  int get activeTaxRatesCount => _activeTaxRates.length;

  /// Load tax rates with current filters and pagination
  Future<void> loadTaxRates({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _taxRates.clear();
    }

    if (_isLoading) return;

    _setLoading(true);
    _clearMessages();

    try {
      final params = TaxRatesListParams(
        page: _currentPage,
        pageSize: _pageSize,
        taxType: _taxTypeFilter,
        isActive: _isActiveFilter,
        search: _searchQuery,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final response = await _taxRatesService.getTaxRates(params: params);

      if (response.success && response.data != null) {
        if (refresh) {
          _taxRates = response.data!.taxRates;
        } else {
          _taxRates.addAll(response.data!.taxRates);
        }

        _updatePagination(response.data!.pagination);
        _setSuccessMessage('Tax rates loaded successfully');
      } else {
        _setErrorMessage(response.message ?? 'Failed to load tax rates');
      }
    } catch (e) {
      DebugHelper.printError('Load tax rates', e);
      _setErrorMessage('An unexpected error occurred while loading tax rates');
    } finally {
      _setLoading(false);
    }
  }

  /// Load active tax rates
  Future<void> loadActiveTaxRates() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _taxRatesService.getActiveTaxRates();

      if (response.success && response.data != null) {
        _activeTaxRates = response.data!;
        _setSuccessMessage('Active tax rates loaded successfully');
      } else {
        _setErrorMessage(response.message ?? 'Failed to load active tax rates');
      }
    } catch (e) {
      DebugHelper.printError('Load active tax rates', e);
      _setErrorMessage('An unexpected error occurred while loading active tax rates');
    } finally {
      _setLoading(false);
    }
  }

  /// Load default tax configuration
  Future<void> loadDefaultTaxConfiguration() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _taxRatesService.getDefaultTaxConfiguration();

      if (response.success && response.data != null) {
        _defaultTaxConfiguration = response.data;
        _setSuccessMessage('Default tax configuration loaded successfully');
      } else {
        _setErrorMessage(response.message ?? 'Failed to load default tax configuration');
      }
    } catch (e) {
      DebugHelper.printError('Load default tax configuration', e);
      _setErrorMessage('An unexpected error occurred while loading default tax configuration');
    } finally {
      _setLoading(false);
    }
  }

  /// Load a specific tax rate by ID
  Future<void> loadTaxRateById(String id) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _taxRatesService.getTaxRateById(id);

      if (response.success && response.data != null) {
        _selectedTaxRate = response.data;
        _setSuccessMessage('Tax rate loaded successfully');
      } else {
        _setErrorMessage(response.message ?? 'Failed to load tax rate');
      }
    } catch (e) {
      DebugHelper.printError('Load tax rate by ID', e);
      _setErrorMessage('An unexpected error occurred while loading tax rate');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new tax rate
  Future<bool> createTaxRate(CreateTaxRateRequest request) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _taxRatesService.createTaxRate(request);

      if (response.success && response.data != null) {
        _taxRates.insert(0, response.data!);
        _totalCount++;

        // Update active tax rates if the new rate is active
        if (response.data!.isActive) {
          _activeTaxRates.add(response.data!);
        }

        _setSuccessMessage('Tax rate created successfully');
        return true;
      } else {
        _setErrorMessage(response.message ?? 'Failed to create tax rate');
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Create tax rate', e);
      _setErrorMessage('An unexpected error occurred while creating tax rate');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing tax rate
  Future<bool> updateTaxRate(String id, UpdateTaxRateRequest request) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _taxRatesService.updateTaxRate(id, request);

      if (response.success && response.data != null) {
        final index = _taxRates.indexWhere((taxRate) => taxRate.id == id);
        if (index != -1) {
          _taxRates[index] = response.data!;
        }

        if (_selectedTaxRate?.id == id) {
          _selectedTaxRate = response.data;
        }

        // Update active tax rates
        _updateActiveTaxRates();

        _setSuccessMessage('Tax rate updated successfully');
        return true;
      } else {
        _setErrorMessage(response.message ?? 'Failed to update tax rate');
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Update tax rate', e);
      _setErrorMessage('An unexpected error occurred while updating tax rate');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a tax rate
  Future<bool> deleteTaxRate(String id) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _taxRatesService.deleteTaxRate(id);

      if (response.success) {
        _taxRates.removeWhere((taxRate) => taxRate.id == id);
        _totalCount--;

        if (_selectedTaxRate?.id == id) {
          _selectedTaxRate = null;
        }

        // Update active tax rates
        _updateActiveTaxRates();

        _setSuccessMessage('Tax rate deleted successfully');
        return true;
      } else {
        _setErrorMessage(response.message ?? 'Failed to delete tax rate');
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Delete tax rate', e);
      _setErrorMessage('An unexpected error occurred while deleting tax rate');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search tax rates
  Future<void> searchTaxRates(String query) async {
    _searchQuery = query.trim();
    await loadTaxRates(refresh: true);
  }

  /// Filter tax rates by type
  Future<void> filterByTaxType(String? taxType) async {
    _taxTypeFilter = taxType;
    await loadTaxRates(refresh: true);
  }

  /// Filter tax rates by active status
  Future<void> filterByActiveStatus(bool? isActive) async {
    _isActiveFilter = isActive;
    await loadTaxRates(refresh: true);
  }

  /// Sort tax rates
  Future<void> sortTaxRates(String sortBy, String sortOrder) async {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    await loadTaxRates(refresh: true);
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_hasNext && !_isLoading) {
      _currentPage++;
      await loadTaxRates();
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_hasPrevious && !_isLoading) {
      _currentPage--;
      await loadTaxRates();
    }
  }

  /// Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      _currentPage = page;
      await loadTaxRates();
    }
  }

  /// Toggle tax rate active status
  Future<bool> toggleTaxRateStatus(String id) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _taxRatesService.toggleTaxRateStatus(id);

      if (response.success && response.data != null) {
        final index = _taxRates.indexWhere((taxRate) => taxRate.id == id);
        if (index != -1) {
          _taxRates[index] = response.data!;
        }

        if (_selectedTaxRate?.id == id) {
          _selectedTaxRate = response.data;
        }

        // Update active tax rates
        _updateActiveTaxRates();

        _setSuccessMessage('Tax rate status updated successfully');
        return true;
      } else {
        _setErrorMessage(response.message ?? 'Failed to update tax rate status');
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Toggle tax rate status', e);
      _setErrorMessage('An unexpected error occurred while updating tax rate status');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get tax rates by type
  Future<List<TaxRateModel>> getTaxRatesByType(String taxType) async {
    try {
      final response = await _taxRatesService.getTaxRatesByType(taxType);

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        _setErrorMessage(response.message ?? 'Failed to get tax rates by type');
        return [];
      }
    } catch (e) {
      DebugHelper.printError('Get tax rates by type', e);
      _setErrorMessage('An unexpected error occurred while getting tax rates by type');
      return [];
    }
  }

  /// Get tax rate by type from active rates
  TaxRateModel? getActiveTaxRateByType(String taxType) {
    try {
      return _activeTaxRates.firstWhere((rate) => rate.taxType == taxType);
    } catch (e) {
      return null;
    }
  }

  /// Check if a tax type is available
  bool isTaxTypeAvailable(String taxType) {
    return _activeTaxRates.any((rate) => rate.taxType == taxType);
  }

  /// Get available tax types
  List<String> get availableTaxTypes {
    return _activeTaxRates.map((rate) => rate.taxType).toList();
  }

  /// Clear all filters and reset to default state
  void clearFilters() {
    _taxTypeFilter = null;
    _isActiveFilter = null;
    _searchQuery = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';
    notifyListeners();
  }

  /// Reset pagination to first page
  void resetPagination() {
    _currentPage = 1;
    notifyListeners();
  }

  /// Select a tax rate
  void selectTaxRate(TaxRateModel? taxRate) {
    _selectedTaxRate = taxRate;
    notifyListeners();
  }

  /// Clear selected tax rate
  void clearSelectedTaxRate() {
    _selectedTaxRate = null;
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear success message
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Refresh tax rates data
  Future<void> refresh() async {
    await loadTaxRates(refresh: true);
    await loadActiveTaxRates();
    await loadDefaultTaxConfiguration();
  }

  /// Initialize provider with essential data
  Future<void> initialize() async {
    await Future.wait([loadActiveTaxRates(), loadDefaultTaxConfiguration()]);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void _updatePagination(PaginationInfo pagination) {
    _currentPage = pagination.currentPage;
    _pageSize = pagination.pageSize;
    _totalCount = pagination.totalCount;
    _totalPages = pagination.totalPages;
    _hasNext = pagination.hasNext;
    _hasPrevious = pagination.hasPrevious;
  }

  void _updateActiveTaxRates() {
    _activeTaxRates = _taxRates.where((rate) => rate.isActive).toList();
  }
}
