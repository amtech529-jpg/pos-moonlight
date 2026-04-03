import 'expenses_model.dart';

class ExpensesListResponse {
  final List<Expense> expenses;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  ExpensesListResponse({required this.expenses, required this.pagination, this.filtersApplied});

  factory ExpensesListResponse.fromJson(Map<String, dynamic> json) {
    return ExpensesListResponse(
      expenses: (json['expenses'] as List).map((expenseJson) => Expense.fromJson(expenseJson)).toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'expenses': expenses.map((expense) => expense.toJson()).toList(), 'pagination': pagination.toJson(), 'filters_applied': filtersApplied};
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

class ExpenseStatisticsResponse {
  final int totalExpenses;
  final double totalAmount;
  final double averageExpense;
  final String formattedTotal;
  final String formattedAverage;
  final Map<String, ExpenseAuthorityStats> byAuthority;
  final Map<String, ExpenseCategoryStats> byCategory;
  final List<ExpenseMonthlyTrend> monthlyTrend;

  ExpenseStatisticsResponse({
    required this.totalExpenses,
    required this.totalAmount,
    required this.averageExpense,
    required this.formattedTotal,
    required this.formattedAverage,
    required this.byAuthority,
    required this.byCategory,
    required this.monthlyTrend,
  });

  factory ExpenseStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseStatisticsResponse(
      totalExpenses: json['expense_count'] as int? ?? 0,
      totalAmount: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      averageExpense: (json['average_expense'] as num?)?.toDouble() ?? 0.0,
      formattedTotal: json['formatted_total'] as String? ?? 'PKR 0.00',
      formattedAverage: json['formatted_average'] as String? ?? 'PKR 0.00',
      byAuthority:
          (json['by_authority'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, ExpenseAuthorityStats.fromJson(value as Map<String, dynamic>)),
          ) ??
          {},
      byCategory:
          (json['by_category'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, ExpenseCategoryStats.fromJson(value as Map<String, dynamic>)),
          ) ??
          {},
      monthlyTrend: (json['monthly_trend'] as List?)?.map((item) => ExpenseMonthlyTrend.fromJson(item)).toList() ?? [],
    );
  }

  double get currentMonthAmount {
     if (monthlyTrend.isEmpty) return 0.0;
     // Assuming the last item in monthlyTrend is the current month, or we iterate to find it.
     // Since backend usually returns trends in order, let's take the last one or 0.
     // However, a better approach is to match the current month string if possible, but 
     // for simplicity and robustness if list is ordered chronologically:
     return monthlyTrend.isNotEmpty ? monthlyTrend.last.totalAmount : 0.0;
  }


  Map<String, dynamic> toJson() {
    return {
      'total_expenses': totalExpenses,
      'total_amount': totalAmount,
      'average_expense': averageExpense,
      'formatted_total': formattedTotal,
      'formatted_average': formattedAverage,
      'by_authority': byAuthority.map((key, value) => MapEntry(key, value.toJson())),
      'by_category': byCategory.map((key, value) => MapEntry(key, value.toJson())),
      'monthly_trend': monthlyTrend.map((item) => item.toJson()).toList(),
    };
  }
}

class ExpenseAuthorityStats {
  final double totalAmount;
  final String formattedAmount;
  final int count;
  final double percentage;

  ExpenseAuthorityStats({required this.totalAmount, required this.formattedAmount, required this.count, required this.percentage});

  factory ExpenseAuthorityStats.fromJson(Map<String, dynamic> json) {
    return ExpenseAuthorityStats(
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount: json['formatted_amount'] as String? ?? 'PKR 0.00',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total_amount': totalAmount, 'formatted_amount': formattedAmount, 'count': count, 'percentage': percentage};
  }
}

class ExpenseCategoryStats {
  final double totalAmount;
  final String formattedAmount;
  final int count;
  final double percentage;

  ExpenseCategoryStats({required this.totalAmount, required this.formattedAmount, required this.count, required this.percentage});

  factory ExpenseCategoryStats.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryStats(
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount: json['formatted_amount'] as String? ?? 'PKR 0.00',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total_amount': totalAmount, 'formatted_amount': formattedAmount, 'count': count, 'percentage': percentage};
  }
}

class ExpenseMonthlyTrend {
  final String month;
  final double totalAmount;
  final String formattedAmount;
  final int count;

