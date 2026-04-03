import 'customer_model.dart';

class CustomersListResponse {
  final List<CustomerModel> customers;
  final PaginationInfo pagination;
  final Map<String, dynamic>? filtersApplied;

  CustomersListResponse({
    required this.customers,
    required this.pagination,
    this.filtersApplied,
  });

  factory CustomersListResponse.fromJson(Map<String, dynamic> json) {
    return CustomersListResponse(
      customers: (json['customers'] as List)
          .map((customerJson) => CustomerModel.fromJson(customerJson))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customers': customers.map((customer) => customer.toJson()).toList(),
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

class CustomerStatisticsResponse {
  final int totalCustomers;
  final int newCustomersThisMonth;
  final int recentCustomersThisWeek;
  final int inactiveCustomers;
  final Map<String, int> statusBreakdown;
  final Map<String, int> typeBreakdown;
  final CustomerVerificationStats verificationStats;
  final List<CustomerCountryStats> topCountries;

  CustomerStatisticsResponse({
    required this.totalCustomers,
    required this.newCustomersThisMonth,
    required this.recentCustomersThisWeek,
    required this.inactiveCustomers,
    required this.statusBreakdown,
    required this.typeBreakdown,
    required this.verificationStats,
    required this.topCountries,
  });

  factory CustomerStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return CustomerStatisticsResponse(
      totalCustomers: json['total_customers'] as int,
      newCustomersThisMonth: json['new_customers_this_month'] as int,
      recentCustomersThisWeek: json['recent_customers_this_week'] as int,
      inactiveCustomers: json['inactive_customers'] as int,
      statusBreakdown: Map<String, int>.from(json['status_breakdown'] as Map),
      typeBreakdown: Map<String, int>.from(json['type_breakdown'] as Map),
      verificationStats: CustomerVerificationStats.fromJson(json['verification_stats']),
      topCountries: (json['top_countries'] as List)
          .map((countryJson) => CustomerCountryStats.fromJson(countryJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_customers': totalCustomers,
      'new_customers_this_month': newCustomersThisMonth,
      'recent_customers_this_week': recentCustomersThisWeek,
      'inactive_customers': inactiveCustomers,
      'status_breakdown': statusBreakdown,
      'type_breakdown': typeBreakdown,
      'verification_stats': verificationStats.toJson(),
      'top_countries': topCountries.map((country) => country.toJson()).toList(),
    };
  }
}

class CustomerVerificationStats {
  final int phoneVerified;
  final int emailVerified;
  final int bothVerified;
  final double phoneVerificationRate;
  final double emailVerificationRate;

  CustomerVerificationStats({
    required this.phoneVerified,
    required this.emailVerified,
    required this.bothVerified,
    required this.phoneVerificationRate,
    required this.emailVerificationRate,
  });

  factory CustomerVerificationStats.fromJson(Map<String, dynamic> json) {
    return CustomerVerificationStats(
      phoneVerified: json['phone_verified'] as int,
      emailVerified: json['email_verified'] as int,
      bothVerified: json['both_verified'] as int,
      phoneVerificationRate: (json['phone_verification_rate'] as num).toDouble(),
      emailVerificationRate: (json['email_verification_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_verified': phoneVerified,
      'email_verified': emailVerified,
      'both_verified': bothVerified,
      'phone_verification_rate': phoneVerificationRate,
      'email_verification_rate': emailVerificationRate,
    };
  }
}

class CustomerCountryStats {
  final String country;
  final int count;

  CustomerCountryStats({
    required this.country,
    required this.count,
  });

  factory CustomerCountryStats.fromJson(Map<String, dynamic> json) {
    return CustomerCountryStats(
      country: json['country'] as String,
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'count': count,
    };
  }
}

// Request Models
class CustomerCreateRequest {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? customerType;
  final String? businessName;
  final String? taxNumber;
  final String? notes;

  CustomerCreateRequest({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.customerType,
    this.businessName,
    this.taxNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (customerType != null) 'customer_type': customerType,
      if (businessName != null) 'business_name': businessName,
      if (taxNumber != null) 'tax_number': taxNumber,
      if (notes != null) 'notes': notes,
    };
  }
}

class CustomerUpdateRequest {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? customerType;
  final String? status;
  final String? businessName;
  final String? taxNumber;
  final String? notes;
  final bool? phoneVerified;
  final bool? emailVerified;

  CustomerUpdateRequest({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.customerType,
    this.status,
    this.businessName,
    this.taxNumber,
    this.notes,
    this.phoneVerified,
    this.emailVerified,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (customerType != null) 'customer_type': customerType,
      if (status != null) 'status': status,
      if (businessName != null) 'business_name': businessName,
      if (taxNumber != null) 'tax_number': taxNumber,
      if (notes != null) 'notes': notes,
      if (phoneVerified != null) 'phone_verified': phoneVerified,
      if (emailVerified != null) 'email_verified': emailVerified,
    };
  }
}

class CustomerContactUpdateRequest {
  final String phone;
  final String email;
  final String? address;
  final String? city;
  final String? country;

  CustomerContactUpdateRequest({
    required this.phone,
    required this.email,
    this.address,
    this.city,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    };
  }
}

class CustomerVerificationRequest {
  final String verificationType; // 'phone' or 'email'
  final bool verified;

  CustomerVerificationRequest({
    required this.verificationType,
    this.verified = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'verification_type': verificationType,
      'verified': verified,
    };
  }
}

class CustomerActivityUpdateRequest {
  final String activityType; // 'order' or 'contact'
  final String? activityDate; // ISO format datetime string

  CustomerActivityUpdateRequest({
    required this.activityType,
    this.activityDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'activity_type': activityType,
      if (activityDate != null) 'activity_date': activityDate,
    };
  }
}

class CustomerBulkActionRequest {
  final List<String> customerIds;
  final String action; // 'activate', 'deactivate', 'mark_regular', 'mark_vip', 'verify_phone', 'verify_email'

  CustomerBulkActionRequest({
    required this.customerIds,
    required this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_ids': customerIds,
      'action': action,
    };
  }
}

class CustomerDuplicateRequest {
  final String name;
  final String phone;
  final String? email;

  CustomerDuplicateRequest({
    required this.name,
    required this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
    };
  }
}

// List Parameters
class CustomerListParams {
  final int page;
  final int pageSize;
  final String? search;
  final bool showInactive;
  final String? customerType;
  final String? status;
  final String? city;
  final String? country;
  final String? verified; // 'any', 'phone', 'email', 'both', 'none'
  final String? createdAfter;
  final String? createdBefore;
  final String? sortBy; // 'name', 'created_at', 'updated_at', 'last_order_date', 'status', 'customer_type'
  final String? sortOrder; // 'asc', 'desc'

  CustomerListParams({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.showInactive = false,
    this.customerType,
    this.status,
    this.city,
    this.country,
    this.verified,
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
    if (customerType != null && customerType!.isNotEmpty) {
      params['customer_type'] = customerType!;
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status!;
    }
    if (city != null && city!.isNotEmpty) {
      params['city'] = city!;
    }
    if (country != null && country!.isNotEmpty) {
      params['country'] = country!;
    }
    if (verified != null && verified!.isNotEmpty) {
      params['verified'] = verified!;
    }
    if (createdAfter != null && createdAfter!.isNotEmpty) {
      params['created_after'] = createdAfter!;
    }
    if (createdBefore != null && createdBefore!.isNotEmpty) {
      params['created_before'] = createdBefore!;
    }
    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sort_by'] = sortBy!;
    }
    if (sortOrder != null && sortOrder!.isNotEmpty) {
      params['sort_order'] = sortOrder!;
    }

    return params;
  }

  CustomerListParams copyWith({
    int? page,
    int? pageSize,
    String? search,
    bool? showInactive,
    String? customerType,
    String? status,
    String? city,
    String? country,
    String? verified,
    String? createdAfter,
    String? createdBefore,
    String? sortBy,
    String? sortOrder,
  }) {
    return CustomerListParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      showInactive: showInactive ?? this.showInactive,
      customerType: customerType ?? this.customerType,
      status: status ?? this.status,
      city: city ?? this.city,
      country: country ?? this.country,
      verified: verified ?? this.verified,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'CustomerListParams(page: $page, pageSize: $pageSize, search: $search, showInactive: $showInactive, customerType: $customerType, status: $status, city: $city, country: $country, verified: $verified, createdAfter: $createdAfter, createdBefore: $createdBefore, sortBy: $sortBy, sortOrder: $sortOrder)';
  }
}