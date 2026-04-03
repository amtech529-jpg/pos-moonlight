import 'package:flutter/material.dart';

import '../models/vendor/vendor_api_responses.dart';
import '../models/vendor/vendor_model.dart' hide VendorListParams;
import '../services/vendor/vendor_service.dart';

class VendorProvider extends ChangeNotifier {
  final VendorService _vendorService = VendorService();

  List<VendorModel> _vendors = [];
  List<VendorModel> _filteredVendors = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasError = false;

  // Pagination
  PaginationInfo? _paginationInfo;
  int _currentPage = 1;
  int _pageSize = 1000;
  bool _showInactive = false;

  // Filters
  String? _selectedCity;
  String? _selectedArea;

  // Sorting
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // Statistics
  VendorStatisticsResponse? _vendorStatistics;

  // Cities and Areas data
  List<VendorCityCount> _cities = [];
  List<VendorAreaCount> _areas = [];

  // Getters
  List<VendorModel> get vendors => _filteredVendors;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  PaginationInfo? get paginationInfo => _paginationInfo;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get showInactive => _showInactive;
  String? get selectedCity => _selectedCity;
  String? get selectedArea => _selectedArea;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  /// Apply client-side filtering as fallback
  List<VendorModel> _applyClientSideFilters(List<VendorModel> vendors) {
    List<VendorModel> filtered = List.from(vendors);

    // Filter by inactive status
    if (!_showInactive) {
      filtered = filtered.where((vendor) => vendor.isActive).toList();
    }

    // Filter by city
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filtered = filtered.where((vendor) => 
        vendor.city.toLowerCase().contains(_selectedCity!.toLowerCase())
      ).toList();
    }

