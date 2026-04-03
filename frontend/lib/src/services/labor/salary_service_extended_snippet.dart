
  /// Generate salary slips for a given month and year
  Future<ApiResponse<List<SalarySlip>>> generateSalarySlips({
    required int month,
    required int year,
    bool force = false,
  }) async {
    try {
      final requestData = {
        'month': month,
        'year': year,
        'force': force,
      };

      DebugHelper.printJson('Generate Salary Slips Request', requestData);

      final response = await _apiClient.post(
        ApiConfig.generateSalarySlips,
        data: requestData,
      );

      DebugHelper.printApiResponse('POST Generate Salary Slips', response.data);

      if (response.statusCode == 201) {
        return ApiResponse<List<SalarySlip>>.fromJson(
          response.data,
          (data) => (data as List).map((e) => SalarySlip.fromJson(e as Map<String, dynamic>)).toList(),
        );
      } else {
        return ApiResponse<List<SalarySlip>>(
          success: false,
          message: response.data['message'] ?? 'Failed to generate salary slips',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Generate salary slips DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<SalarySlip>>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Generate salary slips error: ${e.toString()}');
      return ApiResponse<List<SalarySlip>>(
        success: false,
        message: 'An unexpected error occurred while generating salary slips',
      );
    }
  }

  /// Get salary slips with filtering
  Future<ApiResponse<SalarySlipListResponse>> getSalarySlips({
    int? month,
    int? year,
    String? status,
    String? laborId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (status != null) queryParams['status'] = status;
      if (laborId != null) queryParams['labor_id'] = laborId;

      final response = await _apiClient.get(
        ApiConfig.salarySlips,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Salary Slips', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SalarySlipListResponse>.fromJson(
          response.data,
          (data) => SalarySlipListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<SalarySlipListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get salary slips',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get salary slips DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SalarySlipListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get salary slips error: ${e.toString()}');
      return ApiResponse<SalarySlipListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting salary slips',
      );
    }
  }

  /// Update salary slip status (e.g. mark as PAID)
  Future<ApiResponse<SalarySlip>> updateSalarySlipStatus({
    required String slipId,
    required String status,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.updateSalarySlipStatus(slipId),
        data: {'status': status},
      );

      DebugHelper.printApiResponse('POST Update Salary Slip Status', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SalarySlip>.fromJson(
          response.data,
          (data) => SalarySlip.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<SalarySlip>(
          success: false,
          message: response.data['message'] ?? 'Failed to update salary slip status',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update salary slip status DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SalarySlip>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update salary slip status error: ${e.toString()}');
      return ApiResponse<SalarySlip>(
        success: false,
        message: 'An unexpected error occurred while updating salary slip status',
      );
    }
  }
}
