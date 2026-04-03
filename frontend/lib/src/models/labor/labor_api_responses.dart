import 'package:intl/intl.dart';
import 'labor_model.dart';

class LaborsListResponse {
  final List<LaborModel> labors;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  LaborsListResponse({required this.labors, required this.pagination, this.filtersApplied});

  factory LaborsListResponse.fromJson(Map<String, dynamic> json) {
    return LaborsListResponse(
      labors: (json['labors'] as List<dynamic>?)?.map((laborJson) => LaborModel.fromJson(laborJson as Map<String, dynamic>)).toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'labors': labors.map((labor) => labor.toJson()).toList(), 'pagination': pagination.toJson(), 'filters_applied': filtersApplied};
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
      currentPage: json['current_page'] as int? ?? 1,
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

class LaborStatisticsResponse {
  final int totalLabors;
  final int activeLabors;
  final int inactiveLabors;
  final int newLaborsThisMonth;
  final int recentLaborsThisWeek;
  final LaborSalaryStatistics salaryStatistics;
  final LaborAgeStatistics ageStatistics;
  final List<LaborGenderCount> genderBreakdown;
  final List<LaborDesignationCount> topDesignations;
  final List<LaborCityCount> topCities;
  final List<LaborCasteCount> topCastes;

  LaborStatisticsResponse({
    required this.totalLabors,
    required this.activeLabors,
    required this.inactiveLabors,
    required this.newLaborsThisMonth,
    required this.recentLaborsThisWeek,
    required this.salaryStatistics,
    required this.ageStatistics,
    required this.genderBreakdown,
    required this.topDesignations,
    required this.topCities,
    required this.topCastes,
  });

  factory LaborStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return LaborStatisticsResponse(
      totalLabors: json['total_labors'] as int? ?? 0,
      activeLabors: json['active_labors'] as int? ?? 0,
      inactiveLabors: json['inactive_labors'] as int? ?? 0,
      newLaborsThisMonth: json['new_labors_this_month'] as int? ?? 0,
      recentLaborsThisWeek: json['recent_labors_this_week'] as int? ?? 0,
      salaryStatistics: LaborSalaryStatistics.fromJson(json['salary_statistics'] as Map<String, dynamic>? ?? {}),
      ageStatistics: LaborAgeStatistics.fromJson(json['age_statistics'] as Map<String, dynamic>? ?? {}),
      genderBreakdown:
          (json['gender_breakdown'] as List<dynamic>?)?.map((item) => LaborGenderCount.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      topDesignations:
          (json['top_designations'] as List<dynamic>?)?.map((item) => LaborDesignationCount.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      topCities: (json['top_cities'] as List<dynamic>?)?.map((item) => LaborCityCount.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      topCastes: (json['top_castes'] as List<dynamic>?)?.map((item) => LaborCasteCount.fromJson(item as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_labors': totalLabors,
      'active_labors': activeLabors,
      'inactive_labors': inactiveLabors,
      'new_labors_this_month': newLaborsThisMonth,
      'recent_labors_this_week': recentLaborsThisWeek,
      'salary_statistics': salaryStatistics.toJson(),
      'age_statistics': ageStatistics.toJson(),
      'gender_breakdown': genderBreakdown.map((item) => item.toJson()).toList(),
      'top_designations': topDesignations.map((item) => item.toJson()).toList(),
      'top_cities': topCities.map((item) => item.toJson()).toList(),
      'top_castes': topCastes.map((item) => item.toJson()).toList(),
    };
  }
}

class LaborSalaryStatistics {
  final double? totalSalaryCost;
  final double? avgSalary;
  final double? minSalary;
  final double? maxSalary;
  final int totalLabors;

  LaborSalaryStatistics({this.totalSalaryCost, this.avgSalary, this.minSalary, this.maxSalary, required this.totalLabors});

  factory LaborSalaryStatistics.fromJson(Map<String, dynamic> json) {
    return LaborSalaryStatistics(
      totalSalaryCost: json['total_salary_cost'] is String
          ? double.tryParse(json['total_salary_cost'] as String)
          : (json['total_salary_cost'] as num?)?.toDouble(),
      avgSalary: json['avg_salary'] is String ? double.tryParse(json['avg_salary'] as String) : (json['avg_salary'] as num?)?.toDouble(),
      minSalary: json['min_salary'] is String ? double.tryParse(json['min_salary'] as String) : (json['min_salary'] as num?)?.toDouble(),
      maxSalary: json['max_salary'] is String ? double.tryParse(json['max_salary'] as String) : (json['max_salary'] as num?)?.toDouble(),
      totalLabors: json['total_labors'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_salary_cost': totalSalaryCost,
      'avg_salary': avgSalary,
      'min_salary': minSalary,
      'max_salary': maxSalary,
      'total_labors': totalLabors,
    };
  }
}

class LaborAgeStatistics {
  final double? avgAge;
  final int? minAge;
  final int? maxAge;
  final int totalLabors;

  LaborAgeStatistics({this.avgAge, this.minAge, this.maxAge, required this.totalLabors});

  factory LaborAgeStatistics.fromJson(Map<String, dynamic> json) {
    return LaborAgeStatistics(
      avgAge: json['avg_age'] is String ? double.tryParse(json['avg_age'] as String) : (json['avg_age'] as num?)?.toDouble(),
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      totalLabors: json['total_labors'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'avg_age': avgAge, 'min_age': minAge, 'max_age': maxAge, 'total_labors': totalLabors};
  }
}

class LaborGenderCount {
  final String gender;
  final int count;

  LaborGenderCount({required this.gender, required this.count});

  factory LaborGenderCount.fromJson(Map<String, dynamic> json) {
    return LaborGenderCount(gender: json['gender'] as String? ?? '', count: json['count'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'gender': gender, 'count': count};
  }
}

class LaborDesignationCount {
  final String designation;
  final int count;

  LaborDesignationCount({required this.designation, required this.count});

  factory LaborDesignationCount.fromJson(Map<String, dynamic> json) {
    return LaborDesignationCount(designation: json['designation'] as String? ?? '', count: json['count'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'designation': designation, 'count': count};
  }
}

class LaborCityCount {
  final String city;
  final int count;

  LaborCityCount({required this.city, required this.count});

  factory LaborCityCount.fromJson(Map<String, dynamic> json) {
    return LaborCityCount(city: json['city'] as String? ?? '', count: json['count'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'city': city, 'count': count};
  }
}

class LaborCasteCount {
  final String caste;
  final int count;

  LaborCasteCount({required this.caste, required this.count});

  factory LaborCasteCount.fromJson(Map<String, dynamic> json) {
    return LaborCasteCount(caste: json['caste'] as String? ?? '', count: json['count'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'caste': caste, 'count': count};
  }
}

class LaborSalaryReportResponse {
  final LaborSalaryStatistics salaryStatistics;
  final List<LaborDesignationSalary> designationBreakdown;
  final List<LaborCitySalary> cityBreakdown;
  final List<LaborGenderSalary> genderBreakdown;
  final LaborSalaryRanges salaryRanges;
  final String generatedAt;

  LaborSalaryReportResponse({
    required this.salaryStatistics,
    required this.designationBreakdown,
    required this.cityBreakdown,
    required this.genderBreakdown,
    required this.salaryRanges,
    required this.generatedAt,
  });

  factory LaborSalaryReportResponse.fromJson(Map<String, dynamic> json) {
    return LaborSalaryReportResponse(
      salaryStatistics: LaborSalaryStatistics.fromJson(json['salary_statistics'] as Map<String, dynamic>? ?? {}),
      designationBreakdown:
          (json['designation_breakdown'] as List<dynamic>?)?.map((item) => LaborDesignationSalary.fromJson(item as Map<String, dynamic>)).toList() ??
          [],
      cityBreakdown: (json['city_breakdown'] as List<dynamic>?)?.map((item) => LaborCitySalary.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      genderBreakdown:
          (json['gender_breakdown'] as List<dynamic>?)?.map((item) => LaborGenderSalary.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      salaryRanges: LaborSalaryRanges.fromJson(json['salary_ranges'] as Map<String, dynamic>? ?? {}),
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salary_statistics': salaryStatistics.toJson(),
      'designation_breakdown': designationBreakdown.map((item) => item.toJson()).toList(),
      'city_breakdown': cityBreakdown.map((item) => item.toJson()).toList(),
      'gender_breakdown': genderBreakdown.map((item) => item.toJson()).toList(),
      'salary_ranges': salaryRanges.toJson(),
      'generated_at': generatedAt,
    };
  }
}

class LaborDesignationSalary {
  final String designation;
  final int count;
  final double totalSalary;
  final double avgSalary;

  LaborDesignationSalary({required this.designation, required this.count, required this.totalSalary, required this.avgSalary});

  factory LaborDesignationSalary.fromJson(Map<String, dynamic> json) {
    return LaborDesignationSalary(
      designation: json['designation'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalSalary: json['total_salary'] is String
          ? double.tryParse(json['total_salary'] as String) ?? 0.0
          : (json['total_salary'] as num?)?.toDouble() ?? 0.0,
      avgSalary: json['avg_salary'] is String
          ? double.tryParse(json['avg_salary'] as String) ?? 0.0
          : (json['avg_salary'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'designation': designation, 'count': count, 'total_salary': totalSalary, 'avg_salary': avgSalary};
  }
}

class LaborCitySalary {
  final String city;
  final int count;
  final double totalSalary;
  final double avgSalary;

  LaborCitySalary({required this.city, required this.count, required this.totalSalary, required this.avgSalary});

  factory LaborCitySalary.fromJson(Map<String, dynamic> json) {
    return LaborCitySalary(
      city: json['city'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalSalary: json['total_salary'] is String
          ? double.tryParse(json['total_salary'] as String) ?? 0.0
          : (json['total_salary'] as num?)?.toDouble() ?? 0.0,
      avgSalary: json['avg_salary'] is String
          ? double.tryParse(json['avg_salary'] as String) ?? 0.0
          : (json['avg_salary'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'city': city, 'count': count, 'total_salary': totalSalary, 'avg_salary': avgSalary};
  }
}

class LaborGenderSalary {
  final String gender;
  final int count;
  final double totalSalary;
  final double avgSalary;

  LaborGenderSalary({required this.gender, required this.count, required this.totalSalary, required this.avgSalary});

  factory LaborGenderSalary.fromJson(Map<String, dynamic> json) {
    return LaborGenderSalary(
      gender: json['gender'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalSalary: json['total_salary'] is String
          ? double.tryParse(json['total_salary'] as String) ?? 0.0
          : (json['total_salary'] as num?)?.toDouble() ?? 0.0,
      avgSalary: json['avg_salary'] is String
          ? double.tryParse(json['avg_salary'] as String) ?? 0.0
          : (json['avg_salary'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'gender': gender, 'count': count, 'total_salary': totalSalary, 'avg_salary': avgSalary};
  }
}

class LaborSalaryRanges {
  final int under20k;
  final int between20kTo35k;
  final int between35kTo50k;
  final int between50kTo75k;
  final int above75k;

  LaborSalaryRanges({
    required this.under20k,
    required this.between20kTo35k,
    required this.between35kTo50k,
    required this.between50kTo75k,
    required this.above75k,
  });

  factory LaborSalaryRanges.fromJson(Map<String, dynamic> json) {
    return LaborSalaryRanges(
      under20k: json['under_20k'] as int? ?? 0,
      between20kTo35k: json['20k_to_35k'] as int? ?? 0,
      between35kTo50k: json['35k_to_50k'] as int? ?? 0,
      between50kTo75k: json['50k_to_75k'] as int? ?? 0,
      above75k: json['above_75k'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'under_20k': under20k,
      '20k_to_35k': between20kTo35k,
      '35k_to_50k': between35kTo50k,
      '50k_to_75k': between50kTo75k,
      'above_75k': above75k,
    };
  }
}

class LaborDemographicsReportResponse {
  final LaborAgeStatistics ageStatistics;
  final LaborAgeGroups ageGroups;
  final List<LaborGenderCount> genderBreakdown;
  final List<LaborCasteCount> casteBreakdown;
  final List<LaborLocationCount> locationBreakdown;
  final String generatedAt;

  LaborDemographicsReportResponse({
    required this.ageStatistics,
    required this.ageGroups,
    required this.genderBreakdown,
    required this.casteBreakdown,
    required this.locationBreakdown,
    required this.generatedAt,
  });

  factory LaborDemographicsReportResponse.fromJson(Map<String, dynamic> json) {
    return LaborDemographicsReportResponse(
      ageStatistics: LaborAgeStatistics.fromJson(json['age_statistics'] as Map<String, dynamic>? ?? {}),
      ageGroups: LaborAgeGroups.fromJson(json['age_groups'] as Map<String, dynamic>? ?? {}),
      genderBreakdown:
          (json['gender_breakdown'] as List<dynamic>?)?.map((item) => LaborGenderCount.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      casteBreakdown:
          (json['caste_breakdown'] as List<dynamic>?)?.map((item) => LaborCasteCount.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      locationBreakdown:
          (json['location_breakdown'] as List<dynamic>?)?.map((item) => LaborLocationCount.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age_statistics': ageStatistics.toJson(),
      'age_groups': ageGroups.toJson(),
      'gender_breakdown': genderBreakdown.map((item) => item.toJson()).toList(),
      'caste_breakdown': casteBreakdown.map((item) => item.toJson()).toList(),
      'location_breakdown': locationBreakdown.map((item) => item.toJson()).toList(),
      'generated_at': generatedAt,
    };
  }
}

class LaborAgeGroups {
  final int age16To25;
  final int age26To35;
  final int age36To45;
  final int age46To55;
  final int ageAbove55;

  LaborAgeGroups({required this.age16To25, required this.age26To35, required this.age36To45, required this.age46To55, required this.ageAbove55});

  factory LaborAgeGroups.fromJson(Map<String, dynamic> json) {
    return LaborAgeGroups(
      age16To25: json['16_to_25'] as int? ?? 0,
      age26To35: json['26_to_35'] as int? ?? 0,
      age36To45: json['36_to_45'] as int? ?? 0,
      age46To55: json['46_to_55'] as int? ?? 0,
      ageAbove55: json['above_55'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'16_to_25': age16To25, '26_to_35': age26To35, '36_to_45': age36To45, '46_to_55': age46To55, 'above_55': ageAbove55};
  }
}

class LaborLocationCount {
  final String city;
  final String area;
  final int count;

  LaborLocationCount({required this.city, required this.area, required this.count});

  factory LaborLocationCount.fromJson(Map<String, dynamic> json) {
    return LaborLocationCount(city: json['city'] as String? ?? '', area: json['area'] as String? ?? '', count: json['count'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'city': city, 'area': area, 'count': count};
  }
}

class LaborPaymentsResponse {
  final String laborId;
  final String laborName;
  final List<dynamic> advancePayments;
  final List<dynamic> regularPayments;
  final double totalAdvanceAmount;
  final double totalPaymentsAmount;
  final double remainingMonthlySalary;
  final DateTime? lastPaymentDate;
  final String note;

  LaborPaymentsResponse({
    required this.laborId,
    required this.laborName,
    required this.advancePayments,
    required this.regularPayments,
    required this.totalAdvanceAmount,
    required this.totalPaymentsAmount,
    required this.remainingMonthlySalary,
    this.lastPaymentDate,
    required this.note,
  });

  factory LaborPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return LaborPaymentsResponse(
      laborId: json['labor_id'] as String? ?? '',
      laborName: json['labor_name'] as String? ?? '',
      advancePayments: json['advance_payments'] as List<dynamic>? ?? [],
      regularPayments: json['regular_payments'] as List<dynamic>? ?? [],
      totalAdvanceAmount: json['total_advance_amount'] is String
          ? double.tryParse(json['total_advance_amount'] as String) ?? 0.0
          : (json['total_advance_amount'] as num?)?.toDouble() ?? 0.0,
      totalPaymentsAmount: json['total_payments_amount'] is String
          ? double.tryParse(json['total_payments_amount'] as String) ?? 0.0
          : (json['total_payments_amount'] as num?)?.toDouble() ?? 0.0,
      remainingMonthlySalary: json['remaining_monthly_salary'] is String
          ? double.tryParse(json['remaining_monthly_salary'] as String) ?? 0.0
          : (json['remaining_monthly_salary'] as num?)?.toDouble() ?? 0.0,
      lastPaymentDate: json['last_payment_date'] != null ? DateTime.tryParse(json['last_payment_date'] as String) : null,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labor_id': laborId,
      'labor_name': laborName,
      'advance_payments': advancePayments,
      'regular_payments': regularPayments,
      'total_advance_amount': totalAdvanceAmount,
      'total_payments_amount': totalPaymentsAmount,
      'remaining_monthly_salary': remainingMonthlySalary,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'note': note,
    };
  }
}

// Request Models
class LaborCreateRequest {
  final String name;
  final String cnic;
  final String phoneNumber;
  final String designation;
  final String joiningDate; // YYYY-MM-DD format
  final double salary;
  final String area;
  final String city;
  final String gender;
  final int age;
  final double fixedIncentive;

  LaborCreateRequest({
    required this.name,
    required this.cnic,
    required this.phoneNumber,
    required this.designation,
    required this.joiningDate,
    required this.salary,
    required this.area,
    required this.city,
    required this.gender,
    required this.age,
    required this.fixedIncentive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cnic': cnic,
      'phone_number': phoneNumber,
      'designation': designation,
      'joining_date': joiningDate,
      'salary': salary,
      'area': area,
      'city': city,
      'gender': gender,
      'age': age,
      'fixed_incentive': fixedIncentive,
    };
  }
}

class LaborUpdateRequest {
  final String name;
  final String cnic;
  final String phoneNumber;
  final String designation;
  final String joiningDate; // YYYY-MM-DD format
  final double salary;
  final String area;
  final String city;
  final String gender;
  final int age;
  final double fixedIncentive;

  LaborUpdateRequest({
    required this.name,
    required this.cnic,
    required this.phoneNumber,
    required this.designation,
    required this.joiningDate,
    required this.salary,
    required this.area,
    required this.city,
    required this.gender,
    required this.age,
    required this.fixedIncentive,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cnic': cnic,
      'phone_number': phoneNumber,
      'designation': designation,
      'joining_date': joiningDate,
      'salary': salary,
      'area': area,
      'city': city,
      'gender': gender,
      'age': age,
      'fixed_incentive': fixedIncentive,
    };
  }
}

class LaborBulkActionRequest {
  final List<String> laborIds;
  final String action; // 'activate', 'deactivate', 'update_salary'
  final double? salaryAmount;
  final double? salaryPercentage;

  LaborBulkActionRequest({required this.laborIds, required this.action, this.salaryAmount, this.salaryPercentage});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'labor_ids': laborIds, 'action': action};

    if (salaryAmount != null) {
      json['salary_amount'] = salaryAmount!;
    }
    if (salaryPercentage != null) {
      json['salary_percentage'] = salaryPercentage!;
    }

    return json;
  }
}

// List Parameters
class LaborListParams {
  final int page;
  final int pageSize;
  final bool showInactive;
  final String? search;
  final String? city;
  final String? area;
  final String? designation;
  final String? caste;
  final String? gender;
  final String? minSalary;
  final String? maxSalary;
  final String? minAge;
  final String? maxAge;
  final String? joinedAfter;
  final String? joinedBefore;
  final String? sortBy;
  final String? sortOrder;

  LaborListParams({
    this.page = 1,
    this.pageSize = 20,
    this.showInactive = false,
    this.search,
    this.city,
    this.area,
    this.designation,
    this.caste,
    this.gender,
    this.minSalary,
    this.maxSalary,
    this.minAge,
    this.maxAge,
    this.joinedAfter,
    this.joinedBefore,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page.toString(), 'page_size': pageSize.toString(), 'show_inactive': showInactive.toString()};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }
    if (city != null && city!.isNotEmpty) {
      params['city'] = city!;
    }
    if (area != null && area!.isNotEmpty) {
      params['area'] = area!;
    }
    if (designation != null && designation!.isNotEmpty) {
      params['designation'] = designation!;
    }
    if (caste != null && caste!.isNotEmpty) {
      params['caste'] = caste!;
    }
    if (gender != null && gender!.isNotEmpty) {
      params['gender'] = gender!;
    }
    if (minSalary != null && minSalary!.isNotEmpty) {
      params['min_salary'] = minSalary!;
    }
    if (maxSalary != null && maxSalary!.isNotEmpty) {
      params['max_salary'] = maxSalary!;
    }
    if (minAge != null && minAge!.isNotEmpty) {
      params['min_age'] = minAge!;
    }
    if (maxAge != null && maxAge!.isNotEmpty) {
      params['max_age'] = maxAge!;
    }
    if (joinedAfter != null && joinedAfter!.isNotEmpty) {
      params['joined_after'] = joinedAfter!;
    }
    if (joinedBefore != null && joinedBefore!.isNotEmpty) {
      params['joined_before'] = joinedBefore!;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sort_by'] = sortBy!;
      if (sortOrder != null && sortOrder!.isNotEmpty) {
        params['sort_order'] = sortOrder!;
      }
    }

    return params;
  }

  LaborListParams copyWith({
    int? page,
    int? pageSize,
    bool? showInactive,
    String? search,
    String? city,
    String? area,
    String? designation,
    String? caste,
    String? gender,
    String? minSalary,
    String? maxSalary,
    String? minAge,
    String? maxAge,
    String? joinedAfter,
    String? joinedBefore,
    String? sortBy,
    String? sortOrder,
  }) {
    return LaborListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      showInactive: showInactive ?? this.showInactive,
      search: search ?? this.search,
      city: city ?? this.city,
      area: area ?? this.area,
      designation: designation ?? this.designation,
      caste: caste ?? this.caste,
      gender: gender ?? this.gender,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      joinedAfter: joinedAfter ?? this.joinedAfter,
      joinedBefore: joinedBefore ?? this.joinedBefore,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'LaborListParams(page: $page, pageSize: $pageSize, showInactive: $showInactive, search: $search, city: $city, area: $area, designation: $designation, caste: $caste, gender: $gender, minSalary: $minSalary, maxSalary: $maxSalary, minAge: $minAge, maxAge: $maxAge, joinedAfter: $joinedAfter, joinedBefore: $joinedBefore, sortBy: $sortBy, sortOrder: $sortOrder)';
  }
}