    // Filter by area
    if (_selectedArea != null && _selectedArea!.isNotEmpty) {
      filtered = filtered.where((vendor) => 
        vendor.area.toLowerCase().contains(_selectedArea!.toLowerCase())
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((vendor) =>
        vendor.name.toLowerCase().contains(query) ||
        vendor.businessName.toLowerCase().contains(query) ||
        vendor.displayName.toLowerCase().contains(query) ||
        vendor.phone.toLowerCase().contains(query) ||
        vendor.city.toLowerCase().contains(query) ||
        vendor.area.toLowerCase().contains(query) ||
        vendor.fullAddress.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }
  VendorStatisticsResponse? get vendorStatistics => _vendorStatistics;
  List<VendorCityCount> get cities => _cities;
  List<VendorAreaCount> get areas => _areas;

  /// Load vendors with pagination and filters
  Future<void> loadVendors({
    int? page,
    int? pageSize,
    String? search,
    bool? showInactive,
    String? city,
    String? area,
    bool showLoadingIndicator = true,
  }) async {
    if (showLoadingIndicator) {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Update parameters
      _currentPage = page ?? _currentPage;
      _pageSize = pageSize ?? _pageSize;
      _searchQuery = search ?? _searchQuery;
      _showInactive = showInactive ?? _showInactive;
      _selectedCity = city;
      _selectedArea = area;

      // Build parameters
      final params = VendorListParams(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        showInactive: _showInactive,
        city: _selectedCity,
        area: _selectedArea,
        sortBy: _sortBy,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );

      final response = await _vendorService.getVendors(params: params);

      if (response.success && response.data != null) {
        _vendors = response.data!.vendors;
        
        // Apply client-side filtering as fallback
        _filteredVendors = _applyClientSideFilters(_vendors);
        
        _paginationInfo = response.data!.pagination;
        _hasError = false;
        _errorMessage = null;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        _vendors = [];
        _filteredVendors = [];
        _paginationInfo = null;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load vendors: ${e.toString()}';
      _vendors = [];
      _filteredVendors = [];
      _paginationInfo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh vendors (pull-to-refresh)
  Future<void> refreshVendors() async {
    _currentPage = 1;
    await loadVendors(page: 1, showLoadingIndicator: false);
    await _loadVendorStatistics();
    await _loadCitiesAndAreas();
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_paginationInfo?.hasNext == true) {
      await loadVendors(page: _currentPage + 1, showLoadingIndicator: false);
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_paginationInfo?.hasPrevious == true) {
      await loadVendors(page: _currentPage - 1, showLoadingIndicator: false);
    }
  }

  /// Search vendors
  Future<void> searchVendors(String query) async {
    _searchQuery = query;
    _currentPage = 1;
    await loadVendors(search: _searchQuery, page: 1);
  }

  /// Clear search
  Future<void> clearSearch() async {
    _searchQuery = '';
    _currentPage = 1;
    await loadVendors(search: '', page: 1);
  }

  /// Toggle show inactive vendors
  Future<void> toggleShowInactive() async {
    _showInactive = !_showInactive;
    _currentPage = 1;
    await loadVendors(showInactive: _showInactive, page: 1);
  }

  /// Set city filter
  Future<void> setCityFilter(String? city) async {
    _selectedCity = city;
    _currentPage = 1;
    await loadVendors(city: _selectedCity, page: 1);
  }

  /// Set area filter
  Future<void> setAreaFilter(String? area) async {
    _selectedArea = area;
    _currentPage = 1;
    await loadVendors(area: _selectedArea, page: 1);
  }

  /// Clear all filters
  Future<void> clearAllFilters() async {
    _selectedCity = null;
    _selectedArea = null;
    _searchQuery = '';
    _currentPage = 1;
    await loadVendors(
      city: null,
      area: null,
      search: '',
      page: 1,
    );
  }

  /// Sort vendors
  void setSortBy(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortAscending = (sortBy == 'name' || sortBy == 'business_name' || sortBy == 'city');
      }
    }

    loadVendors(showLoadingIndicator: false);
  }

  /// Add new vendor
  Future<bool> addVendor({
    required String name,
    String? businessName,
    String? cnic,
    required String phone,
    String? city,
    String? area,
    DateTime? createdAt,
  }) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _vendorService.createVendor(
        name: name,
        businessName: businessName,
        cnic: cnic,
        phone: phone,
        city: city,
        area: area,
        createdAt: createdAt,
      );

      if (response.success && response.data != null) {
        // Refresh the vendor list to include the new vendor
        await refreshVendors();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to create vendor: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ... (UpdateVendor kept as is or updated if needed, but user only asked for add vendor changes)
  // For safety, I will only update addVendor and validateVendorData. 
  // Wait, I can't skip lines if I use replace_file_content.
  // I will just update validateVendorData separately as it is further down.
  // This tool call only updates addVendor.


  /// Update existing vendor
  Future<bool> updateVendor({
    required String id,
    required String name,
    required String businessName,
    String? cnic,
    required String phone,
    required String city,
    required String area,
  }) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _vendorService.updateVendor(
        id: id,
        name: name,
        businessName: businessName,
        cnic: cnic,
        phone: phone,
        city: city,
        area: area,
      );

      if (response.success && response.data != null) {
        // Update the vendor in the current list
        final index = _vendors.indexWhere((vendor) => vendor.id == id);
        if (index != -1) {
          _vendors[index] = response.data!;
          _filteredVendors = List.from(_vendors);
        }
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to update vendor: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete vendor permanently (hard delete)
  Future<bool> deleteVendor(String id) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _vendorService.deleteVendor(id);

      if (response.success) {
        // Remove vendor from current list
        _vendors.removeWhere((vendor) => vendor.id == id);
        _filteredVendors = List.from(_vendors);
        await _loadVendorStatistics();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to delete vendor: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Soft delete vendor (set as inactive)
  Future<bool> softDeleteVendor(String id) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _vendorService.softDeleteVendor(id);

      if (response.success) {
        // Update vendor in current list or remove if not showing inactive
        final index = _vendors.indexWhere((vendor) => vendor.id == id);
        if (index != -1) {
          if (_showInactive) {
            _vendors[index] = _vendors[index].copyWith(isActive: false);
            _filteredVendors = List.from(_vendors);
          } else {
            _vendors.removeAt(index);
            _filteredVendors = List.from(_vendors);
          }
        }
        await _loadVendorStatistics();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to deactivate vendor: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restore vendor
  Future<bool> restoreVendor(String id) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _vendorService.restoreVendor(id);

      if (response.success && response.data != null) {
        // Update vendor in current list
        final index = _vendors.indexWhere((vendor) => vendor.id == id);
        if (index != -1) {
          _vendors[index] = response.data!;
          _filteredVendors = List.from(_vendors);
        }
        await _loadVendorStatistics();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to restore vendor: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bulk vendor actions
  Future<bool> bulkVendorActions({required List<String> vendorIds, required String action}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _vendorService.bulkVendorActions(vendorIds: vendorIds, action: action);

      if (response.success) {
        // Refresh vendor list to reflect changes
        await refreshVendors();
        return true;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to perform bulk action: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get vendor by ID
  VendorModel? getVendorById(String id) {
    try {
      return _vendors.firstWhere((vendor) => vendor.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Load vendor statistics
  Future<void> _loadVendorStatistics() async {
    try {
      final response = await _vendorService.getVendorStatistics();
      if (response.success && response.data != null) {
        _vendorStatistics = response.data;
      }
    } catch (e) {
      debugPrint('Error loading vendor statistics: $e');
    }
  }

  /// Load cities and areas
  Future<void> _loadCitiesAndAreas() async {
    try {
      // Load cities
      final citiesResponse = await _vendorService.getVendorCities();
      if (citiesResponse.success && citiesResponse.data != null) {
        _cities = citiesResponse.data!;
      }

      // Load areas
      final areasResponse = await _vendorService.getVendorAreas();
      if (areasResponse.success && areasResponse.data != null) {
        _areas = areasResponse.data!;
      }
    } catch (e) {
      debugPrint('Error loading cities and areas: $e');
    }
  }

  /// Get areas for a specific city
  Future<List<VendorAreaCount>> getAreasForCity(String city) async {
    try {
      final response = await _vendorService.getVendorAreas(city: city);
      if (response.success && response.data != null) {
        return response.data!;
      }
    } catch (e) {
      debugPrint('Error loading areas for city: $e');
    }
    return [];
  }

  /// Get vendor payments
  Future<VendorPaymentsResponse?> getVendorPayments({
    required String vendorId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _vendorService.getVendorPayments(
        vendorId: vendorId,
        page: page,
        pageSize: pageSize,
      );

      if (response.success && response.data != null) {
        return response.data;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return null;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to get vendor payments: ${e.toString()}';
      return null;
    }
  }

  /// Get vendor transactions
  Future<VendorTransactionsResponse?> getVendorTransactions({
    required String vendorId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _vendorService.getVendorTransactions(
        vendorId: vendorId,
        page: page,
        pageSize: pageSize,
      );

      if (response.success && response.data != null) {
        return response.data;
      } else {
        _hasError = true;
        _errorMessage = response.message;
        return null;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to get vendor transactions: ${e.toString()}';
      return null;
    }
  }

  /// Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Enhanced statistics for dashboard
  Map<String, dynamic> get vendorStats {
    if (_vendorStatistics == null) {
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'recentlyAdded': 0,
        'uniqueCities': 0,
        'uniqueAreas': 0,
        'monthlyGrowthRate': 0.0,
      };
    }

    return {
      'total': _vendorStatistics!.totalVendors,
      'active': _vendorStatistics!.activeVendors,
      'inactive': _vendorStatistics!.inactiveVendors,
      'recentlyAdded': _vendorStatistics!.newVendorsThisMonth,
      'uniqueCities': _vendorStatistics!.topCities.length,
      'uniqueAreas': _areas.length,
      'monthlyGrowthRate': _vendorStatistics!.monthlyGrowthRate,
    };
  }

  /// Get recently created vendors
  List<VendorModel> getRecentlyCreated({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _vendors.where((vendor) => vendor.createdAt.isAfter(cutoffDate)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Set page size
  Future<void> setPageSize(int pageSize) async {
    if (_pageSize != pageSize) {
      _pageSize = pageSize;
      _currentPage = 1;
      await loadVendors(pageSize: _pageSize, page: 1);
    }
  }

  /// Load vendors by specific segments
  Future<void> loadNewVendors({int days = 30}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _vendorService.getRecentVendors(days: days, page: 1, pageSize: _pageSize);

      if (response.success && response.data != null) {
        _vendors = response.data!.vendors;
        _filteredVendors = List.from(_vendors);
        _paginationInfo = response.data!.pagination;
        _hasError = false;
        _errorMessage = null;
      } else {
        _hasError = true;
        _errorMessage = response.message;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load new vendors: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Advanced search with multiple parameters
  Future<void> advancedSearch({
    String? query,
    String? city,
    String? area,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final params = VendorListParams(
        page: 1,
        pageSize: _pageSize,
        search: query,
        showInactive: _showInactive,
        city: city,
        area: area,
        createdAfter: createdAfter?.toIso8601String().split('T')[0],
        createdBefore: createdBefore?.toIso8601String().split('T')[0],
        sortBy: _sortBy,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );

      final response = await _vendorService.getVendors(params: params);

      if (response.success && response.data != null) {
        _vendors = response.data!.vendors;
        _filteredVendors = List.from(_vendors);
        _paginationInfo = response.data!.pagination;

        // Update filter states
        _searchQuery = query ?? '';
        _selectedCity = city;
        _selectedArea = area;
        _currentPage = 1;

        _hasError = false;
        _errorMessage = null;
      } else {
        _hasError = true;
        _errorMessage = response.message;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Advanced search failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get vendor distribution by city
  Map<String, int> getVendorDistributionByCity() {
    final distribution = <String, int>{};
    for (final vendor in _vendors) {
      distribution[vendor.city] = (distribution[vendor.city] ?? 0) + 1;
    }
    return distribution;
  }

  /// Get vendor growth trend (monthly)
  List<Map<String, dynamic>> getVendorGrowthTrend() {
    if (_vendorStatistics?.vendorsByMonth == null) return [];

    return _vendorStatistics!.vendorsByMonth
        .map(
          (monthData) => {
        'month': monthData.monthName,
        'count': monthData.count,
        'monthCode': monthData.month,
      },
    )
        .toList();
  }

  /// Get top performing cities
  List<Map<String, dynamic>> getTopPerformingCities({int limit = 5}) {
    return _vendorStatistics?.topCities
        .take(limit)
        .map((cityData) => {'city': cityData.city, 'count': cityData.count})
        .toList() ??
        [];
  }

  /// Check if vendor exists by CNIC
  bool vendorExistsByCnic(String cnic) {
    return _vendors.any((vendor) => vendor.cnic == cnic);
  }

  /// Check if vendor exists by phone
  bool vendorExistsByPhone(String phone) {
    return _vendors.any((vendor) => vendor.phone == phone);
  }

  /// Get vendor suggestions for autocomplete
  List<VendorModel> getVendorSuggestions(String query) {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _vendors
        .where(
          (vendor) =>
      vendor.name.toLowerCase().contains(lowercaseQuery) ||
          vendor.businessName.toLowerCase().contains(lowercaseQuery) ||
          (vendor.cnic?.contains(query) ?? false) ||
          vendor.phone.contains(query),
    )
        .take(10)
        .toList();
  }

  /// Get similar vendors based on location
  List<VendorModel> getSimilarVendors(VendorModel vendor, {int limit = 5}) {
    return _vendors
        .where((v) => v.id != vendor.id && (v.city == vendor.city || v.area == vendor.area))
        .take(limit)
        .toList();
  }

  /// Validate vendor data before submission
  Map<String, String> validateVendorData({
    required String name,
    String? businessName,
    String? cnic,
    required String phone,
    String? city,
    String? area,
  }) {
    final errors = <String, String>{};

    // Name validation
    if (name.trim().isEmpty) {
      errors['name'] = 'Vendor name is required';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Vendor name must be at least 2 characters';
    }

    // Business name validation
    if (businessName != null && businessName.trim().isNotEmpty) {
      if (businessName.trim().length < 2) {
        errors['businessName'] = 'Business name must be at least 2 characters';
      }
    }

    // CNIC validation
    if (cnic != null && cnic.trim().isNotEmpty) {
      if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(cnic.trim())) {
        errors['cnic'] = 'CNIC format should be XXXXX-XXXXXXX-X';
      } else if (vendorExistsByCnic(cnic.trim())) {
        errors['cnic'] = 'A vendor with this CNIC already exists';
      }
    }

    // Phone validation
    if (phone.trim().isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (phone.trim().length < 10) {
      errors['phone'] = 'Phone number must be at least 10 digits';
    } else if (vendorExistsByPhone(phone.trim())) {
      errors['phone'] = 'A vendor with this phone number already exists';
    }

    // City validation
    if (city != null && city.trim().isNotEmpty) {
       // Optional check if needed
    }

    // Area validation
    if (area != null && area.trim().isNotEmpty) {
       // Optional check if needed
    }

    return errors;
  }

  /// Reset all filters and search
  Future<void> resetAllFiltersAndSearch() async {
    _searchQuery = '';
    _selectedCity = null;
    _selectedArea = null;
    _showInactive = false;
    _currentPage = 1;
    _sortBy = 'created_at';
    _sortAscending = false;

    await loadVendors(
      page: 1,
      search: '',
      showInactive: false,
      city: null,
      area: null,
    );
  }

  /// Initialize provider with initial data load
  Future<void> initialize() async {
    await loadVendors();
    await _loadVendorStatistics();
    await _loadCitiesAndAreas();
  }

  /// Dispose resources
  @override
  void dispose() {
    _vendors.clear();
    _filteredVendors.clear();
    _cities.clear();
    _areas.clear();
    super.dispose();
  }
}