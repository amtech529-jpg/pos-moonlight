import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/zakat/zakat_model.dart';
import '../models/zakat/zakat_api_responses.dart';
import '../services/zakat_service.dart';

class ZakatProvider extends ChangeNotifier {
  final ZakatService _zakatService = ZakatService();

  List<Zakat> _zakatRecords = [];
  List<Zakat> _filteredRecords = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _searchQuery = '';
  PaginationInfo? _paginationInfo;
  ZakatStatisticsResponse? _statistics;

  // Sorting and filtering
  String _sortBy = 'date';
  bool _sortAscending = false;
  String? _selectedBeneficiary;
  String? _selectedAuthority;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _showInactive = false;

  // Getters
  List<Zakat> get zakatRecords => _filteredRecords;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  PaginationInfo? get paginationInfo => _paginationInfo;
  ZakatStatisticsResponse? get statistics => _statistics;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  String? get selectedBeneficiary => _selectedBeneficiary;
  String? get selectedAuthority => _selectedAuthority;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  bool get showInactive => _showInactive;

  ZakatProvider() {
    loadZakatRecords();
  }

  /// Load zakat records from API
  Future<void> loadZakatRecords({int page = 1, int pageSize = 20, bool showLoading = true}) async {
    if (showLoading) {
      _setLoading(true);
    }

    try {
      final params = ZakatListParams(
        page: page,
        pageSize: pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        beneficiaryName: _selectedBeneficiary,
        authorizedBy: _selectedAuthority,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        sortBy: _sortBy,
        sortOrder: _sortAscending ? 'asc' : 'desc',
        showInactive: _showInactive,
      );

      final response = await _zakatService.getZakats(params: params);

      if (response.success && response.data != null) {
        _zakatRecords = response.data!.zakats;
        _filteredRecords = List.from(_zakatRecords);
        _paginationInfo = response.data!.pagination;
        _clearError();
      } else {
        _setError(response.message ?? 'Failed to load zakat records');
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _zakatService.getZakatStatistics();

      if (response.success && response.data != null) {
        _statistics = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Add new zakat record
  Future<bool> addZakat({
    required String name,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required double amount,
    required String beneficiaryName,
    String? beneficiaryContact,
    String? notes,
    required String authorizedBy,
  }) async {
    _setLoading(true);

    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final response = await _zakatService.createZakat(
        name: name,
        description: description,
        date: date,
        time: timeString,
        amount: amount,
        beneficiaryName: beneficiaryName,
        beneficiaryContact: beneficiaryContact,
        notes: notes,
        authorizedBy: authorizedBy,
      );

      if (response.success && response.data != null) {
        // Refresh the list to include the new record
        await loadZakatRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to add zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing zakat record
  Future<bool> updateZakat({
    required String id,
    required String name,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required double amount,
    required String beneficiaryName,
    String? beneficiaryContact,
    String? notes,
    required String authorizedBy,
  }) async {
    _setLoading(true);

    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final response = await _zakatService.updateZakat(
        id: id,
        name: name,
        description: description,
        date: date,
        time: timeString,
        amount: amount,
        beneficiaryName: beneficiaryName,
        beneficiaryContact: beneficiaryContact,
        notes: notes,
        authorizedBy: authorizedBy,
      );

      if (response.success && response.data != null) {
        // Refresh the list to include the updated record
        await loadZakatRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete zakat record
  Future<bool> deleteZakat(String id) async {
    _setLoading(true);

    try {
      final response = await _zakatService.deleteZakat(id);

      if (response.success) {
        // Refresh the list to remove the deleted record
        await loadZakatRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search zakat records
  Future<void> searchZakat(String query) async {
    _searchQuery = query;
    // Reload records with search query
    await loadZakatRecords();
  }

  /// Set sorting
  Future<void> setSortBy(String sortBy) async {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = false;
    }
    // Reload records with new sorting
    await loadZakatRecords();
  }

  /// Set beneficiary filter
  Future<void> setBeneficiaryFilter(String? beneficiary) async {
    _selectedBeneficiary = beneficiary;
    await loadZakatRecords();
  }

  /// Set authority filter
  Future<void> setAuthorityFilter(String? authority) async {
    _selectedAuthority = authority;
    await loadZakatRecords();
  }

  /// Set date range filter
  Future<void> setDateRangeFilter(DateTime? from, DateTime? to) async {
    _dateFrom = from;
    _dateTo = to;
    await loadZakatRecords();
  }

  /// Set inactive records filter
  Future<void> setShowInactiveFilter(bool showInactive) async {
    _showInactive = showInactive;
    await loadZakatRecords();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _selectedBeneficiary = null;
    _selectedAuthority = null;
    _dateFrom = null;
    _dateTo = null;
    _searchQuery = '';
    _showInactive = false;
    await loadZakatRecords();
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_paginationInfo?.hasNext == true) {
      await loadZakatRecords(page: _paginationInfo!.currentPage + 1);
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_paginationInfo?.hasPrevious == true) {
      await loadZakatRecords(page: _paginationInfo!.currentPage - 1);
    }
  }

  /// Duplicate zakat record
  Future<bool> duplicateZakat(String id) async {
    _setLoading(true);

    try {
      final response = await _zakatService.duplicateZakat(id);

      if (response.success && response.data != null) {
        // Refresh the list to include the duplicated record
        await loadZakatRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to duplicate zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify zakat record
  Future<bool> verifyZakat(String id) async {
    _setLoading(true);

    try {
      final response = await _zakatService.verifyZakat(id);

      if (response.success && response.data != null) {
        // Update the record in the local list
        final index = _zakatRecords.indexWhere((zakat) => zakat.id == id);
        if (index != -1) {
          _zakatRecords[index] = response.data!;
          _filteredRecords = List.from(_zakatRecords);
        }
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to verify zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Unverify zakat record
  Future<bool> unverifyZakat(String id) async {
    _setLoading(true);

    try {
      final response = await _zakatService.unverifyZakat(id);

      if (response.success && response.data != null) {
        // Update the record in the local list
        final index = _zakatRecords.indexWhere((zakat) => zakat.id == id);
        if (index != -1) {
          _zakatRecords[index] = response.data!;
          _filteredRecords = List.from(_zakatRecords);
        }
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to unverify zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Archive zakat record
  Future<bool> archiveZakat(String id) async {
    _setLoading(true);

    try {
      final response = await _zakatService.archiveZakat(id);

      if (response.success && response.data != null) {
        // Update the record in the local list
        final index = _zakatRecords.indexWhere((zakat) => zakat.id == id);
        if (index != -1) {
          _zakatRecords[index] = response.data!;
          _filteredRecords = List.from(_zakatRecords);
        }
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to archive zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Unarchive zakat record
  Future<bool> unarchiveZakat(String id) async {
    _setLoading(true);

    try {
      final response = await _zakatService.unarchiveZakat(id);

      if (response.success && response.data != null) {
        // Update the record in the local list
        final index = _zakatRecords.indexWhere((zakat) => zakat.id == id);
        if (index != -1) {
          _zakatRecords[index] = response.data!;
          _filteredRecords = List.from(_zakatRecords);
        }
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to unarchive zakat record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bulk actions on zakat records
  Future<bool> bulkZakatActions({required List<String> zakatIds, required String action}) async {
    _setLoading(true);

    try {
      final response = await _zakatService.bulkZakatActions(zakatIds: zakatIds, action: action);

      if (response.success) {
        // Refresh the list to reflect bulk changes
        await loadZakatRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to perform bulk action');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get zakats by beneficiary
  Future<List<Zakat>?> getZakatsByBeneficiary({required String beneficiaryName, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final response = await _zakatService.getZakatsByBeneficiary(beneficiaryName: beneficiaryName, dateFrom: dateFrom, dateTo: dateTo);

      if (response.success && response.data != null) {
        return response.data!.zakats;
      } else {
        _setError(response.message ?? 'Failed to get zakats by beneficiary');
        return null;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return null;
    }
  }

  /// Get zakats by authority
  Future<List<Zakat>?> getZakatsByAuthority({required String authority, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final response = await _zakatService.getZakatsByAuthority(authority: authority, dateFrom: dateFrom, dateTo: dateTo);

      if (response.success && response.data != null) {
        return response.data!.zakats;
      } else {
        _setError(response.message ?? 'Failed to get zakats by authority');
        return null;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return null;
    }
  }

  /// Get zakats by date range
  Future<List<Zakat>?> getZakatsByDateRange({required DateTime startDate, required DateTime endDate}) async {
    try {
      final response = await _zakatService.getZakatsByDateRange(startDate: startDate, endDate: endDate);

      if (response.success && response.data != null) {
        return response.data!.zakats;
      } else {
        _setError(response.message ?? 'Failed to get zakats by date range');
        return null;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return null;
    }
  }

  /// Get beneficiary report
  Future<ZakatBeneficiaryReportResponse?> getBeneficiaryReport({required String beneficiaryName}) async {
    try {
      final response = await _zakatService.getBeneficiaryReport(beneficiaryName: beneficiaryName);

      if (response.success && response.data != null) {
        return response.data!;
      } else {
        _setError(response.message ?? 'Failed to get beneficiary report');
        return null;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return null;
    }
  }

  /// Refresh data (for pull-to-refresh functionality)
  Future<void> refreshZakatRecords() async {
    await loadZakatRecords();
    await loadStatistics();
  }

  /// Get statistics
  Map<String, dynamic> get zakatStats {
    if (_statistics == null) {
      // Return default stats if statistics not loaded
      return {
        'total': _zakatRecords.length,
        'totalAmount': _zakatRecords.fold<double>(0.0, (sum, zakat) => sum + zakat.amount).toStringAsFixed(0),
        'thisYear': _getThisYearCount(),
        'thisMonth': _getThisMonthCount(),
      };
    }

    return {
      'total': _statistics!.totalZakats,
      'totalAmount': _statistics!.totalAmount.toStringAsFixed(0),
      'thisYear': _statistics!.thisYearCount,
      'thisMonth': _statistics!.thisMonthCount,
    };
  }

  /// Get records by year
  List<Zakat> getRecordsByYear(int year) {
    return _zakatRecords.where((zakat) => zakat.date.year == year).toList();
  }

  /// Get records by month
  List<Zakat> getRecordsByMonth(int year, int month) {
    return _zakatRecords.where((zakat) => zakat.date.year == year && zakat.date.month == month).toList();
  }

  /// Get total amount by year
  double getTotalAmountByYear(int year) {
    return _zakatRecords.where((zakat) => zakat.date.year == year).fold<double>(0.0, (sum, zakat) => sum + zakat.amount);
  }

  /// Get total amount by month
  double getTotalAmountByMonth(int year, int month) {
    return _zakatRecords.where((zakat) => zakat.date.year == year && zakat.date.month == month).fold<double>(0.0, (sum, zakat) => sum + zakat.amount);
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  int _getThisYearCount() {
    final currentYear = DateTime.now().year;
    return _zakatRecords.where((zakat) => zakat.date.year == currentYear).length;
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    return _zakatRecords.where((zakat) => zakat.date.year == now.year && zakat.date.month == now.month).length;
  }

  /// Clear all records (for testing purposes)
  void clearAllRecords() {
    _zakatRecords.clear();
    _filteredRecords.clear();
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
