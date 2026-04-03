import 'package:flutter/material.dart';

// Main Profit Loss Record Model
class ProfitLossRecord {
  final String id;
  final String periodType;
  final String periodTypeDisplay;
  final DateTime startDate;
  final DateTime endDate;
  final double totalSalesIncome;
  final double totalCostOfGoodsSold;
  final double totalLaborPayments;
  final double totalVendorPayments;
  final double totalExpenses;
  final double totalZakat;
  final double totalExpensesCalculated;
  final double grossProfit;
  final double grossProfitMarginPercentage;
  final double netProfit;
  final double profitMarginPercentage;
  final int totalProductsSold;
  final double averageOrderValue;
  final String? calculationNotes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  ProfitLossRecord({
    required this.id,
    required this.periodType,
    required this.periodTypeDisplay,
    required this.startDate,
    required this.endDate,
    required this.totalSalesIncome,
    required this.totalCostOfGoodsSold,
    required this.totalLaborPayments,
    required this.totalVendorPayments,
    required this.totalExpenses,
    required this.totalZakat,
    required this.totalExpensesCalculated,
    required this.grossProfit,
    required this.grossProfitMarginPercentage,
    required this.netProfit,
    required this.profitMarginPercentage,
    required this.totalProductsSold,
    required this.averageOrderValue,
    this.calculationNotes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  // Computed properties
  bool get isProfitable => netProfit > 0;

  String get formattedPeriod {
    switch (periodType.toLowerCase()) {
      case 'daily':
        return '${startDate.day}/${startDate.month}/${startDate.year}';
      case 'weekly':
        return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}/${endDate.year}';
      case 'monthly':
        return _getMonthName(startDate.month) + ' ${startDate.year}';
      case 'yearly':
        return '${startDate.year}';
      case 'custom':
        return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
      default:
        return 'Unknown Period';
    }
  }

  String _getMonthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  }

  String get formattedTotalIncome => 'PKR ${totalSalesIncome.toStringAsFixed(0)}';
  String get formattedTotalExpenses => 'PKR ${totalExpensesCalculated.toStringAsFixed(0)}';
  String get formattedNetProfit => 'PKR ${netProfit.toStringAsFixed(0)}';
  String get formattedProfitMargin => '${profitMarginPercentage.toStringAsFixed(1)}%';
  String get formattedGrossProfit => 'PKR ${grossProfit.toStringAsFixed(0)}';
  String get formattedGrossProfitMargin => '${grossProfitMarginPercentage.toStringAsFixed(1)}%';

  // Expense breakdown percentages
  double get laborPercentage => totalExpensesCalculated > 0 ? (totalLaborPayments / totalExpensesCalculated) * 100 : 0.0;
  double get vendorPercentage => totalExpensesCalculated > 0 ? (totalVendorPayments / totalExpensesCalculated) * 100 : 0.0;
  double get otherExpensesPercentage => totalExpensesCalculated > 0 ? (totalExpenses / totalExpensesCalculated) * 100 : 0.0;
  double get zakatPercentage => totalExpensesCalculated > 0 ? (totalZakat / totalExpensesCalculated) * 100 : 0.0;

  factory ProfitLossRecord.fromJson(Map<String, dynamic> json) {
    return ProfitLossRecord(
      id: json['id'] as String,
      periodType: json['period_type'] as String,
      periodTypeDisplay: json['period_type_display'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalSalesIncome: _parseDouble(json['total_sales_income']),
      totalCostOfGoodsSold: _parseDouble(json['total_cost_of_goods_sold']),
      totalLaborPayments: _parseDouble(json['total_labor_payments']),
      totalVendorPayments: _parseDouble(json['total_vendor_payments']),
      totalExpenses: _parseDouble(json['total_expenses']),
      totalZakat: _parseDouble(json['total_zakat']),
      totalExpensesCalculated: _parseDouble(json['total_expenses_calculated']),
      grossProfit: _parseDouble(json['gross_profit']),
      grossProfitMarginPercentage: _parseDouble(json['gross_profit_margin_percentage']),
      netProfit: _parseDouble(json['net_profit']),
      profitMarginPercentage: _parseDouble(json['profit_margin_percentage']),
      totalProductsSold: _parseInt(json['total_products_sold']),
      averageOrderValue: _parseDouble(json['average_order_value']),
      calculationNotes: json['calculation_notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by']?.toString(),
    );
  }

  // Helper method to safely parse numeric values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse integer values
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_type': periodType,
      'period_type_display': periodTypeDisplay,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'total_sales_income': totalSalesIncome,
      'total_cost_of_goods_sold': totalCostOfGoodsSold,
      'total_labor_payments': totalLaborPayments,
      'total_vendor_payments': totalVendorPayments,
      'total_expenses': totalExpenses,
      'total_zakat': totalZakat,
      'total_expenses_calculated': totalExpensesCalculated,
      'gross_profit': grossProfit,
      'gross_profit_margin_percentage': grossProfitMarginPercentage,
      'net_profit': netProfit,
      'profit_margin_percentage': profitMarginPercentage,
      'total_products_sold': totalProductsSold,
      'average_order_value': averageOrderValue,
      'calculation_notes': calculationNotes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}

// Request model for calculating profit and loss
class ProfitLossCalculationRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String periodType;
  final bool includeCalculations;
  final String? calculationNotes;

