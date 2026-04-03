import 'package:flutter/material.dart';

class Payable {
  final String id;
  final String creditorName;
  final String? creditorPhone;
  final String? creditorEmail;
  final String? vendorId;
  final String? vendorName;
  final String? vendorBusinessName;
  final double amountBorrowed;
  final double amountPaid;
  final double balanceRemaining;
  final String reasonOrItem;
  final DateTime dateBorrowed;
  final DateTime expectedRepaymentDate;
  final bool isFullyPaid;
  final double paymentPercentage;
  final String priority;
  final String status;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final int? createdById;

  // Computed fields from backend
  final int? daysSinceBorrowed;
  final int? daysUntilDue;
  final bool? isOverdue;
  final String? repaymentStatus;
  final String? priorityColor;
  final String? statusColor;
  final int? paymentsCount;
  final DateTime? latestPaymentDate;

  Payable({
    required this.id,
    required this.creditorName,
    this.creditorPhone,
    this.creditorEmail,
    this.vendorId,
    this.vendorName,
    this.vendorBusinessName,
    required this.amountBorrowed,
    required this.amountPaid,
    required this.balanceRemaining,
    required this.reasonOrItem,
    required this.dateBorrowed,
    required this.expectedRepaymentDate,
    required this.isFullyPaid,
    required this.paymentPercentage,
    required this.priority,
    required this.status,
    this.notes,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.createdById,
    this.daysSinceBorrowed,
    this.daysUntilDue,
    this.isOverdue,
    this.repaymentStatus,
    this.priorityColor,
    this.statusColor,
    this.paymentsCount,
    this.latestPaymentDate,
  });

  // Factory constructor from JSON
  factory Payable.fromJson(Map<String, dynamic> json) {
    return Payable(
      id: json['id'] ?? '',
      creditorName: json['creditor_name'] ?? '',
      creditorPhone: json['creditor_phone'],
      creditorEmail: json['creditor_email'],
      vendorId: json['vendor'],
      vendorName: json['vendor_name'],
      vendorBusinessName: json['vendor_business_name'],
      amountBorrowed: _parseDouble(json['amount_borrowed']),
      amountPaid: _parseDouble(json['amount_paid']),
      balanceRemaining: _parseDouble(json['balance_remaining']),
      reasonOrItem: json['reason_or_item'] ?? 'No reason specified',
      dateBorrowed: json['date_borrowed'] != null ? DateTime.parse(json['date_borrowed']) : DateTime.now(),
      expectedRepaymentDate: DateTime.parse(json['expected_repayment_date']),
      isFullyPaid: json['is_fully_paid'] ?? false,
      paymentPercentage: _parseDouble(json['payment_percentage']),
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'ACTIVE',
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      createdBy: json['created_by'] ?? json['created_by_email'] ?? 'Unknown',
      createdById: json['created_by_id'],
      daysSinceBorrowed: json['days_since_borrowed'],
      daysUntilDue: json['days_until_due'],
      isOverdue: json['is_overdue'],
      repaymentStatus: json['repayment_status'],
      priorityColor: json['priority_color'],
      statusColor: json['status_color'],
      paymentsCount: json['payments_count'],
      latestPaymentDate: json['latest_payment_date'] != null ? DateTime.parse(json['latest_payment_date']) : null,
    );
  }

