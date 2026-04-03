import 'package:intl/intl.dart';

class CustomerLedgerEntry {
  final String id;
  final String customerId;
  final DateTime date;
  final String description;
  final String transactionType;
  final double debit;
  final double credit;
  final double balance;
  final String? referenceNumber;
  final String? paymentMethod;
  final String? notes;
  final String? sourceModule;
  final String? status;

  CustomerLedgerEntry({
    required this.id,
    required this.customerId,
    required this.date,
    required this.description,
    required this.transactionType,
    required this.debit,
    required this.credit,
    required this.balance,
    this.referenceNumber,
    this.paymentMethod,
    this.notes,
    this.sourceModule,
    this.status,
  });

  factory CustomerLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CustomerLedgerEntry(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description: json['description']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? '',
      debit: (json['debit'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      referenceNumber: json['reference_number']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      notes: json['notes']?.toString(),
      sourceModule: json['source_module']?.toString(),
      status: json['status']?.toString(),
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get formattedDebit => debit > 0 ? 'Rs. ${NumberFormat('#,##0.00').format(debit)}' : '-';
  String get formattedCredit => credit > 0 ? 'Rs. ${NumberFormat('#,##0.00').format(credit)}' : '-';
  String get formattedBalance => 'Rs. ${NumberFormat('#,##0.00').format(balance)}';

  bool get isDebit => debit > 0;
  bool get isCredit => credit > 0;
  
  String get transactionTypeDisplay {
    switch (transactionType.toUpperCase()) {
      case 'DEBIT':
        return 'Customer Owes';
      case 'CREDIT':
        return 'Customer Paid';
      default:
        return transactionType;
    }
  }
}

class CustomerLedgerSummary {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final double totalSales;
  final double totalPayments;
  final double totalReceivables;
  final double totalReceivablePayments;
  final double totalDebit;
  final double totalCredit;
  final double outstandingBalance;
  final double currentBalance;
  final int totalTransactions;
  final String? firstTransactionDate;
  final String? lastTransactionDate;

  CustomerLedgerSummary({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.totalSales,
    required this.totalPayments,
    required this.totalReceivables,
    required this.totalReceivablePayments,
    required this.totalDebit,
    required this.totalCredit,
    required this.outstandingBalance,
    required this.currentBalance,
    required this.totalTransactions,
    this.firstTransactionDate,
    this.lastTransactionDate,
  });

  factory CustomerLedgerSummary.fromJson(Map<String, dynamic> json) {
    return CustomerLedgerSummary(
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerEmail: json['customer_email']?.toString() ?? '',
      totalSales: (json['total_sales'] ?? 0).toDouble(),
      totalPayments: (json['total_payments'] ?? 0).toDouble(),
      totalReceivables: (json['total_receivables'] ?? 0).toDouble(),
      totalReceivablePayments: (json['total_receivable_payments'] ?? 0).toDouble(),
      totalDebit: (json['total_debit'] ?? 0).toDouble(),
      totalCredit: (json['total_credit'] ?? 0).toDouble(),
      outstandingBalance: (json['outstanding_balance'] ?? 0).toDouble(),
      currentBalance: (json['current_balance'] ?? 0).toDouble(),
      totalTransactions: json['total_transactions'] ?? 0,
      firstTransactionDate: json['first_transaction_date']?.toString(),
      lastTransactionDate: json['last_transaction_date']?.toString(),
    );
  }

  String get formattedTotalSales => 'Rs. ${NumberFormat('#,##0.00').format(totalSales)}';
  String get formattedTotalPayments => 'Rs. ${NumberFormat('#,##0.00').format(totalPayments)}';
  String get formattedTotalReceivables => 'Rs. ${NumberFormat('#,##0.00').format(totalReceivables)}';
  String get formattedTotalDebit => 'Rs. ${NumberFormat('#,##0.00').format(totalDebit)}';
  String get formattedTotalCredit => 'Rs. ${NumberFormat('#,##0.00').format(totalCredit)}';
  String get formattedOutstandingBalance => 'Rs. ${NumberFormat('#,##0.00').format(outstandingBalance)}';
  String get formattedCurrentBalance => 'Rs. ${NumberFormat('#,##0.00').format(currentBalance)}';
  
  String get balanceStatus {
    if (outstandingBalance > 0) {
      return 'Customer Owes';
    } else if (outstandingBalance < 0) {
      return 'Customer Credit';
    } else {
      return 'Settled';
    }
  }
}

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
      totalPages: json['total_pages'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }
}

class CustomerLedgerResponse {
  final bool success;
  final String? message;
  final List<CustomerLedgerEntry> ledgerEntries;
  final CustomerLedgerSummary summary;
  final PaginationInfo pagination;

  CustomerLedgerResponse({
    required this.success,
    this.message,
    required this.ledgerEntries,
    required this.summary,
    required this.pagination,
  });

  factory CustomerLedgerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return CustomerLedgerResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      ledgerEntries: (data['ledger_entries'] as List?)
          ?.map((e) => CustomerLedgerEntry.fromJson(e))
          .toList() ??
          [],
      summary: CustomerLedgerSummary.fromJson(data['summary'] ?? {}),
      pagination: PaginationInfo.fromJson(data['pagination'] ?? {}),
    );
  }

  factory CustomerLedgerResponse.error(String message) {
    return CustomerLedgerResponse(
      success: false,
      message: message,
      ledgerEntries: [],
      summary: CustomerLedgerSummary(
        customerId: '',
        customerName: '',
        customerPhone: '',
        customerEmail: '',
        totalSales: 0,
        totalPayments: 0,
        totalReceivables: 0,
        totalReceivablePayments: 0,
        totalDebit: 0,
        totalCredit: 0,
        outstandingBalance: 0,
        currentBalance: 0,
        totalTransactions: 0,
      ),
      pagination: PaginationInfo(
        currentPage: 1,
        pageSize: 20,
        totalCount: 0,
        totalPages: 0,
        hasNext: false,
        hasPrevious: false,
      ),
    );
  }
}
