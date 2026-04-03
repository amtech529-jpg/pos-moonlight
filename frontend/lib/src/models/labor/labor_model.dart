class LaborModel {
  final String id;
  final String name;
  final String? cnic;
  final String phoneNumber;
  final String? caste;
  final String designation;
  final DateTime joiningDate;
  final double salary;
  final String area;
  final String city;
  final String gender;
  final int age;
  final double fixedIncentive;
  final String displayName;
  final String initials;
  final bool isNewLabor;
  final bool isRecentLabor;
  final int workExperienceDays;
  final double workExperienceYears;
  final String phoneCountryCode;
  final String formattedPhone;
  final String fullAddress;
  final String genderDisplay;
  final int advancePaymentsCount;
  final double totalAdvanceAmount;
  final int paymentsCount;
  final double totalPaymentsAmount;
  final DateTime? lastPaymentDate;
  final double remainingMonthlySalary;
  final double remainingAdvanceAmount;
  final double totalAdvancesAmount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int? createdById;

  const LaborModel({
    required this.id,
    required this.name,
    this.cnic,
    required this.phoneNumber,
    this.caste,
    required this.designation,
    required this.joiningDate,
    required this.salary,
    required this.area,
    required this.city,
    required this.gender,
    required this.age,
    required this.fixedIncentive,
    required this.displayName,
    required this.initials,
    required this.isNewLabor,
    required this.isRecentLabor,
    required this.workExperienceDays,
    required this.workExperienceYears,
    required this.phoneCountryCode,
    required this.formattedPhone,
    required this.fullAddress,
    required this.genderDisplay,
    required this.advancePaymentsCount,
    required this.totalAdvanceAmount,
    required this.paymentsCount,
    required this.totalPaymentsAmount,
    this.lastPaymentDate,
    required this.remainingMonthlySalary,
    required this.remainingAdvanceAmount,
    required this.totalAdvancesAmount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdById,
  });

  factory LaborModel.fromJson(Map<String, dynamic> json) {
    return LaborModel(
      id: json['id'] as String,
      name: json['name'] as String,
      cnic: json['cnic'] as String?,
      phoneNumber: json['phone_number'] as String,
      caste: json['caste'] as String?,
      designation: json['designation'] as String,
      joiningDate: DateTime.parse(json['joining_date'] as String),
      salary: json['salary'] is String ? double.parse(json['salary'] as String) : (json['salary'] as num?)?.toDouble() ?? 0.0,
      area: json['area'] as String,
      city: json['city'] as String,
      gender: json['gender'] as String,
      age: json['age'] as int? ?? 0,
      fixedIncentive: json['fixed_incentive'] is String ? double.parse(json['fixed_incentive'] as String) : (json['fixed_incentive'] as num?)?.toDouble() ?? 0.0,
      displayName: json['display_name'] as String,
      initials: json['initials'] as String,
      isNewLabor: json['is_new_labor'] as bool? ?? false,
      isRecentLabor: json['is_recent_labor'] as bool? ?? false,
      workExperienceDays: json['work_experience_days'] as int? ?? 0,
      workExperienceYears: json['work_experience_years'] is String
          ? double.parse(json['work_experience_years'] as String)
          : (json['work_experience_years'] as num?)?.toDouble() ?? 0.0,
      phoneCountryCode: json['phone_country_code'] as String? ?? '',
      formattedPhone: json['formatted_phone'] as String? ?? json['phone_number'] as String,
      fullAddress: json['full_address'] as String,
      genderDisplay: json['gender_display'] as String,
      advancePaymentsCount: json['advance_payments_count'] as int? ?? 0,
      totalAdvanceAmount: json['total_advance_amount'] is String
          ? double.parse(json['total_advance_amount'] as String)
          : (json['total_advance_amount'] as num?)?.toDouble() ?? 0.0,
      paymentsCount: json['payments_count'] as int? ?? 0,
      totalPaymentsAmount: json['total_payments_amount'] is String
          ? double.parse(json['total_payments_amount'] as String)
          : (json['total_payments_amount'] as num?)?.toDouble() ?? 0.0,
      lastPaymentDate: json['last_payment_date'] != null ? DateTime.parse(json['last_payment_date'] as String) : null,
      remainingMonthlySalary: json['remaining_monthly_salary'] is String
          ? double.parse(json['remaining_monthly_salary'] as String)
          : (json['remaining_monthly_salary'] as num?)?.toDouble() ?? 0.0,
      remainingAdvanceAmount: json['remaining_advance_amount'] is String
          ? double.parse(json['remaining_advance_amount'] as String)
          : (json['remaining_advance_amount'] as num?)?.toDouble() ?? 0.0,
      totalAdvancesAmount: json['total_advances_amount'] is String
          ? double.parse(json['total_advances_amount'] as String)
          : (json['total_advances_amount'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['created_at'] as String),
      createdBy: json['created_by'] as String? ?? json['created_by_email'] as String?,
      createdById: json['created_by_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cnic': cnic,
      'phone_number': phoneNumber,
      'caste': caste,
      'designation': designation,
      'joining_date': joiningDate.toIso8601String().split('T')[0],
      'salary': salary,
      'area': area,
      'city': city,
      'gender': gender,
      'age': age,
      'fixed_incentive': fixedIncentive,
      'display_name': displayName,
      'initials': initials,
      'is_new_labor': isNewLabor,
      'is_recent_labor': isRecentLabor,
      'work_experience_days': workExperienceDays,
      'work_experience_years': workExperienceYears,
      'phone_country_code': phoneCountryCode,
      'formatted_phone': formattedPhone,
      'full_address': fullAddress,
      'gender_display': genderDisplay,
      'advance_payments_count': advancePaymentsCount,
      'total_advance_amount': totalAdvanceAmount,
      'payments_count': paymentsCount,
      'total_payments_amount': totalPaymentsAmount,
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'remaining_monthly_salary': remainingMonthlySalary,
      'remaining_advance_amount': remainingAdvanceAmount,
      'total_advances_amount': totalAdvancesAmount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'created_by_id': createdById,
    };
  }

  LaborModel copyWith({
    String? id,
    String? name,
    String? cnic,
    String? phoneNumber,
    String? caste,
    String? designation,
    DateTime? joiningDate,
    double? salary,
    String? area,
    String? city,
    String? gender,
    int? age,
    double? fixedIncentive,
    String? displayName,
    String? initials,
    bool? isNewLabor,
    bool? isRecentLabor,
    int? workExperienceDays,
    double? workExperienceYears,
    String? phoneCountryCode,
    String? formattedPhone,
    String? fullAddress,
    String? genderDisplay,
    int? advancePaymentsCount,
    double? totalAdvanceAmount,
    int? paymentsCount,
    double? totalPaymentsAmount,
    DateTime? lastPaymentDate,
    double? remainingMonthlySalary,
    double? remainingAdvanceAmount,
    double? totalAdvancesAmount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? createdById,
  }) {
    return LaborModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cnic: cnic ?? this.cnic,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      caste: caste ?? this.caste,
      designation: designation ?? this.designation,
      joiningDate: joiningDate ?? this.joiningDate,
      salary: salary ?? this.salary,
      area: area ?? this.area,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      fixedIncentive: fixedIncentive ?? this.fixedIncentive,
      displayName: displayName ?? this.displayName,
      initials: initials ?? this.initials,
      isNewLabor: isNewLabor ?? this.isNewLabor,
      isRecentLabor: isRecentLabor ?? this.isRecentLabor,
      workExperienceDays: workExperienceDays ?? this.workExperienceDays,
      workExperienceYears: workExperienceYears ?? this.workExperienceYears,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      formattedPhone: formattedPhone ?? this.formattedPhone,
      fullAddress: fullAddress ?? this.fullAddress,
      genderDisplay: genderDisplay ?? this.genderDisplay,
      advancePaymentsCount: advancePaymentsCount ?? this.advancePaymentsCount,
      totalAdvanceAmount: totalAdvanceAmount ?? this.totalAdvanceAmount,
      paymentsCount: paymentsCount ?? this.paymentsCount,
      totalPaymentsAmount: totalPaymentsAmount ?? this.totalPaymentsAmount,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      remainingMonthlySalary: remainingMonthlySalary ?? this.remainingMonthlySalary,
      remainingAdvanceAmount: remainingAdvanceAmount ?? this.remainingAdvanceAmount,
      totalAdvancesAmount: totalAdvancesAmount ?? this.totalAdvancesAmount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LaborModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LaborModel(id: $id, name: $name, designation: $designation, isActive: $isActive)';
  }
}
