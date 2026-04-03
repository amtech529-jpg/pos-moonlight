import 'vendor_model.dart';

class VendorsListResponse {
  final List<VendorModel> vendors;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  VendorsListResponse({
    required this.vendors,
    required this.pagination,
    this.filtersApplied,
  });

  factory VendorsListResponse.fromJson(Map<String, dynamic> json) {
    return VendorsListResponse(
      vendors: (json['vendors'] as List)
          .map((vendorJson) => VendorModel.fromJson(vendorJson))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendors': vendors.map((vendor) => vendor.toJson()).toList(),
      'pagination': pagination.toJson(),
      'filters_applied': filtersApplied,
    };
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
      currentPage: json['current_page'] as int,
      pageSize: json['page_size'] as int,
      totalCount: json['total_count'] as int,
      totalPages: json['total_pages'] as int,
      hasNext: json['has_next'] as bool,
      hasPrevious: json['has_previous'] as bool,
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

  @override
  String toString() {
    return 'PaginationInfo(currentPage: $currentPage, pageSize: $pageSize, totalCount: $totalCount, totalPages: $totalPages, hasNext: $hasNext, hasPrevious: $hasPrevious)';
  }
}

class VendorStatisticsResponse {
  final int totalVendors;
  final int activeVendors;
  final int inactiveVendors;
  final int newVendorsThisMonth;
  final int recentVendorsThisWeek;
  final List<VendorCityCount> topCities;
  final List<VendorAreaCount> topAreas;

  VendorStatisticsResponse({
    required this.totalVendors,
    required this.activeVendors,
    required this.inactiveVendors,
    required this.newVendorsThisMonth,
    required this.recentVendorsThisWeek,
    required this.topCities,
    required this.topAreas,
  });

  // Computed properties
  double get monthlyGrowthRate {
    // Simple calculation for demo - you can implement more sophisticated logic
    return totalVendors > 0 ? (newVendorsThisMonth / totalVendors) * 100 : 0.0;
  }

  List<VendorMonthCount> get vendorsByMonth {
    // Placeholder for month-wise data - implement based on your needs
    return [];
  }

  factory VendorStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return VendorStatisticsResponse(
      totalVendors: json['total_vendors'] as int,
      activeVendors: json['active_vendors'] as int,
      inactiveVendors: json['inactive_vendors'] as int,
      newVendorsThisMonth: json['new_vendors_this_month'] as int,
      recentVendorsThisWeek: json['recent_vendors_this_week'] as int,
      topCities: (json['top_cities'] as List)
          .map((cityJson) => VendorCityCount.fromJson(cityJson))
          .toList(),
      topAreas: (json['top_areas'] as List)
          .map((areaJson) => VendorAreaCount.fromJson(areaJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_vendors': totalVendors,
      'active_vendors': activeVendors,
      'inactive_vendors': inactiveVendors,
      'new_vendors_this_month': newVendorsThisMonth,
      'recent_vendors_this_week': recentVendorsThisWeek,
      'top_cities': topCities.map((city) => city.toJson()).toList(),
      'top_areas': topAreas.map((area) => area.toJson()).toList(),
    };
  }
}

class VendorCityCount {
  final String city;
  final int count;

  VendorCityCount({
    required this.city,
    required this.count,
  });

  factory VendorCityCount.fromJson(Map<String, dynamic> json) {
    return VendorCityCount(
      city: json['city'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'count': count,
    };
  }
}

class VendorAreaCount {
  final String area;
  final String city;
  final int count;

  VendorAreaCount({
    required this.area,
    required this.city,
    required this.count,
  });

  factory VendorAreaCount.fromJson(Map<String, dynamic> json) {
    return VendorAreaCount(
      area: json['area'] as String,
      city: json['city'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'city': city,
      'count': count,
    };
  }
}

class VendorMonthCount {
  final String month;
  final String monthName;
  final int count;

  VendorMonthCount({
    required this.month,
    required this.monthName,
    required this.count,
  });

