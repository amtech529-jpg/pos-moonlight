import 'advance_payment_model.dart';

// Pagination information
class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'page_size': pageSize,
      'total_count': totalCount,
      'total_pages': totalPages,
      'has_next': hasNext,
      'has_previous': hasPrevious,
    };
  }
}

// List response for advance payments
class AdvancePaymentsListResponse {
  final List<AdvancePayment> advancePayments;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  AdvancePaymentsListResponse({required this.advancePayments, required this.pagination, this.filtersApplied});

  factory AdvancePaymentsListResponse.fromJson(Map<String, dynamic> json) {
    return AdvancePaymentsListResponse(
      advancePayments: (json['advance_payments'] as List).map((paymentJson) => AdvancePayment.fromJson(paymentJson)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advance_payments': advancePayments.map((payment) => payment.toJson()).toList(),
      'pagination': pagination.toJson(),
      'filters_applied': filtersApplied,
    };
  }
}

// Statistics response
class AdvancePaymentStatisticsResponse {
  final int totalPayments;
  final double totalAmount;
  final int todayPayments;
  final double todayAmount;
  final int thisMonthPayments;
  final double thisMonthAmount;
  final Map<String, dynamic> amountStatistics;
  final List<Map<String, dynamic>> topLaborRecipients;
  final List<Map<String, dynamic>> monthlyBreakdown;
  final int paymentsWithReceipts;
  final int paymentsWithoutReceipts;

  AdvancePaymentStatisticsResponse({
    required this.totalPayments,
    required this.totalAmount,
    required this.todayPayments,
    required this.todayAmount,
    required this.thisMonthPayments,
    required this.thisMonthAmount,
    required this.amountStatistics,
    required this.topLaborRecipients,
    required this.monthlyBreakdown,
    required this.paymentsWithReceipts,
    required this.paymentsWithoutReceipts,
  });

