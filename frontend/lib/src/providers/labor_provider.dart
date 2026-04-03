import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/labor/labor_model.dart';
import '../models/labor/labor_api_responses.dart';
import '../services/labor/labor_service.dart';

class LaborProvider extends ChangeNotifier {
  final LaborService _laborService = LaborService();

  // State variables
  List<LaborModel> _labors = [];
  List<LaborModel> _filteredLabors = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  PaginationInfo? _paginationInfo;
  LaborStatisticsResponse? _statistics;
  LaborSalaryReportResponse? _salaryReport;
  LaborDemographicsReportResponse? _demographicsReport;

  // Filter state
  String? _searchQuery;
  String? _selectedCity;
  String? _selectedArea;
  String? _selectedDesignation;
  String? _selectedGender;
  String? _minSalary;
  String? _maxSalary;
  String? _minAge;
  String? _maxAge;
  DateTime? _joinedAfter;
  DateTime? _joinedBefore;
  bool _showInactive = false;

  // Sorting state
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  bool _sortAscending = true;

  // Pagination state
  int _currentPage = 1;
  int _pageSize = 20;

  // Getters
  List<LaborModel> get labors => _filteredLabors;

  List<LaborModel> get allLabors => _labors;

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  String? get errorMessage => _errorMessage;

  PaginationInfo? get paginationInfo => _paginationInfo;

  LaborStatisticsResponse? get statistics => _statistics;

  LaborSalaryReportResponse? get salaryReport => _salaryReport;

  LaborDemographicsReportResponse? get demographicsReport => _demographicsReport;

  // Filter getters
  String? get searchQuery => _searchQuery;

  String? get selectedCity => _selectedCity;

  String? get selectedArea => _selectedArea;

  String? get selectedDesignation => _selectedDesignation;
  String? get selectedGender => _selectedGender;

  String? get minSalary => _minSalary;

  String? get maxSalary => _maxSalary;

  String? get minAge => _minAge;

  String? get maxAge => _maxAge;

  DateTime? get joinedAfter => _joinedAfter;

  DateTime? get joinedBefore => _joinedBefore;

  bool get showInactive => _showInactive;

  // Sorting getters
  String get sortBy => _sortBy;

  String get sortOrder => _sortOrder;

  bool get sortAscending => _sortAscending;

  // Pagination getters
  int get currentPage => _currentPage;

  int get pageSize => _pageSize;

  // Computed properties
  bool get hasActiveFilters =>
      _searchQuery?.isNotEmpty == true ||
      _selectedCity?.isNotEmpty == true ||
      _selectedArea?.isNotEmpty == true ||
      _selectedDesignation?.isNotEmpty == true ||
      _selectedGender?.isNotEmpty == true ||
      _minSalary?.isNotEmpty == true ||
      _maxSalary?.isNotEmpty == true ||
      _minAge?.isNotEmpty == true ||
      _maxAge?.isNotEmpty == true ||
      _joinedAfter != null ||
      _joinedBefore != null ||
      _showInactive;

  int get totalActiveLabors => _labors.where((labor) => labor.isActive).length;

  int get totalInactiveLabors => _labors.where((labor) => !labor.isActive).length;

  int get totalLabors => _labors.length;

  LaborProvider() {
    loadLabors();
  }

