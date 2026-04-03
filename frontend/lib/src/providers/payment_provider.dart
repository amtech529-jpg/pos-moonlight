import 'package:flutter/material.dart';
import '../models/payment/payment_model.dart';
import '../models/payment/payment_request_models.dart';
import '../models/payment/payment_response_models.dart';
import '../services/payment_service.dart';
import '../services/labor/labor_service.dart';
import '../models/labor/labor_model.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final LaborService _laborService = LaborService();

  // State variables
  List<PaymentModel> _payments = [];
  PaymentStatisticsResponse? _statistics;
  PaymentSummaryResponse? _summary;
  bool _isLoading = false;
  String? _error;
  String? _success;
  PaginationInfo? _pagination;

  // Filter state variables
  String? _selectedLaborId;
  String? _selectedPayerType;
  String? _selectedPaymentMethod;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  DateTime? _paymentMonthFrom;
  DateTime? _paymentMonthTo;
  double? _minAmount;
  double? _maxAmount;
  bool? _hasReceipt;
  bool? _isFinalPayment;
  String _sortBy = 'date';
  bool _sortAscending = false;
  bool _showInactive = false;
  String _searchQuery = '';

  // Data lists
  List<PaymentLabor> _laborers = [];
  List<String> _payerTypes = ['LABOR', 'VENDOR', 'CUSTOMER', 'OTHER'];
  List<String> _paymentMethods = ['CASH', 'BANK_TRANSFER', 'MOBILE_PAYMENT', 'CHECK', 'CARD', 'OTHER'];
  List<LaborModel> _labors = [];

  // Getters
  List<PaymentModel> get payments => _payments;
  PaymentStatisticsResponse? get statistics => _statistics;
  PaymentSummaryResponse? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;
  PaginationInfo? get pagination => _pagination;
  List<LaborModel> get labors => _labors;

  // Filter getters
  String? get selectedLaborId => _selectedLaborId;
  String? get selectedPayerType => _selectedPayerType;
  String? get selectedPaymentMethod => _selectedPaymentMethod;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  DateTime? get paymentMonthFrom => _paymentMonthFrom;
  DateTime? get paymentMonthTo => _paymentMonthTo;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  bool? get hasReceipt => _hasReceipt;
  bool? get isFinalPayment => _isFinalPayment;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  bool get showInactive => _showInactive;
  String get searchQuery => _searchQuery;

  // Data getters
  List<PaymentLabor> get laborers => _laborers;
  List<String> get payerTypes => _payerTypes;
  List<String> get paymentMethods => _paymentMethods;

  // Static lists for UI
  static const List<String> staticPayerTypes = ['LABOR', 'VENDOR', 'CUSTOMER', 'OTHER'];
  static const List<String> staticPaymentMethods = ['CASH', 'BANK_TRANSFER', 'MOBILE_PAYMENT', 'CHECK', 'CARD', 'OTHER'];

  // Computed properties
  String? get errorMessage => _error;
  bool get hasReceiptFilter => _hasReceipt != null;
  bool get isFinalPaymentFilter => _isFinalPayment != null;

  // Payment statistics (alias for statistics)
  PaymentStatisticsResponse? get paymentStats => _statistics;

  // ===== PAYMENT MANAGEMENT =====

  /// Load payments with filtering
  Future<void> loadPayments({PaymentFilterRequest? filter, bool refresh = false}) async {
    // Always load if refresh is explicitly true or if payments list is empty
    if (!refresh && _payments.isNotEmpty) return;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.getPayments(filter: filter);
      debugPrint('🔍 Payment Provider Response: success=${response.success}, payments=${response.data?.payments.length ?? 0}');
      if (response.success && response.data != null) {
        _payments = response.data!.payments;
        _pagination = response.data!.pagination;
        debugPrint('💾 Loaded ${_payments.length} payments into provider');
        _computeStatistics(); // Compute statistics after loading payments
        _setSuccess(response.message);
      } else {
        debugPrint('❌ Failed to load payments: ${response.message}');
        _setError(response.message);
      }
    } catch (e) {
      debugPrint('💥 Error loading payments: $e');
      _setError('Error loading payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String id) async {
    try {
      final response = await _paymentService.getPaymentById(id);
      if (response.success && response.data != null) {
        return response.data;
      } else {
        _setError(response.message);
        return null;
      }
    } catch (e) {
      _setError('Error getting payment: $e');
      return null;
    }
  }

  /// Create new payment
  Future<bool> createPayment(CreatePaymentRequest request) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.createPayment(request);
      if (response.success && response.data != null) {
        _payments.insert(0, response.data!);
        _computeStatistics(); // Update statistics after creating payment
        _setSuccess('Payment created successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error creating payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update payment
  Future<bool> updatePayment({
    required String id,
    String? laborId,
    String? vendorId,
    String? orderId,
    String? saleId,
    required double amountPaid,
    double? bonus,
    double? deduction,
    required DateTime paymentMonth,
    bool? isFinalPayment,
    required String paymentMethod,
    String? description,
    required DateTime date,
    required DateTime time,
    String? receiptImagePath,
    String? payerType,
    String? payerId,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Convert DateTime to TimeOfDay for the request
      final timeOfDay = TimeOfDay(hour: time.hour, minute: time.minute);

      // Create UpdatePaymentRequest from parameters
      final request = UpdatePaymentRequest(
        laborId: laborId,
        vendorId: vendorId,
        orderId: orderId,
        saleId: saleId,
        amountPaid: amountPaid,
        bonus: bonus ?? 0.0,
        deduction: deduction ?? 0.0,
        paymentMonth: paymentMonth,
        isFinalPayment: isFinalPayment ?? false,
        paymentMethod: paymentMethod,
        description: description,
        date: date,
        time: timeOfDay,
        receiptImagePath: receiptImagePath,
        payerType: payerType ?? 'LABOR',
        payerId: payerId,
      );

      final response = await _paymentService.updatePayment(id, request);
      if (response.success && response.data != null) {
        final index = _payments.indexWhere((p) => p.id == id);
        if (index != -1) {
          _payments[index] = response.data!;
          _computeStatistics(); // Update statistics after updating payment
          notifyListeners();
        }
        _setSuccess('Payment updated successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error updating payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete payment
  Future<bool> deletePayment(String id) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.deletePayment(id);
      if (response.success) {
        _payments.removeWhere((p) => p.id == id);
        _computeStatistics(); // Update statistics after deleting payment
        _setSuccess('Payment deleted successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error deleting payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Soft delete payment
  Future<bool> softDeletePayment(String id) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.softDeletePayment(id);
      if (response.success) {
        final index = _payments.indexWhere((p) => p.id == id);
        if (index != -1) {
          _payments[index] = _payments[index].copyWith(isActive: false);
          _computeStatistics(); // Update statistics after soft deleting payment
          notifyListeners();
        }
        _setSuccess('Payment soft deleted successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error soft deleting payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Restore payment
  Future<bool> restorePayment(String id) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.restorePayment(id);
      if (response.success) {
        final index = _payments.indexWhere((p) => p.id == id);
        if (index != -1) {
          _payments[index] = _payments[index].copyWith(isActive: true);
          _computeStatistics(); // Update statistics after restoring payment
          notifyListeners();
        }
        _setSuccess('Payment restored successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error restoring payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search payments
  Future<void> searchPayments(String query) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.searchPayments(query);
      if (response.success && response.data != null) {
        _payments = response.data!.payments;
        _pagination = response.data!.pagination;
        _computeStatistics(); // Update statistics after search
        _setSuccess('Search completed');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error searching payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get payments by labor
  Future<void> getPaymentsByLabor(String laborId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.getPaymentsByLabor(laborId);
      if (response.success && response.data != null) {
        _payments = response.data!.payments;
        _pagination = response.data!.pagination;
        _setSuccess('Labor payments loaded');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading labor payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get payments by vendor
  Future<void> getPaymentsByVendor(String vendorId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.getPaymentsByVendor(vendorId);
      if (response.success && response.data != null) {
        _payments = response.data!.payments;
        _pagination = response.data!.pagination;
        _setSuccess('Vendor payments loaded');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading vendor payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get payments by sale
  Future<void> getPaymentsBySale(String saleId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.getPaymentsBySale(saleId);
      if (response.success && response.data != null) {
        _payments = response.data!.payments;
        _pagination = response.data!.pagination;
        _setSuccess('Sale payments loaded');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading sale payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get payments by date range
  Future<void> getPaymentsByDateRange(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.getPaymentsByDateRange(startDate, endDate);
      if (response.success && response.data != null) {
        _payments = response.data!.payments;
        _pagination = response.data!.pagination;
        _setSuccess('Date range payments loaded');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading date range payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get payments by method
  Future<void> getPaymentsByMethod(String method) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.getPaymentsByMethod(method);
      if (response.success && response.data != null) {
        _payments = response.data!.payments;
        _pagination = response.data!.pagination;
        _setSuccess('Method payments loaded');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading method payments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mark payment as final
  Future<bool> markAsFinalPayment(String id) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.markAsFinalPayment(id);
      if (response.success) {
        final index = _payments.indexWhere((p) => p.id == id);
        if (index != -1) {
          _payments[index] = _payments[index].copyWith(isFinalPayment: true);
          notifyListeners();
        }
        _setSuccess('Payment marked as final');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error marking payment as final: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ===== PAYMENT PROCESSING =====

  /// Process payment for sale
  Future<bool> processSalePayment({
    required String saleId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.processPayment(
        saleId: saleId,
        amount: amount,
        paymentMethod: paymentMethod,
        currency: 'PKR',
        reference: reference,
        notes: notes,
      );

      if (response.success) {
        _setSuccess('Payment processed successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error processing payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Process split payment
  Future<bool> processSplitPayment({
    required String saleId,
    required List<Map<String, dynamic>> splitDetails,
    String? reference,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _paymentService.processSplitPayment(
        saleId: saleId,
        splitDetails: splitDetails,
        currency: 'PKR',
        reference: reference,
        notes: notes,
      );

      if (response.success) {
        _setSuccess('Split payment processed successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error processing split payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ===== FILTER METHODS =====

  /// Set labor filter
  void setLaborFilter(String? laborId) {
    _selectedLaborId = laborId;
    notifyListeners();
  }

  /// Set payer type filter
  void setPayerTypeFilter(String? payerType) {
    _selectedPayerType = payerType;
    notifyListeners();
  }

  /// Set payment method filter
  void setPaymentMethodFilter(String? paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }

  /// Set date range filter
  void setDateRangeFilter(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  /// Set payment month range filter
  void setPaymentMonthRangeFilter(DateTime? from, DateTime? to) {
    _paymentMonthFrom = from;
    _paymentMonthTo = to;
    notifyListeners();
  }

  /// Set amount range filter
  void setAmountRangeFilter(double? min, double? max) {
    _minAmount = min;
    _maxAmount = max;
    notifyListeners();
  }

  /// Set receipt filter
  void setReceiptFilter(bool? hasReceipt) {
    _hasReceipt = hasReceipt;
    notifyListeners();
  }

  /// Set final payment filter
  void setFinalPaymentFilter(bool? isFinal) {
    _isFinalPayment = isFinal;
    notifyListeners();
  }

  /// Set sort options
  void setSortOptions(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    notifyListeners();
  }

  /// Set show inactive filter
  void setShowInactiveFilter(bool show) {
    _showInactive = show;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Reset all filters
  void resetFilters() {
    _selectedLaborId = null;
    _selectedPayerType = null;
    _selectedPaymentMethod = null;
    _dateFrom = null;
    _dateTo = null;
    _paymentMonthFrom = null;
    _paymentMonthTo = null;
    _minAmount = null;
    _maxAmount = null;
    _hasReceipt = null;
    _isFinalPayment = null;
    _sortBy = 'date';
    _sortAscending = false;
    _showInactive = false;
    _searchQuery = '';
    notifyListeners();
  }

  // ===== UTILITY METHODS =====

  /// Clear all messages
  void _clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Set success message
  void _setSuccess(String message) {
    _success = message;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear success
  void clearSuccess() {
    _success = null;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadPayments(refresh: true);
  }

  /// Initialize provider
  Future<void> initialize() async {
    await loadPayments(refresh: true);
  }

  /// Refresh data (alias for refresh)
  Future<void> refreshData() async {
    await refresh();
  }

  /// Add payment with individual parameters
  Future<bool> addPayment({
    String? laborId,
    String? vendorId,
    String? orderId,
    String? saleId,
    required String payerType,
    String? payerId,
    String? laborName,
    String? laborPhone,
    String? laborRole,
    required double amountPaid,
    double? bonus,
    double? deduction,
    required String paymentMonth,
    bool? isFinalPayment,
    required String paymentMethod,
    String? description,
    required DateTime date,
    required TimeOfDay time,
    String? receiptImagePath,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Parse paymentMonth string to DateTime
      final paymentMonthDateTime = DateTime.parse(paymentMonth);

      // Create CreatePaymentRequest from parameters
      final request = CreatePaymentRequest(
        laborId: laborId,
        vendorId: vendorId,
        orderId: orderId,
        saleId: saleId,
        payerType: payerType,
        payerId: payerId,
        laborName: laborName,
        laborPhone: laborPhone,
        laborRole: laborRole,
        amountPaid: amountPaid,
        bonus: bonus ?? 0.0,
        deduction: deduction ?? 0.0,
        paymentMonth: paymentMonthDateTime,
        isFinalPayment: isFinalPayment ?? false,
        paymentMethod: paymentMethod,
        description: description,
        date: date,
        time: time,
        receiptImagePath: receiptImagePath,
      );

      final response = await _paymentService.createPayment(request);
      if (response.success && response.data != null) {
        _payments.insert(0, response.data!);
        _computeStatistics(); // Update statistics after creating payment
        _setSuccess('Payment created successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error creating payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load laborers (FIXED: Handles 0 remaining salary)
  Future<void> loadLaborers() async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _laborService.getLabors();
      if (response.success && response.data != null) {
        _labors = response.data!.labors;

        _laborers = _labors.map((labor) {
          // Use remainingMonthlySalary if available and > 0
          // Otherwise, use full salary (assuming no payments yet or new month)
          final displayAmount = (labor.remainingMonthlySalary != null && labor.remainingMonthlySalary > 0)
              ? labor.remainingMonthlySalary
              : labor.salary;

          return PaymentLabor(
            id: labor.id,
            name: labor.name,
            role: labor.designation,
            remainingAmount: displayAmount,
            phone: labor.formattedPhone,
          );
        }).toList();

        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading laborers: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Compute statistics from loaded payments
  void _computeStatistics() {
    if (_payments.isEmpty) {
      _statistics = null;
      return;
    }

    double totalAmountPaid = 0.0;
    double totalBonus = 0.0;
    double totalDeduction = 0.0;
    int totalPayments = _payments.length;

    // Initialize distribution maps
    Map<String, int> payerTypeDistribution = {};
    Map<String, int> paymentMethodDistribution = {};
    Map<String, double> monthlyDistribution = {};
    Map<String, double> dailyDistribution = {};
    List<Map<String, dynamic>> recentPayments = [];
    Map<String, double> topPayers = {};

    for (final payment in _payments) {
      totalAmountPaid += payment.amountPaid;
      totalBonus += payment.bonus ?? 0.0;
      totalDeduction += payment.deduction ?? 0.0;

      // Payer type distribution
      final payerType = payment.payerType ?? 'LABOR';
      payerTypeDistribution[payerType] = (payerTypeDistribution[payerType] ?? 0) + 1;

      // Payment method distribution
      final paymentMethod = payment.paymentMethod;
      paymentMethodDistribution[paymentMethod] = (paymentMethodDistribution[paymentMethod] ?? 0) + 1;

      // Monthly distribution (by payment month)
      final monthKey = '${payment.paymentMonth.year}-${payment.paymentMonth.month.toString().padLeft(2, '0')}';
      monthlyDistribution[monthKey] = (monthlyDistribution[monthKey] ?? 0.0) + payment.amountPaid;

      // Daily distribution (by payment date)
      final dayKey = '${payment.date.year}-${payment.date.month.toString().padLeft(2, '0')}-${payment.date.day.toString().padLeft(2, '0')}';
      dailyDistribution[dayKey] = (dailyDistribution[dayKey] ?? 0.0) + payment.amountPaid;

      // Top payers (by total amount)
      final payerId = payment.payerId ?? payment.laborId ?? 'Unknown';
      topPayers[payerId] = (topPayers[payerId] ?? 0.0) + payment.amountPaid;
    }

    // Get recent payments (last 5)
    final sortedPayments = List<PaymentModel>.from(_payments)..sort((a, b) => b.date.compareTo(a.date));

    recentPayments = sortedPayments
        .take(5)
        .map(
          (payment) => {
        'id': payment.id,
        'amount': payment.amountPaid,
        'date': payment.date.toIso8601String(),
        'method': payment.paymentMethod,
        'payer_type': payment.payerType ?? 'LABOR',
      },
    )
        .toList();

    // Sort top payers by amount
    final sortedTopPayers = Map.fromEntries(topPayers.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    final top5Payers = Map.fromEntries(sortedTopPayers.entries.take(5));

    final netAmount = totalAmountPaid + totalBonus - totalDeduction;

    _statistics = PaymentStatisticsResponse(
      totalPayments: totalPayments,
      totalAmountPaid: totalAmountPaid,
      totalBonus: totalBonus,
      totalDeduction: totalDeduction,
      netAmount: netAmount,
      payerTypeDistribution: payerTypeDistribution,
      paymentMethodDistribution: paymentMethodDistribution,
      monthlyDistribution: monthlyDistribution,
      dailyDistribution: dailyDistribution,
      recentPayments: recentPayments,
      topPayers: top5Payers,
    );

    notifyListeners();
  }

  // ===== STATISTICS METHODS =====

  /// Load payment statistics
  Future<void> loadStatistics() async {
    _setLoading(true);
    _clearMessages();

    try {
      // If we have payments loaded, compute statistics from them
      if (_payments.isNotEmpty) {
        _computeStatistics();
      } else {
        // Load payments first, then compute statistics
        await loadPayments(refresh: true);
        _computeStatistics();
      }
    } catch (e) {
      _setError('Error loading statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get this month's payments count
  int getThisMonthPayments() {
    if (_payments.isEmpty) return 0;

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return _payments.where((payment) {
      final paymentMonth = DateTime(payment.paymentMonth.year, payment.paymentMonth.month);
      return paymentMonth.isAtSameMomentAs(thisMonth);
    }).length;
  }

  /// Get this week's payments count
  int getThisWeekPayments() {
    if (_payments.isEmpty) return 0;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _payments.where((payment) {
      return payment.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && payment.date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).length;
  }

  /// Get this month's total payment amount
  double getThisMonthAmount() {
    if (_payments.isEmpty) return 0.0;

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return _payments
        .where((payment) {
      final paymentMonth = DateTime(payment.paymentMonth.year, payment.paymentMonth.month);
      return paymentMonth.isAtSameMomentAs(thisMonth);
    })
        .fold(0.0, (sum, payment) => sum + payment.amountPaid);
  }

  /// Get this week's total payment amount
  double getThisWeekAmount() {
    if (_payments.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _payments
        .where((payment) {
      return payment.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) && payment.date.isBefore(endOfWeek.add(const Duration(days: 1)));
    })
        .fold(0.0, (sum, payment) => sum + payment.amountPaid);
  }
}