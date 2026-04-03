class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? address;
  final String? city;
  final String country;
  final String customerType; // 'INDIVIDUAL' or 'BUSINESS'
  final String status; // 'NEW', 'REGULAR', 'VIP', 'INACTIVE'
  final String? notes;
  final bool phoneVerified;
  final bool emailVerified;
  final String? businessName;
  final String? taxNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByEmail;
  final int? createdById;
  final DateTime? lastOrderDate;
  final DateTime? lastContactDate;

  // Computed fields from API
  final String displayName;
  final bool isNewCustomer;
  final bool isRecentCustomer;
  final int customerAgeDays;
  final String initials;
  final bool isPakistaniCustomer;
  final String? phoneCountryCode;
  final String formattedCountryPhone;

  // Sales-related fields from backend
  final int totalSalesCount;
  final double totalSalesAmount;  // Add total sales amount
  final bool hasRecentSales;

  // Display fields from backend
  final String customerTypeDisplay;
  final String statusDisplay;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.address,
    this.city,
    required this.country,
    required this.customerType,
    required this.status,
    this.notes,
    required this.phoneVerified,
    required this.emailVerified,
    this.businessName,
    this.taxNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdByEmail,
    this.createdById,
    this.lastOrderDate,
    this.lastContactDate,
    required this.displayName,
    required this.isNewCustomer,
    required this.isRecentCustomer,
    required this.customerAgeDays,
    required this.initials,
    required this.isPakistaniCustomer,
    this.phoneCountryCode,
    required this.formattedCountryPhone,
    required this.totalSalesCount,
    required this.totalSalesAmount,  // Add total sales amount
    required this.hasRecentSales,
    required this.customerTypeDisplay,
    required this.statusDisplay,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String? ?? 'Pakistan',
      customerType: json['customer_type'] as String? ?? 'INDIVIDUAL',
      status: json['status'] as String? ?? 'NEW',
      notes: json['notes'] as String?,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      emailVerified: json['email_verified'] as bool? ?? false,
      businessName: json['business_name'] as String?,
      taxNumber: json['tax_number'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.parse(json['created_at'] as String),
      createdByEmail: json['created_by_email'] as String?,
      createdById: json['created_by_id'] as int?,
      lastOrderDate: json['last_order_date'] != null ? DateTime.parse(json['last_order_date'] as String) : null,
      lastContactDate: json['last_contact_date'] != null ? DateTime.parse(json['last_contact_date'] as String) : null,
      displayName: json['display_name'] as String? ?? json['name'] as String,
      isNewCustomer: json['is_new_customer'] as bool? ?? false,
      isRecentCustomer: json['is_recent_customer'] as bool? ?? false,
      customerAgeDays: json['customer_age_days'] as int? ?? 0,
      initials: json['initials'] as String? ?? 'CU',
      isPakistaniCustomer: json['is_pakistani_customer'] as bool? ?? false,
      phoneCountryCode: json['phone_country_code'] as String?,
      formattedCountryPhone: json['formatted_country_phone'] as String? ?? '',
      totalSalesCount: json['total_sales_count'] as int? ?? 0,
      totalSalesAmount: (json['total_sales_amount'] as num?)?.toDouble() ?? 0.0,  // Add total sales amount
      hasRecentSales: json['has_recent_sales'] as bool? ?? false,
      customerTypeDisplay: json['customer_type_display'] as String? ?? json['customer_type'] as String,
      statusDisplay: json['status_display'] as String? ?? json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'country': country,
      'customer_type': customerType,
      'status': status,
      'notes': notes,
      'phone_verified': phoneVerified,
      'email_verified': emailVerified,
      'business_name': businessName,
      'tax_number': taxNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by_email': createdByEmail,
      'created_by_id': createdById,
      'last_order_date': lastOrderDate?.toIso8601String(),
      'last_contact_date': lastContactDate?.toIso8601String(),
      'display_name': displayName,
      'is_new_customer': isNewCustomer,
      'is_recent_customer': isRecentCustomer,
      'customer_age_days': customerAgeDays,
      'initials': initials,
      'is_pakistani_customer': isPakistaniCustomer,
      'phone_country_code': phoneCountryCode,
      'formatted_country_phone': formattedCountryPhone,
      'total_sales_count': totalSalesCount,
      'total_sales_amount': totalSalesAmount,  // Add total sales amount
      'has_recent_sales': hasRecentSales,
      'customer_type_display': customerTypeDisplay,
      'status_display': statusDisplay,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? country,
    String? customerType,
    String? status,
    String? notes,
    bool? phoneVerified,
    bool? emailVerified,
    String? businessName,
    String? taxNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByEmail,
    int? createdById,
    DateTime? lastOrderDate,
    DateTime? lastContactDate,
    String? displayName,
    bool? isNewCustomer,
    bool? isRecentCustomer,
    int? customerAgeDays,
    String? initials,
    bool? isPakistaniCustomer,
    String? phoneCountryCode,
    String? formattedCountryPhone,
    int? totalSalesCount,
    double? totalSalesAmount,  // Add total sales amount
    bool? hasRecentSales,
    String? customerTypeDisplay,
    String? statusDisplay,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      customerType: customerType ?? this.customerType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      emailVerified: emailVerified ?? this.emailVerified,
      businessName: businessName ?? this.businessName,
      taxNumber: taxNumber ?? this.taxNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdById: createdById ?? this.createdById,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      displayName: displayName ?? this.displayName,
      isNewCustomer: isNewCustomer ?? this.isNewCustomer,
      isRecentCustomer: isRecentCustomer ?? this.isRecentCustomer,
      customerAgeDays: customerAgeDays ?? this.customerAgeDays,
      initials: initials ?? this.initials,
      isPakistaniCustomer: isPakistaniCustomer ?? this.isPakistaniCustomer,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      formattedCountryPhone: formattedCountryPhone ?? this.formattedCountryPhone,
      totalSalesCount: totalSalesCount ?? this.totalSalesCount,
      totalSalesAmount: totalSalesAmount ?? this.totalSalesAmount,  // Add total sales amount
      hasRecentSales: hasRecentSales ?? this.hasRecentSales,
      customerTypeDisplay: customerTypeDisplay ?? this.customerTypeDisplay,
      statusDisplay: statusDisplay ?? this.statusDisplay,
    );
  }

  // Formatted dates for display
  String get formattedCreatedAt {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  String get formattedUpdatedAt {
    return '${updatedAt.day.toString().padLeft(2, '0')}/${updatedAt.month.toString().padLeft(2, '0')}/${updatedAt.year}';
  }

  String get formattedLastOrderDate {
    if (lastOrderDate == null) return 'Never';
    return '${lastOrderDate!.day.toString().padLeft(2, '0')}/${lastOrderDate!.month.toString().padLeft(2, '0')}/${lastOrderDate!.year}';
  }

  String get formattedLastContactDate {
    if (lastContactDate == null) return 'Never';
    return '${lastContactDate!.day.toString().padLeft(2, '0')}/${lastContactDate!.month.toString().padLeft(2, '0')}/${lastContactDate!.year}';
  }

  // Sales-related getters for customer table
  double? get lastPurchase {
    // Return the total sales amount if customer has sales
    return totalSalesAmount > 0 ? totalSalesAmount : null;
  }

  DateTime? get lastPurchaseDate {
    // Use lastOrderDate as the purchase date
    return lastOrderDate;
  }

  // Relative dates
  String get relativeCreatedAt {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final customerDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final difference = today.difference(customerDate).inDays;
    return _getRelativeDateString(difference);
  }

  String get relativeUpdatedAt {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final customerDate = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
    final difference = today.difference(customerDate).inDays;
    return _getRelativeDateString(difference);
  }

  String get relativeLastOrderDate {
    if (lastOrderDate == null) return 'Never';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(lastOrderDate!.year, lastOrderDate!.month, lastOrderDate!.day);
    final difference = today.difference(orderDate).inDays;
    return _getRelativeDateString(difference);
  }

  String _getRelativeDateString(int difference) {
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  // Helper getters
  String get statusDisplayName {
    switch (status.toUpperCase()) {
      case 'NEW':
        return 'New Customer';
      case 'REGULAR':
        return 'Regular Customer';
      case 'VIP':
        return 'VIP Customer';
      case 'INACTIVE':
        return 'Inactive Customer';
      default:
        return status;
    }
  }

  String get customerTypeDisplayName {
    switch (customerType.toUpperCase()) {
      case 'INDIVIDUAL':
        return 'Individual';
      case 'BUSINESS':
        return 'Business';
      default:
        return customerType;
    }
  }

  bool get hasBusinessInfo {
    return customerType.toUpperCase() == 'BUSINESS' && businessName != null && businessName!.isNotEmpty;
  }

  bool get isVerified {
    return phoneVerified || emailVerified;
  }

  bool get isFullyVerified {
    return phoneVerified && emailVerified;
  }

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, phone: $phone, email: $email, status: $status, customerType: $customerType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.status == status &&
        other.customerType == customerType &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, phone, email, status, customerType, isActive);
  }
}