  ProfitLossCalculationRequest({
    required this.startDate,
    required this.endDate,
    required this.periodType,
    this.includeCalculations = true,
    this.calculationNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'period_type': periodType,
      'include_calculations': includeCalculations,
      if (calculationNotes != null) 'calculation_notes': calculationNotes,
    };
  }
}

// Response model for profit and loss list
class ProfitLossListResponse {
  final List<ProfitLossRecord> records;
  final int totalCount;

  ProfitLossListResponse({required this.records, required this.totalCount});

  factory ProfitLossListResponse.fromJson(Map<String, dynamic> json) {
    return ProfitLossListResponse(
      records: (json['records'] as List).map((recordJson) => ProfitLossRecord.fromJson(recordJson)).toList(),
      totalCount: json['total_count'] as int,
    );
  }
}

// Summary model for different periods
class ProfitLossSummary {
  final Map<String, dynamic> periodInfo;
  final double totalSalesIncome;
  final double totalCostOfGoodsSold;
  final int totalProductsSold;
  final double averageOrderValue;
  final double totalLaborPayments;
  final double totalVendorPayments;
  final double totalExpenses;
  final double totalZakat;
  final double totalExpensesCalculated;
  final double grossProfit;
  final double grossProfitMarginPercentage;
  final double netProfit;
  final double profitMarginPercentage;
  final bool isProfitable;
  final DateTime calculationTimestamp;
  final Map<String, int> sourceRecordsCount;

  ProfitLossSummary({
    required this.periodInfo,
    required this.totalSalesIncome,
    required this.totalCostOfGoodsSold,
    required this.totalProductsSold,
    required this.averageOrderValue,
    required this.totalLaborPayments,
    required this.totalVendorPayments,
    required this.totalExpenses,
    required this.totalZakat,
    required this.totalExpensesCalculated,
    required this.grossProfit,
    required this.grossProfitMarginPercentage,
    required this.netProfit,
    required this.profitMarginPercentage,
    required this.isProfitable,
    required this.calculationTimestamp,
    required this.sourceRecordsCount,
  });

  // Formatted strings
  String get formattedTotalIncome => 'PKR ${totalSalesIncome.toStringAsFixed(0)}';
  String get formattedTotalExpenses => 'PKR ${totalExpensesCalculated.toStringAsFixed(0)}';
  String get formattedNetProfit => 'PKR ${netProfit.toStringAsFixed(0)}';
  String get formattedProfitMargin => '${profitMarginPercentage.toStringAsFixed(1)}%';
  String get formattedGrossProfit => 'PKR ${grossProfit.toStringAsFixed(0)}';
  String get formattedGrossProfitMargin => '${grossProfitMarginPercentage.toStringAsFixed(1)}%';

  factory ProfitLossSummary.fromJson(Map<String, dynamic> json) {
    return ProfitLossSummary(
      periodInfo: json['period_info'] as Map<String, dynamic>,
      totalSalesIncome: _parseDouble(json['total_sales_income']),
      totalCostOfGoodsSold: _parseDouble(json['total_cost_of_goods_sold']),
      totalProductsSold: _parseInt(json['total_products_sold']),
      averageOrderValue: _parseDouble(json['average_order_value']),
      totalLaborPayments: _parseDouble(json['total_labor_payments']),
      totalVendorPayments: _parseDouble(json['total_vendor_payments']),
      totalExpenses: _parseDouble(json['total_expenses']),
      totalZakat: _parseDouble(json['total_zakat']),
      totalExpensesCalculated: _parseDouble(json['total_expenses_calculated']),
      grossProfit: _parseDouble(json['gross_profit']),
      grossProfitMarginPercentage: _parseDouble(json['gross_profit_margin_percentage']),
      netProfit: _parseDouble(json['net_profit']),
      profitMarginPercentage: _parseDouble(json['profit_margin_percentage']),
      isProfitable: json['is_profitable'] as bool,
      calculationTimestamp: DateTime.parse(json['calculation_timestamp'] as String),
      sourceRecordsCount: Map<String, int>.from(json['source_records_count'] as Map),
    );
  }

  // Helper method to safely parse numeric values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse integer values
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}

// Product profitability model
class ProductProfitability {
  final String productId;
  final String productName;
  final String productCategory;
  final int unitsSold;
  final double totalRevenue;
  final double averageSalePrice;
  final double costPrice;
  final double totalCost;
  final double grossProfit;
  final double profitMargin;
  final bool isProfitable;
  final int profitabilityRank;

