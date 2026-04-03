import 'dart:io';

// List parameters for advance payments
class AdvancePaymentListParams {
  final int page;
  final int pageSize;
  final String? search;
  final String? laborName;
  final String? laborRole;
  final String? laborPhone;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? hasReceipt;
  final String? sortBy;
  final String? sortOrder;
  final bool showInactive;

  AdvancePaymentListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.laborName,
    this.laborRole,
    this.laborPhone,
    this.minAmount,
    this.maxAmount,
    this.dateFrom,
    this.dateTo,
    this.hasReceipt,
    this.sortBy = 'date',
    this.sortOrder = 'desc',
    this.showInactive = false,
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy ?? 'date',
      'sort_order': sortOrder ?? 'desc',
      'show_inactive': showInactive.toString(),
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (laborName != null && laborName!.isNotEmpty) {
      params['labor_name'] = laborName!;
    }
    if (laborRole != null && laborRole!.isNotEmpty) {
      params['labor_role'] = laborRole!;
    }
    if (laborPhone != null && laborPhone!.isNotEmpty) {
      params['labor_phone'] = laborPhone!;
    }
    if (minAmount != null) {
      params['min_amount'] = minAmount!.toString();
    }
    if (maxAmount != null) {
      params['max_amount'] = maxAmount!.toString();
    }
    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }
    if (hasReceipt != null && hasReceipt!.isNotEmpty) {
      params['has_receipt'] = hasReceipt!;
    }

    return params;
  }

  AdvancePaymentListParams copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? laborName,
    String? laborRole,
    String? laborPhone,
    double? minAmount,
    double? maxAmount,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? hasReceipt,
    String? sortBy,
    String? sortOrder,
    bool? showInactive,
  }) {
    return AdvancePaymentListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      laborName: laborName ?? this.laborName,
      laborRole: laborRole ?? this.laborRole,
      laborPhone: laborPhone ?? this.laborPhone,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      hasReceipt: hasReceipt ?? this.hasReceipt,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      showInactive: showInactive ?? this.showInactive,
    );
  }
}

// Create request for advance payment
class AdvancePaymentCreateRequest {
  final String laborId;
  final double amount;
  final String description;
  final DateTime date;
  final String time; // HH:MM format
  final File? receiptImagePath;

  AdvancePaymentCreateRequest({
    required this.laborId,
    required this.amount,
    required this.description,
    required this.date,
    required this.time,
    this.receiptImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'labor': laborId, // Changed from 'labor_id' to 'labor'
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      // Note: receipt_image_path will be handled separately for file uploads
    };
  }

  // Method to create FormData for file uploads
  Map<String, dynamic> toFormData() {
    return {
      'labor': laborId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      // receipt_image_path will be added separately when handling file uploads
    };
  }

  AdvancePaymentCreateRequest copyWith({String? laborId, double? amount, String? description, DateTime? date, String? time, File? receiptImagePath}) {
    return AdvancePaymentCreateRequest(
      laborId: laborId ?? this.laborId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
    );
  }
}

// Update request for advance payment
class AdvancePaymentUpdateRequest {
  final String laborId;
  final double amount;
  final String description;
  final DateTime date;
  final String time; // HH:MM format
  final File? receiptImagePath;

  AdvancePaymentUpdateRequest({
    required this.laborId,
    required this.amount,
    required this.description,
    required this.date,
    required this.time,
    this.receiptImagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'labor': laborId, // Changed from 'labor_id' to 'labor'
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      // Note: receipt_image_path will be handled separately for file uploads
    };
  }

  // Method to create FormData for file uploads
  Map<String, dynamic> toFormData() {
    return {
      'labor': laborId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      // receipt_image_path will be added separately when handling file uploads
    };
  }

  AdvancePaymentUpdateRequest copyWith({String? laborId, double? amount, String? description, DateTime? date, String? time, File? receiptImagePath}) {
    return AdvancePaymentUpdateRequest(
      laborId: laborId ?? this.laborId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
    );
  }
}

// Bulk action request
class AdvancePaymentBulkActionRequest {
  final List<String> paymentIds;
  final String action; // 'activate', 'deactivate', 'delete'

  AdvancePaymentBulkActionRequest({required this.paymentIds, required this.action});

  Map<String, dynamic> toJson() {
    return {'payment_ids': paymentIds, 'action': action};
  }

  AdvancePaymentBulkActionRequest copyWith({List<String>? paymentIds, String? action}) {
    return AdvancePaymentBulkActionRequest(paymentIds: paymentIds ?? this.paymentIds, action: action ?? this.action);
  }
}

// Search request
class AdvancePaymentSearchRequest {
  final String query;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minAmount;
  final double? maxAmount;
  final int page;
  final int pageSize;

  AdvancePaymentSearchRequest({required this.query, this.dateFrom, this.dateTo, this.minAmount, this.maxAmount, this.page = 1, this.pageSize = 20});

  Map<String, String> toQueryParameters() {
    final params = <String, String>{'q': query, 'page': page.toString(), 'page_size': pageSize.toString()};

    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }
    if (minAmount != null) {
      params['min_amount'] = minAmount!.toString();
    }
    if (maxAmount != null) {
      params['max_amount'] = maxAmount!.toString();
    }

    return params;
  }

  AdvancePaymentSearchRequest copyWith({
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? minAmount,
    double? maxAmount,
    int? page,
    int? pageSize,
  }) {
    return AdvancePaymentSearchRequest(
      query: query ?? this.query,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

// Date range request
class AdvancePaymentDateRangeRequest {
  final DateTime startDate;
  final DateTime endDate;
  final int page;
  final int pageSize;

  AdvancePaymentDateRangeRequest({required this.startDate, required this.endDate, this.page = 1, this.pageSize = 20});

  Map<String, String> toQueryParameters() {
    return {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
  }

  AdvancePaymentDateRangeRequest copyWith({DateTime? startDate, DateTime? endDate, int? page, int? pageSize}) {
    return AdvancePaymentDateRangeRequest(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

// Recent payments request
class AdvancePaymentRecentRequest {
  final int days;
  final int page;
  final int pageSize;

  AdvancePaymentRecentRequest({this.days = 7, this.page = 1, this.pageSize = 20});

  Map<String, String> toQueryParameters() {
    return {'days': days.toString(), 'page': page.toString(), 'page_size': pageSize.toString()};
  }

  AdvancePaymentRecentRequest copyWith({int? days, int? page, int? pageSize}) {
    return AdvancePaymentRecentRequest(days: days ?? this.days, page: page ?? this.page, pageSize: pageSize ?? this.pageSize);
  }
}

// Monthly report request
class AdvancePaymentMonthlyReportRequest {
  final int year;
  final int month;

  AdvancePaymentMonthlyReportRequest({required this.year, required this.month});

  Map<String, String> toQueryParameters() {
    return {'year': year.toString(), 'month': month.toString()};
  }

  AdvancePaymentMonthlyReportRequest copyWith({int? year, int? month}) {
    return AdvancePaymentMonthlyReportRequest(year: year ?? this.year, month: month ?? this.month);
  }
}

// Today payments request
class AdvancePaymentTodayRequest {
  final int page;
  final int pageSize;

  AdvancePaymentTodayRequest({this.page = 1, this.pageSize = 20});

  Map<String, String> toQueryParameters() {
    return {'page': page.toString(), 'page_size': pageSize.toString()};
  }

  AdvancePaymentTodayRequest copyWith({int? page, int? pageSize}) {
    return AdvancePaymentTodayRequest(page: page ?? this.page, pageSize: pageSize ?? this.pageSize);
  }
}
