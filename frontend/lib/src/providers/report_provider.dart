import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  List<dynamic> _topCustomers = [];
  List<dynamic> _topProducts = [];
  List<dynamic> _revenueData = [];
  List<dynamic> _monthlyRevenue = [];
  Map<String, dynamic> _businessSummary = {};
  List<dynamic> _toolUsageTrends = [];
  List<dynamic> _toolUsageHistory = [];
  List<dynamic> _reorderHistory = [];
  bool _isLoading = false;

  List<dynamic> get topCustomers => _topCustomers;
  List<dynamic> get topProducts => _topProducts;
  List<dynamic> get revenueData => _revenueData;
  List<dynamic> get monthlyRevenue => _monthlyRevenue;
  Map<String, dynamic> get businessSummary => _businessSummary;
  List<dynamic> get toolUsageTrends => _toolUsageTrends;
  List<dynamic> get toolUsageHistory => _toolUsageHistory;
  List<dynamic> get reorderHistory => _reorderHistory;
  bool get isLoading => _isLoading;

  Future<void> fetchAllReports({int toolMonths = 6}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getTopCustomers(),
        _service.getTopProducts(),
        _service.getRevenueReport(),
        _service.getToolUsageReport(months: toolMonths),
        _service.getMonthlyRevenueReport(),
        _service.getBusinessPerformance(),
      ]);

      _topCustomers = results[0] as List<dynamic>;
      _topProducts = results[1] as List<dynamic>;
      _revenueData = results[2] as List<dynamic>;
      
      final toolData = results[3] as Map<String, dynamic>;
      _toolUsageTrends = toolData['monthly_usage'] ?? [];
      _toolUsageHistory = toolData['recent_history'] ?? [];
      _reorderHistory = toolData['reorder_history'] ?? [];

      _monthlyRevenue = results[4] as List<dynamic>;
      _businessSummary = results[5] as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchToolUsageReport({int months = 6}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final toolData = await _service.getToolUsageReport(months: months);
      _toolUsageTrends = toolData['monthly_usage'] ?? [];
      _toolUsageHistory = toolData['recent_history'] ?? [];
      _reorderHistory = toolData['reorder_history'] ?? [];
    } catch (e) {
      debugPrint("Error fetching tool usage report: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
