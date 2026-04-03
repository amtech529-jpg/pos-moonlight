import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  // State variables
  bool _isLoading = false;
  String? _error;
  String? _success;

  // Analytics data
  Map<String, dynamic>? _salesAnalytics;
  Map<String, dynamic>? _salesTrends;
  Map<String, dynamic>? _customerAnalytics;
  Map<String, dynamic>? _productAnalytics;
  Map<String, dynamic>? _financialAnalytics;
  Map<String, dynamic>? _revenueAnalytics;
  Map<String, dynamic>? _profitMarginAnalytics;
  Map<String, dynamic>? _taxAnalytics;
  Map<String, dynamic>? _performanceAnalytics;
  Map<String, dynamic>? _dashboardAnalytics;
  Map<String, dynamic>? _realTimeAnalytics;

  // Reporting data
  List<Map<String, dynamic>> _reportTemplates = [];
  Map<String, dynamic>? _lastGeneratedReport;
  Map<String, dynamic>? _lastExportedData;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;

  // Analytics getters
  Map<String, dynamic>? get salesAnalytics => _salesAnalytics;
  Map<String, dynamic>? get salesTrends => _salesTrends;
  Map<String, dynamic>? get customerAnalytics => _customerAnalytics;
  Map<String, dynamic>? get productAnalytics => _productAnalytics;
  Map<String, dynamic>? get financialAnalytics => _financialAnalytics;
  Map<String, dynamic>? get revenueAnalytics => _revenueAnalytics;
  Map<String, dynamic>? get profitMarginAnalytics => _profitMarginAnalytics;
  Map<String, dynamic>? get taxAnalytics => _taxAnalytics;
  Map<String, dynamic>? get performanceAnalytics => _performanceAnalytics;
  Map<String, dynamic>? get dashboardAnalytics => _dashboardAnalytics;
  Map<String, dynamic>? get realTimeAnalytics => _realTimeAnalytics;

  // Reporting getters
  List<Map<String, dynamic>> get reportTemplates => _reportTemplates;
  Map<String, dynamic>? get lastGeneratedReport => _lastGeneratedReport;
  Map<String, dynamic>? get lastExportedData => _lastExportedData;

  // ===== SALES ANALYTICS =====

  /// Load sales analytics
  Future<void> loadSalesAnalytics({
    String? dateFrom,
    String? dateTo,
    String? groupBy,
    String? customerId,
    String? productId,
    String? paymentMethod,
  }) async {
    try {
      final response = await _analyticsService.getSalesAnalytics(
        dateFrom: dateFrom,
        dateTo: dateTo,
        groupBy: groupBy,
        customerId: customerId,
        productId: productId,
        paymentMethod: paymentMethod,
      );

      if (response.success && response.data != null) {
        _salesAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading sales analytics: $e');
    }
  }

  /// Load sales trends
  Future<void> loadSalesTrends({String? dateFrom, String? dateTo, String? period, String? metric}) async {
    try {
      final response = await _analyticsService.getSalesTrends(dateFrom: dateFrom, dateTo: dateTo, period: period, metric: metric);

      if (response.success && response.data != null) {
        _salesTrends = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading sales trends: $e');
    }
  }

  /// Load customer analytics
  Future<void> loadCustomerAnalytics({String? dateFrom, String? dateTo, String? customerId, String? groupBy}) async {
    try {
      final response = await _analyticsService.getCustomerAnalytics(dateFrom: dateFrom, dateTo: dateTo, customerId: customerId, groupBy: groupBy);

      if (response.success && response.data != null) {
        _customerAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading customer analytics: $e');
    }
  }

  /// Load product analytics
  Future<void> loadProductAnalytics({String? dateFrom, String? dateTo, String? productId, String? categoryId, String? groupBy}) async {
    try {
      final response = await _analyticsService.getProductAnalytics(
        dateFrom: dateFrom,
        dateTo: dateTo,
        productId: productId,
        categoryId: categoryId,
        groupBy: groupBy,
      );

      if (response.success && response.data != null) {
        _productAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading product analytics: $e');
    }
  }

  // ===== FINANCIAL ANALYTICS =====

  /// Load financial analytics
  Future<void> loadFinancialAnalytics({String? dateFrom, String? dateTo, String? groupBy, String? currency}) async {
    try {
      final response = await _analyticsService.getFinancialAnalytics(dateFrom: dateFrom, dateTo: dateTo, groupBy: groupBy, currency: currency);

      if (response.success && response.data != null) {
        _financialAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading financial analytics: $e');
    }
  }

  /// Load revenue analytics
  Future<void> loadRevenueAnalytics({String? dateFrom, String? dateTo, String? groupBy, String? source}) async {
    try {
      final response = await _analyticsService.getRevenueAnalytics(dateFrom: dateFrom, dateTo: dateTo, groupBy: groupBy, source: source);

      if (response.success && response.data != null) {
        _revenueAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading revenue analytics: $e');
    }
  }

  /// Load profit margin analytics
  Future<void> loadProfitMarginAnalytics({String? dateFrom, String? dateTo, String? groupBy, String? productCategory}) async {
    try {
      final response = await _analyticsService.getProfitMarginAnalytics(
        dateFrom: dateFrom,
        dateTo: dateTo,
        groupBy: groupBy,
        productCategory: productCategory,
      );

      if (response.success && response.data != null) {
        _profitMarginAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading profit margin analytics: $e');
    }
  }

  // ===== TAX ANALYTICS =====

  /// Load tax analytics
  Future<void> loadTaxAnalytics({String? dateFrom, String? dateTo, String? taxType, String? groupBy}) async {
    try {
      final response = await _analyticsService.getTaxAnalytics(dateFrom: dateFrom, dateTo: dateTo, taxType: taxType, groupBy: groupBy);

      if (response.success && response.data != null) {
        _taxAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading tax analytics: $e');
    }
  }

  // ===== PERFORMANCE ANALYTICS =====

  /// Load performance analytics
  Future<void> loadPerformanceAnalytics({String? dateFrom, String? dateTo, String? metric, String? groupBy}) async {
    try {
      final response = await _analyticsService.getPerformanceAnalytics(dateFrom: dateFrom, dateTo: dateTo, metric: metric, groupBy: groupBy);

      if (response.success && response.data != null) {
        _performanceAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading performance analytics: $e');
    }
  }

  // ===== DASHBOARD ANALYTICS =====

  /// Load dashboard analytics
  Future<void> loadDashboardAnalytics({String? dateRange, List<String>? metrics}) async {
    try {
      final response = await _analyticsService.getDashboardAnalytics(dateRange: dateRange, metrics: metrics);

      if (response.success && response.data != null) {
        _dashboardAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading dashboard analytics: $e');
    }
  }

  /// Load real-time analytics
  Future<void> loadRealTimeAnalytics({List<String>? metrics, String? interval}) async {
    try {
      final response = await _analyticsService.getRealTimeAnalytics(metrics: metrics, interval: interval);

      if (response.success && response.data != null) {
        _realTimeAnalytics = response.data;
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading real-time analytics: $e');
    }
  }

  // ===== REPORTING =====

  /// Generate comprehensive report
  Future<bool> generateReport({required String reportType, String? dateFrom, String? dateTo, Map<String, dynamic>? filters, String? format}) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _analyticsService.generateReport(
        reportType: reportType,
        dateFrom: dateFrom,
        dateTo: dateTo,
        filters: filters,
        format: format,
      );

      if (response.success && response.data != null) {
        _lastGeneratedReport = response.data;
        _setSuccess('Report generated successfully');
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error generating report: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Load report templates
  Future<void> loadReportTemplates() async {
    try {
      final response = await _analyticsService.getReportTemplates();
      if (response.success && response.data != null) {
        _reportTemplates = response.data ?? [];
        notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading report templates: $e');
    }
  }

  /// Export analytics data
  Future<bool> exportAnalyticsData({
    required String dataType,
    String? dateFrom,
    String? dateTo,
    Map<String, dynamic>? filters,
    String? format,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _analyticsService.exportAnalyticsData(
        dataType: dataType,
        dateFrom: dateFrom,
        dateTo: dateTo,
        filters: filters,
        format: format,
      );

      if (response.success && response.data != null) {
        _lastExportedData = response.data;
        _setSuccess('Data exported successfully');
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error exporting analytics data: $e');
      _setLoading(false);
      return false;
    }
  }

  // ===== UTILITY METHODS =====

  /// Get analytics data by type
  Map<String, dynamic>? getAnalyticsByType(String type) {
    switch (type.toLowerCase()) {
      case 'sales':
        return _salesAnalytics;
      case 'sales_trends':
        return _salesTrends;
      case 'customer':
        return _customerAnalytics;
      case 'product':
        return _productAnalytics;
      case 'financial':
        return _financialAnalytics;
      case 'revenue':
        return _revenueAnalytics;
      case 'profit_margin':
        return _profitMarginAnalytics;
      case 'tax':
        return _taxAnalytics;
      case 'performance':
        return _performanceAnalytics;
      case 'dashboard':
        return _dashboardAnalytics;
      case 'real_time':
        return _realTimeAnalytics;
      default:
        return null;
    }
  }

  /// Check if analytics data is available
  bool hasAnalyticsData(String type) {
    return getAnalyticsByType(type) != null;
  }

  /// Get report template by ID
  Map<String, dynamic>? getReportTemplateById(String id) {
    try {
      return _reportTemplates.firstWhere((template) => template['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Get report template by name
  Map<String, dynamic>? getReportTemplateByName(String name) {
    try {
      return _reportTemplates.firstWhere((template) => template['name'] == name);
    } catch (e) {
      return null;
    }
  }

  // ===== STATE MANAGEMENT =====

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _success = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _success = success;
    _error = null;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSuccess() {
    _success = null;
    notifyListeners();
  }

  void clearLastGeneratedReport() {
    _lastGeneratedReport = null;
    notifyListeners();
  }

  void clearLastExportedData() {
    _lastExportedData = null;
    notifyListeners();
  }

  /// Initialize provider
  Future<void> initialize() async {
    await Future.wait([loadReportTemplates(), loadDashboardAnalytics()]);
  }

  /// Refresh all analytics data
  Future<void> refreshAllAnalytics() async {
    await Future.wait([
      loadSalesAnalytics(),
      loadSalesTrends(),
      loadCustomerAnalytics(),
      loadProductAnalytics(),
      loadFinancialAnalytics(),
      loadRevenueAnalytics(),
      loadProfitMarginAnalytics(),
      loadTaxAnalytics(),
      loadPerformanceAnalytics(),
      loadDashboardAnalytics(),
      loadRealTimeAnalytics(),
    ]);
  }

  /// Refresh specific analytics
  Future<void> refreshAnalytics(String type) async {
    switch (type.toLowerCase()) {
      case 'sales':
        await loadSalesAnalytics();
        break;
      case 'sales_trends':
        await loadSalesTrends();
        break;
      case 'customer':
        await loadCustomerAnalytics();
        break;
      case 'product':
        await loadProductAnalytics();
        break;
      case 'financial':
        await loadFinancialAnalytics();
        break;
      case 'revenue':
        await loadRevenueAnalytics();
        break;
      case 'profit_margin':
        await loadProfitMarginAnalytics();
        break;
      case 'tax':
        await loadTaxAnalytics();
        break;
      case 'performance':
        await loadPerformanceAnalytics();
        break;
      case 'dashboard':
        await loadDashboardAnalytics();
        break;
      case 'real_time':
        await loadRealTimeAnalytics();
        break;
    }
  }
}
