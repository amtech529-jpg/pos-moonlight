import 'package:frontend/src/models/api_response.dart';
import 'payable_model.dart';

// API Response Models for Payables

class PayablesListResponse {
  final List<Payable> payables;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  PayablesListResponse({required this.payables, required this.pagination, this.filtersApplied});

  factory PayablesListResponse.fromJson(Map<String, dynamic> json) {
    return PayablesListResponse(
      payables: (json['payables'] as List).map((payableJson) => Payable.fromJson(payableJson)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }
}

class PayablePriorityBreakdown {
  final String priority;
  final int count;
  final double amount;

  PayablePriorityBreakdown({required this.priority, required this.count, required this.amount});

  factory PayablePriorityBreakdown.fromJson(Map<String, dynamic> json) {
    return PayablePriorityBreakdown(priority: json['priority'] ?? '', count: json['count'] ?? 0, amount: (json['amount'] ?? 0.0).toDouble());
  }

  Map<String, dynamic> toJson() {
    return {'priority': priority, 'count': count, 'amount': amount};
  }
}

class PayableStatusBreakdown {
  final String status;
  final int count;
  final double amount;

  PayableStatusBreakdown({required this.status, required this.count, required this.amount});

  factory PayableStatusBreakdown.fromJson(Map<String, dynamic> json) {
    return PayableStatusBreakdown(status: json['status'] ?? '', count: json['count'] ?? 0, amount: (json['amount'] ?? 0.0).toDouble());
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'count': count, 'amount': amount};
  }
}

class PayableTopCreditor {
  final String creditorName;
  final int count;
  final double totalAmount;

  PayableTopCreditor({required this.creditorName, required this.count, required this.totalAmount});

  factory PayableTopCreditor.fromJson(Map<String, dynamic> json) {
    return PayableTopCreditor(
      creditorName: json['creditor_name'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'creditor_name': creditorName, 'count': count, 'total_amount': totalAmount};
  }
}

class PayableStatisticsResponse {
  final int totalPayables;
  final int overduePayables;
  final int urgentPayables;
  final int paidPayables;
  final int pendingPayables;
  final double totalBorrowedAmount;
  final double totalPaidAmount;
  final double totalOutstandingAmount;
  final double overdueAmount;
  final List<PayablePriorityBreakdown> priorityBreakdown;
  final List<PayableStatusBreakdown> statusBreakdown;
  final List<PayableTopCreditor> topCreditors;

  PayableStatisticsResponse({
    required this.totalPayables,
    required this.overduePayables,
    required this.urgentPayables,
    required this.paidPayables,
    required this.pendingPayables,
    required this.totalBorrowedAmount,
    required this.totalPaidAmount,
    required this.totalOutstandingAmount,
    required this.overdueAmount,
    required this.priorityBreakdown,
    required this.statusBreakdown,
    required this.topCreditors,
  });

  factory PayableStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return PayableStatisticsResponse(
      totalPayables: json['total_payables'] ?? 0,
      overduePayables: json['overdue_payables'] ?? 0,
      urgentPayables: json['urgent_payables'] ?? 0,
      paidPayables: json['paid_payables'] ?? 0,
      pendingPayables: json['pending_payables'] ?? 0,
      totalBorrowedAmount: double.tryParse(json['total_borrowed_amount']?.toString() ?? '0') ?? 0.0,
      totalPaidAmount: double.tryParse(json['total_paid_amount']?.toString() ?? '0') ?? 0.0,
      totalOutstandingAmount: double.tryParse(json['total_outstanding_amount']?.toString() ?? '0') ?? 0.0,
      overdueAmount: double.tryParse(json['overdue_amount']?.toString() ?? '0') ?? 0.0,
      priorityBreakdown: (json['priority_breakdown'] as List? ?? []).map((data) => PayablePriorityBreakdown.fromJson(data)).toList(),
      statusBreakdown: (json['status_breakdown'] as List? ?? []).map((data) => PayableStatusBreakdown.fromJson(data)).toList(),
      topCreditors: (json['top_creditors'] as List? ?? []).map((data) => PayableTopCreditor.fromJson(data)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_payables': totalPayables,
      'overdue_payables': overduePayables,
      'urgent_payables': urgentPayables,
      'paid_payables': paidPayables,
      'pending_payables': pendingPayables,
      'total_borrowed_amount': totalBorrowedAmount,
      'total_paid_amount': totalPaidAmount,
      'total_outstanding_amount': totalOutstandingAmount,
      'overdue_amount': overdueAmount,
      'priority_breakdown': priorityBreakdown.map((p) => p.toJson()).toList(),
      'status_breakdown': statusBreakdown.map((s) => s.toJson()).toList(),
      'top_creditors': topCreditors.map((c) => c.toJson()).toList(),
    };
  }
}

class PayableStatistics {
  final int totalPayables;
  final int activePayables;
  final int overduePayables;
  final int urgentPayables;
  final double totalAmountBorrowed;
  final double totalAmountPaid;
  final double totalBalanceRemaining;
  final double averagePaymentPercentage;
  final int totalCreditors;
  final int totalVendors;