  factory AdvancePaymentStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return AdvancePaymentStatisticsResponse(
      totalPayments: json['total_payments'] ?? 0,
      totalAmount: (json['total_amount'] is String) ? double.parse(json['total_amount']) : (json['total_amount'] ?? 0.0),
      todayPayments: json['today_payments'] ?? 0,
      todayAmount: (json['today_amount'] is String) ? double.parse(json['today_amount']) : (json['today_amount'] ?? 0.0),
      thisMonthPayments: json['this_month_payments'] ?? 0,
      thisMonthAmount: (json['this_month_amount'] is String) ? double.parse(json['this_month_amount']) : (json['this_month_amount'] ?? 0.0),
      amountStatistics: json['amount_statistics'] ?? {},
      topLaborRecipients: (json['top_labor_recipients'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      monthlyBreakdown: (json['monthly_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      paymentsWithReceipts: json['payments_with_receipts'] ?? 0,
      paymentsWithoutReceipts: json['payments_without_receipts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_payments': totalPayments,
      'total_amount': totalAmount,
      'today_payments': todayPayments,
      'today_amount': todayAmount,
      'this_month_payments': thisMonthPayments,
      'this_month_amount': thisMonthAmount,
      'amount_statistics': amountStatistics,
      'top_labor_recipients': topLaborRecipients,
      'monthly_breakdown': monthlyBreakdown,
      'payments_with_receipts': paymentsWithReceipts,
      'payments_without_receipts': paymentsWithoutReceipts,
    };
  }
}

// Monthly report response
class AdvancePaymentMonthlyReportResponse {
  final String month;
  final Map<String, dynamic> monthlyStatistics;
  final List<Map<String, dynamic>> dailyBreakdown;
  final List<Map<String, dynamic>> laborBreakdown;
  final List<Map<String, dynamic>> topPaymentDays;
  final String generatedAt;

  AdvancePaymentMonthlyReportResponse({
    required this.month,
    required this.monthlyStatistics,
    required this.dailyBreakdown,
    required this.laborBreakdown,
    required this.topPaymentDays,
    required this.generatedAt,
  });

  factory AdvancePaymentMonthlyReportResponse.fromJson(Map<String, dynamic> json) {
    return AdvancePaymentMonthlyReportResponse(
      month: json['month'] ?? '',
      monthlyStatistics: json['monthly_statistics'] ?? {},
      dailyBreakdown: (json['daily_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      laborBreakdown: (json['labor_breakdown'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      topPaymentDays: (json['top_payment_days'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      generatedAt: json['generated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'monthly_statistics': monthlyStatistics,
      'daily_breakdown': dailyBreakdown,
      'labor_breakdown': laborBreakdown,
      'top_payment_days': topPaymentDays,
      'generated_at': generatedAt,
    };
  }
}

// Labor advance report response
class LaborAdvanceReportResponse {
  final List<Map<String, dynamic>> laborAdvanceReport;
  final Map<String, dynamic> summary;
  final String generatedAt;

  LaborAdvanceReportResponse({required this.laborAdvanceReport, required this.summary, required this.generatedAt});

  factory LaborAdvanceReportResponse.fromJson(Map<String, dynamic> json) {
    return LaborAdvanceReportResponse(
      laborAdvanceReport: (json['labor_advance_report'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      summary: json['summary'] ?? {},
      generatedAt: json['generated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'labor_advance_report': laborAdvanceReport, 'summary': summary, 'generated_at': generatedAt};
  }
}

// Labor advance summary response
class LaborAdvanceSummaryResponse {
  final String laborId;
  final String laborName;
  final String laborRole;
  final double currentSalary;
  final double totalAdvances;
  final int paymentCount;
  final DateTime? lastPaymentDate;
  final double thisMonthAdvances;
  final double remainingSalaryBalance;

  LaborAdvanceSummaryResponse({
    required this.laborId,
    required this.laborName,
    required this.laborRole,
    required this.currentSalary,
    required this.totalAdvances,
    required this.paymentCount,
    this.lastPaymentDate,
    required this.thisMonthAdvances,
    required this.remainingSalaryBalance,
  });

  factory LaborAdvanceSummaryResponse.fromJson(Map<String, dynamic> json) {
    return LaborAdvanceSummaryResponse(
      laborId: json['labor_id'] ?? '',
      laborName: json['labor_name'] ?? '',
      laborRole: json['labor_role'] ?? '',
      currentSalary: (json['current_salary'] is String) ? double.parse(json['current_salary']) : (json['current_salary'] ?? 0.0),
      totalAdvances: (json['total_advances'] is String) ? double.parse(json['total_advances']) : (json['total_advances'] ?? 0.0),
      paymentCount: json['payment_count'] ?? 0,
      lastPaymentDate: json['last_payment_date'] != null ? DateTime.parse(json['last_payment_date']) : null,
      thisMonthAdvances: (json['this_month_advances'] is String) ? double.parse(json['this_month_advances']) : (json['this_month_advances'] ?? 0.0),
      remainingSalaryBalance: (json['remaining_salary_balance'] is String)
          ? double.parse(json['remaining_salary_balance'])
          : (json['remaining_salary_balance'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labor_id': laborId,
      'labor_name': laborName,
      'labor_role': laborRole,
      'current_salary': currentSalary,
      'total_advances': totalAdvances,
      'payment_count': paymentCount,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'this_month_advances': thisMonthAdvances,
      'remaining_salary_balance': remainingSalaryBalance,
    };
  }
}

// Date range response
class AdvancePaymentsByDateRangeResponse {
  final Map<String, dynamic> dateRange;
  final List<AdvancePayment> advancePayments;
  final int count;
  final double totalAmount;
  final String formattedTotal;
  final Map<String, dynamic> summary;

  AdvancePaymentsByDateRangeResponse({
    required this.dateRange,
    required this.advancePayments,
    required this.count,
    required this.totalAmount,
    required this.formattedTotal,
    required this.summary,
  });

  factory AdvancePaymentsByDateRangeResponse.fromJson(Map<String, dynamic> json) {
    return AdvancePaymentsByDateRangeResponse(
      dateRange: json['date_range'] ?? {},
      advancePayments: (json['advance_payments'] as List).map((paymentJson) => AdvancePayment.fromJson(paymentJson)).toList(),
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] is String) ? double.parse(json['total_amount']) : (json['total_amount'] ?? 0.0),
      formattedTotal: json['formatted_total'] ?? '',
      summary: json['summary'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_range': dateRange,
      'advance_payments': advancePayments.map((payment) => payment.toJson()).toList(),
      'count': count,
      'total_amount': totalAmount,
      'formatted_total': formattedTotal,
      'summary': summary,
    };
  }
}

// Today payments response
class TodayPaymentsResponse {
  final List<AdvancePayment> advancePayments;
  final PaginationInfo pagination;
  final String date;
  final Map<String, dynamic> summary;

  TodayPaymentsResponse({required this.advancePayments, required this.pagination, required this.date, required this.summary});

  factory TodayPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return TodayPaymentsResponse(
      advancePayments: (json['advance_payments'] as List).map((paymentJson) => AdvancePayment.fromJson(paymentJson)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      date: json['date'] ?? '',
      summary: json['summary'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advance_payments': advancePayments.map((payment) => payment.toJson()).toList(),
      'pagination': pagination.toJson(),
      'date': date,
      'summary': summary,
    };
  }
}

// Recent payments response
class RecentPaymentsResponse {
  final List<AdvancePayment> advancePayments;
  final PaginationInfo pagination;
  final int days;
  final String description;

  RecentPaymentsResponse({required this.advancePayments, required this.pagination, required this.days, required this.description});

  factory RecentPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return RecentPaymentsResponse(
      advancePayments: (json['advance_payments'] as List).map((paymentJson) => AdvancePayment.fromJson(paymentJson)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      days: json['days'] ?? 7,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advance_payments': advancePayments.map((payment) => payment.toJson()).toList(),
      'pagination': pagination.toJson(),
      'days': days,
      'description': description,
    };
  }
}

// Bulk actions response
class BulkAdvancePaymentActionsResponse {
  final String action;
  final List<Map<String, dynamic>>? updatedPayments;
  final List<String>? deletedPayments;
  final int totalUpdated;
  final int totalDeleted;

  BulkAdvancePaymentActionsResponse({
    required this.action,
    this.updatedPayments,
    this.deletedPayments,
    required this.totalUpdated,
    required this.totalDeleted,
  });

  factory BulkAdvancePaymentActionsResponse.fromJson(Map<String, dynamic> json) {
    return BulkAdvancePaymentActionsResponse(
      action: json['action'] ?? '',
      updatedPayments: json['updated_payments'] != null ? (json['updated_payments'] as List).cast<Map<String, dynamic>>() : null,
      deletedPayments: json['deleted_payments'] != null ? (json['deleted_payments'] as List).cast<String>() : null,
      totalUpdated: json['total_updated'] ?? 0,
      totalDeleted: json['total_deleted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'updated_payments': updatedPayments,
      'deleted_payments': deletedPayments,
      'total_updated': totalUpdated,
      'total_deleted': totalDeleted,
    };
  }
}


