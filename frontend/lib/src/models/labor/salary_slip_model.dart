
class SalarySlip {
  final String id;
  final String? referenceNumber;
  final String laborId;
  final String laborName;
  final String laborDesignation;
  final String? laborCnic;
  final String? laborPhone;
  final int month;
  final int year;
  final DateTime salaryDate;
  final double baseSalary;
  final double totalAdvances;
  final double deductions;
  final double bonuses;
  final double netSalary;
  final String status;
  final DateTime? paymentDate;
  final String? notes;
  final String? createdBy;

  SalarySlip({
    required this.id,
    this.referenceNumber,
    required this.laborId,
    required this.laborName,
    required this.laborDesignation,
    this.laborCnic,
    this.laborPhone,
    required this.month,
    required this.year,
    required this.salaryDate,
    required this.baseSalary,
    required this.totalAdvances,
    required this.deductions,
    required this.bonuses,
    required this.netSalary,
    required this.status,
    this.paymentDate,
    this.notes,
    this.createdBy,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: json['id'] as String,
      referenceNumber: json['reference_number'] as String?,
      laborId: json['labor'] as String,
      laborName: json['labor_name'] as String? ?? 'Unknown',
      laborDesignation: json['labor_designation'] as String? ?? '',
      laborCnic: json['labor_cnic'] as String?,
      laborPhone: json['labor_phone'] as String?,
      month: json['month'] as int,
      year: json['year'] as int,
      salaryDate: DateTime.parse(json['salary_date']),
      baseSalary: double.tryParse(json['base_salary'].toString()) ?? 0.0,
      totalAdvances: double.tryParse(json['total_advances'].toString()) ?? 0.0,
      deductions: double.tryParse(json['deductions'].toString()) ?? 0.0,
      bonuses: double.tryParse(json['bonuses'].toString()) ?? 0.0,
      netSalary: double.tryParse(json['net_salary'].toString()) ?? 0.0,
      status: json['status'] as String,
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date']) : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
    );
  }
}

class SalarySlipListResponse {
  final List<SalarySlip> slips;
  final int totalCount;
  final int page;
  final int pageSize;

  SalarySlipListResponse({
    required this.slips,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory SalarySlipListResponse.fromJson(Map<String, dynamic> json) {
    return SalarySlipListResponse(
      slips: (json['slips'] as List?)?.map((e) => SalarySlip.fromJson(e)).toList() ?? [],
      totalCount: (json['pagination'] != null) ? (json['pagination']['total_count'] as int? ?? 0) : 0,
      page: (json['pagination'] != null) ? (json['pagination']['page'] as int? ?? 1) : 1,
      pageSize: (json['pagination'] != null) ? (json['pagination']['page_size'] as int? ?? 20) : 20,
    );
  }
}