  factory VendorMonthCount.fromJson(Map<String, dynamic> json) {
    return VendorMonthCount(
      month: json['month'] as String,
      monthName: json['month_name'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'month_name': monthName,
      'count': count,
    };
  }
}

class VendorPaymentsResponse {
  final String vendorId;
  final String vendorName;
  final List<VendorPayment> payments;
  final VendorPaymentSummary summary;
  final String note;

  VendorPaymentsResponse({
    required this.vendorId,
    required this.vendorName,
    required this.payments,
    required this.summary,
    required this.note,
  });

  factory VendorPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return VendorPaymentsResponse(
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String,
      payments: [], // Empty for now as it's placeholder
      summary: VendorPaymentSummary(
        totalPayments: json['total_payments'] as int? ?? 0,
        totalAmount: (json['total_payments_amount'] as num?)?.toDouble() ?? 0.0,
        firstPaymentDate: null,
        lastPaymentDate: json['last_payment_date'] != null
            ? DateTime.parse(json['last_payment_date'])
            : null,
        averageAmount: 0.0,
      ),
      note: json['note'] as String? ?? 'Payment integration not yet implemented.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'summary': summary.toJson(),
      'note': note,
    };
  }
}

class VendorPayment {
  final String id;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime paymentDate;
  final String? reference;
  final String? notes;

  VendorPayment({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    this.reference,
    this.notes,
  });

  factory VendorPayment.fromJson(Map<String, dynamic> json) {
    return VendorPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      status: json['status'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      'payment_date': paymentDate.toIso8601String(),
      'reference': reference,
      'notes': notes,
    };
  }
}

class VendorPaymentSummary {
  final int totalPayments;
  final double totalAmount;
  final DateTime? firstPaymentDate;
  final DateTime? lastPaymentDate;
  final double averageAmount;

  VendorPaymentSummary({
    required this.totalPayments,
    required this.totalAmount,
    this.firstPaymentDate,
    this.lastPaymentDate,
    required this.averageAmount,
  });

  factory VendorPaymentSummary.fromJson(Map<String, dynamic> json) {
    return VendorPaymentSummary(
      totalPayments: json['total_payments'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      firstPaymentDate: json['first_payment_date'] != null
          ? DateTime.parse(json['first_payment_date'] as String)
          : null,
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'] as String)
          : null,
      averageAmount: (json['average_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_payments': totalPayments,
      'total_amount': totalAmount,
      'first_payment_date': firstPaymentDate?.toIso8601String(),
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'average_amount': averageAmount,
    };
  }
}

class VendorTransactionsResponse {
  final String vendorId;
  final String vendorName;
  final List<VendorTransaction> transactions;
  final VendorTransactionSummary summary;
  final String note;

  VendorTransactionsResponse({
    required this.vendorId,
    required this.vendorName,
    required this.transactions,
    required this.summary,
    required this.note,
  });

  factory VendorTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return VendorTransactionsResponse(
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String,
      transactions: [], // Empty for now as it's placeholder
      summary: VendorTransactionSummary(
        totalTransactions: 0,
        totalAmount: 0.0,
        pendingAmount: 0.0,
        paidAmount: 0.0,
        lastTransactionDate: null,
      ),
      note: json['note'] as String? ?? 'Transaction integration not yet implemented.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'transactions': transactions.map((transaction) => transaction.toJson()).toList(),
      'summary': summary.toJson(),
      'note': note,
    };
  }
}

class VendorTransaction {
  final String id;
  final String type;
  final double amount;
  final String status;
  final DateTime transactionDate;
  final String? description;

  VendorTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.transactionDate,
    this.description,
  });

  factory VendorTransaction.fromJson(Map<String, dynamic> json) {
    return VendorTransaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'status': status,
      'transaction_date': transactionDate.toIso8601String(),
      'description': description,
    };
  }
}

class VendorTransactionSummary {
  final int totalTransactions;
  final double totalAmount;
  final double pendingAmount;
  final double paidAmount;
  final DateTime? lastTransactionDate;

  VendorTransactionSummary({
    required this.totalTransactions,
    required this.totalAmount,
    required this.pendingAmount,
    required this.paidAmount,
    this.lastTransactionDate,
  });

