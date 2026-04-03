import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/customer_ledger/customer_ledger_model.dart';
import 'api_client.dart';

class CustomerLedgerService {
  final ApiClient _apiClient = ApiClient();

  Future<CustomerLedgerResponse> getCustomerLedger({
    required String customerId,
    int page = 1,
    int pageSize = 20,
    String? startDate,
    String? endDate,
    String? transactionType,
  }) async {
    try {
      debugPrint('🔵 CustomerLedgerService: Starting getCustomerLedger for customerId: $customerId, page: $page');

      // REAL API CALL - Backend endpoint
      debugPrint('🔵 CustomerLedgerService: Calling real API endpoint: ${ApiConfig.customerLedger(customerId)}');
      
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'page_size': pageSize,
      };
      
      if (startDate != null) queryParameters['start_date'] = startDate;
      if (endDate != null) queryParameters['end_date'] = endDate;
      if (transactionType != null) queryParameters['transaction_type'] = transactionType;

      final response = await _apiClient.get(
        ApiConfig.customerLedger(customerId),
        queryParameters: queryParameters,
      );
      
      debugPrint('✅ CustomerLedgerService: API response received');
      debugPrint('📊 CustomerLedgerService: Raw response: ${response.data}');

      final ledgerResponse = CustomerLedgerResponse.fromJson(response.data);
      debugPrint('✅ CustomerLedgerService: Response parsed successfully - ${ledgerResponse.ledgerEntries.length} entries');
      debugPrint('📊 CustomerLedgerService: Summary - Outstanding: ${ledgerResponse.summary.outstandingBalance}, Current: ${ledgerResponse.summary.currentBalance}');

      return ledgerResponse;

    } catch (e) {
      debugPrint('❌ CustomerLedgerService: Error occurred - $e');
      return CustomerLedgerResponse.error('Error fetching customer ledger: $e');
    }
  }

  Future<Map<String, dynamic>?> exportCustomerLedger({
    required String customerId,
    required String format,
    String? startDate,
    String? endDate,
    String? transactionType,
  }) async {
    try {
      debugPrint('🔵 CustomerLedgerService: Starting export for customerId: $customerId, format: $format');

      final Map<String, dynamic> queryParameters = {
        'format': format,
      };
      
      if (startDate != null) queryParameters['start_date'] = startDate;
      if (endDate != null) queryParameters['end_date'] = endDate;
      if (transactionType != null) queryParameters['transaction_type'] = transactionType;

      // TODO: Uncomment when backend is ready
      // final response = await _apiClient.get(
      //   ApiConfig.customerLedger(customerId),
      //   queryParameters: queryParameters,
      // );
      // return response.data;

      await Future.delayed(Duration(seconds: 1));
      debugPrint('✅ CustomerLedgerService: Export mock completed');
      return {'message': 'Export coming soon'};
    } catch (e) {
      debugPrint('❌ CustomerLedgerService: Export error - $e');
      return null;
    }
  }
}
