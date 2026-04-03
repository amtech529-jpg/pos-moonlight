import 'payment_model.dart';

/// Response model for payment list with pagination
class PaymentListResponse {
  final List<PaymentModel> payments;
  final PaginationInfo pagination;

  PaymentListResponse({required this.payments, required this.pagination});

  factory PaymentListResponse.fromJson(Map<String, dynamic> json) {
    return PaymentListResponse(
      payments: (json['payments'] as List<dynamic>?)?.map((payment) => PaymentModel.fromJson(payment as Map<String, dynamic>)).toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

/// Response model for payment statistics
class PaymentStatisticsResponse {
  final int totalPayments;
  final double totalAmountPaid;
  final double totalBonus;
  final double totalDeduction;
  final double netAmount;
  final Map<String, dynamic> payerTypeDistribution;
  final Map<String, dynamic> paymentMethodDistribution;
  final Map<String, dynamic> monthlyDistribution;
  final Map<String, dynamic> dailyDistribution;
  final List<dynamic> recentPayments;
  final Map<String, dynamic> topPayers;

  PaymentStatisticsResponse({
    required this.totalPayments,
    required this.totalAmountPaid,
    required this.totalBonus,
    required this.totalDeduction,
    required this.netAmount,
    required this.payerTypeDistribution,
    required this.paymentMethodDistribution,
    required this.monthlyDistribution,
    required this.dailyDistribution,
    required this.recentPayments,
    required this.topPayers,
  });

  factory PaymentStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatisticsResponse(
      totalPayments: json['total_payments'] as int? ?? 0,
      totalAmountPaid: (json['total_amount_paid'] as num?)?.toDouble() ?? 0.0,
      totalBonus: (json['total_bonus'] as num?)?.toDouble() ?? 0.0,
      totalDeduction: (json['total_deduction'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      payerTypeDistribution: json['payer_type_distribution'] as Map<String, dynamic>? ?? {},
      paymentMethodDistribution: json['payment_method_distribution'] as Map<String, dynamic>? ?? {},
      monthlyDistribution: json['monthly_distribution'] as Map<String, dynamic>? ?? {},
      dailyDistribution: json['daily_distribution'] as Map<String, dynamic>? ?? {},
      recentPayments: json['recent_payments'] as List<dynamic>? ?? [],
      topPayers: json['top_payers'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Response model for payment summary
class PaymentSummaryResponse {
  final int totalPayments;
  final double totalAmount;
  final int todayPayments;
  final double todayAmount;
  final int thisMonthPayments;
  final double thisMonthAmount;
  final int thisYearPayments;
  final double thisYearAmount;
  final Map<String, dynamic> methodBreakdown;
  final Map<String, dynamic> typeBreakdown;

  PaymentSummaryResponse({
    required this.totalPayments,
    required this.totalAmount,
    required this.todayPayments,
    required this.todayAmount,
    required this.thisMonthPayments,
    required this.thisMonthAmount,
    required this.thisYearPayments,
    required this.thisYearAmount,
    required this.methodBreakdown,
    required this.typeBreakdown,
  });

  factory PaymentSummaryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryResponse(
      totalPayments: json['total_payments'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      todayPayments: json['today_payments'] as int? ?? 0,
      todayAmount: (json['today_amount'] as num?)?.toDouble() ?? 0.0,
      thisMonthPayments: json['this_month_payments'] as int? ?? 0,
      thisMonthAmount: (json['this_month_amount'] as num?)?.toDouble() ?? 0.0,
      thisYearPayments: json['this_year_payments'] as int? ?? 0,
      thisYearAmount: (json['this_year_amount'] as num?)?.toDouble() ?? 0.0,
      methodBreakdown: json['method_breakdown'] as Map<String, dynamic>? ?? {},
      typeBreakdown: json['type_breakdown'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Response model for payment reconciliation
class PaymentReconciliationResponse {
  final DateTime reconciliationDate;
  final double expectedAmount;
  final double actualAmount;
  final double variance;
  final List<PaymentModel> reconciledPayments;
  final List<Map<String, dynamic>> discrepancies;
  final String reconciliationStatus;

  PaymentReconciliationResponse({
    required this.reconciliationDate,
    required this.expectedAmount,
    required this.actualAmount,
    required this.variance,
    required this.reconciledPayments,
    required this.discrepancies,
    required this.reconciliationStatus,
  });

  factory PaymentReconciliationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentReconciliationResponse(
      reconciliationDate: DateTime.parse(json['reconciliation_date'] as String),
      expectedAmount: (json['expected_amount'] as num).toDouble(),
      actualAmount: (json['actual_amount'] as num).toDouble(),
      variance: (json['variance'] as num).toDouble(),
      reconciledPayments: (json['reconciled_payments'] as List<dynamic>)
          .map((payment) => PaymentModel.fromJson(payment as Map<String, dynamic>))
          .toList(),
      discrepancies: (json['discrepancies'] as List<dynamic>).map((discrepancy) => discrepancy as Map<String, dynamic>).toList(),
      reconciliationStatus: json['reconciliation_status'] as String,
    );
  }
}

/// Pagination information
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
      currentPage: json['current_page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 10,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }
}

