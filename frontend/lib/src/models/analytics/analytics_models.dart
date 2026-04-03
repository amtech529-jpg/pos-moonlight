import 'package:flutter/material.dart';

class BusinessMetrics {
  final String id;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final int salesCount;
  final double averageSaleValue;
  final int newCustomers;
  final int returningCustomers;
  final int totalCustomers;
  final int productsSold;
  final List<Map<String, dynamic>> topSellingProducts;
  final int lowStockProducts;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final int ordersFulfilled;
  final int ordersPending;
  final double averageFulfillmentTime;
  final double cashPayments;
  final double bankTransfers;
  final double pendingPayments;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessMetrics({
    required this.id,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.salesCount,
    required this.averageSaleValue,
    required this.newCustomers,
    required this.returningCustomers,
    required this.totalCustomers,
    required this.productsSold,
    required this.topSellingProducts,
    required this.lowStockProducts,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.ordersFulfilled,
    required this.ordersPending,
    required this.averageFulfillmentTime,
    required this.cashPayments,
    required this.bankTransfers,
    required this.pendingPayments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BusinessMetrics.fromJson(Map<String, dynamic> json) {
    return BusinessMetrics(
      id: json['id'] ?? '',
      periodType: json['period_type'] ?? '',
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      totalSales: (json['total_sales'] ?? 0.0).toDouble(),
      salesCount: json['sales_count'] ?? 0,
      averageSaleValue: (json['average_sale_value'] ?? 0.0).toDouble(),
      newCustomers: json['new_customers'] ?? 0,
      returningCustomers: json['returning_customers'] ?? 0,
      totalCustomers: json['total_customers'] ?? 0,
      productsSold: json['products_sold'] ?? 0,
      topSellingProducts: (json['top_selling_products'] as List<dynamic>?)?.map((item) => Map<String, dynamic>.from(item)).toList() ?? [],
      lowStockProducts: json['low_stock_products'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0.0).toDouble(),
      netProfit: (json['net_profit'] ?? 0.0).toDouble(),
      profitMargin: (json['profit_margin'] ?? 0.0).toDouble(),
      ordersFulfilled: json['orders_fulfilled'] ?? 0,
      ordersPending: json['orders_pending'] ?? 0,
      averageFulfillmentTime: (json['average_fulfillment_time'] ?? 0.0).toDouble(),
      cashPayments: (json['cash_payments'] ?? 0.0).toDouble(),
      bankTransfers: (json['bank_transfers'] ?? 0.0).toDouble(),
      pendingPayments: (json['pending_payments'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_type': periodType,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_sales': totalSales,
      'sales_count': salesCount,
      'average_sale_value': averageSaleValue,
      'new_customers': newCustomers,
      'returning_customers': returningCustomers,
      'total_customers': totalCustomers,
      'products_sold': productsSold,
      'top_selling_products': topSellingProducts,
      'low_stock_products': lowStockProducts,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'profit_margin': profitMargin,
      'orders_fulfilled': ordersFulfilled,
      'orders_pending': ordersPending,
      'average_fulfillment_time': averageFulfillmentTime,
      'cash_payments': cashPayments,
      'bank_transfers': bankTransfers,
      'pending_payments': pendingPayments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Formatted values
  String get formattedTotalSales => 'PKR ${totalSales.toStringAsFixed(2)}';
  String get formattedAverageSaleValue => 'PKR ${averageSaleValue.toStringAsFixed(2)}';
  String get formattedTotalRevenue => 'PKR ${totalRevenue.toStringAsFixed(2)}';
  String get formattedTotalExpenses => 'PKR ${totalExpenses.toStringAsFixed(2)}';
  String get formattedNetProfit => 'PKR ${netProfit.toStringAsFixed(2)}';
  String get formattedProfitMargin => '${profitMargin.toStringAsFixed(1)}%';
  String get formattedCashPayments => 'PKR ${cashPayments.toStringAsFixed(2)}';
  String get formattedBankTransfers => 'PKR ${bankTransfers.toStringAsFixed(2)}';
  String get formattedPendingPayments => 'PKR ${pendingPayments.toStringAsFixed(2)}';
}

class CustomerInsightsData {
  final List<CustomerInsight> insights;
  final Map<String, dynamic> summary;

  CustomerInsightsData({required this.insights, required this.summary});

  factory CustomerInsightsData.fromJson(Map<String, dynamic> json) {
    return CustomerInsightsData(
      insights: (json['insights'] as List<dynamic>?)?.map((item) => CustomerInsight.fromJson(item)).toList() ?? [],
      summary: json['summary'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'insights': insights.map((item) => item.toJson()).toList(), 'summary': summary};
  }
}

class CustomerInsight {
  final String id;
  final String customerId;
  final String customerName;
  final int totalPurchases;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? firstPurchaseDate;
  final DateTime? lastPurchaseDate;
  final int daysSinceLastPurchase;
  final String customerSegment;
  final double loyaltyScore;
  final DateTime calculatedAt;
  final DateTime updatedAt;

  CustomerInsight({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.totalPurchases,
    required this.totalSpent,
    required this.averageOrderValue,
    this.firstPurchaseDate,
    this.lastPurchaseDate,
    required this.daysSinceLastPurchase,
    required this.customerSegment,
    required this.loyaltyScore,
    required this.calculatedAt,
    required this.updatedAt,
  });

  factory CustomerInsight.fromJson(Map<String, dynamic> json) {
    return CustomerInsight(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      totalPurchases: json['total_purchases'] ?? 0,
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0.0).toDouble(),
      firstPurchaseDate: json['first_purchase_date'] != null ? DateTime.parse(json['first_purchase_date']) : null,
      lastPurchaseDate: json['last_purchase_date'] != null ? DateTime.parse(json['last_purchase_date']) : null,
      daysSinceLastPurchase: json['days_since_last_purchase'] ?? 0,
      customerSegment: json['customer_segment'] ?? '',
      loyaltyScore: (json['loyalty_score'] ?? 0.0).toDouble(),
      calculatedAt: DateTime.parse(json['calculated_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'total_purchases': totalPurchases,
      'total_spent': totalSpent,
      'average_order_value': averageOrderValue,
      'first_purchase_date': firstPurchaseDate?.toIso8601String(),
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'days_since_last_purchase': daysSinceLastPurchase,
      'customer_segment': customerSegment,
      'loyalty_score': loyaltyScore,
      'calculated_at': calculatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Formatted values
  String get formattedTotalSpent => 'PKR ${totalSpent.toStringAsFixed(2)}';
  String get formattedAverageOrderValue => 'PKR ${averageOrderValue.toStringAsFixed(2)}';
  String get formattedLoyaltyScore => '${loyaltyScore.toStringAsFixed(1)}%';

  // Get customer segment color
  Color get segmentColor {
    switch (customerSegment.toLowerCase()) {
      case 'vip':
        return Colors.amber;
      case 'regular':
        return Colors.blue;
      case 'occasional':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class ProductPerformanceData {
  final List<ProductPerformance> performances;
  final Map<String, dynamic> summary;

  ProductPerformanceData({required this.performances, required this.summary});

  factory ProductPerformanceData.fromJson(Map<String, dynamic> json) {
    return ProductPerformanceData(
      performances: (json['performances'] as List<dynamic>?)?.map((item) => ProductPerformance.fromJson(item)).toList() ?? [],
      summary: json['summary'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'performances': performances.map((item) => item.toJson()).toList(), 'summary': summary};
  }
}

class ProductPerformance {
  final String id;
  final String productId;
  final String productName;
  final String category;
  final int unitsSold;
  final double revenueGenerated;
  final double profitMargin;
  final int currentStock;
  final int reorderPoint;
  final double stockTurnoverRate;
  final bool isTopSeller;
  final bool isLowStock;
  final double performanceScore;
  final DateTime calculatedAt;
  final DateTime updatedAt;

  ProductPerformance({
    required this.id,
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitsSold,
    required this.revenueGenerated,
    required this.profitMargin,
    required this.currentStock,
    required this.reorderPoint,
    required this.stockTurnoverRate,
    required this.isTopSeller,
    required this.isLowStock,
    required this.performanceScore,
    required this.calculatedAt,
    required this.updatedAt,
  });

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      category: json['category'] ?? '',
      unitsSold: json['units_sold'] ?? 0,
      revenueGenerated: (json['revenue_generated'] ?? 0.0).toDouble(),
      profitMargin: (json['profit_margin'] ?? 0.0).toDouble(),
      currentStock: json['current_stock'] ?? 0,
      reorderPoint: json['reorder_point'] ?? 0,
      stockTurnoverRate: (json['stock_turnover_rate'] ?? 0.0).toDouble(),
      isTopSeller: json['is_top_seller'] ?? false,
      isLowStock: json['is_low_stock'] ?? false,
      performanceScore: (json['performance_score'] ?? 0.0).toDouble(),
      calculatedAt: DateTime.parse(json['calculated_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'units_sold': unitsSold,
      'revenue_generated': revenueGenerated,
      'profit_margin': profitMargin,
      'current_stock': currentStock,
      'reorder_point': reorderPoint,
      'stock_turnover_rate': stockTurnoverRate,
      'is_top_seller': isTopSeller,
      'is_low_stock': isLowStock,
      'performance_score': performanceScore,
      'calculated_at': calculatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Formatted values
  String get formattedRevenueGenerated => 'PKR ${revenueGenerated.toStringAsFixed(2)}';
  String get formattedProfitMargin => '${profitMargin.toStringAsFixed(1)}%';
  String get formattedStockTurnoverRate => '${stockTurnoverRate.toStringAsFixed(1)}x';
  String get formattedPerformanceScore => '${performanceScore.toStringAsFixed(1)}%';

  // Get stock status
  String get stockStatus {
    if (currentStock == 0) {
      return 'Out of Stock';
    } else if (currentStock <= reorderPoint) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  // Get stock status color
  Color get stockStatusColor {
    if (currentStock == 0) {
      return Colors.red;
    } else if (currentStock <= reorderPoint) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

class RealtimeAnalytics {
  final int activeUsers;
  final int currentOrders;
  final double todaySales;
  final int pendingPayments;
  final List<Map<String, dynamic>> recentActivities;
  final DateTime lastUpdated;

  RealtimeAnalytics({
    required this.activeUsers,
    required this.currentOrders,
    required this.todaySales,
    required this.pendingPayments,
    required this.recentActivities,
    required this.lastUpdated,
  });

  factory RealtimeAnalytics.fromJson(Map<String, dynamic> json) {
    return RealtimeAnalytics(
      activeUsers: json['active_users'] ?? 0,
      currentOrders: json['current_orders'] ?? 0,
      todaySales: (json['today_sales'] ?? 0.0).toDouble(),
      pendingPayments: json['pending_payments'] ?? 0,
      recentActivities: (json['recent_activities'] as List<dynamic>?)?.map((item) => Map<String, dynamic>.from(item)).toList() ?? [],
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_users': activeUsers,
      'current_orders': currentOrders,
      'today_sales': todaySales,
      'pending_payments': pendingPayments,
      'recent_activities': recentActivities,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  String get formattedTodaySales => 'PKR ${todaySales.toStringAsFixed(2)}';
}

class AnalyticsExport {
  final String downloadUrl;
  final String fileName;
  final String format;
  final int fileSize;
  final DateTime exportedAt;

  AnalyticsExport({required this.downloadUrl, required this.fileName, required this.format, required this.fileSize, required this.exportedAt});

  factory AnalyticsExport.fromJson(Map<String, dynamic> json) {
    return AnalyticsExport(
      downloadUrl: json['download_url'] ?? '',
      fileName: json['file_name'] ?? '',
      format: json['format'] ?? '',
      fileSize: json['file_size'] ?? 0,
      exportedAt: DateTime.parse(json['exported_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {'download_url': downloadUrl, 'file_name': fileName, 'format': format, 'file_size': fileSize, 'exported_at': exportedAt.toIso8601String()};
  }

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize} B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