  factory VendorTransactionSummary.fromJson(Map<String, dynamic> json) {
    return VendorTransactionSummary(
      totalTransactions: json['total_transactions'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      pendingAmount: (json['pending_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_transactions': totalTransactions,
      'total_amount': totalAmount,
      'pending_amount': pendingAmount,
      'paid_amount': paidAmount,
      'last_transaction_date': lastTransactionDate?.toIso8601String(),
    };
  }
}

// Request Models
class VendorCreateRequest {
  final String name;
  final String? businessName;
  final String? cnic;
  final String phone;
  final String? city;
  final String? area;
  final DateTime? createdAt;

  VendorCreateRequest({
    required this.name,
    this.businessName,
    this.cnic,
    required this.phone,
    this.city,
    this.area,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'business_name': businessName,
      'cnic': cnic?.isEmpty == true ? null : cnic, // Send null if empty, otherwise send value
      'phone': phone,
      'city': city,
      'area': area,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class VendorUpdateRequest {
  final String name;
  final String businessName;
  final String? cnic;
  final String phone;
  final String city;
  final String area;

  VendorUpdateRequest({
    required this.name,
    required this.businessName,
    this.cnic,
    required this.phone,
    required this.city,
    required this.area,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'business_name': businessName,
      'cnic': cnic?.isEmpty == true ? null : cnic, // Send null if empty, otherwise send value
      'phone': phone,
      'city': city,
      'area': area,
    };
  }
}

class VendorBulkActionRequest {
  final List<String> vendorIds;
  final String action; // 'activate', 'deactivate'

  VendorBulkActionRequest({
    required this.vendorIds,
    required this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendor_ids': vendorIds,
      'action': action,
    };
  }
}

class VendorNoteRequest {
  final String note;

  VendorNoteRequest({
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'note': note,
    };
  }
}

class VendorNote {
  final String id;
  final String note;
  final String createdByName;
  final DateTime createdAt;

  VendorNote({
    required this.id,
    required this.note,
    required this.createdByName,
    required this.createdAt,
  });

  factory VendorNote.fromJson(Map<String, dynamic> json) {
    return VendorNote(
      id: json['id'] as String,
      note: json['note'] as String,
      createdByName: json['created_by']['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// List Parameters
class VendorListParams {
  final int page;
  final int pageSize;
  final String? search;
  final bool showInactive;
  final String? city;
  final String? area;
  final String? createdAfter;
  final String? createdBefore;
  final String? sortBy; // 'name', 'created_at', 'updated_at', 'business_name'
  final String? sortOrder; // 'asc', 'desc'

  VendorListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.showInactive = false,
    this.city,
    this.area,
    this.createdAfter,
    this.createdBefore,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'show_inactive': showInactive.toString(),
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (city != null && city!.isNotEmpty) {
      params['city'] = city!;
    }
    if (area != null && area!.isNotEmpty) {
      params['area'] = area!;
    }
    if (createdAfter != null && createdAfter!.isNotEmpty) {
      params['created_after'] = createdAfter!;
    }
    if (createdBefore != null && createdBefore!.isNotEmpty) {
      params['created_before'] = createdBefore!;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sort_by'] = sortBy!;
      if (sortOrder != null && sortOrder!.isNotEmpty) {
        params['sort_order'] = sortOrder!;
      }
    }

    return params;
  }

  VendorListParams copyWith({
    int? page,
    int? pageSize,
    String? search,
    bool? showInactive,
    String? city,
    String? area,
    String? createdAfter,
    String? createdBefore,
    String? sortBy,
    String? sortOrder,
  }) {
    return VendorListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      showInactive: showInactive ?? this.showInactive,
      city: city ?? this.city,
      area: area ?? this.area,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'VendorListParams(page: $page, pageSize: $pageSize, search: $search, showInactive: $showInactive, city: $city, area: $area, createdAfter: $createdAfter, createdBefore: $createdBefore, sortBy: $sortBy, sortOrder: $sortOrder)';
  }
}