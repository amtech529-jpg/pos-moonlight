import 'profit_loss_models.dart';

class ProfitLossListResponse {
  final List<ProfitLossRecord> records;
  final int totalCount;

  ProfitLossListResponse({required this.records, required this.totalCount});

  factory ProfitLossListResponse.fromJson(Map<String, dynamic> json) {
    return ProfitLossListResponse(
      records: (json['records'] as List? ?? json['results'] as List? ?? [])
          .map((recordJson) => ProfitLossRecord.fromJson(recordJson))
          .toList(),
      totalCount: json['total_count'] as int? ?? json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'records': records.map((record) => record.toJson()).toList(), 'total_count': totalCount};
  }
}

class ProfitLossCalculationResponse {
  final String message;
  final ProfitLossRecord record;

  ProfitLossCalculationResponse({required this.message, required this.record});

  factory ProfitLossCalculationResponse.fromJson(Map<String, dynamic> json) {
    return ProfitLossCalculationResponse(
      message: json['message'] as String,
      record: ProfitLossRecord.fromJson(json['record'] as Map<String, dynamic>),
    );
  }
}

class ProfitLossSummaryResponse {
  final ProfitLossSummary summary;

  ProfitLossSummaryResponse({required this.summary});

  factory ProfitLossSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ProfitLossSummaryResponse(summary: ProfitLossSummary.fromJson(json));
  }
}

class ProductProfitabilityResponse {
  final List<ProductProfitability> products;

  ProductProfitabilityResponse({required this.products});

  factory ProductProfitabilityResponse.fromJson(List<dynamic> json) {
    return ProductProfitabilityResponse(
      products: json.map((productJson) => ProductProfitability.fromJson(productJson)).toList(),
    );
  }
}

class ProfitLossDashboardResponse {
  final ProfitLossDashboard dashboard;

  ProfitLossDashboardResponse({required this.dashboard});

  factory ProfitLossDashboardResponse.fromJson(Map<String, dynamic> json) {
    return ProfitLossDashboardResponse(dashboard: ProfitLossDashboard.fromJson(json));
  }
}

// Error response model
class ProfitLossErrorResponse {
  final String error;
  final Map<String, dynamic>? errors;

  ProfitLossErrorResponse({required this.error, this.errors});

  factory ProfitLossErrorResponse.fromJson(Map<String, dynamic> json) {
    return ProfitLossErrorResponse(
      error: json['error'] as String? ?? json['message'] as String? ?? 'Unknown error',
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