  // Helper method to safely parse double values from JSON
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditor_name': creditorName,
      'creditor_phone': creditorPhone,
      'creditor_email': creditorEmail,
      'vendor': vendorId,
      'amount_borrowed': amountBorrowed,
      'amount_paid': amountPaid,
      'reason_or_item': reasonOrItem,
      'date_borrowed': dateBorrowed.toIso8601String().split('T')[0],
      'expected_repayment_date': expectedRepaymentDate.toIso8601String().split('T')[0],
      'priority': priority,
      'status': status,
      'notes': notes,
    };
  }

  // Copy with method
  Payable copyWith({
    String? id,
    String? creditorName,
    String? creditorPhone,
    String? creditorEmail,
    String? vendorId,
    String? vendorName,
    String? vendorBusinessName,
    double? amountBorrowed,
    double? amountPaid,
    double? balanceRemaining,
    String? reasonOrItem,
    DateTime? dateBorrowed,
    DateTime? expectedRepaymentDate,
    bool? isFullyPaid,
    double? paymentPercentage,
    String? priority,
    String? status,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? createdById,
    int? daysSinceBorrowed,
    int? daysUntilDue,
    bool? isOverdue,
    String? repaymentStatus,
    String? priorityColor,
    String? statusColor,
    int? paymentsCount,
    DateTime? latestPaymentDate,
  }) {
    return Payable(
      id: id ?? this.id,
      creditorName: creditorName ?? this.creditorName,
      creditorPhone: creditorPhone ?? this.creditorPhone,
      creditorEmail: creditorEmail ?? this.creditorEmail,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorBusinessName: vendorBusinessName ?? this.vendorBusinessName,
      amountBorrowed: amountBorrowed ?? this.amountBorrowed,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceRemaining: balanceRemaining ?? this.balanceRemaining,
      reasonOrItem: reasonOrItem ?? this.reasonOrItem,
      dateBorrowed: dateBorrowed ?? this.dateBorrowed,
      expectedRepaymentDate: expectedRepaymentDate ?? this.expectedRepaymentDate,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
      paymentPercentage: paymentPercentage ?? this.paymentPercentage,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      daysSinceBorrowed: daysSinceBorrowed ?? this.daysSinceBorrowed,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      isOverdue: isOverdue ?? this.isOverdue,
      repaymentStatus: repaymentStatus ?? this.repaymentStatus,
      priorityColor: priorityColor ?? this.priorityColor,
      statusColor: statusColor ?? this.statusColor,
      paymentsCount: paymentsCount ?? this.paymentsCount,
      latestPaymentDate: latestPaymentDate ?? this.latestPaymentDate,
    );
  }

  // Getters for computed properties
  String get statusText {
    if (isFullyPaid) return 'Fully Paid';
    if (amountPaid > 0 && balanceRemaining > 0) return 'Partially Paid';
    if (isOverdue == true) return 'Overdue';
    return 'Pending';
  }

  Color get statusColorValue {
    if (isFullyPaid) return Colors.green;
    if (amountPaid > 0 && balanceRemaining > 0) return Colors.orange;
    if (isOverdue == true) return Colors.red;
    return Colors.blue;
  }

  Color get priorityColorValue {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.yellow;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool get isOverdueComputed => expectedRepaymentDate.isBefore(DateTime.now()) && balanceRemaining > 0;
  bool get isPartiallyPaid => amountPaid > 0 && balanceRemaining > 0;

  // Formatted dates
  String get formattedDateBorrowed =>
      '${dateBorrowed.day.toString().padLeft(2, '0')}/${dateBorrowed.month.toString().padLeft(2, '0')}/${dateBorrowed.year}';
  String get formattedExpectedRepaymentDate =>
      '${expectedRepaymentDate.day.toString().padLeft(2, '0')}/${expectedRepaymentDate.month.toString().padLeft(2, '0')}/${expectedRepaymentDate.year}';
  String get formattedCreatedAt => '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

  // Relative dates
  String get relativeDateBorrowed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(dateBorrowed.year, dateBorrowed.month, dateBorrowed.day);
    final difference = today.difference(recordDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    final years = (difference / 365).floor();
    return years == 1 ? '1 year ago' : '$years years ago';
  }

  String get relativeExpectedRepaymentDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(expectedRepaymentDate.year, expectedRepaymentDate.month, expectedRepaymentDate.day);
    final difference = recordDate.difference(today).inDays;

    if (difference < 0) return 'Overdue by ${difference.abs()} days';
    if (difference == 0) return 'Due today';
    if (difference == 1) return 'Due tomorrow';
    if (difference < 7) return 'Due in $difference days';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? 'Due in 1 week' : 'Due in $weeks weeks';
    }
    if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? 'Due in 1 month' : 'Due in $months months';
    }
    final years = (difference / 365).floor();
    return years == 1 ? 'Due in 1 year' : 'Due in $years years';
  }

  // Formatted amounts
  String get formattedAmountBorrowed => 'PKR ${amountBorrowed.toStringAsFixed(2)}';
  String get formattedAmountPaid => 'PKR ${amountPaid.toStringAsFixed(2)}';
  String get formattedBalanceRemaining => 'PKR ${balanceRemaining.toStringAsFixed(2)}';
  String get formattedPaymentPercentage => '${paymentPercentage.toStringAsFixed(1)}%';

  // Days overdue
  int get daysOverdue {
    if (!isOverdueComputed) return 0;
    return DateTime.now().difference(expectedRepaymentDate).inDays;
  }

  // Vendor display
  String get vendorDisplayName {
    if (vendorBusinessName != null && vendorBusinessName!.isNotEmpty) {
      return vendorBusinessName!;
    }
    if (vendorName != null && vendorName!.isNotEmpty) {
      return vendorName!;
    }
    return 'No vendor';
  }

  // Creditor summary
  String get creditorSummary {
    if (creditorPhone != null && creditorPhone!.isNotEmpty) {
      return '$creditorName ($creditorPhone)';
    }
    if (creditorEmail != null && creditorEmail!.isNotEmpty) {
      return '$creditorName ($creditorEmail)';
    }
    return creditorName;
  }

  // Priority display
  String get priorityDisplay {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return '🚨 Urgent';
      case 'HIGH':
        return '⚠️ High';
      case 'MEDIUM':
        return '📋 Medium';
      case 'LOW':
        return '✅ Low';
      default:
        return priority;
    }
  }

  // Status display
  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return '🟢 Active';
      case 'PAID':
        return '✅ Paid';
      case 'OVERDUE':
        return '🔴 Overdue';
      case 'PARTIALLY_PAID':
        return '🟡 Partially Paid';
      case 'CANCELLED':
        return '❌ Cancelled';
      default:
        return status;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payable && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payable(id: $id, creditorName: $creditorName, amountBorrowed: $amountBorrowed, status: $status)';
  }
}
