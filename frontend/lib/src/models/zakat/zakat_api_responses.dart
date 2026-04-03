import 'zakat_model.dart';

class ZakatsListResponse {
  final List<Zakat> zakats;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  ZakatsListResponse({required this.zakats, required this.pagination, this.filtersApplied});

  factory ZakatsListResponse.fromJson(Map<String, dynamic> json) {
    return ZakatsListResponse(
      zakats: (json['zakat_entries'] as List).map((zakatJson) => Zakat.fromJson(zakatJson)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'zakats': zakats.map((zakat) => zakat.toJson()).toList(), 'pagination': pagination.toJson(), 'filters_applied': filtersApplied};
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
      currentPage: json['page'] as int? ?? json['current_page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
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

class ZakatStatisticsResponse {
  final int totalZakats;
  final int activeZakats;
  final int inactiveZakats;
  final double totalAmount;
  final double averageAmount;
  final int thisMonthCount;
  final double thisMonthAmount;
  final int thisYearCount;
  final double thisYearAmount;
  final List<ZakatBeneficiaryCount> topBeneficiaries;
  final List<ZakatAuthorityCount> authorityStats;
  final List<ZakatMonthlyCount> monthlyData;

  ZakatStatisticsResponse({
    required this.totalZakats,
    required this.activeZakats,
    required this.inactiveZakats,
    required this.totalAmount,
    required this.averageAmount,
    required this.thisMonthCount,
    required this.thisMonthAmount,
    required this.thisYearCount,
    required this.thisYearAmount,
    required this.topBeneficiaries,
    required this.authorityStats,
    required this.monthlyData,
  });

  factory ZakatStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return ZakatStatisticsResponse(
      totalZakats: json['zakat_count'] as int? ?? 0,
      activeZakats: json['zakat_count'] as int? ?? 0, // Backend doesn't separate active/inactive in stats
      inactiveZakats: 0, // Backend doesn't provide this field
      totalAmount: (json['total_zakat'] as num?)?.toDouble() ?? 0.0,
      averageAmount: (json['average_zakat'] as num?)?.toDouble() ?? 0.0,
      thisMonthCount: 0, // Backend doesn't provide this field
      thisMonthAmount: 0.0, // Backend doesn't provide this field
      thisYearCount: 0, // Backend doesn't provide this field
      thisYearAmount: 0.0, // Backend doesn't provide this field
      topBeneficiaries: (json['top_beneficiaries'] as List?)?.map((item) => ZakatBeneficiaryCount.fromJson(item)).toList() ?? [],
      authorityStats: [], // Backend provides 'by_authority' in different format
      monthlyData: (json['monthly_trend'] as List?)?.map((item) => ZakatMonthlyCount.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_zakats': totalZakats,
      'active_zakats': activeZakats,
      'inactive_zakats': inactiveZakats,
      'total_amount': totalAmount,
      'average_amount': averageAmount,
      'this_month_count': thisMonthCount,
      'this_month_amount': thisMonthAmount,
      'this_year_count': thisYearCount,
      'this_year_amount': thisYearAmount,
      'top_beneficiaries': topBeneficiaries.map((item) => item.toJson()).toList(),
      'authority_stats': authorityStats.map((item) => item.toJson()).toList(),
      'monthly_data': monthlyData.map((item) => item.toJson()).toList(),
    };
  }
}

class ZakatBeneficiaryCount {
  final String beneficiaryName;
  final int count;
  final double totalAmount;

  ZakatBeneficiaryCount({required this.beneficiaryName, required this.count, required this.totalAmount});

  factory ZakatBeneficiaryCount.fromJson(Map<String, dynamic> json) {
    return ZakatBeneficiaryCount(
      beneficiaryName: json['name'] as String? ?? json['beneficiary_name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'beneficiary_name': beneficiaryName, 'count': count, 'total_amount': totalAmount};
  }
}

class ZakatAuthorityCount {
  final String authority;
  final int count;
  final double totalAmount;

  ZakatAuthorityCount({required this.authority, required this.count, required this.totalAmount});

  factory ZakatAuthorityCount.fromJson(Map<String, dynamic> json) {
    return ZakatAuthorityCount(
      authority: json['authority'] as String,
      count: json['count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'authority': authority, 'count': count, 'total_amount': totalAmount};
  }
}

class ZakatMonthlyCount {
  final String month;
  final String monthName;
  final int count;
  final double totalAmount;
  final int year;

  ZakatMonthlyCount({required this.month, required this.monthName, required this.count, required this.totalAmount, required this.year});

  factory ZakatMonthlyCount.fromJson(Map<String, dynamic> json) {
    return ZakatMonthlyCount(
      month: json['month'] as String? ?? '',
      monthName: json['month'] as String? ?? '', // Backend doesn't provide separate month_name
      count: json['count'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      year: DateTime.now().year, // Backend doesn't provide year, use current year as fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {'month': month, 'month_name': monthName, 'count': count, 'total_amount': totalAmount, 'year': year};
  }
}

class ZakatBeneficiaryReportResponse {
  final List<ZakatBeneficiaryReport> beneficiaries;
  final int totalBeneficiaries;
  final double totalDistributed;

  ZakatBeneficiaryReportResponse({required this.beneficiaries, required this.totalBeneficiaries, required this.totalDistributed});

  factory ZakatBeneficiaryReportResponse.fromJson(Map<String, dynamic> json) {
    return ZakatBeneficiaryReportResponse(
      beneficiaries: (json['beneficiaries'] as List).map((item) => ZakatBeneficiaryReport.fromJson(item)).toList(),
      totalBeneficiaries: json['total_beneficiaries'] as int,
      totalDistributed: (json['total_distributed'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beneficiaries': beneficiaries.map((item) => item.toJson()).toList(),
      'total_beneficiaries': totalBeneficiaries,
      'total_distributed': totalDistributed,
    };
  }
}

class ZakatBeneficiaryReport {
  final String beneficiaryName;
  final String? beneficiaryContact;
  final int zakatCount;
  final double totalAmount;
  final DateTime firstZakat;
  final DateTime lastZakat;

  ZakatBeneficiaryReport({
    required this.beneficiaryName,
    this.beneficiaryContact,
    required this.zakatCount,
    required this.totalAmount,
    required this.firstZakat,
    required this.lastZakat,
  });

  factory ZakatBeneficiaryReport.fromJson(Map<String, dynamic> json) {
    return ZakatBeneficiaryReport(
      beneficiaryName: json['beneficiary_name'] as String,
      beneficiaryContact: json['beneficiary_contact'] as String?,
      zakatCount: json['zakat_count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      firstZakat: DateTime.parse(json['first_zakat'] as String),
      lastZakat: DateTime.parse(json['last_zakat'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beneficiary_name': beneficiaryName,
      'beneficiary_contact': beneficiaryContact,
      'zakat_count': zakatCount,
      'total_amount': totalAmount,
      'first_zakat': firstZakat.toIso8601String(),
      'last_zakat': lastZakat.toIso8601String(),
    };
  }
}

// Request Models
class ZakatCreateRequest {
  final String name;
  final String description;
  final DateTime date;
  final String time; // Format: "HH:MM"
  final double amount;
  final String beneficiaryName;
  final String? beneficiaryContact;
  final String? notes;
  final String authorizedBy;

  ZakatCreateRequest({
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.amount,
    required this.beneficiaryName,
    this.beneficiaryContact,
    this.notes,
    required this.authorizedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'time': time,
      'amount': amount,
      'beneficiary_name': beneficiaryName,
      'beneficiary_contact': beneficiaryContact,
      'notes': notes,
      'authorized_by': authorizedBy,
    };
  }
}

class ZakatUpdateRequest {
  final String name;
  final String description;
  final DateTime date;
  final String time; // Format: "HH:MM"
  final double amount;
  final String beneficiaryName;
  final String? beneficiaryContact;
  final String? notes;
  final String authorizedBy;

  ZakatUpdateRequest({
    required this.name,
    required this.description,
    required this.date,
    required this.time,
    required this.amount,
    required this.beneficiaryName,
    this.beneficiaryContact,
    this.notes,
    required this.authorizedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'time': time,
      'amount': amount,
      'beneficiary_name': beneficiaryName,
      'beneficiary_contact': beneficiaryContact,
      'notes': notes,
      'authorized_by': authorizedBy,
    };
  }
}

class ZakatBulkActionRequest {
  final List<String> zakatIds;
  final String action; // 'activate', 'deactivate', 'delete'

  ZakatBulkActionRequest({required this.zakatIds, required this.action});

  Map<String, dynamic> toJson() {
    return {'zakat_ids': zakatIds, 'action': action};
  }
}

class ZakatDateRangeRequest {
  final DateTime startDate;
  final DateTime endDate;
  final int page;
  final int pageSize;

  ZakatDateRangeRequest({required this.startDate, required this.endDate, this.page = 1, this.pageSize = 20});

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'page': page,
      'page_size': pageSize,
    };
  }
}

// List Parameters
class ZakatListParams {
  final int page;
  final int pageSize;
  final String? search;
  final bool showInactive;
  final String? beneficiaryName;
  final String? authorizedBy;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? sortBy; // 'date', 'amount', 'created_at', 'beneficiary_name'
  final String? sortOrder; // 'asc', 'desc'

  ZakatListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.showInactive = false,
    this.beneficiaryName,
    this.authorizedBy,
    this.dateFrom,
    this.dateTo,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page.toString(), 'page_size': pageSize.toString(), 'show_inactive': showInactive.toString()};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (beneficiaryName != null && beneficiaryName!.isNotEmpty) {
      params['beneficiary_name'] = beneficiaryName!;
    }
    if (authorizedBy != null && authorizedBy!.isNotEmpty) {
      params['authorized_by'] = authorizedBy!;
    }
    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sort_by'] = sortBy!;
      if (sortOrder != null && sortOrder!.isNotEmpty) {
        params['sort_order'] = sortOrder!;
      }
    }

    return params;
  }

  ZakatListParams copyWith({
    int? page,
    int? pageSize,
    String? search,
    bool? showInactive,
    String? beneficiaryName,
    String? authorizedBy,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortOrder,
  }) {
    return ZakatListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      showInactive: showInactive ?? this.showInactive,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      authorizedBy: authorizedBy ?? this.authorizedBy,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'ZakatListParams(page: $page, pageSize: $pageSize, search: $search, showInactive: $showInactive, beneficiaryName: $beneficiaryName, authorizedBy: $authorizedBy, dateFrom: $dateFrom, dateTo: $dateTo, sortBy: $sortBy, sortOrder: $sortOrder)';
  }
}