  ExpenseMonthlyTrend({required this.month, required this.totalAmount, required this.formattedAmount, required this.count});

  factory ExpenseMonthlyTrend.fromJson(Map<String, dynamic> json) {
    return ExpenseMonthlyTrend(
      month: json['month'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount: json['formatted_amount'] as String? ?? 'PKR 0.00',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'month': month, 'total_amount': totalAmount, 'formatted_amount': formattedAmount, 'count': count};
  }
}

// Request Models
class ExpenseCreateRequest {
  final String expense;
  final String description;
  final DateTime date;
  final String time; // Format: "HH:MM"
  final double amount;
  final String withdrawalBy;
  final String? category;
  final String? notes;
  final bool isRecurring;
  final bool isSalaryDeductible;
  final String? deductibleLaborId;

  ExpenseCreateRequest({
    required this.expense,
    required this.description,
    required this.date,
    required this.time,
    required this.amount,
    required this.withdrawalBy,
    this.category,
    this.notes,
    this.isRecurring = false,
    this.isSalaryDeductible = false,
    this.deductibleLaborId,
  });


  Map<String, dynamic> toJson() {
    return {
      'expense': expense,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'time': time,
      'amount': amount,
      'withdrawal_by': withdrawalBy,
      'category': category,
      'notes': notes,
      'is_recurring': isRecurring,
      'is_salary_deductible': isSalaryDeductible,
      'deductible_labor': deductibleLaborId,
    };
  }

}

class ExpenseUpdateRequest {
  final String expense;
  final String description;
  final DateTime date;
  final String time; // Format: "HH:MM"
  final double amount;
  final String withdrawalBy;
  final String? category;
  final String? notes;
  final bool isRecurring;
  final bool isSalaryDeductible;
  final String? deductibleLaborId;

  ExpenseUpdateRequest({
    required this.expense,
    required this.description,
    required this.date,
    required this.time,
    required this.amount,
    required this.withdrawalBy,
    this.category,
    this.notes,
    this.isRecurring = false,
    this.isSalaryDeductible = false,
    this.deductibleLaborId,
  });


  Map<String, dynamic> toJson() {
    return {
      'expense': expense,
      'description': description,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'time': time,
      'amount': amount,
      'withdrawal_by': withdrawalBy,
      'category': category,
      'notes': notes,
      'is_recurring': isRecurring,
      'is_salary_deductible': isSalaryDeductible,
      'deductible_labor': deductibleLaborId,
    };
  }

}

class ExpenseDateRangeRequest {
  final DateTime startDate;
  final DateTime endDate;
  final int page;
  final int pageSize;

  ExpenseDateRangeRequest({required this.startDate, required this.endDate, this.page = 1, this.pageSize = 20});

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
class ExpenseListParams {
  final int page;
  final int pageSize;
  final String? search;
  final String? withdrawalBy;
  final String? category;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? sortBy; // 'date', 'amount', 'created_at', 'category'
  final String? sortOrder; // 'asc', 'desc'

  ExpenseListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.withdrawalBy,
    this.category,
    this.dateFrom,
    this.dateTo,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page.toString(), 'page_size': pageSize.toString()};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (withdrawalBy != null && withdrawalBy!.isNotEmpty) {
      params['withdrawal_by'] = withdrawalBy!;
    }
    if (category != null && category!.isNotEmpty) {
      params['category'] = category!;
    }
    if (dateFrom != null) {
      params['date_from'] = dateFrom!.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      params['date_to'] = dateTo!.toIso8601String().split('T')[0];
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['ordering'] = sortOrder == 'asc' ? sortBy! : '-$sortBy';
    }

    return params;
  }

  ExpenseListParams copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? withdrawalBy,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortOrder,
  }) {
    return ExpenseListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      withdrawalBy: withdrawalBy ?? this.withdrawalBy,
      category: category ?? this.category,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'ExpenseListParams(page: $page, pageSize: $pageSize, search: $search, withdrawalBy: $withdrawalBy, category: $category, dateFrom: $dateFrom, dateTo: $dateTo, sortBy: $sortBy, sortOrder: $sortOrder)';
  }
}