  PayableStatistics({
    required this.totalPayables,
    required this.activePayables,
    required this.overduePayables,
    required this.urgentPayables,
    required this.totalAmountBorrowed,
    required this.totalAmountPaid,
    required this.totalBalanceRemaining,
    required this.averagePaymentPercentage,
    required this.totalCreditors,
    required this.totalVendors,
  });

  factory PayableStatistics.fromJson(Map<String, dynamic> json) {
    return PayableStatistics(
      totalPayables: json['total_payables'] ?? 0,
      activePayables: json['active_payables'] ?? 0,
      overduePayables: json['overdue_payables'] ?? 0,
      urgentPayables: json['urgent_payables'] ?? 0,
      totalAmountBorrowed: (json['total_amount_borrowed'] ?? 0.0).toDouble(),
      totalAmountPaid: (json['total_amount_paid'] ?? 0.0).toDouble(),
      totalBalanceRemaining: (json['total_balance_remaining'] ?? 0.0).toDouble(),
      averagePaymentPercentage: (json['average_payment_percentage'] ?? 0.0).toDouble(),
      totalCreditors: json['total_creditors'] ?? 0,
      totalVendors: json['total_vendors'] ?? 0,
    );
  }
}

class PayableChartData {
  final String label;
  final double value;
  final String? color;

  PayableChartData({required this.label, required this.value, this.color});

  factory PayableChartData.fromJson(Map<String, dynamic> json) {
    return PayableChartData(label: json['label'] ?? '', value: (json['value'] ?? 0.0).toDouble(), color: json['color']);
  }
}

class PayablePrioritySummary {
  final String priority;
  final int count;
  final double totalAmount;
  final double averageAmount;

  PayablePrioritySummary({required this.priority, required this.count, required this.totalAmount, required this.averageAmount});

  factory PayablePrioritySummary.fromJson(Map<String, dynamic> json) {
    return PayablePrioritySummary(
      priority: json['priority'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      averageAmount: (json['average_amount'] ?? 0.0).toDouble(),
    );
  }
}

class PayableStatusSummary {
  final String status;
  final int count;
  final double totalAmount;
  final double averageAmount;

  PayableStatusSummary({required this.status, required this.count, required this.totalAmount, required this.averageAmount});

  factory PayableStatusSummary.fromJson(Map<String, dynamic> json) {
    return PayableStatusSummary(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      averageAmount: (json['average_amount'] ?? 0.0).toDouble(),
    );
  }
}

class PayableVendorSummary {
  final String vendorName;
  final int count;
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;

  PayableVendorSummary({
    required this.vendorName,
    required this.count,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalRemaining,
  });

  factory PayableVendorSummary.fromJson(Map<String, dynamic> json) {
    return PayableVendorSummary(
      vendorName: json['vendor_name'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      totalPaid: (json['total_paid'] ?? 0.0).toDouble(),
      totalRemaining: (json['total_remaining'] ?? 0.0).toDouble(),
    );
  }
}

// Request Models

class PayableListParams {
  final int page;
  final int pageSize;
  final String? search;
  final String? status;
  final String? priority;
  final String? vendorId;
  final DateTime? dueAfter;
  final DateTime? dueBefore;
  final DateTime? borrowedAfter;
  final DateTime? borrowedBefore;
  final bool? overdueOnly;
  final bool? urgentOnly;
  final String? sortBy;
  final String? sortOrder;
  final bool? showInactive;

  PayableListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.status,
    this.priority,
    this.vendorId,
    this.dueAfter,
    this.dueBefore,
    this.borrowedAfter,
    this.borrowedBefore,
    this.overdueOnly,
    this.urgentOnly,
    this.sortBy = 'expected_repayment_date',
    this.sortOrder = 'asc',
    this.showInactive = false,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'show_inactive': showInactive.toString(),
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }
    if (priority != null && priority!.isNotEmpty) {
      params['priority'] = priority;
    }
    if (vendorId != null && vendorId!.isNotEmpty) {
      params['vendor_id'] = vendorId;
    }
    if (dueAfter != null) {
      params['due_after'] = dueAfter!.toIso8601String().split('T')[0];
    }
    if (dueBefore != null) {
      params['due_before'] = dueBefore!.toIso8601String().split('T')[0];
    }
    if (borrowedAfter != null) {
      params['borrowed_after'] = borrowedAfter!.toIso8601String().split('T')[0];
    }
    if (borrowedBefore != null) {
      params['borrowed_before'] = borrowedBefore!.toIso8601String().split('T')[0];
    }
    if (overdueOnly == true) {
      params['overdue_only'] = 'true';
    }
    if (urgentOnly == true) {
      params['urgent_only'] = 'true';
    }

