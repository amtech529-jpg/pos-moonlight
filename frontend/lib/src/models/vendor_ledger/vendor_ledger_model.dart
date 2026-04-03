import 'package:intl/intl.dart';

class VendorLedgerEntry {
  final String id;
  final String vendorId;
  final DateTime date;
  final String description;
  final String transactionType;
  final double debit;
  final double credit;
  final double balance;
  final String? referenceNumber;
  final String? paymentMethod;
  final String? notes;

  VendorLedgerEntry({
    required this.id,
    required this.vendorId,
    required this.date,
    required this.description,
    required this.transactionType,
    required this.debit,
    required this.credit,
    required this.balance,
    this.referenceNumber,
    this.paymentMethod,
    this.notes,
  });

  factory VendorLedgerEntry.fromJson(Map<String, dynamic> json) {
    return VendorLedgerEntry(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      description: json['description']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? '',
      debit: (json['debit'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      referenceNumber: json['reference_number']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get formattedDebit => debit > 0 ? 'Rs. ${NumberFormat('#,##0.00').format(debit)}' : '-';
  String get formattedCredit => credit > 0 ? 'Rs. ${NumberFormat('#,##0.00').format(credit)}' : '-';
  String get formattedBalance => 'Rs. ${NumberFormat('#,##0.00').format(balance)}';

  bool get isDebit => debit > 0;
  bool get isCredit => credit > 0;
}

class VendorLedgerSummary {
  final double openingBalance;
  final double totalDebits;
  final double totalCredits;
  final double closingBalance;

  VendorLedgerSummary({
    required this.openingBalance,
    required this.totalDebits,
    required this.totalCredits,
    required this.closingBalance,
  });

  factory VendorLedgerSummary.fromJson(Map<String, dynamic> json) {
    return VendorLedgerSummary(
      openingBalance: (json['opening_balance'] ?? 0).toDouble(),
      totalDebits: (json['total_debits'] ?? 0).toDouble(),
      totalCredits: (json['total_credits'] ?? 0).toDouble(),
      closingBalance: (json['closing_balance'] ?? 0).toDouble(),
    );
  }

  String get formattedOpeningBalance => 'Rs. ${NumberFormat('#,##0.00').format(openingBalance)}';
  String get formattedTotalDebits => 'Rs. ${NumberFormat('#,##0.00').format(totalDebits)}';
  String get formattedTotalCredits => 'Rs. ${NumberFormat('#,##0.00').format(totalCredits)}';
  String get formattedClosingBalance => 'Rs. ${NumberFormat('#,##0.00').format(closingBalance)}';
}

class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

class VendorLedgerResponse {
  final bool success;
  final String? message;
  final List<VendorLedgerEntry> ledgerEntries;
  final VendorLedgerSummary summary;
  final PaginationInfo pagination;

  VendorLedgerResponse({
    required this.success,
    this.message,
    required this.ledgerEntries,
    required this.summary,
    required this.pagination,
  });

  factory VendorLedgerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return VendorLedgerResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      ledgerEntries: (data['ledger_entries'] as List?)  // Changed from 'entries' to 'ledger_entries'
          ?.map((e) => VendorLedgerEntry.fromJson(e))
          .toList() ??
          [],
      summary: VendorLedgerSummary.fromJson(data['summary'] ?? {}),
      pagination: PaginationInfo.fromJson(data['pagination'] ?? {}),
    );
  }

  factory VendorLedgerResponse.error(String message) {
    return VendorLedgerResponse(
      success: false,
      message: message,
      ledgerEntries: [],
      summary: VendorLedgerSummary(
        openingBalance: 0,
        totalDebits: 0,
        totalCredits: 0,
        closingBalance: 0,
      ),
      pagination: PaginationInfo(
        currentPage: 1,
        pageSize: 20,
        totalCount: 0,
        totalPages: 0,
      ),
    );
  }
}
