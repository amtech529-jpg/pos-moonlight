import 'package:frontend/src/config/api_config.dart';
import 'package:frontend/src/services/api_client.dart';

class LedgerService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getGeneralLedger({
    String? customerId,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, String> queryParams = {};
    if (customerId != null) {
      queryParams['customer_id'] = customerId;
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate;
    }

    final response = await _apiClient.get(
      ApiConfig.invoiceLedger,
      queryParameters: queryParams,
    );

    if (response.data['success'] == true) {
      return response.data['data'];
    } else {
      throw Exception(response.data['message'] ?? 'Failed to load ledger');
    }
  }
}
