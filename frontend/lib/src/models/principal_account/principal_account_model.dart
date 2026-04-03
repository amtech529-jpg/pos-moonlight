import 'package:flutter/material.dart';
import '../common_models.dart';

class PrincipalAccount {
  final String id;
  final DateTime date;
  final TimeOfDay time;
  final String sourceModule;
  final String? sourceId;
  final String description;
  final String type; // 'CREDIT' or 'DEBIT'
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? handledBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCredit;
  final bool isDebit;
  final String relativeDate;

  PrincipalAccount({
    required this.id,
    required this.date,
    required this.time,
    required this.sourceModule,
    this.sourceId,
    required this.description,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.handledBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isCredit,
    required this.isDebit,
    required this.relativeDate,
  });

  factory PrincipalAccount.fromJson(Map<String, dynamic> json) {
    return PrincipalAccount(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      time: _parseTime(json['time'] ?? ''),
      sourceModule: json['source_module'] ?? '',
      sourceId: json['source_id'],
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount'] is String ? double.parse(json['amount'] as String) : (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceBefore: json['balance_before'] is String ? double.parse(json['balance_before'] as String) : (json['balance_before'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: json['balance_after'] is String ? double.parse(json['balance_after'] as String) : (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      handledBy: json['handled_by'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isCredit: json['is_credit'] ?? false,
      isDebit: json['is_debit'] ?? false,
      relativeDate: json['relative_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'source_module': sourceModule,
      'source_id': sourceId,
      'description': description,
      'type': type,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'handled_by': handledBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_credit': isCredit,
      'is_debit': isDebit,
      'relative_date': relativeDate,
    };
  }

  static TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Fallback to current time if parsing fails
    }
    return TimeOfDay.now();
  }

  // Formatted date for display
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formatted time for display
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Combined date and time for sorting
  DateTime get dateTime {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Get color for transaction type
  Color get typeColor {
    return type == 'CREDIT' ? Colors.green : Colors.red;
  }

  // Get icon for transaction type
  IconData get typeIcon {
    return type == 'CREDIT' ? Icons.add_circle_outline : Icons.remove_circle_outline;
  }

  // Get color for source module
  Color get sourceModuleColor {
    switch (sourceModule.toLowerCase()) {
      case 'sales':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'advance_payment':
        return Colors.orange;
      case 'expenses':
        return Colors.red;
      case 'receivables':
        return Colors.purple;
      case 'payables':
        return Colors.brown;
      case 'zakat':
        return Colors.teal;
      case 'labor':
        return Colors.indigo;
      case 'vendor':
        return Colors.amber;
      case 'orders':
        return Colors.cyan;
      case 'adjustment':
        return Colors.grey;
      case 'transfer':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  // Get formatted amount with currency
  String get formattedAmount {
    return 'PKR ${amount.toStringAsFixed(2)}';
  }

  // Get formatted balance after
  String get formattedBalanceAfter {
    return 'PKR ${balanceAfter.toStringAsFixed(2)}';
  }
}

class PrincipalAccountBalance {
  final int id;
  final double currentBalance;
  final DateTime lastUpdated;
  final String? lastTransactionId;
  final String formattedBalance;

  PrincipalAccountBalance({
    required this.id,
    required this.currentBalance,
    required this.lastUpdated,
    this.lastTransactionId,
    required this.formattedBalance,
  });

  factory PrincipalAccountBalance.fromJson(Map<String, dynamic> json) {
    return PrincipalAccountBalance(
      id: json['id'] ?? 0,
      currentBalance: json['current_balance'] is String ? double.parse(json['current_balance'] as String) : (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
      lastTransactionId: json['last_transaction_id'],
      formattedBalance: json['formatted_balance'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'current_balance': currentBalance,
      'last_updated': lastUpdated.toIso8601String(),
      'last_transaction_id': lastTransactionId,
      'formatted_balance': formattedBalance,
    };
  }
}

class PrincipalAccountStatistics {
  final double totalCredits;
  final double totalDebits;
  final double currentBalance;
  final int transactionCount;
  final Map<String, dynamic> moduleBreakdown;
  final Map<String, dynamic> monthlyTrend;
  final List<PrincipalAccount> recentTransactions;

  PrincipalAccountStatistics({
    required this.totalCredits,
    required this.totalDebits,
    required this.currentBalance,
    required this.transactionCount,
    required this.moduleBreakdown,
    required this.monthlyTrend,
    required this.recentTransactions,
  });

  factory PrincipalAccountStatistics.fromJson(Map<String, dynamic> json) {
    return PrincipalAccountStatistics(
      totalCredits: json['total_credits'] is String ? double.parse(json['total_credits'] as String) : (json['total_credits'] as num?)?.toDouble() ?? 0.0,
      totalDebits: json['total_debits'] is String ? double.parse(json['total_debits'] as String) : (json['total_debits'] as num?)?.toDouble() ?? 0.0,
      currentBalance: json['current_balance'] is String ? double.parse(json['current_balance'] as String) : (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] ?? 0,
      moduleBreakdown: json['module_breakdown'] ?? {},
      monthlyTrend: json['monthly_trend'] ?? {},
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)?.map((t) => PrincipalAccount.fromJson(t as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_credits': totalCredits,
      'total_debits': totalDebits,
      'current_balance': currentBalance,
      'transaction_count': transactionCount,
      'module_breakdown': moduleBreakdown,
      'monthly_trend': monthlyTrend,
      'recent_transactions': recentTransactions.map((t) => t.toJson()).toList(),
    };
  }

  // Get formatted values
  String get formattedTotalCredits => 'PKR ${totalCredits.toStringAsFixed(2)}';
  String get formattedTotalDebits => 'PKR ${totalDebits.toStringAsFixed(2)}';
  String get formattedCurrentBalance => 'PKR ${currentBalance.toStringAsFixed(2)}';
}

class PrincipalAccountListResponse {
  final List<PrincipalAccount> transactions;
  final PaginationInfo pagination;

  PrincipalAccountListResponse({required this.transactions, required this.pagination});

  factory PrincipalAccountListResponse.fromJson(Map<String, dynamic> json) {
    return PrincipalAccountListResponse(
      transactions: (json['transactions'] as List<dynamic>?)?.map((t) => PrincipalAccount.fromJson(t)).toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'transactions': transactions.map((t) => t.toJson()).toList(), 'pagination': pagination.toJson()};
  }
}

class PrincipalAccountListParams {
  final int page;
  final int pageSize;
  final String? search;
  final String? sourceModule;
  final String? transactionType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minAmount;
  final double? maxAmount;
  final String? handledBy;
  final bool showInactive;

  PrincipalAccountListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.sourceModule,
    this.transactionType,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
    this.handledBy,
    this.showInactive = false,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page.toString(), 'page_size': pageSize.toString(), 'show_inactive': showInactive.toString()};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (sourceModule != null && sourceModule!.isNotEmpty) {
      params['source_module'] = sourceModule;
    }
    if (transactionType != null && transactionType!.isNotEmpty) {
      params['transaction_type'] = transactionType;
    }
    if (dateFrom != null) {
      params['date_from'] = '${dateFrom!.year}-${dateFrom!.month.toString().padLeft(2, '0')}-${dateFrom!.day.toString().padLeft(2, '0')}';
    }
    if (dateTo != null) {
      params['date_to'] = '${dateTo!.year}-${dateTo!.month.toString().padLeft(2, '0')}-${dateTo!.day.toString().padLeft(2, '0')}';
    }
    if (minAmount != null) {
      params['min_amount'] = minAmount.toString();
    }
    if (maxAmount != null) {
      params['max_amount'] = maxAmount.toString();
    }
    if (handledBy != null && handledBy!.isNotEmpty) {
      params['handled_by'] = handledBy;
    }

    return params;
  }
}

class PrincipalAccountCreateRequest {
  final DateTime date;
  final TimeOfDay time;
  final String sourceModule;
  final String? sourceId;
  final String description;
  final String type;
  final double amount;
  final String? handledBy;
  final String? notes;

  PrincipalAccountCreateRequest({
    required this.date,
    required this.time,
    required this.sourceModule,
    this.sourceId,
    required this.description,
    required this.type,
    required this.amount,
    this.handledBy,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'source_module': sourceModule,
      'source_id': sourceId,
      'description': description,
      'type': type,
      'amount': amount,
      'handled_by': handledBy,
      'notes': notes,
    };
  }
}

class PrincipalAccountUpdateRequest {
  final String? description;
  final String? notes;
  final String? handledBy;

  PrincipalAccountUpdateRequest({this.description, this.notes, this.handledBy});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (description != null) json['description'] = description;
    if (notes != null) json['notes'] = notes;
    if (handledBy != null) json['handled_by'] = handledBy;
    return json;
  }
}

class ModuleTransactionResponse {
  final String transactionId;
  final double newBalance;

  ModuleTransactionResponse({required this.transactionId, required this.newBalance});

  factory ModuleTransactionResponse.fromJson(Map<String, dynamic> json) {
    return ModuleTransactionResponse(transactionId: json['transaction_id'] ?? '', newBalance: (json['new_balance'] ?? 0.0).toDouble());
  }

  Map<String, dynamic> toJson() {
    return {'transaction_id': transactionId, 'new_balance': newBalance};
  }

  String get formattedNewBalance => 'PKR ${newBalance.toStringAsFixed(2)}';
}

// PaginationInfo is now imported from common_models.dart