  // Error handling
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _hasError = false;
      _errorMessage = null;
    }
    notifyListeners();
  }

  // Load labors with current filters
  Future<void> loadLabors() async {
    _setLoading(true);

    try {
      final params = LaborListParams(
        page: _currentPage,
        pageSize: _pageSize,
        showInactive: _showInactive,
        search: _searchQuery,
        city: _selectedCity,
        area: _selectedArea,
        designation: _selectedDesignation,
        gender: _selectedGender,
        minSalary: _minSalary,
        maxSalary: _maxSalary,
        minAge: _minAge,
        maxAge: _maxAge,
        joinedAfter: _joinedAfter?.toIso8601String().split('T')[0],
        joinedBefore: _joinedBefore?.toIso8601String().split('T')[0],
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final response = await _laborService.getLabors(params: params);

      if (response.success && response.data != null) {
        _labors = response.data!.labors;
        _filteredLabors = List.from(_labors);
        _paginationInfo = response.data!.pagination;
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Failed to load labors: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh labors (reset to first page)
  Future<void> refreshLabors() async {
    _currentPage = 1;
    await loadLabors();
  }

  // Create new labor
  Future<bool> createLabor({
    required String name,
    required String cnic,
    required String phoneNumber,
    required String designation,
    required DateTime joiningDate,
    required double salary,
    required String area,
    required String city,
    required String gender,
    required int age,
    required double fixedIncentive,
  }) async {
    _setLoading(true);

    try {
      final response = await _laborService.createLabor(
        name: name,
        cnic: cnic,
        phoneNumber: phoneNumber,
        designation: designation,
        joiningDate: joiningDate,
        salary: salary,
        area: area,
        city: city,
        gender: gender,
        age: age,
        fixedIncentive: fixedIncentive,
      );

      if (response.success && response.data != null) {
        await refreshLabors(); // Reload the list
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to create labor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update labor
  Future<bool> updateLabor({
    required String id,
    required String name,
    required String cnic,
    required String phoneNumber,
    required String designation,
    required DateTime joiningDate,
    required double salary,
    required String area,
    required String city,
    required String gender,
    required int age,
    required double fixedIncentive,
  }) async {
    _setLoading(true);

    try {
      final response = await _laborService.updateLabor(
        id: id,
        name: name,
        cnic: cnic,
        phoneNumber: phoneNumber,
        designation: designation,
        joiningDate: joiningDate,
        salary: salary,
        area: area,
        city: city,
        gender: gender,
        age: age,
        fixedIncentive: fixedIncentive,
      );

      if (response.success && response.data != null) {
        await refreshLabors(); // Reload the list
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to update labor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete labor (hard delete)
  Future<bool> deleteLabor(String id) async {
    _setLoading(true);

    try {
      final response = await _laborService.deleteLabor(id);

      if (response.success) {
        await refreshLabors(); // Reload the list
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete labor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Soft delete labor
  Future<bool> softDeleteLabor(String id) async {
    _setLoading(true);

    try {
      final response = await _laborService.softDeleteLabor(id);

      if (response.success) {
        await refreshLabors(); // Reload the list
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to soft delete labor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Restore labor
  Future<bool> restoreLabor(String id) async {
    _setLoading(true);

    try {
      final response = await _laborService.restoreLabor(id);

      if (response.success) {
        await refreshLabors(); // Reload the list
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to restore labor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get labor by ID
  Future<LaborModel?> getLaborById(String id) async {
    try {
      final response = await _laborService.getLaborById(id);
      if (response.success && response.data != null) {
        return response.data;
      } else {
        _setError(response.message);
        return null;
      }
    } catch (e) {
      _setError('Failed to get labor: ${e.toString()}');
      return null;
    }
  }

  // Search functionality
  Future<void> searchLabors(String query) async {
    _searchQuery = query;
    _currentPage = 1;
    await loadLabors();
  }

  void clearSearch() {
    _searchQuery = null;
    _currentPage = 1;
    loadLabors();
  }

  // Filter methods
  Future<void> setCityFilter(String? city) async {
    _selectedCity = city;
    _currentPage = 1;
    await loadLabors();
  }

  Future<void> setAreaFilter(String? area) async {
    _selectedArea = area;
    _currentPage = 1;
    await loadLabors();
  }

  Future<void> setDesignationFilter(String? designation) async {
    _selectedDesignation = designation;
    _currentPage = 1;
    await loadLabors();
    notifyListeners();
  }

  Future<void> setGenderFilter(String? gender) async {
    _selectedGender = gender;
    _currentPage = 1;
    await loadLabors();
  }

  Future<void> setSalaryRangeFilter(String? minSalary, String? maxSalary) async {
    _minSalary = minSalary;
    _maxSalary = maxSalary;
    _currentPage = 1;
    await loadLabors();
  }

  Future<void> setAgeRangeFilter(String? minAge, String? maxAge) async {
    _minAge = minAge;
    _maxAge = maxAge;
    _currentPage = 1;
    await loadLabors();
  }

  Future<void> setDateRangeFilter(DateTime? joinedAfter, DateTime? joinedBefore) async {
    _joinedAfter = joinedAfter;
    _joinedBefore = joinedBefore;
    _currentPage = 1;
    await loadLabors();
  }

  Future<void> setShowInactive(bool showInactive) async {
    _showInactive = showInactive;
    _currentPage = 1;
    await loadLabors();
  }

  Future<void> toggleShowInactive() async {
    _showInactive = !_showInactive;
    _currentPage = 1;
    await loadLabors();
  }

  // Apply multiple filters at once
  Future<void> applyFilters({
    String? search,
    String? city,
    String? area,
    String? designation,
    String? gender,
    String? minSalary,
    String? maxSalary,
    String? minAge,
    String? maxAge,
    DateTime? joinedAfter,
    DateTime? joinedBefore,
    bool? showInactive,
  }) async {
    _searchQuery = search;
    _selectedCity = city;
    _selectedArea = area;
    _selectedDesignation = designation;
    _selectedGender = gender;
    _minSalary = minSalary;
    _maxSalary = maxSalary;
    _minAge = minAge;
    _maxAge = maxAge;
    _joinedAfter = joinedAfter;
    _joinedBefore = joinedBefore;
    if (showInactive != null) _showInactive = showInactive;

    _currentPage = 1;
    await loadLabors();
  }

  // Clear all filters
  Future<void> clearAllFilters() async {
    _searchQuery = null;
    _selectedCity = null;
    _selectedArea = null;
    _selectedDesignation = null;
    _selectedGender = null;
    _minSalary = null;
    _maxSalary = null;
    _minAge = null;
    _maxAge = null;
    _joinedAfter = null;
    _joinedBefore = null;
    _showInactive = false;
    _currentPage = 1;
    await loadLabors();
  }

  // Sorting
  Future<void> setSortBy(String sortBy) async {
    if (_sortBy == sortBy) {
      // Toggle sort order if same field
      _sortAscending = !_sortAscending;
      _sortOrder = _sortAscending ? 'asc' : 'desc';
    } else {
      // New field, default to ascending
      _sortBy = sortBy;
      _sortAscending = true;
      _sortOrder = 'asc';
    }

    _currentPage = 1;
    await loadLabors();
  }

  // Pagination
  Future<void> loadNextPage() async {
    if (_paginationInfo?.hasNext == true) {
      _currentPage++;
      await loadLabors();
    }
  }

  Future<void> loadPreviousPage() async {
    if (_paginationInfo?.hasPrevious == true && _currentPage > 1) {
      _currentPage--;
      await loadLabors();
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= (_paginationInfo?.totalPages ?? 1)) {
      _currentPage = page;
      await loadLabors();
    }
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    loadLabors();
  }

  // Statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _laborService.getLaborStatistics();
      if (response.success && response.data != null) {
        _statistics = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load statistics: ${e.toString()}');
    }
  }

  // Salary Report
  Future<void> loadSalaryReport() async {
    try {
      final response = await _laborService.getSalaryReport();
      if (response.success && response.data != null) {
        _salaryReport = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load salary report: ${e.toString()}');
    }
  }

  // Demographics Report
  Future<void> loadDemographicsReport() async {
    try {
      final response = await _laborService.getDemographicsReport();
      if (response.success && response.data != null) {
        _demographicsReport = response.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load demographics report: ${e.toString()}');
    }
  }

  // Bulk operations
  Future<bool> bulkActivateLabors(List<String> laborIds) async {
    return await _performBulkAction(laborIds, 'activate');
  }

  Future<bool> bulkDeactivateLabors(List<String> laborIds) async {
    return await _performBulkAction(laborIds, 'deactivate');
  }

  Future<bool> bulkUpdateSalary(List<String> laborIds, {double? amount, double? percentage}) async {
    _setLoading(true);

    try {
      final response = await _laborService.bulkLaborActions(
        laborIds: laborIds,
        action: 'update_salary',
        salaryAmount: amount,
        salaryPercentage: percentage,
      );

      if (response.success) {
        await refreshLabors();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to update salaries: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _performBulkAction(List<String> laborIds, String action) async {
    _setLoading(true);

    try {
      final response = await _laborService.bulkLaborActions(laborIds: laborIds, action: action);

      if (response.success) {
        await refreshLabors();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to perform bulk action: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Duplicate labor
  Future<bool> duplicateLabor({
    required String id,
    required String newName,
    required String newPhone,
    required String newCnic,
    int? newAge,
  }) async {
    _setLoading(true);

    try {
      final response = await _laborService.duplicateLabor(
        id: id,
        newName: newName,
        newPhone: newPhone,
        newCnic: newCnic,
        newAge: newAge,
      );

      if (response.success) {
        await refreshLabors();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to duplicate labor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update labor contact
  Future<bool> updateLaborContact({
    required String id,
    String? phoneNumber,
    String? city,
    String? area,
  }) async {
    try {
      final response = await _laborService.updateLaborContact(
        id: id,
        phoneNumber: phoneNumber,
        city: city,
        area: area,
      );

      if (response.success) {
        await refreshLabors();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to update labor contact: ${e.toString()}');
      return false;
    }
  }

  // Update labor salary
  Future<bool> updateLaborSalary({required String id, double? salary, String? designation}) async {
    try {
      final response = await _laborService.updateLaborSalary(
        id: id,
        salary: salary,
        designation: designation,
      );

      if (response.success) {
        await refreshLabors();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to update labor salary: ${e.toString()}');
      return false;
    }
  }

  // Validate labor data before submission
  Map<String, String> validateLaborData({
    required String name,
    required String cnic,
    required String phoneNumber,
    required String designation,
    required DateTime joiningDate,
    required double salary,
    required String area,
    required String city,
    required String gender,
    required int age,
    required double fixedIncentive,
  }) {
    final errors = <String, String>{};

    // Name validation
    if (name.trim().isEmpty) {
      errors['name'] = 'Labor name is required';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Labor name must be at least 2 characters';
    }

    // CNIC validation (Now optional)
    if (cnic.trim().isNotEmpty) {
      if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(cnic.trim())) {
        errors['cnic'] = 'CNIC format should be XXXXX-XXXXXXX-X';
      } else if (_labors.any((labor) => labor.cnic == cnic.trim())) {
        errors['cnic'] = 'A labor with this CNIC already exists';
      }
    }

    // Phone validation
    if (phoneNumber.trim().isEmpty) {
      errors['phoneNumber'] = 'Phone number is required';
    } else if (phoneNumber.trim().length < 10) {
      errors['phoneNumber'] = 'Phone number must be at least 10 digits';
    } else if (_labors.any((labor) => labor.phoneNumber == phoneNumber.trim())) {
      errors['phoneNumber'] = 'A labor with this phone number already exists';
    }

    // Designation validation
    if (designation.trim().isEmpty) {
      errors['designation'] = 'Designation is required';
    }

    // Joining date validation
    if (joiningDate.isAfter(DateTime.now())) {
      errors['joiningDate'] = 'Joining date cannot be in the future';
    }

    // Salary validation
    if (salary <= 0) {
      errors['salary'] = 'Salary must be greater than zero';
    }

    // Area validation
    if (area.trim().isEmpty) {
      errors['area'] = 'Area is required';
    }

    // City validation
    if (city.trim().isEmpty) {
      errors['city'] = 'City is required';
    }

    // FIXED: Gender validation using backend's expected codes
    if (gender.trim().isEmpty) {
      errors['gender'] = 'Gender is required';
    } else {
      // Validate that gender is one of the expected codes
      final validGenders = ['M', 'F', 'O'];
      if (!validGenders.contains(gender.trim())) {
        errors['gender'] = 'Gender must be M, F, or O';
      }
    }

    // Age validation
    if (age <= 0) {
      errors['age'] = 'Age must be greater than zero';
    } else if (age < 18) {
      errors['age'] = 'Age must be at least 18';
    }

    return errors;
  }

  // Add helper methods for gender display/conversion
  String getGenderDisplayName(String genderCode) {
    switch (genderCode) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return genderCode;
    }
  }

  String getGenderCode(String displayName) {
    switch (displayName) {
      case 'Male':
        return 'M';
      case 'Female':
        return 'F';
      case 'Other':
        return 'O';
      default:
        return displayName;
    }
  }

  // Update availableGenders getter to return display names
  List<String> get availableGenders {
    return _labors
        .map((labor) => getGenderDisplayName(labor.gender))
        .where((gender) => gender.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  // Export functionality (placeholder)
  Future<void> exportData() async {
    // Implement export functionality
    // This could export to CSV, Excel, PDF, etc.
    try {
      // For now, just simulate export
      await Future.delayed(Duration(seconds: 1));
      // In real implementation, you might use packages like csv, excel, pdf, etc.
    } catch (e) {
      _setError('Failed to export data: ${e.toString()}');
    }
  }

  // Get unique values for filters (from current data)
  List<String> get availableCities {
    return _labors.map((labor) => labor.city).where((city) => city.isNotEmpty).toSet().toList()..sort();
  }

  List<String> get availableAreas {
    return _labors.map((labor) => labor.area).where((area) => area.isNotEmpty).toSet().toList()..sort();
  }

  List<String> get availableDesignations {
    return _labors.map((labor) => labor.designation).where((designation) => designation.isNotEmpty).toSet().toList()..sort();
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
}