    return params;
  }
}

class PayableCreateRequest {
  final String creditorName;
  final String? creditorPhone;
  final String? creditorEmail;
  final String? vendorId;
  final double amountBorrowed;
  final double amountPaid;
  final String reasonOrItem;
  final DateTime dateBorrowed;
  final DateTime expectedRepaymentDate;
  final String priority;
  final String? notes;

  PayableCreateRequest({
    required this.creditorName,
    this.creditorPhone,
    this.creditorEmail,
    this.vendorId,
    required this.amountBorrowed,
    this.amountPaid = 0.0,
    this.reasonOrItem = '',
    required this.dateBorrowed,
    required this.expectedRepaymentDate,
    this.priority = 'MEDIUM',
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'creditor_name': creditorName,
      'creditor_phone': creditorPhone ?? '',
      'creditor_email': creditorEmail,
      'vendor': vendorId,
      'amount_borrowed': amountBorrowed,
      'amount_paid': amountPaid,
      'reason_or_item': reasonOrItem,
      'date_borrowed': dateBorrowed.toIso8601String().split('T')[0],
      'expected_repayment_date': expectedRepaymentDate.toIso8601String().split('T')[0],
      'priority': priority,
      'notes': notes ?? '', // Send empty string instead of null
    };
  }
}

class PayableUpdateRequest {
  final String? creditorName;
  final String? creditorPhone;
  final String? creditorEmail;
  final String? vendorId;
  final double? amountBorrowed;
  final double? amountPaid;
  final String? reasonOrItem;
  final DateTime? dateBorrowed;
  final DateTime? expectedRepaymentDate;
  final String? priority;
  final String? status;
  final String? notes;

  PayableUpdateRequest({
    this.creditorName,
    this.creditorPhone,
    this.creditorEmail,
    this.vendorId,
    this.amountBorrowed,
    this.amountPaid,
    this.reasonOrItem,
    this.dateBorrowed,
    this.expectedRepaymentDate,
    this.priority,
    this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (creditorName != null) json['creditor_name'] = creditorName;
    if (creditorPhone != null) json['creditor_phone'] = creditorPhone;
    if (creditorEmail != null) json['creditor_email'] = creditorEmail;
    if (vendorId != null) json['vendor'] = vendorId;
    if (amountBorrowed != null) json['amount_borrowed'] = amountBorrowed;
    if (amountPaid != null) json['amount_paid'] = amountPaid;
    if (reasonOrItem != null) json['reason_or_item'] = reasonOrItem;
    if (dateBorrowed != null) json['date_borrowed'] = dateBorrowed!.toIso8601String().split('T')[0];
    if (expectedRepaymentDate != null) json['expected_repayment_date'] = expectedRepaymentDate!.toIso8601String().split('T')[0];
    if (priority != null) json['priority'] = priority;
    if (status != null) json['status'] = status;
    if (notes != null) json['notes'] = notes;

    return json;
  }
}

class PayablePaymentRequest {
  final double amount;
  final DateTime paymentDate;
  final String? notes;

  PayablePaymentRequest({required this.amount, required this.paymentDate, this.notes});

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'payment_date': paymentDate.toIso8601String().split('T')[0], 'notes': notes};
  }
}

class PayableContactUpdateRequest {
  final String? creditorPhone;
  final String? creditorEmail;

  PayableContactUpdateRequest({this.creditorPhone, this.creditorEmail});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (creditorPhone != null) json['creditor_phone'] = creditorPhone;
    if (creditorEmail != null) json['creditor_email'] = creditorEmail;

    return json;
  }
}

class PayableBulkActionRequest {
  final List<String> payableIds;
  final String action;
  final Map<String, dynamic>? actionData;

  PayableBulkActionRequest({required this.payableIds, required this.action, this.actionData});

  Map<String, dynamic> toJson() {
    return {'payable_ids': payableIds, 'action': action, 'action_data': actionData};
  }
}

// Pagination Info (reusing from api_response.dart)
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
      currentPage: json['current_page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }
}