  ProductProfitability({
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.unitsSold,
    required this.totalRevenue,
    required this.averageSalePrice,
    required this.costPrice,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMargin,
    required this.isProfitable,
    required this.profitabilityRank,
  });

  String get formattedTotalRevenue => 'PKR ${totalRevenue.toStringAsFixed(0)}';
  String get formattedGrossProfit => 'PKR ${grossProfit.toStringAsFixed(0)}';
  String get formattedProfitMargin => '${profitMargin.toStringAsFixed(1)}%';

  factory ProductProfitability.fromJson(Map<String, dynamic> json) {
    return ProductProfitability(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productCategory: json['product_category'] as String,
      unitsSold: _parseInt(json['units_sold']),
      totalRevenue: _parseDouble(json['total_revenue']),
      averageSalePrice: _parseDouble(json['average_sale_price']),
      costPrice: _parseDouble(json['cost_price']),
      totalCost: _parseDouble(json['total_cost']),
      grossProfit: _parseDouble(json['gross_profit']),
      profitMargin: _parseDouble(json['profit_margin']),
      isProfitable: json['is_profitable'] as bool,
      profitabilityRank: _parseInt(json['profitability_rank']),
    );
  }

  // Helper method to safely parse numeric values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse integer values
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}

// Dashboard model with comparisons
class ProfitLossDashboard {
  final PeriodData currentMonth;
  final PeriodData previousMonth;
  final GrowthMetrics growthMetrics;
  final TrendMetrics trends;
  final ExpenseBreakdown expenseBreakdown;

  ProfitLossDashboard({
    required this.currentMonth,
    required this.previousMonth,
    required this.growthMetrics,
    required this.trends,
    required this.expenseBreakdown,
  });

  factory ProfitLossDashboard.fromJson(Map<String, dynamic> json) {
    return ProfitLossDashboard(
      currentMonth: PeriodData.fromJson(json['current_month']),
      previousMonth: PeriodData.fromJson(json['previous_month']),
      growthMetrics: GrowthMetrics.fromJson(json['growth_metrics']),
      trends: TrendMetrics.fromJson(json['trends']),
      expenseBreakdown: ExpenseBreakdown.fromJson(json['expense_breakdown']),
    );
  }
}

class PeriodData {
  final String period;
  final double salesIncome;
  final double totalExpenses;
  final double netProfit;
  final int productsSold;
  final int ordersCount;

  PeriodData({
    required this.period,
    required this.salesIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.productsSold,
    required this.ordersCount,
  });

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      period: json['period'] as String,
      salesIncome: _parseDouble(json['sales_income']),
      totalExpenses: _parseDouble(json['total_expenses']),
      netProfit: _parseDouble(json['net_profit']),
      productsSold: _parseInt(json['products_sold']),
      ordersCount: _parseInt(json['orders_count']),
    );
  }

  // Helper method to safely parse numeric values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse integer values
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }
}

class GrowthMetrics {
  final double salesGrowth;
  final double expenseGrowth;
  final double profitGrowth;

  GrowthMetrics({required this.salesGrowth, required this.expenseGrowth, required this.profitGrowth});

  factory GrowthMetrics.fromJson(Map<String, dynamic> json) {
    return GrowthMetrics(
      salesGrowth: _parseDouble(json['sales_growth']),
      expenseGrowth: _parseDouble(json['expense_growth']),
      profitGrowth: _parseDouble(json['profit_growth']),
    );
  }

  // Helper method to safely parse numeric values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}

class TrendMetrics {
  final String salesTrend;
  final String profitTrend;

  TrendMetrics({required this.salesTrend, required this.profitTrend});

  factory TrendMetrics.fromJson(Map<String, dynamic> json) {
    return TrendMetrics(salesTrend: json['sales_trend'] as String, profitTrend: json['profit_trend'] as String);
  }
}

class ExpenseBreakdown {
  final double laborPayments;
  final double vendorPayments;
  final double otherExpenses;
  final double zakat;

  ExpenseBreakdown({required this.laborPayments, required this.vendorPayments, required this.otherExpenses, required this.zakat});

  factory ExpenseBreakdown.fromJson(Map<String, dynamic> json) {
    return ExpenseBreakdown(
      laborPayments: _parseDouble(json['labor_payments']),
      vendorPayments: _parseDouble(json['vendor_payments']),
      otherExpenses: _parseDouble(json['other_expenses']),
      zakat: _parseDouble(json['zakat']),
    );
  }

  // Helper method to safely parse numeric values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}

// List parameters for filtering profit loss records
class ProfitLossListParams {
  final String? periodType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isProfitable;

  ProfitLossListParams({this.periodType, this.startDate, this.endDate, this.isProfitable});

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (periodType != null && periodType!.isNotEmpty) {
      params['period_type'] = periodType!;
    }
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String().split('T')[0];
    }
    if (isProfitable != null) {
      params['is_profitable'] = isProfitable!.toString();
    }

    return params;
  }
}
